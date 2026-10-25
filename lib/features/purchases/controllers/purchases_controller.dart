import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/purchase_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/purchase_models.dart';
import '../../../data/repositories/erp_purchases_repository.dart';
import '../../../data/repositories/erp_sales_invoices_repository.dart'
    show PendingPayment;

/// ينشئ متحكمًا جديدًا كلما فُتح قسم «المشتريات».
class PurchasesControllerFactory {
  PurchasesControllerFactory(this._repository);

  final ErpPurchasesRepository _repository;

  PurchasesController create() => PurchasesController(_repository);
}

/// تبويبات الاستلامات.
enum ReceiptBucket { draft, toBill, completed }

/// حالة قسم المشتريات كله: أوامر الشراء والاستلامات والفواتير والدفعات.
///
/// كل شيء يُقرأ من ERPNext، والمستند ينتقل بين التبويبات وحده بحسب حالته هناك.
/// الاستلام والفاتورة والدفعة تُحفظ مسودة ويعتمدها ERPNext.
class PurchasesController extends ChangeNotifier {
  PurchasesController(this._repository);

  final ErpPurchasesRepository _repository;

  List<PurchaseOrder> _orders = [];
  List<PurchaseReceipt> _receipts = [];
  List<PurchaseInvoice> _invoices = [];
  List<PendingPayment> _pending = [];

  bool _loaded = false;
  bool _refreshing = false;
  String? _error;
  bool _disposed = false;
  int _requestId = 0;

  bool get loaded => _loaded;
  bool get refreshing => _refreshing;

  /// خطأ يحل محل المحتوى (فقط حين لا توجد بيانات معروضة)
  String? get error => _error;

  // ───────── القوائم ─────────

  List<PurchaseOrder> ordersByStage(PurchaseStage stage) => UnmodifiableListView([
        for (final o in _orders)
          if (o.stage == stage) o,
      ]);

  /// أحدث نسخة من أمر الشراء (null إن حُذف)
  PurchaseOrder? orderByName(String name) {
    for (final o in _orders) {
      if (o.name == name) return o;
    }
    return null;
  }

  List<PurchaseReceipt> receiptsByBucket(ReceiptBucket bucket) =>
      UnmodifiableListView([
        for (final r in _receipts)
          if (_receiptBucket(r) == bucket) r,
      ]);

  ReceiptBucket? _receiptBucket(PurchaseReceipt r) {
    if (r.docstatus == 0) return ReceiptBucket.draft;
    if (r.docstatus != 1 || r.status == 'Cancelled' || r.status == 'Return') {
      return null;
    }
    return r.billed ? ReceiptBucket.completed : ReceiptBucket.toBill;
  }

  List<PurchaseInvoice> invoicesByBucket(PurchaseInvoiceBucket bucket) =>
      UnmodifiableListView([
        for (final i in _invoices)
          if (i.bucket == bucket) i,
      ]);

  /// مجموع الدفعات المحفوظة مسودة (بانتظار الاعتماد) على فاتورة
  double pendingAmount(String invoiceName) => _pending
      .where((p) => p.invoice == invoiceName)
      .fold<double>(0, (sum, p) => sum + p.amount);

  // ───────── التحميل ─────────

  Future<void> load() => refresh();

  Future<void> refresh() async {
    if (_refreshing) return;
    final requestId = ++_requestId;
    _refreshing = true;
    _error = null;
    _notify();

    try {
      final results = await Future.wait([
        _repository.fetchOrders(),
        _repository.fetchReceipts(),
        _repository.fetchInvoices(),
      ]);
      if (_disposed || requestId != _requestId) return;
      _orders = results[0] as List<PurchaseOrder>;
      _receipts = results[1] as List<PurchaseReceipt>;
      _invoices = results[2] as List<PurchaseInvoice>;
      try {
        _pending = await _repository.reconcilePending();
      } catch (e) {
        debugPrint('PurchasesController.reconcilePending failed: $e');
        _pending = await _repository.readPending();
      }
    } catch (e) {
      if (_disposed || requestId != _requestId) return;
      debugPrint('PurchasesController.refresh failed: $e');
      // نُبقي ما هو معروض إن وُجد، وإلا نعرض الخطأ
      if (!_loaded) {
        _error = e is ErpApiException && e.type == ErpErrorType.network
            ? AppStrings.offlineNoCache
            : describeError(e, fallback: AppStrings.loadInvoicesError);
      }
    }

    _loaded = true;
    _refreshing = false;
    _notify();
  }

  // ───────── أوامر الشراء ─────────

  Future<List<ErpSupplier>> searchSuppliers(String q) =>
      _repository.searchSuppliers(q);

  /// سعر الشراء من Standard Buying (null = غير محدد)
  Future<double?> buyingRate(String code) => _repository.fetchBuyingRate(code);

  Future<List<PurchasableItem>> searchItems(String q) =>
      _repository.searchItems(q);

  /// يحفظ أمر شراء جديدًا (مسودة). يعيد null عند النجاح، وإلا نص الخطأ.
  Future<String?> createOrder({
    required ErpSupplier supplier,
    required List<NewPurchaseLine> lines,
    required DateTime scheduleDate,
  }) async {
    try {
      await _repository.createOrder(
        supplier: supplier,
        lines: lines,
        scheduleDate: scheduleDate,
      );
      await refresh();
      return null;
    } catch (e) {
      return _failure(e, PurchaseStrings.orderCreateFailed, 'createOrder');
    }
  }

  /// يعتمد أمر شراء مسودة (الاعتماد الوحيد من التطبيق).
  Future<String?> approveOrder(PurchaseOrder order) async {
    if (order.docstatus != 0) return AppStrings.draftStateChanged;
    try {
      await _repository.submitOrder(order.name);
      await refresh();
      return null;
    } catch (e) {
      return _failure(e, PurchaseStrings.approveFailed, 'approveOrder');
    }
  }

  Future<String?> deleteOrder(PurchaseOrder order) async {
    if (order.docstatus != 0) return AppStrings.draftStateChanged;
    try {
      await _repository.deleteOrder(order.name);
      await refresh();
      return null;
    } catch (e) {
      return _failure(e, PurchaseStrings.deleteFailed, 'deleteOrder');
    }
  }

  /// استلام: ينشئ استلامًا مسودة من أمر الشراء المعتمد.
  Future<String?> receive(PurchaseOrder order) async {
    if (!order.canReceive) return AppStrings.draftStateChanged;
    try {
      await _repository.createReceiptDraft(order.name);
      await refresh();
      return null;
    } catch (e) {
      return _failure(e, PurchaseStrings.receiveFailed, 'receive');
    }
  }

  // ───────── الفوترة ─────────

  /// فوترة استلام معتمد: ينشئ فاتورة مشتريات مسودة.
  Future<String?> billReceipt(PurchaseReceipt receipt) async {
    if (!receipt.canBill) return AppStrings.draftStateChanged;
    try {
      await _repository.createInvoiceDraft(receipt.name);
      await refresh();
      return null;
    } catch (e) {
      return _failure(e, PurchaseStrings.billFailed, 'billReceipt');
    }
  }

  /// فوترة من أمر الشراء نفسه: تُفوتَر على أحدث استلام معتمد له.
  Future<String?> billOrder(PurchaseOrder order) async {
    if (!order.canBill) return AppStrings.draftStateChanged;
    try {
      final receipt = await _repository.findSubmittedReceipt(order.name);
      if (receipt == null) return PurchaseStrings.billNoReceipt;
      await _repository.createInvoiceDraft(receipt);
      await refresh();
      return null;
    } catch (e) {
      return _failure(e, PurchaseStrings.billFailed, 'billOrder');
    }
  }

  // ───────── الدفع ─────────

  Future<List<String>> modesOfPayment() => _repository.fetchModesOfPayment();

  /// يحفظ دفعة للمورد (مسودة). يعيد null عند النجاح، وإلا نص الخطأ.
  Future<String?> pay(
    PurchaseInvoice invoice, {
    required double amount,
    required String modeOfPayment,
    String? note,
    String? referenceNo,
    DateTime? referenceDate,
  }) async {
    try {
      final payment = await _repository.savePayment(
        invoice: invoice,
        amount: amount,
        modeOfPayment: modeOfPayment,
        note: note,
        referenceNo: referenceNo,
        referenceDate: referenceDate,
      );
      _pending = [..._pending, payment];
      _notify();
      return null;
    } catch (e) {
      return _failure(e, PurchaseStrings.paymentFailed, 'pay');
    }
  }

  // ───────── التفاصيل والطباعة ─────────

  Future<PurchaseDocDetail> detail(String doctype, String name) =>
      _repository.fetchDetail(doctype, name);

  /// يحفظ كميات بنود مستند مسودة. يعيد المستند المحسوب من ERPNext عند النجاح،
  /// وإلا نص الخطأ. القوائم تُحدَّث في الخلفية ليظهر الإجمالي الجديد فيها.
  Future<({PurchaseDocDetail? detail, String? error})> saveItems(
    String doctype,
    String name,
    List<PurchaseLineEdit> edits,
  ) async {
    try {
      final detail = await _repository.updateItems(doctype, name, edits);
      unawaited(refresh());
      return (detail: detail, error: null);
    } catch (e) {
      return (
        detail: null,
        error: _failure(e, PurchaseStrings.itemsSaveFailed, 'saveItems'),
      );
    }
  }

  Future<Uint8List> downloadPdf(String doctype, String name) =>
      _repository.downloadPdf(doctype, name);

  // ───────── أدوات ─────────

  String _failure(Object e, String fallback, String where) {
    debugPrint('PurchasesController.$where: $e');
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
