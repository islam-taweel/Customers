import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/invoice.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../data/repositories/erp_invoice_repository.dart';
import '../../../data/repositories/invoice_repository.dart';

/// فواتير عميل واحد من ERPNext (تبويب «الفاتورة»). يُنشأ عند فتح التبويب ويُتلف عند مغادرته.
///
/// يعمل دون إنترنت: يعرض أولًا النسخة المحفوظة على الهاتف (إن وُجدت) ثم يحاول تحديثها
/// من ERPNext. إن فشل التحديث تبقى النسخة المحفوظة ظاهرة مع [notice] يشرح السبب.
class CustomerInvoicesController extends ChangeNotifier {
  CustomerInvoicesController(
    this._repository,
    this._localRepository,
    this._customer,
  );

  final ErpInvoiceRepository _repository;
  final InvoiceRepository _localRepository;
  final Customer _customer;

  /// فواتير ERPNext (المحفوظة أو المجلوبة)
  final List<SalesInvoice> _erpInvoices = [];

  /// فواتير الطلبيات المحفوظة على الهاتف لهذا العميل
  List<Invoice> _localInvoices = [];

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

  /// true بعد قراءة الفواتير المحلية (المسودات لا تنتظر الشبكة)
  bool _localLoaded = false;
  bool get localLoaded => _localLoaded;

  /// المسودات (تبويب «مسودة»): فواتير الطلبيات المحلية غير المعتمدة، الأحدث أولًا
  List<Invoice> get drafts => UnmodifiableListView([
        for (final i in _localInvoices)
          if (!i.submitted) i,
      ]);

  /// المعتمدة (تبويب «معتمدة»): طلبيات اعتُمدت من التطبيق + فواتير ERPNext،
  /// من الأحدث إلى الأقدم
  List<SalesInvoice> get submitted {
    final all = <SalesInvoice>[
      for (final i in _localInvoices)
        if (i.submitted) i.toListEntry(),
      ..._erpInvoices,
    ]..sort((a, b) {
        final byDate = b.postingDate.compareTo(a.postingDate);
        return byDate != 0 ? byDate : b.name.compareTo(a.name);
      });
    return UnmodifiableListView(all);
  }

  /// بعد تعديل مسودة أو حذفها أو اعتمادها: إعادة قراءة المحلي فقط.
  Future<void> reloadLocal() async {
    await _loadLocal();
    _notify();
  }

  /// تفاصيل فاتورة محلية بحسب رقمها المعروض (null إن لم تكن محلية)
  SalesInvoiceDetail? localDetail(String name) {
    for (final i in _localInvoices) {
      if (i.displayName == name) return i.toDetail();
    }
    return null;
  }

  Future<void> _loadLocal() async {
    try {
      _localInvoices = await _localRepository.getInvoices(_customer.id!);
    } catch (e) {
      debugPrint('CustomerInvoicesController._loadLocal failed: $e');
      _localInvoices = [];
    }
    _localLoaded = true;
  }

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

    // 1) المحفوظ على الهاتف يظهر فورًا (فواتير الطلبيات + نسخة ERPNext)
    await _loadLocal();
    if (_isStale(requestId)) return;
    _notify(); // المسودات تظهر فورًا دون انتظار نسخة ERPNext
    final cached = await _repository.readCachedInvoices(_customer);
    if (_isStale(requestId)) return;

    if (cached != null) {
      _apply(cached);
      _isLoading = false;
    } else {
      _isLoading = _localInvoices.isEmpty;
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
      } else if (_localInvoices.isNotEmpty) {
        // لا نسخة من ERPNext، لكن الفواتير المحلية تُعرض مع تنبيه
        _notice = isOffline
            ? AppStrings.offlineNoCache
            : describeError(e, fallback: AppStrings.loadInvoicesError);
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
    _erpInvoices
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
