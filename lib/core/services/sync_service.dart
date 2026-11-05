import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../data/api/erp_api_client.dart';
import '../../data/models/pending_order.dart';
import '../../data/models/sync_models.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/erp_cache_store.dart';
import '../../data/repositories/erp_customer_repository.dart';
import '../../data/repositories/erp_invoice_repository.dart';
import '../../data/repositories/erp_order_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/pending_order_repository.dart';
import '../../features/customers/controllers/customers_controller.dart';
import '../constants/app_strings.dart';
import '../utils/error_messages.dart';

/// ينسّق المزامنة بين الجهاز و ERPNext، وكلها **تلقائية** ما دام الخادم متاحًا:
///
/// * **التنزيل** (العملاء، الأصناف، الفواتير): بعد الدخول، وعند عودة الاتصال،
///   وعند الرجوع للتطبيق، وكل 15 دقيقة (وبعد دقيقتين إن فشلت). يُحفظ كله محليًا
///   فيعمل التطبيق دون اتصال.
/// * **الرفع**: الطلبيات المنشأة دون اتصال تُرفع عند عودة الاتصال
///   (فحص كل 30 ثانية + عند فتح التطبيق + بعد كل حفظ دون اتصال).
///
/// توفر الاتصال يُعرف بفحص الخادم نفسه (ping) كل 30 ثانية والتطبيق في المقدمة.
class SyncService extends ChangeNotifier with WidgetsBindingObserver {
  SyncService({
    required ErpApiClient api,
    required CustomersController customersController,
    required CustomerRepository customerRepository,
    required ErpCustomerRepository erpCustomers,
    required ErpOrderRepository erpOrders,
    required ErpInvoiceRepository erpInvoices,
    required InvoiceRepository invoiceRepository,
    required PendingOrderRepository pendingRepository,
    required ErpCacheStore cache,
  })  : _api = api,
        _customersController = customersController,
        _customerRepo = customerRepository,
        _erpCustomers = erpCustomers,
        _orders = erpOrders,
        _erpInvoices = erpInvoices,
        _invoiceRepo = invoiceRepository,
        _pending = pendingRepository,
        _cache = cache;

  final ErpApiClient _api;
  final CustomersController _customersController;
  final CustomerRepository _customerRepo;
  final ErpCustomerRepository _erpCustomers;
  final ErpOrderRepository _orders;
  final ErpInvoiceRepository _erpInvoices;
  final InvoiceRepository _invoiceRepo;
  final PendingOrderRepository _pending;
  final ErpCacheStore _cache;

  static const Duration _checkInterval = Duration(seconds: 30);
  static const Duration _autoSyncInterval = Duration(minutes: 15);
  static const Duration _retryInterval = Duration(minutes: 2);

  final Map<SyncSection, SectionStatus> _status = {
    for (final s in SyncSection.values) s: SectionStatus(),
  };

  Timer? _timer;
  bool _pushing = false;
  bool _disposed = false;
  int _pendingCount = 0;
  int _failedCount = 0;
  int _lastPushFailed = 0;

  /// المزامنة التلقائية تعمل فقط والمستخدم مسجّل الدخول (يضبطها main)
  bool _enabled = false;
  bool _initialized = false;
  bool _foreground = true;
  bool _checking = false;
  bool _syncingAll = false;

  /// null = لم يُفحص بعد
  bool? _online;

  /// موعد المزامنة الكاملة التالية (null = الآن)
  DateTime? _nextFullSync;

  SectionStatus status(SyncSection section) => _status[section]!;

  /// آخر نتيجة لفحص الخادم (null = لم يُفحص بعد)
  bool? get online => _online;

  /// مزامنة كاملة (العملاء ← الأصناف ← الفواتير) جارية الآن
  bool get syncingAll => _syncingAll;

  /// طلبيات محفوظة محليًا وتنتظر الرفع
  int get pendingCount => _pendingCount;

  /// طلبيات رفضها الخادم وتحتاج مراجعة
  int get failedCount => _failedCount;

  // ───────────────────────── البدء ─────────────────────────

  Future<void> init() async {
    for (final section in SyncSection.values) {
      final entry = await _cache.read(_metaKey(section));
      if (entry == null) continue;
      final s = _status[section]!;
      s.lastSync = entry.savedAt;
      try {
        final meta = jsonDecode(entry.json) as Map<String, dynamic>;
        s.count = (meta['count'] as num?)?.toInt();
        s.summary = meta['summary'] as String?;
      } catch (_) {
        // بيانات تعريف تالفة: نُبقي وقت المزامنة فقط
      }
    }
    await refreshCounts();

    WidgetsBinding.instance.addObserver(this);
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, (_) => _tick());
    _initialized = true;

    // أول فحص فورًا: مزامنة كاملة إن كان المستخدم داخلًا والخادم متاحًا
    unawaited(_tick());
  }

  /// يستدعيه main عند الدخول/الخروج. الدخول يبدأ مزامنة كاملة فورًا.
  void setEnabled(bool enabled) {
    if (enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      _nextFullSync = null;
      if (_initialized) unawaited(_tick());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    // الرجوع للتطبيق: فحص فوري، ومزامنة كاملة إن مرّ وقتها
    if (_foreground) unawaited(_tick());
  }

  // ───────────────────────── المزامنة التلقائية ─────────────────────────

  /// يفحص الخادم، ثم: مزامنة كاملة إن عاد الاتصال أو حان موعدها، وإلا رفع
  /// الطلبيات المعلّقة فقط. لا يعمل مرتين معًا.
  Future<void> _tick() async {
    if (!_enabled || !_foreground || _disposed || _checking || _syncingAll) {
      return;
    }
    _checking = true;
    try {
      final online = await _api.ping();
      if (_disposed) return;
      final cameBack = online && _online == false;
      if (online != _online) {
        _online = online;
        _notify();
      }
      if (!online) return;

      // عاد الاتصال بعد انقطاع: لا ننتظر الموعد
      if (cameBack) _nextFullSync = null;
      final next = _nextFullSync;
      if (next == null || !DateTime.now().isBefore(next)) {
        await _syncAll();
      } else if (_pendingCount > 0) {
        await pushPending();
      }
    } finally {
      _checking = false;
    }
  }

  /// العملاء ← الأصناف ← الفواتير (تشمل رفع الطلبيات). الموعد التالي بعد
  /// 15 دقيقة، أو دقيقتين إن فشل قسم.
  Future<void> _syncAll() async {
    _syncingAll = true;
    _notify();
    try {
      await syncCustomers();
      if (!_enabled || _disposed) return;
      await syncItems();
      if (!_enabled || _disposed) return;
      await syncInvoices();
    } finally {
      final failed = SyncSection.values.any((s) => _status[s]!.error != null);
      _nextFullSync =
          DateTime.now().add(failed ? _retryInterval : _autoSyncInterval);
      _syncingAll = false;
      _notify();
    }
  }

  String _metaKey(SyncSection s) => 'sync:${s.name}';

  Future<void> refreshCounts() async {
    try {
      final c = await _pending.counts();
      _pendingCount = c.pending;
      _failedCount = c.failed;
    } catch (e) {
      debugPrint('SyncService.refreshCounts failed: $e');
    }
    _notify();
  }

  /// تستدعيه شاشة الطلبية بعد حفظ طلبية دون اتصال.
  Future<void> onPendingChanged() async {
    await refreshCounts();
    unawaited(pushPending());
  }

  // ───────────────────────── الرفع التلقائي ─────────────────────────

  /// يرفع الطلبيات المعلّقة إن كان الخادم متاحًا. آمن للاستدعاء في أي وقت:
  /// لا يعمل مرتين معًا، ولا يفعل شيئًا إن لم يوجد ما يُرفع.
  Future<PushResult> pushPending() async {
    if (_pushing || _disposed) return PushResult.nothing;
    _pushing = true;
    try {
      final open = await _pending.getPending();
      if (open.isEmpty) {
        await refreshCounts();
        return PushResult.nothing;
      }
      if (!await _api.ping()) {
        await refreshCounts();
        return const PushResult(offline: true);
      }

      var sent = 0;
      var failed = 0;
      Object? stopError;
      var offline = false;

      for (final order in open) {
        try {
          final created = await _orders.createOrderFromPending(order);
          await _pending.markSynced(order.id!, created.id);
          sent++;
          await _linkInvoice(order, created.id);
        } on ErpApiException catch (e) {
          debugPrint('SyncService.push(${order.id}) failed: $e');
          if (e.type == ErpErrorType.network) {
            offline = true;
            break;
          }
          if (e.type == ErpErrorType.sessionExpired ||
              e.type == ErpErrorType.forbidden) {
            stopError = e;
            break;
          }
          failed++;
          await _pending.markFailed(
            order.id!,
            e.detail ?? describeError(e, fallback: AppStrings.syncFailed),
          );
        } catch (e) {
          debugPrint('SyncService.push(${order.id}) failed: $e');
          failed++;
          await _pending.markFailed(order.id!, '$e');
        }
      }

      _lastPushFailed = failed;
      await _pending.purgeSynced();
      await refreshCounts();
      if (sent > 0) unawaited(_customersController.refresh());
      return PushResult(
        sent: sent,
        failed: failed,
        offline: offline,
        error: stopError,
      );
    } catch (e) {
      debugPrint('SyncService.pushPending failed: $e');
      return PushResult(error: e);
    } finally {
      _pushing = false;
      _notify();
    }
  }

  /// يربط الفاتورة المحلية برقم الطلبية في ERPNext. فشله لا يلغي الرفع.
  Future<void> _linkInvoice(PendingOrder order, String erpOrderId) async {
    final invoiceId = order.invoiceId;
    if (invoiceId == null) return;
    try {
      await _invoiceRepo.markOrderInvoiceSynced(invoiceId, erpOrderId);
    } catch (e) {
      debugPrint('SyncService._linkInvoice failed: $e');
    }
  }

  // ───────────────────────── أقسام المزامنة ─────────────────────────

  Future<void> syncCustomers() {
    return _run(SyncSection.customers, (report) async {
      report(null, SyncStep.customers);
      final remote = await _erpCustomers.fetchCustomers();
      await _customerRepo.syncFromErp(remote);
      await _customersController.refresh();
      return (count: remote.length, summary: AppStrings.syncedCustomers(remote.length));
    });
  }

  Future<void> syncItems() {
    return _run(SyncSection.items, (report) async {
      final result = await _orders.syncCatalog(onProgress: report);
      return (
        count: result.items,
        summary: AppStrings.syncedItems(result.items, result.groups),
      );
    });
  }

  /// يرفع أولًا الطلبيات المحفوظة (بما فيها المرفوضة سابقًا لإعادة المحاولة)،
  /// ثم يجلب فواتير كل العملاء المرتبطين بـ ERPNext ويحفظها محليًا.
  Future<void> syncInvoices() async {
    await _run(SyncSection.invoices, (report) async {
      report(null, SyncStep.uploadingOrders);
      await _pending.resetFailed();
      final push = await pushPending();
      if (push.offline) {
        throw const ErpApiException(ErpErrorType.network);
      }
      if (push.error != null) throw push.error!;

      final links = await _customerRepo.getErpLinks();
      if (links.isEmpty) throw const _NoLinkedCustomers();

      final result = await _erpInvoices.syncAll(links, onProgress: report);
      return (
        count: result.invoices,
        summary: AppStrings.syncedInvoices(result.invoices),
      );
    });

    // تنبيه (لا خطأ): بعض الطلبيات رفضها الخادم
    if (_lastPushFailed > 0) {
      final s = _status[SyncSection.invoices]!;
      s.warning = AppStrings.failedOrdersCount(_lastPushFailed);
      _notify();
    }
  }

  Future<void> _run(
    SyncSection section,
    Future<({int count, String summary})> Function(
      void Function(double? progress, SyncStep step) report,
    ) body,
  ) async {
    final s = _status[section]!;
    if (s.running) return;

    s.running = true;
    s.progress = null;
    s.stage = null;
    s.error = null;
    s.warning = null;
    _notify();

    try {
      final result = await body((progress, step) {
        s.progress = progress;
        s.stage = AppStrings.syncStep(step);
        _notify();
      });
      s.lastSync = DateTime.now();
      s.count = result.count;
      s.summary = result.summary;
      await _cache.write(
        _metaKey(section),
        jsonEncode({'count': result.count, 'summary': result.summary}),
      );
    } on _NoLinkedCustomers {
      s.error = AppStrings.syncCustomersFirst;
    } catch (e) {
      debugPrint('SyncService.$section failed: $e');
      s.error = describeError(e, fallback: AppStrings.syncFailed);
    } finally {
      s.running = false;
      s.progress = null;
      s.stage = null;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// لا يوجد عميل مرتبط بـ ERPNext: يجب مزامنة العملاء أولًا.
class _NoLinkedCustomers implements Exception {
  const _NoLinkedCustomers();
}
