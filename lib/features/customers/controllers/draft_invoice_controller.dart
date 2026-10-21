import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/invoice.dart';
import '../../../data/models/pending_order.dart';
import '../../../data/repositories/erp_draft_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/pending_order_repository.dart';

/// سطر قابل للتعديل في مسودة: الكمية فقط تتغير (السعر ثابت وقت الطلب).
class DraftLine {
  final String code;
  final String name;
  final double rate;
  double qty;

  DraftLine({
    required this.code,
    required this.name,
    required this.rate,
    required this.qty,
  });

  double get total => qty * rate;
}

/// مسودة واحدة (فاتورة محلية غير معتمدة): عرضها وتعديلها وحذفها واعتمادها.
///
/// مسودة **لم تُرفع** بعد (أُنشئت دون اتصال): تُعدَّل وتُحذف محليًا فقط، فتُرفع
/// بمحتواها الجديد لاحقًا. مسودة **مرفوعة**: تُعدَّل وتُحذف وتُعتمد في ERPNext
/// أولًا (تحتاج اتصالًا) ثم تتبعها النسخة المحلية.
class DraftInvoiceController extends ChangeNotifier {
  DraftInvoiceController(
    this._invoices,
    this._pending,
    this._erp,
    this._invoice,
  ) {
    resetEdit();
  }

  final InvoiceRepository _invoices;
  final PendingOrderRepository _pending;
  final ErpDraftRepository _erp;

  Invoice _invoice;
  bool _busy = false;
  String? _error;
  bool _disposed = false;

  final List<DraftLine> _lines = [];
  late DateTime _deliveryDate;

  Invoice get invoice => _invoice;
  bool get busy => _busy;
  String? get error => _error;

  /// false = لم تُرفع إلى ERPNext بعد (لا يمكن اعتمادها قبل الرفع)
  bool get isUploaded => !_invoice.pendingUpload && _hasOrderId;

  bool get _hasOrderId => (_invoice.orderId ?? '').isNotEmpty;

  List<DraftLine> get lines => List.unmodifiable(_lines);
  DateTime get deliveryDate => _deliveryDate;
  double get total => _lines.fold(0.0, (sum, l) => sum + l.total);
  bool get canSave => _lines.isNotEmpty && !_busy;

  // ───────────────────────── التعديل ─────────────────────────

  /// يبدأ جلسة تعديل من المحتوى المحفوظ حاليًا.
  void resetEdit() {
    _lines.clear();
    try {
      final raw = _invoice.itemsJson;
      if (raw != null && raw.isNotEmpty) {
        for (final e in jsonDecode(raw) as List) {
          final m = Map<String, dynamic>.from(e as Map);
          final qty = (m['qty'] as num?)?.toDouble() ?? 0;
          if (qty <= 0) continue;
          _lines.add(
            DraftLine(
              code: (m['code'] ?? '').toString(),
              name: (m['name'] ?? m['code'] ?? '').toString(),
              rate: (m['rate'] as num?)?.toDouble() ?? 0,
              qty: qty,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('DraftInvoiceController.resetEdit: $e');
    }
    _deliveryDate = _parseDate(_invoice.deliveryDate) ?? _today();
    _error = null;
    _notify();
  }

  void setQty(int index, double qty) {
    if (index < 0 || index >= _lines.length || !qty.isFinite || qty <= 0) {
      return;
    }
    _lines[index].qty = qty;
    _notify();
  }

  void increment(int index) {
    if (index < 0 || index >= _lines.length) return;
    setQty(index, _lines[index].qty + 1);
  }

  void decrement(int index) {
    if (index < 0 || index >= _lines.length) return;
    final next = _lines[index].qty - 1;
    if (next > 0) setQty(index, next);
  }

  void removeAt(int index) {
    if (index < 0 || index >= _lines.length) return;
    _lines.removeAt(index);
    _notify();
  }

  void setDeliveryDate(DateTime date) {
    _deliveryDate = DateTime(date.year, date.month, date.day);
    _notify();
  }

  // ───────────────────────── الإجراءات ─────────────────────────

  Future<bool> save() async {
    if (_lines.isEmpty) {
      _error = AppStrings.draftNoItems;
      _notify();
      return false;
    }
    return _run(AppStrings.draftSaveFailed, () async {
      final fresh = await _freshDraft();
      final plines = [
        for (final l in _lines)
          PendingOrderLine(
            code: l.code,
            name: l.name,
            qty: l.qty,
            rate: l.rate,
          ),
      ];
      final newTotal = total;
      final date = _isoDate(_deliveryDate);

      if (fresh.pendingUpload) {
        final pending = await _pending.findOpenByInvoice(fresh.id!);
        if (pending == null) throw const _StateChanged();
        await _pending.updateContent(
          pending.id!,
          lines: plines,
          total: newTotal,
          deliveryDate: date,
        );
      } else if ((fresh.orderId ?? '').isNotEmpty) {
        await _erp.updateOrder(
          fresh.orderId!,
          deliveryDate: date,
          lines: plines,
        );
      }

      final json = jsonEncode([
        for (final l in plines)
          {'code': l.code, 'name': l.name, 'qty': l.qty, 'rate': l.rate},
      ]);
      await _invoices.updateDraft(
        fresh.id!,
        itemsJson: json,
        amount: newTotal,
        deliveryDate: date,
      );
      _invoice = fresh.copyWith(
        itemsJson: json,
        amount: newTotal,
        deliveryDate: date,
      );
    });
  }

  Future<bool> delete() {
    return _run(AppStrings.draftDeleteFailed, () async {
      final fresh = await _freshDraft();
      if (fresh.pendingUpload) {
        final pending = await _pending.findOpenByInvoice(fresh.id!);
        if (pending != null) await _pending.delete(pending.id!);
      } else if ((fresh.orderId ?? '').isNotEmpty) {
        await _erp.deleteOrder(fresh.orderId!);
      }
      await _invoices.deleteInvoice(fresh.id!);
    });
  }

  Future<bool> submit() {
    return _run(AppStrings.draftSubmitFailed, () async {
      final fresh = await _freshDraft();
      final orderId = fresh.orderId ?? '';
      if (fresh.pendingUpload || orderId.isEmpty) throw const _StateChanged();

      await _erp.submitOrder(orderId);
      await _invoices.markSubmitted(fresh.id!);
      _invoice = fresh.copyWith(submitted: true);
    });
  }

  // ───────────────────────── داخلي ─────────────────────────

  /// آخر حالة للمسودة من القاعدة (قد تكون رُفعت أو اعتُمدت أو حُذفت منذ فتح الشاشة).
  Future<Invoice> _freshDraft() async {
    final fresh = await _invoices.getInvoice(_invoice.id!);
    if (fresh == null || fresh.submitted) {
      if (fresh != null) _invoice = fresh;
      throw const _StateChanged();
    }
    _invoice = fresh;
    return fresh;
  }

  Future<bool> _run(String fallback, Future<void> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    _notify();
    try {
      await action();
      return true;
    } on _StateChanged {
      _error = AppStrings.draftStateChanged;
      return false;
    } on ErpApiException catch (e) {
      debugPrint('DraftInvoiceController: $e');
      if (e.type == ErpErrorType.network) {
        _error = AppStrings.draftNeedsConnection;
      } else {
        final detail = e.type == ErpErrorType.server ? e.detail : null;
        final base = describeError(e, fallback: fallback);
        _error = detail == null || detail.isEmpty ? base : '$fallback\n$detail';
      }
      return false;
    } catch (e) {
      debugPrint('DraftInvoiceController: $e');
      _error = fallback;
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime? _parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final d = DateTime.tryParse(iso);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  static String _isoDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _StateChanged implements Exception {
  const _StateChanged();
}
