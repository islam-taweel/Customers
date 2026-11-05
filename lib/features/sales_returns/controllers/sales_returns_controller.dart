import 'package:flutter/foundation.dart';

import '../../../core/constants/returns_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/return_models.dart';
import '../../../data/repositories/erp_sales_returns_repository.dart';

/// رسالة الخطأ مع نص ERPNext نفسه عند أخطاء الخادم (مثل: الكمية أكبر من المتاح في الصف 2).
String _withDetail(Object e, String fallback) {
  final detail =
      e is ErpApiException && e.type == ErpErrorType.server ? e.detail : null;
  final base = describeError(e, fallback: fallback);
  return (detail == null || detail.isEmpty) ? base : '$fallback\n$detail';
}

/// ينشئ متحكمات قسم «مردود المبيعات».
class SalesReturnsControllerFactory {
  SalesReturnsControllerFactory(this._repository);

  final ErpSalesReturnsRepository _repository;

  SalesReturnsController create() => SalesReturnsController(_repository);

  ReturnInvoicesController createInvoices(ReturnCustomer customer) =>
      ReturnInvoicesController(_repository, customer);

  ReturnItemsController createItems(ReturnInvoice invoice) =>
      ReturnItemsController(_repository, invoice);

  PendingReturnsController createPending() =>
      PendingReturnsController(_repository);
}

/// أساس مشترك: تحميل مع حالة انتظار وخطأ، وإشعار آمن بعد الإغلاق.
abstract class _LoadingController extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> _run(Future<void> Function() task) async {
    _loading = true;
    _error = null;
    _notify();
    try {
      await task();
    } catch (e) {
      debugPrint('$runtimeType.load failed: $e');
      _error = describeError(e, fallback: ReturnsStrings.loadFailed);
    } finally {
      _loading = false;
      _notify();
    }
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

/// قائمة العملاء الذين لديهم فواتير سابقة، مع البحث.
class SalesReturnsController extends _LoadingController {
  SalesReturnsController(this._repository) {
    load();
  }

  final ErpSalesReturnsRepository _repository;

  List<ReturnCustomer> _all = const [];
  DateTime? _savedAt;
  String _query = '';

  DateTime? get savedAt => _savedAt;
  String get query => _query;
  bool get hasAny => _all.isNotEmpty;

  List<ReturnCustomer> get customers {
    final q = normalizeDigits(_query.trim()).toLowerCase();
    if (q.isEmpty) return _all;
    return [
      for (final c in _all)
        if (c.name.toLowerCase().contains(q) || c.id.toLowerCase().contains(q))
          c,
    ];
  }

  void setQuery(String value) {
    _query = value;
    _notify();
  }

  Future<void> load() => _run(() async {
        final result = await _repository.fetchCustomers();
        _all = result.data;
        _savedAt = result.savedAt;
      });
}

/// فواتير العميل المعتمدة التي يمكن الإرجاع منها.
class ReturnInvoicesController extends _LoadingController {
  ReturnInvoicesController(this._repository, this.customer) {
    load();
  }

  final ErpSalesReturnsRepository _repository;
  final ReturnCustomer customer;

  List<ReturnInvoice> _invoices = const [];
  List<ReturnInvoice> get invoices => _invoices;

  Future<void> load() => _run(() async {
        _invoices = await _repository.fetchInvoices(customer.id);
      });
}

/// أصناف فاتورة واحدة: اختيار كميات الإرجاع (حتى المتاح، وبلا كسور للوحدات الصحيحة)
/// ثم حفظ إشعار الدائن وإرجاع البضاعة مسودتين.
class ReturnItemsController extends _LoadingController {
  ReturnItemsController(this._repository, this.invoice) {
    load();
  }

  final ErpSalesReturnsRepository _repository;
  final ReturnInvoice invoice;

  List<ReturnableItem> _items = const [];
  final Map<String, double> _qty = {};
  bool _saving = false;
  bool _showErrors = false;
  String reason = '';

  List<ReturnableItem> get items => _items;
  bool get saving => _saving;
  bool get showErrors => _showErrors;

  double qtyOf(ReturnableItem item) => _qty[item.rowName] ?? 0;

  int get chosenCount => _qty.values.where((q) => q > 0).length;

  double get returnTotal {
    var total = 0.0;
    for (final item in _items) {
      total += qtyOf(item) * item.rate;
    }
    return total;
  }

  /// خطأ كمية الصنف (null = سليمة)
  String? errorOf(ReturnableItem item) {
    final q = qtyOf(item);
    if (q <= 0) return null;
    if (q > item.returnable + 0.0001) {
      return ReturnsStrings.maxReturnable(_plain(item.returnable));
    }
    if (item.wholeNumber && q != q.roundToDouble()) {
      return ReturnsStrings.wholeNumberOnly;
    }
    return null;
  }

  Future<void> load() => _run(() async {
        _items = await _repository.fetchReturnableItems(invoice.name);
        _qty.clear();
      });

  void setQty(ReturnableItem item, double value) {
    _qty[item.rowName] = value < 0 ? 0 : value;
    _notify();
  }

  void increment(ReturnableItem item) {
    final next = qtyOf(item).floorToDouble() + 1;
    setQty(item, next > item.returnable ? item.returnable : next);
  }

  void decrement(ReturnableItem item) {
    final q = qtyOf(item);
    final next = q == q.roundToDouble() ? q - 1 : q.floorToDouble();
    setQty(item, next);
  }

  /// يتحقق ثم يحفظ. يعيد المرتجع المحفوظ أو رسالة خطأ.
  Future<({CreatedReturn? created, String? error})> create() async {
    if (chosenCount == 0) {
      return (created: null, error: ReturnsStrings.nothingChosen);
    }
    if (_items.any((i) => errorOf(i) != null)) {
      _showErrors = true;
      _notify();
      return (created: null, error: ReturnsStrings.fixErrors);
    }

    _saving = true;
    _notify();
    try {
      final created = await _repository.createReturn(
        invoice: invoice.name,
        items: _items,
        quantities: Map.of(_qty),
        reason: reason,
      );
      return (created: created, error: null);
    } catch (e) {
      debugPrint('ReturnItemsController.create failed: $e');
      return (
        created: null,
        error: _withDetail(e, ReturnsStrings.createFailed),
      );
    } finally {
      _saving = false;
      _notify();
    }
  }
}

/// المرتجعات المحفوظة مسودة: اعتمادها أو رفضها، ثم رد المال بعد اعتماد إشعار الدائن.
class PendingReturnsController extends _LoadingController {
  PendingReturnsController(this._repository) {
    load();
  }

  final ErpSalesReturnsRepository _repository;

  List<PendingReturn> _items = const [];
  final Set<String> _busy = {};

  List<PendingReturn> get creditNotes =>
      [for (final r in _items) if (r.isCreditNote) r];
  List<PendingReturn> get stockReturns =>
      [for (final r in _items) if (!r.isCreditNote) r];
  bool isBusy(PendingReturn r) => _busy.contains('${r.doctype}/${r.name}');

  Future<void> load() => _run(() async {
        _items = await _repository.fetchPending();
      });

  /// يعيد رسالة خطأ أو null عند النجاح (ويُزال من القائمة).
  Future<String?> approve(PendingReturn r) =>
      _act(r, () => _repository.approve(r));

  Future<String?> reject(PendingReturn r) =>
      _act(r, () => _repository.reject(r));

  Future<String?> _act(PendingReturn r, Future<void> Function() task) async {
    final key = '${r.doctype}/${r.name}';
    _busy.add(key);
    _notify();
    try {
      await task();
      _items = [
        for (final x in _items)
          if ('${x.doctype}/${x.name}' != key) x,
      ];
      return null;
    } catch (e) {
      debugPrint('PendingReturnsController action failed: $e');
      return _withDetail(e, ReturnsStrings.actionFailed);
    } finally {
      _busy.remove(key);
      _notify();
    }
  }

  Future<RefundCheck> checkRefund(PendingReturn creditNote) =>
      _repository.checkRefund(creditNote);

  Future<List<String>> fetchModesOfPayment() =>
      _repository.fetchModesOfPayment();

  /// يعيد رقم دفعة الرد أو رسالة خطأ.
  Future<({String? entry, String? error})> saveRefund({
    required PendingReturn creditNote,
    required String modeOfPayment,
    String? referenceNo,
    DateTime? referenceDate,
  }) async {
    try {
      final entry = await _repository.saveRefund(
        creditNote: creditNote.name,
        modeOfPayment: modeOfPayment,
        referenceNo: referenceNo,
        referenceDate: referenceDate,
      );
      return (entry: entry, error: null);
    } catch (e) {
      debugPrint('PendingReturnsController.saveRefund failed: $e');
      return (entry: null, error: _withDetail(e, ReturnsStrings.refundFailed));
    }
  }
}

String _plain(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
