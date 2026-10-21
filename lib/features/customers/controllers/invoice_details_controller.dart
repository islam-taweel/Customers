import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../data/repositories/erp_invoice_repository.dart';

/// حالة شاشة تفاصيل فاتورة واحدة. يعرض النسخة المحفوظة على الهاتف فورًا (إن وُجدت)
/// ثم يحدّثها من ERPNext، فتعمل الشاشة دون إنترنت للفواتير التي فُتحت أو جُلبت من قبل.
class InvoiceDetailsController extends ChangeNotifier {
  /// فاتورة مبيعات معتمدة من ERPNext (Sales Invoice)
  InvoiceDetailsController(
    this._repository,
    this.invoiceName, {
    required this.customerPhone,
  })  : doctype = 'Sales Invoice',
        _loadFromServer = true,
        _isLoading = true;

  /// طلبية اعتُمدت من التطبيق (Sales Order): التفاصيل جاهزة ولا تُجلب من ERPNext،
  /// وملف PDF وحده يُطلب من الخادم.
  InvoiceDetailsController.local(
    this._repository,
    SalesInvoiceDetail detail, {
    required this.customerPhone,
  })  : doctype = 'Sales Order',
        invoiceName = detail.name,
        _loadFromServer = false,
        _detail = detail,
        _isLoading = false;

  final ErpInvoiceRepository _repository;

  /// نوع المستند في ERPNext (لطلب ملف PDF الصحيح)
  final String doctype;

  /// false = التفاصيل محلية كاملة فلا نحدّثها من الشبكة
  final bool _loadFromServer;

  /// رقم الفاتورة كما جاء من القائمة تمامًا (مثل ACC-SINV-2026-00004)
  final String invoiceName;

  /// هاتف العميل من قاعدة البيانات المحلية (الفاتورة في ERPNext لا تحمله)
  final String customerPhone;

  SalesInvoiceDetail? _detail;
  bool _isLoading;
  String? _error;
  String? _notice;
  int _requestId = 0;
  bool _disposed = false;

  SalesInvoiceDetail? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// تنبيه فوق الفاتورة: «غير متصل، تُعرض بيانات محفوظة...»
  String? get notice => _notice;

  /// التحميل الأول (ويُستخدم أيضًا لإعادة المحاولة بعد خطأ).
  Future<void> load() async {
    final repository = _repository;
    if (!_loadFromServer) {
      _notify();
      return;
    }
    final requestId = ++_requestId;
    _error = null;
    _notice = null;

    // 1) المحفوظ على الهاتف يظهر فورًا
    final cached = await repository.readCachedInvoiceDetail(invoiceName);
    if (_isStale(requestId)) return;

    if (cached != null) {
      _detail = cached.detail;
      _isLoading = false;
    } else {
      _isLoading = true;
    }
    _notify();

    // 2) ثم التحديث من ERPNext
    try {
      final fresh = await repository.fetchInvoiceDetail(invoiceName);
      if (_isStale(requestId)) return;
      _detail = fresh.detail;
    } catch (e) {
      if (_isStale(requestId)) return;
      debugPrint('InvoiceDetailsController.load failed: $e');
      final isOffline = e is ErpApiException && e.type == ErpErrorType.network;

      if (cached != null) {
        final when = formatDateTime(cached.savedAt!);
        _notice = isOffline
            ? AppStrings.offlineNotice(when)
            : AppStrings.staleNotice(
                describeError(e, fallback: AppStrings.loadInvoiceError),
                when,
              );
      } else {
        _error = isOffline
            ? AppStrings.offlineNoCache
            : describeError(e, fallback: AppStrings.loadInvoiceError);
      }
    }

    _isLoading = false;
    _notify();
  }

  /// ملف PDF الرسمي من ERPNext (download_pdf). يرمي [ErpApiException] إن تعذّر.
  Future<Uint8List> downloadServerPdf() =>
      _repository.downloadPdf(doctype, invoiceName);

  bool _isStale(int requestId) => _disposed || requestId != _requestId;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
