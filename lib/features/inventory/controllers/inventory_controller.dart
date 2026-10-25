import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/inventory_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/inventory_models.dart';
import '../../../data/repositories/erp_inventory_repository.dart';

/// ينشئ متحكمًا جديدًا كلما فُتح قسم «الجرد».
class InventoryControllerFactory {
  InventoryControllerFactory(this._repository);

  final ErpInventoryRepository _repository;

  InventoryController create() => InventoryController(_repository);
}

/// نتيجة محاولة إضافة صنف للقائمة.
enum AddOutcome { added, duplicate, notFound, blocked, error }

/// حالة شاشة الجرد: قائمة أصناف (كل صنف بكميته) تُرسل كلها دفعة واحدة.
class InventoryController extends ChangeNotifier {
  InventoryController(this._repository);

  final ErpInventoryRepository _repository;

  final List<CountLine> _lines = [];
  bool _searching = false;
  bool _sending = false;
  bool _showErrors = false;
  bool _disposed = false;

  /// 'Stock Reconciliation' (جرد لاحق) أو 'Opening Stock' (التحميل الأول)
  String purpose = ErpInventoryRepository.purposeReconciliation;

  List<CountLine> get lines => List.unmodifiable(_lines);
  bool get searching => _searching;
  bool get sending => _sending;

  /// بعد أول محاولة إرسال فاشلة تظهر أخطاء الحقول الناقصة
  bool get showErrors => _showErrors;

  /// الباركود/الرمز → يضيف الصنف للقائمة (دون تكرار).
  Future<({AddOutcome outcome, String message})> addByBarcode(String raw) async {
    final code = normalizeDigits(raw.trim());
    if (code.isEmpty) return (outcome: AddOutcome.notFound, message: '');

    _searching = true;
    _notify();
    try {
      final item = await _repository.findByBarcode(code);
      if (_disposed) return (outcome: AddOutcome.error, message: '');
      if (item == null) {
        return (
          outcome: AddOutcome.notFound,
          message: InventoryStrings.notFound(code),
        );
      }
      if (item.hasSerialOrBatch) {
        return (
          outcome: AddOutcome.blocked,
          message: '${item.name}\n${InventoryStrings.serialBatchBlocked}',
        );
      }
      if (_lines.any((l) => l.item.code == item.code)) {
        return (
          outcome: AddOutcome.duplicate,
          message: InventoryStrings.alreadyInList,
        );
      }
      _lines.insert(0, CountLine(item)); // الأحدث في الأعلى
      return (
        outcome: AddOutcome.added,
        message: InventoryStrings.added(item.name),
      );
    } catch (e) {
      debugPrint('InventoryController.addByBarcode failed: $e');
      return (
        outcome: AddOutcome.error,
        message: _message(e, InventoryStrings.lookupFailed),
      );
    } finally {
      _searching = false;
      _notify();
    }
  }

  /// null = نص فارغ أو غير صالح
  static double? parseQty(String text) {
    if (text.trim().isEmpty) return null;
    final v = parseAmount(text);
    return (v == null || v.isNaN) ? null : v;
  }

  void setQty(CountLine line, String text) {
    line.qty = parseQty(text);
    _notify();
  }

  void setRate(CountLine line, String text) {
    line.rate = parseQty(text);
    _notify();
  }

  void remove(CountLine line) {
    _lines.remove(line);
    _notify();
  }

  void clearAll() {
    _lines.clear();
    _showErrors = false;
    _notify();
  }

  void setPurpose(String value) {
    purpose = value;
    _notify();
  }

  bool get allValid => _lines.isNotEmpty && _lines.every((l) => l.valid);

  /// يرسل القائمة كاملة في طلب واحد (مسودة). يعيد `error` أو `id`.
  Future<({String? error, String? id})> send() async {
    if (_sending) return (error: AppStrings.draftStateChanged, id: null);
    if (_lines.isEmpty) return (error: InventoryStrings.listEmptyTitle, id: null);
    if (!allValid) {
      _showErrors = true;
      _notify();
      return (error: InventoryStrings.fixErrors, id: null);
    }

    _sending = true;
    _notify();
    try {
      final id = await _repository.submitList(
        lines: List.of(_lines),
        purpose: purpose,
      );
      if (_disposed) return (error: null, id: id);
      _lines.clear();
      _showErrors = false;
      return (error: null, id: id);
    } catch (e) {
      // القائمة تبقى كما هي ليعيد المستخدم المحاولة
      debugPrint('InventoryController.send failed: $e');
      return (error: _message(e, InventoryStrings.saveFailed), id: null);
    } finally {
      _sending = false;
      _notify();
    }
  }

  String _message(Object e, String fallback) {
    if (e is ErpApiException) {
      if (e.type == ErpErrorType.network) return AppStrings.draftNeedsConnection;
      final detail = e.type == ErpErrorType.server ? e.detail : null;
      final base = describeError(e, fallback: fallback);
      return (detail == null || detail.isEmpty) ? base : '$fallback\n$detail';
    }
    return fallback;
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
