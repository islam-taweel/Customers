import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../data/repositories/erp_invoice_repository.dart';

/// فواتير عميل واحد من ERPNext (تبويب «الفاتورة»). يُنشأ عند فتح التبويب ويُتلف عند مغادرته.
///
/// يعمل دون إنترنت: يعرض أولًا النسخة المحفوظة على الهاتف (إن وُجدت) ثم يحاول تحديثها
/// من ERPNext. إن فشل التحديث تبقى النسخة المحفوظة ظاهرة مع [notice] يشرح السبب.
class CustomerInvoicesController extends ChangeNotifier {
  CustomerInvoicesController(this._repository, this._customer);

  final ErpInvoiceRepository _repository;
  final Customer _customer;

  final List<SalesInvoice> _invoices = [];

  /// true فقط حين لا توجد بيانات نعرضها بعد (لا نسخة محفوظة والجلب جارٍ)
  bool _isLoading = true;

  /// true أثناء التحديث من ERPNext بينما بيانات محفوظة معروضة
  bool _isRefreshing = false;

  /// false = لا يوجد عميل مطابق في ERPNext (بالهاتف ولا بالاسم)
  bool _matched = true;

  /// رسالة خطأ تحل محل المحتوى (فقط إن لم تكن هناك بيانات محفوظة نعرضها)
  String? _error;

  /// تنبيه فوق المحتوى: «غير متصل، تُعرض بيانات محفوظة...»
  String? _notice;

  int _requestId = 0;
  bool _disposed = false;

  /// من الأحدث إلى الأقدم
  List<SalesInvoice> get invoices => UnmodifiableListView(_invoices);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get matched => _matched;
  String? get error => _error;
  String? get notice => _notice;

  /// التحميل الأول (ويُستخدم أيضًا لإعادة المحاولة بعد خطأ).
  Future<void> load() async {
    final requestId = ++_requestId;
    _error = null;
    _notice = null;

    // 1) المحفوظ على الهاتف يظهر فورًا
    final cached = await _repository.readCachedInvoices(_customer);
    if (_isStale(requestId)) return;

    if (cached != null) {
      _apply(cached);
      _isLoading = false;
    } else {
      _isLoading = true;
    }
    _isRefreshing = true;
    _notify();

    // 2) ثم التحديث من ERPNext
    try {
      final fresh = await _repository.fetchInvoices(_customer);
      if (_isStale(requestId)) return;
      _apply(fresh);
    } catch (e) {
      if (_isStale(requestId)) return;
      debugPrint('CustomerInvoicesController.load failed: $e');
      final isOffline = e is ErpApiException && e.type == ErpErrorType.network;

      if (cached != null) {
        // نُبقي المحفوظ ظاهرًا ونشرح للمستخدم لماذا لم يُحدَّث
        final when = formatDateTime(cached.savedAt!);
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

    _isLoading = false;
    _isRefreshing = false;
    _notify();
  }

  void _apply(InvoicesResult result) {
    _matched = result.matched;
    _invoices
      ..clear()
      ..addAll(result.invoices);
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
