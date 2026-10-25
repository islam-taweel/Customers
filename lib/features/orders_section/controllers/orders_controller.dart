import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/invoice.dart';
import '../../../data/repositories/erp_draft_repository.dart';
import '../../../data/repositories/erp_fulfillment_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/pending_order_repository.dart';
import '../../customers/controllers/draft_invoice_controller.dart';

/// ينشئ متحكمًا جديدًا كلما فُتح قسم «الطلبات» (نفس نمط بقية المصانع).
class OrdersControllerFactory {
  OrdersControllerFactory(
    this._invoices,
    this._pending,
    this._drafts,
    this._fulfillment,
  );

  final InvoiceRepository _invoices;
  final PendingOrderRepository _pending;
  final ErpDraftRepository _drafts;
  final ErpFulfillmentRepository _fulfillment;

  OrdersController create() =>
      OrdersController(_invoices, _pending, _drafts, _fulfillment);
}

/// طلبيات كل العملاء موزعة على مراحلها: مسودة ← بانتظار التسليم ←
/// بانتظار الفوترة ← مكتملة. كل طلبية تنتقل بين التبويبات وحدها حسب مرحلتها.
///
/// القراءة محلية أولًا (تعمل دون إنترنت)، ثم تُحدَّث المراحل من ERPNext لأن
/// الفوترة (وأحيانًا التسليم) تتم هناك.
class OrdersController extends ChangeNotifier {
  OrdersController(
    this._invoices,
    this._pending,
    this._drafts,
    this._fulfillment,
  );

  final InvoiceRepository _invoices;
  final PendingOrderRepository _pending;
  final ErpDraftRepository _drafts;
  final ErpFulfillmentRepository _fulfillment;

  List<Invoice> _all = [];
  bool _loaded = false;
  bool _refreshing = false;
  String? _notice;
  bool _disposed = false;

  /// true بعد أول قراءة محلية
  bool get loaded => _loaded;

  /// true أثناء تحديث المراحل من ERPNext
  bool get refreshing => _refreshing;

  /// تنبيه فوق التبويبات إن تعذّر التحديث من ERPNext
  String? get notice => _notice;

  /// طلبيات مرحلة واحدة (الأحدث أولًا). الطلبية التي لها سند تسليم مسودة في
  /// ERPNext لا تظهر في «بانتظار التسليم»، فهي في قسم التسليمات.
  List<Invoice> byStage(OrderStage stage) => UnmodifiableListView([
        for (final i in _all)
          if (i.stage == stage &&
              !(stage == OrderStage.toDeliver && i.isErpDeliveryDraft))
            i,
      ]);

  // ───────── التسليمات ─────────

  /// تبويب «مسودة»: سندات تسليم مسودة في ERPNext لم تُعتمد بعد، بلا أزرار
  List<Invoice> get deliveryDrafts => UnmodifiableListView([
        for (final i in _all)
          if (i.isErpDeliveryDraft) i,
      ]);

  /// تبويب «انتظار الفوترة»: طلبيات سُلِّمت أو أُنشئ لها سند تسليم.
  /// زر الفوترة مظلل إلى أن يُعتمد السند في ERPNext ([Invoice.canBill]).
  List<Invoice> get deliveriesToBill => byStage(OrderStage.toBill);

  /// تبويب «مكتملة»: الطلبيات التي فُوتِرت
  List<Invoice> get deliveriesCompleted => byStage(OrderStage.completed);

  /// المرحلة الحالية لطلبية محلية (null إن حُذفت)
  OrderStage? stageOf(int id) {
    for (final i in _all) {
      if (i.id == id) return i.stage;
    }
    return null;
  }

  // ───────────────────────── التحميل ─────────────────────────

  /// قراءة المحلي فورًا ثم تحديث المراحل من ERPNext.
  Future<void> load() async {
    await reloadLocal();
    await refresh();
  }

  /// إعادة قراءة المحلي فقط (بعد تعديل مسودة أو حذفها أو اعتمادها).
  Future<void> reloadLocal() async {
    try {
      _all = await _invoices.getAllInvoices();
    } catch (e) {
      debugPrint('OrdersController.reloadLocal failed: $e');
    }
    _loaded = true;
    _notify();
  }

  /// يقرأ حالتي التسليم والفوترة من ERPNext للطلبيات غير المكتملة، فتنتقل
  /// الطلبية التي سُلِّمت أو فُوتِرت هناك إلى التبويب التالي.
  Future<void> refresh() async {
    if (_refreshing) return;
    final open = [
      for (final i in _all)
        if (i.submitted &&
            !(i.delivered && i.billed) &&
            (i.orderId ?? '').isNotEmpty &&
            i.id != null)
          i,
    ];
    if (open.isEmpty) return;

    _refreshing = true;
    _notice = null;
    _notify();
    try {
      final statuses = await _fulfillment.fetchStatuses([
        for (final i in open) i.orderId!,
      ]);

      // سندات التسليم المسودة التي أُنشئت خارج التطبيق (تبويب «مسودة» في التسليمات).
      // فشل هذا الفحص وحده لا يوقف مزامنة الحالات.
      final pendingCheck = [
        for (final i in open)
          if (!(statuses[i.orderId]?.delivered ?? i.delivered) &&
              (i.deliveryNote ?? '').isEmpty)
            i.orderId!,
      ];
      var drafts = <String>{};
      try {
        if (pendingCheck.isNotEmpty) {
          drafts = await _fulfillment.ordersWithDraftDelivery(pendingCheck);
        }
      } catch (e) {
        debugPrint('OrdersController.refresh drafts check failed: $e');
        drafts = {
          for (final i in open)
            if (i.deliveryDraft) i.orderId!,
        };
      }

      for (final i in open) {
        final s = statuses[i.orderId];
        if (s == null) continue;
        final draft = !s.delivered && drafts.contains(i.orderId);
        if (s.delivered != i.delivered ||
            s.billed != i.billed ||
            draft != i.deliveryDraft) {
          await _invoices.updateFulfillment(
            i.id!,
            delivered: s.delivered,
            billed: s.billed,
            deliveryDraft: draft,
          );
        }
      }

      // سند أو فاتورة أنشأهما التطبيق وحذفهما المسؤول (رفض): تعود الطلبية لمرحلتها.
      // فشل هذا الفحص وحده لا يوقف المزامنة.
      try {
        await _dropRejectedDocs(open, statuses);
      } catch (e) {
        debugPrint('OrdersController.refresh rejected check failed: $e');
      }
      await reloadLocal();
    } catch (e) {
      debugPrint('OrdersController.refresh failed: $e');
      _notice = AppStrings.ordersRefreshFailed;
    } finally {
      _refreshing = false;
      _notify();
    }
  }

  // ───────────────────────── الإجراءات ─────────────────────────

  /// متحكم مسودة واحدة (تعديل/حذف/اعتماد) كما في شاشة فواتير العميل.
  DraftInvoiceController openDraft(Invoice invoice) =>
      DraftInvoiceController(_invoices, _pending, _drafts, invoice);

  /// يسلّم طلبية معتمدة: ينشئ لها سند تسليم مسودة في ERPNext فتنتقل إلى
  /// «انتظار الفوترة» (الفوترة مظللة حتى يُعتمد السند هناك).
  /// يعيد null عند النجاح، وإلا نص الخطأ للعرض.
  Future<String?> deliver(Invoice invoice) async {
    final orderId = invoice.orderId ?? '';
    if (!invoice.submitted ||
        invoice.pendingUpload ||
        orderId.isEmpty ||
        invoice.stage != OrderStage.toDeliver ||
        invoice.isErpDeliveryDraft) {
      return AppStrings.draftStateChanged;
    }
    try {
      final note = await _fulfillment.deliverOrder(orderId);
      await _invoices.markDeliveryCreated(invoice.id!, note);
      await reloadLocal();
      // قد تكون فُوتِرت في ERPNext أصلًا، فنقرأ حالتها الفعلية
      unawaited(refresh());
      return null;
    } on ErpApiException catch (e) {
      debugPrint('OrdersController.deliver: $e');
      if (e.type == ErpErrorType.network) return AppStrings.draftNeedsConnection;
      final detail = e.type == ErpErrorType.server ? e.detail : null;
      final base = describeError(e, fallback: AppStrings.deliverFailed);
      return detail == null || detail.isEmpty
          ? base
          : '${AppStrings.deliverFailed}\n$detail';
    } catch (e) {
      debugPrint('OrdersController.deliver: $e');
      return AppStrings.deliverFailed;
    }
  }

  /// يمسح سند التسليم أو الفاتورة التي أنشأها التطبيق ثم لم تعد موجودة في ERPNext
  /// (حذفها المسؤول عند الرفض) أو أُلغيت.
  Future<void> _dropRejectedDocs(
    List<Invoice> open,
    Map<String, OrderFulfillment> statuses,
  ) async {
    final notes = [
      for (final i in open)
        if ((i.deliveryNote ?? '').isNotEmpty &&
            !(statuses[i.orderId]?.delivered ?? i.delivered))
          i,
    ];
    if (notes.isNotEmpty) {
      final found = await _fulfillment.existingDocs(
        'Delivery Note',
        [for (final i in notes) i.deliveryNote!],
      );
      for (final i in notes) {
        final docstatus = found[i.deliveryNote];
        if (docstatus == null || docstatus == 2) {
          await _invoices.clearDeliveryNote(i.id!);
        }
      }
    }

    final bills = [
      for (final i in open)
        if ((i.salesInvoice ?? '').isNotEmpty &&
            !(statuses[i.orderId]?.billed ?? i.billed))
          i,
    ];
    if (bills.isNotEmpty) {
      final found = await _fulfillment.existingDocs(
        'Sales Invoice',
        [for (final i in bills) i.salesInvoice!],
      );
      for (final i in bills) {
        final docstatus = found[i.salesInvoice];
        if (docstatus == null || docstatus == 2) {
          await _invoices.clearSalesInvoice(i.id!);
        }
      }
    }
  }

  /// يفوتر طلبية سُلِّمت واعتُمد سند تسليمها في ERPNext.
  /// يعيد null عند النجاح، وإلا نص الخطأ للعرض.
  Future<String?> bill(Invoice invoice) async {
    final orderId = invoice.orderId ?? '';
    if (!invoice.canBill || orderId.isEmpty) {
      return AppStrings.draftStateChanged;
    }
    try {
      final name = await _fulfillment.createInvoiceDraft(
        orderId: orderId,
        deliveryNote: invoice.deliveryNote,
      );
      await _invoices.markInvoiceCreated(invoice.id!, name);
      await reloadLocal();
      // نقرأ حالتها الفعلية من ERPNext
      unawaited(refresh());
      return null;
    } on ErpApiException catch (e) {
      debugPrint('OrdersController.bill: $e');
      if (e.type == ErpErrorType.network) return AppStrings.draftNeedsConnection;
      final detail = e.type == ErpErrorType.server ? e.detail : null;
      final base = describeError(e, fallback: AppStrings.billFailed);
      return detail == null || detail.isEmpty
          ? base
          : '${AppStrings.billFailed}\n$detail';
    } catch (e) {
      debugPrint('OrdersController.bill: $e');
      return AppStrings.billFailed;
    }
  }

  /// ملف PDF للطلبية من ERPNext (يرمي عند تعذّره، فتولّد الشاشة بديلًا محليًا).
  Future<Uint8List> downloadPdf(String orderId) =>
      _fulfillment.downloadOrderPdf(orderId);

  /// ملف PDF لسند التسليم إن وُجد (أنشأه التطبيق)، وإلا ملف الطلبية.
  Future<Uint8List> downloadDeliveryPdf(Invoice invoice) {
    final note = invoice.deliveryNote ?? '';
    if (note.isNotEmpty) return _fulfillment.downloadDeliveryNotePdf(note);
    return _fulfillment.downloadOrderPdf(invoice.orderId ?? '');
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
