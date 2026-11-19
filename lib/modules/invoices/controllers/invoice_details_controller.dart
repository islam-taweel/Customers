import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../data/repositories/erp_invoice_repository.dart';

/// حالة شاشة تفاصيل فاتورة واحدة. يعرض النسخة المحفوظة على الهاتف فورًا (إن وُجدت)
/// ثم يحدّثها من ERPNext، فتعمل الشاشة دون إنترنت للفواتير التي فُتحت أو جُلبت من قبل.
///
/// (R3) نفس منطق المتحكم القديم بحالة Rx. يُنشأ من CustomerDetailsController
/// (openInvoice / openLocalInvoice) ويُسجَّل مع مسار الشاشة، فيبدأ التحميل في onInit.
class InvoiceDetailsController extends GetxController {
  /// فاتورة مبيعات معتمدة من ERPNext (Sales Invoice)
  InvoiceDetailsController(
    this._repository,
    this.invoiceName, {
    required this.customerPhone,
  }) : doctype = 'Sales Invoice',
       _loadFromServer = true,
       isLoading = true.obs;

  /// طلبية اعتُمدت من التطبيق (Sales Order): التفاصيل جاهزة ولا تُجلب من ERPNext،
  /// وملف PDF وحده يُطلب من الخادم.
  InvoiceDetailsController.local(
    this._repository,
    SalesInvoiceDetail detail, {
    required this.customerPhone,
  }) : doctype = 'Sales Order',
       invoiceName = detail.name,
       _loadFromServer = false,
       isLoading = false.obs {
    this.detail.value = detail;
  }

  final ErpInvoiceRepository _repository;

  /// نوع المستند في ERPNext (لطلب ملف PDF الصحيح)
  final String doctype;

  /// false = التفاصيل محلية كاملة فلا نحدّثها من الشبكة
  final bool _loadFromServer;

  /// رقم الفاتورة كما جاء من القائمة تمامًا (مثل ACC-SINV-2026-00004)
  final String invoiceName;

  /// هاتف العميل من قاعدة البيانات المحلية (الفاتورة في ERPNext لا تحمله)
  final String customerPhone;

  final detail = Rxn<SalesInvoiceDetail>();
  final RxBool isLoading;
  final error = RxnString();

  /// تنبيه فوق الفاتورة: «غير متصل، تُعرض بيانات محفوظة...»
  final notice = RxnString();

  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// التحميل الأول (ويُستخدم أيضًا لإعادة المحاولة بعد خطأ).
  Future<void> load() async {
    final repository = _repository;
    if (!_loadFromServer) return;
    final requestId = ++_requestId;
    error.value = null;
    notice.value = null;

    // 1) المحفوظ على الهاتف يظهر فورًا
    final cached = await repository.readCachedInvoiceDetail(invoiceName);
    if (_isStale(requestId)) return;

    if (cached != null) {
      detail.value = cached.detail;
      isLoading.value = false;
    } else {
      isLoading.value = true;
    }

    // 2) ثم التحديث من ERPNext
    try {
      final fresh = await repository.fetchInvoiceDetail(invoiceName);
      if (_isStale(requestId)) return;
      detail.value = fresh.detail;
    } catch (e) {
      if (_isStale(requestId)) return;
      debugPrint('InvoiceDetailsController.load failed: $e');
      final isOffline = e is ErpApiException && e.type == ErpErrorType.network;

      if (cached != null) {
        final when = formatDateTime(cached.savedAt!);
        notice.value = isOffline
            ? AppStrings.offlineNotice(when)
            : AppStrings.staleNotice(
                describeError(e, fallback: AppStrings.loadInvoiceError),
                when,
              );
      } else {
        error.value = isOffline
            ? AppStrings.offlineNoCache
            : describeError(e, fallback: AppStrings.loadInvoiceError);
      }
    }

    isLoading.value = false;
  }

  /// ملف PDF الرسمي من ERPNext (download_pdf). يرمي [ErpApiException] إن تعذّر.
  Future<Uint8List> downloadServerPdf() =>
      _repository.downloadPdf(doctype, invoiceName);

  /// زر «القيود المحاسبية» في كل الحالات: فاتورة ERPNext (معتمدة أو مسودة؛ المسودة
  /// تُعرض «بانتظار الاعتماد» دون طلب قيودها)، أو طلبية رُفعت إلى ERPNext
  /// (قيود تسليمها وفوترتها ودفعاتها). الطلبية غير المرفوعة (INV-…) لا رقم لها هناك.
  bool get hasGlEntries =>
      doctype == 'Sales Invoice' || !invoiceName.startsWith('INV-');

  bool _isStale(int requestId) => isClosed || requestId != _requestId;
}
