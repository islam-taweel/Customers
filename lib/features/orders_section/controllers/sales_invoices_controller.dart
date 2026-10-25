import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../data/repositories/erp_sales_invoices_repository.dart';
import '../../../data/repositories/invoice_repository.dart';

/// ينشئ متحكمًا جديدًا كلما فُتح قسم «الطلبات» (نفس نمط بقية المصانع).
class SalesInvoicesControllerFactory {
  SalesInvoicesControllerFactory(this._repository, this._invoices);

  final ErpSalesInvoicesRepository _repository;
  final InvoiceRepository _invoices;

  SalesInvoicesController create() =>
      SalesInvoicesController(_repository, _invoices);
}

/// فواتير المبيعات في تبويباتها: مسودة ← غير مدفوعة ← مدفوعة جزئيًا ← مدفوعة.
///
/// الفاتورة تنتقل بين التبويبات وحدها بحسب مستحقها في ERPNext. الدفعة تُحفظ
/// مسودة هناك، فلا يتغير شيء في الفاتورة إلا بعد اعتمادها في ERPNext.
class SalesInvoicesController extends ChangeNotifier {
  SalesInvoicesController(this._repository, this._invoices);

  final ErpSalesInvoicesRepository _repository;
  final InvoiceRepository _invoices;

  /// فواتير (مسودات) أنشأها التطبيق عند فوترة الطلبيات: تُعرض «غير مدفوعة» فورًا
  Set<String> _appBilled = {};

  List<SalesInvoice> _all = [];
  List<PendingPayment> _pending = [];
  bool _loaded = false;
  bool _refreshing = false;
  String? _error;
  String? _notice;
  bool _disposed = false;
  int _requestId = 0;

  /// وقت البيانات المعروضة: حفظ النسخة المحلية أو آخر جلب ناجح
  DateTime? _dataAt;

  /// true بعد أول قراءة (محلية أو من ERPNext)
  bool get loaded => _loaded;
  bool get refreshing => _refreshing;

  /// خطأ يحل محل المحتوى (فقط حين لا توجد نسخة محفوظة نعرضها)
  String? get error => _error;

  /// تنبيه فوق المحتوى: «غير متصل، تُعرض بيانات محفوظة...»
  String? get notice => _notice;

  /// تبويب الفاتورة: المسودة التي أنشأها التطبيق بالفوترة تُحسب «غير مدفوعة»
  /// (دفعها معطّل حتى يعتمدها المسؤول)، وبقية المسودات تبقى «مسودة».
  InvoiceBucket bucketOf(SalesInvoice i) {
    final bucket = i.bucket;
    if (bucket == InvoiceBucket.draft && _appBilled.contains(i.name)) {
      return InvoiceBucket.unpaid;
    }
    return bucket;
  }

  List<SalesInvoice> byBucket(InvoiceBucket bucket) => UnmodifiableListView([
        for (final i in _all)
          if (bucketOf(i) == bucket) i,
      ]);

  /// مجموع الدفعات المحفوظة مسودة (بانتظار الاعتماد) على فاتورة
  double pendingAmount(String invoiceName) => _pending
      .where((p) => p.invoice == invoiceName)
      .fold<double>(0, (sum, p) => sum + p.amount);

  /// التحميل الأول: المحفوظ يظهر فورًا ثم يُحدَّث من ERPNext.
  Future<void> load() async {
    final cached = await _repository.readCached();
    _pending = await _repository.readPending();
    _appBilled = await _loadAppBilled();
    if (_disposed) return;
    if (cached != null) {
      _all = cached.invoices;
      _dataAt = cached.savedAt;
      _loaded = true;
      _notify();
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    final requestId = ++_requestId;
    _refreshing = true;
    _error = null;
    _notice = null;
    // قد تكون فاتورة جديدة أُنشئت من «التسليمات» منذ آخر تحديث
    _appBilled = await _loadAppBilled();
    _notify();

    try {
      final fresh = await _repository.fetchAll();
      if (_disposed || requestId != _requestId) return;
      _all = fresh.invoices;
      _dataAt = DateTime.now();
      try {
        _pending = await _repository.reconcilePending();
      } catch (e) {
        debugPrint('SalesInvoicesController.reconcilePending failed: $e');
      }
    } catch (e) {
      if (_disposed || requestId != _requestId) return;
      debugPrint('SalesInvoicesController.refresh failed: $e');
      final isOffline = e is ErpApiException && e.type == ErpErrorType.network;
      if (_loaded) {
        // نُبقي المعروض ظاهرًا ونشرح لماذا لم يُحدَّث
        final when = formatDateTime(_dataAt ?? DateTime.now());
        _notice = isOffline
            ? AppStrings.offlineNotice(when)
            : AppStrings.staleNotice(
                describeError(e, fallback: AppStrings.loadInvoicesError),
                when,
              );
      } else {
        _error = isOffline
            ? AppStrings.offlineNoCache
            : describeError(e, fallback: AppStrings.loadInvoicesError);
      }
    }

    _loaded = true;
    _refreshing = false;
    _notify();
  }

  Future<Set<String>> _loadAppBilled() async {
    try {
      return await _invoices.billedSalesInvoiceNames();
    } catch (e) {
      debugPrint('SalesInvoicesController._loadAppBilled failed: $e');
      return _appBilled;
    }
  }

  /// طرق الدفع من ERPNext لنافذة الدفع
  Future<List<String>> modesOfPayment() => _repository.fetchModesOfPayment();

  /// يحفظ دفعة على فاتورة. يعيد null عند النجاح، وإلا نص الخطأ للعرض.
  Future<String?> pay(
    SalesInvoice invoice, {
    required double amount,
    required String modeOfPayment,
    String? note,
    PaymentDetails details = const PaymentDetails(),
  }) async {
    try {
      final payment = await _repository.savePayment(
        invoice: invoice,
        amount: amount,
        modeOfPayment: modeOfPayment,
        note: note,
        details: details,
      );
      _pending = [..._pending, payment];
      _notify();
      return null;
    } on ErpApiException catch (e) {
      debugPrint('SalesInvoicesController.pay: $e');
      if (e.type == ErpErrorType.network) return AppStrings.draftNeedsConnection;
      final detail = e.type == ErpErrorType.server ? e.detail : null;
      final base = describeError(e, fallback: AppStrings.paymentSaveFailed);
      return (detail == null || detail.isEmpty)
          ? base
          : '${AppStrings.paymentSaveFailed}\n$detail';
    } catch (e) {
      debugPrint('SalesInvoicesController.pay: $e');
      return AppStrings.paymentSaveFailed;
    }
  }

  Future<Uint8List> downloadPdf(String invoiceName) =>
      _repository.downloadInvoicePdf(invoiceName);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
