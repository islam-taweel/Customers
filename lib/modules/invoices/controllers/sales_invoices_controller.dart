import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../collections/controllers/invoice_collections_controller.dart';
import '../repository/sales_invoices_repository.dart';

/// فواتير المبيعات في تبويباتها: مسودة ← غير مدفوعة ← مدفوعة جزئيًا ← مدفوعة.
///
/// الفاتورة تنتقل بين التبويبات وحدها بحسب مستحقها في ERPNext. الدفعة تُحفظ
/// مسودة هناك (InvoiceCollectionsController)، فلا يتغير شيء في الفاتورة إلا بعد
/// اعتمادها في ERPNext.
///
/// (R3) نفس منطق المتحكم القديم (ChangeNotifier) بحالة Rx.
class SalesInvoicesController extends GetxController {
  SalesInvoicesController(this._repository, this._invoices, this._collections);

  final ErpSalesInvoicesRepository _repository;
  final InvoiceRepository _invoices;
  final InvoiceCollectionsController _collections;

  /// فواتير (مسودات) أنشأها التطبيق عند فوترة الطلبيات: تُعرض «غير مدفوعة» فورًا
  final _appBilled = <String>{}.obs;

  final _all = <SalesInvoice>[].obs;

  /// true بعد أول قراءة (محلية أو من ERPNext)
  final loaded = false.obs;
  final refreshing = false.obs;

  /// خطأ يحل محل المحتوى (فقط حين لا توجد نسخة محفوظة نعرضها)
  final error = RxnString();

  /// تنبيه فوق المحتوى: «غير متصل، تُعرض بيانات محفوظة...»
  final notice = RxnString();

  int _requestId = 0;

  /// وقت البيانات المعروضة: حفظ النسخة المحلية أو آخر جلب ناجح
  DateTime? _dataAt;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// تبويب الفاتورة: المسودة التي أنشأها التطبيق بالفوترة تُحسب «غير مدفوعة»
  /// (دفعها معطّل حتى يعتمدها المسؤول)، وبقية المسودات تبقى «مسودة».
  InvoiceBucket bucketOf(SalesInvoice i) {
    final bucket = i.bucket;
    if (bucket == InvoiceBucket.draft && _appBilled.contains(i.name)) {
      return InvoiceBucket.unpaid;
    }
    return bucket;
  }

  List<SalesInvoice> byBucket(InvoiceBucket bucket) => List.unmodifiable([
    for (final i in _all)
      if (bucketOf(i) == bucket) i,
  ]);

  /// التحميل الأول: المحفوظ يظهر فورًا ثم يُحدَّث من ERPNext.
  Future<void> load() async {
    final cached = await _repository.readCached();
    await _collections.loadPending();
    final billed = await _loadAppBilled();
    if (isClosed) return;
    _appBilled.assignAll(billed);
    if (cached != null) {
      _all.assignAll(cached.invoices);
      _dataAt = cached.savedAt;
      loaded.value = true;
    }
    await reload();
  }

  /// (R3) كانت refresh(): الاسم محجوز في GetxController (يستدعيه update)
  Future<void> reload() async {
    if (refreshing.value) return;
    final requestId = ++_requestId;
    refreshing.value = true;
    error.value = null;
    notice.value = null;
    // قد تكون فاتورة جديدة أُنشئت من «التسليمات» منذ آخر تحديث
    _appBilled.assignAll(await _loadAppBilled());

    try {
      final fresh = await _repository.fetchAll();
      if (isClosed || requestId != _requestId) return;
      _all.assignAll(fresh.invoices);
      _dataAt = DateTime.now();
      await _collections.reconcile();
    } catch (e) {
      if (isClosed || requestId != _requestId) return;
      debugPrint('SalesInvoicesController.refresh failed: $e');
      final isOffline = e is ErpApiException && e.type == ErpErrorType.network;
      if (loaded.value) {
        // نُبقي المعروض ظاهرًا ونشرح لماذا لم يُحدَّث
        final when = formatDateTime(_dataAt ?? DateTime.now());
        notice.value = isOffline
            ? AppStrings.offlineNotice(when)
            : AppStrings.staleNotice(
                describeError(e, fallback: AppStrings.loadInvoicesError),
                when,
              );
      } else {
        error.value = isOffline
            ? AppStrings.offlineNoCache
            : describeError(e, fallback: AppStrings.loadInvoicesError);
      }
    }

    if (isClosed) return;
    loaded.value = true;
    refreshing.value = false;
  }

  Future<Set<String>> _loadAppBilled() async {
    try {
      return await _invoices.billedSalesInvoiceNames();
    } catch (e) {
      debugPrint('SalesInvoicesController._loadAppBilled failed: $e');
      return {..._appBilled};
    }
  }

  Future<Uint8List> downloadPdf(String invoiceName) =>
      _repository.downloadInvoicePdf(invoiceName);
}
