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
  InvoiceDetailsController(
    this._repository,
    this.invoiceName, {
    required this.customerPhone,
  });

  final ErpInvoiceRepository _repository;

  /// رقم الفاتورة كما جاء من القائمة تمامًا (مثل ACC-SINV-2026-00004)
  final String invoiceName;

  /// هاتف العميل من قاعدة البيانات المحلية (الفاتورة في ERPNext لا تحمله)
  final String customerPhone;

  SalesInvoiceDetail? _detail;
  bool _isLoading = true;
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
    final requestId = ++_requestId;
    _error = null;
    _notice = null;

    // 1) المحفوظ على الهاتف يظهر فورًا
    final cached = await _repository.readCachedInvoiceDetail(invoiceName);
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
      final fresh = await _repository.fetchInvoiceDetail(invoiceName);
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
