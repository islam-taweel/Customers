import 'package:flutter/foundation.dart';

import '../../../core/constants/warehouse_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/warehouse_models.dart';
import '../../../data/repositories/erp_warehouse_repository.dart';

/// رسالة الخطأ مع نص ERPNext نفسه عند أخطاء الخادم (مثل: رصيد سالب في الصف 2).
String _withDetail(Object e, String fallback) {
  final detail =
      e is ErpApiException && e.type == ErpErrorType.server ? e.detail : null;
  final base = describeError(e, fallback: fallback);
  return (detail == null || detail.isEmpty) ? base : '$fallback\n$detail';
}

/// ينشئ متحكمات قسم «المستودعات».
class WarehousesControllerFactory {
  WarehousesControllerFactory(this._repository);

  final ErpWarehouseRepository _repository;

  WarehousesController create() => WarehousesController(_repository);

  WarehouseStockController createStock(Warehouse warehouse) =>
      WarehouseStockController(_repository, warehouse);

  TransferController createTransfer({String? from}) =>
      TransferController(_repository, from: from);

  PendingTransfersController createPending() =>
      PendingTransfersController(_repository);
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
      _error = describeError(e, fallback: WarehouseStrings.loadFailed);
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

bool _matches(WarehouseStock s, String query) {
  final q = normalizeDigits(query.trim()).toLowerCase();
  return q.isEmpty ||
      s.itemName.toLowerCase().contains(q) ||
      s.itemCode.toLowerCase().contains(q);
}

/// 1) قائمة المستودعات.
class WarehousesController extends _LoadingController {
  WarehousesController(this._repository) {
    load();
  }

  final ErpWarehouseRepository _repository;

  List<Warehouse> _warehouses = const [];
  List<Warehouse> get warehouses => _warehouses;

  Future<void> load() => _run(() async {
        _warehouses = await _repository.fetchWarehouses();
      });
}

/// 2) أصناف مستودع واحد بكمياتها، مع البحث.
class WarehouseStockController extends _LoadingController {
  WarehouseStockController(this._repository, this.warehouse) {
    load();
  }

  final ErpWarehouseRepository _repository;
  final Warehouse warehouse;

  List<WarehouseStock> _all = const [];
  String _query = '';

  String get query => _query;
  bool get hasAny => _all.isNotEmpty;
  List<WarehouseStock> get items =>
      [for (final s in _all) if (_matches(s, _query)) s];

  void setQuery(String value) {
    _query = value;
    _notify();
  }

  Future<void> load() => _run(() async {
        _all = await _repository.fetchStock(warehouse.name);
      });
}

/// 3) نقل أصناف بين مستودعين: المصدر والهدف، الكميات، ثم الحفظ مسودة.
class TransferController extends _LoadingController {
  TransferController(this._repository, {String? from}) {
    _from = from;
    _init();
  }

  final ErpWarehouseRepository _repository;

  List<Warehouse> _warehouses = const [];
  String? _from;
  String? _to;
  List<WarehouseStock> _stock = const [];
  bool _stockLoading = false;
  String? _stockError;
  final Map<String, double> _quantities = {};
  String _query = '';
  bool _saving = false;
  String remarks = '';

  List<Warehouse> get warehouses => _warehouses;
  String? get from => _from;
  String? get to => _to;
  bool get stockLoading => _stockLoading;
  String? get stockError => _stockError;
  bool get saving => _saving;
  String get query => _query;
  bool get hasStock => _stock.isNotEmpty;
  Map<String, double> get quantities => Map.unmodifiable(_quantities);
  bool get sameWarehouse => _from != null && _from == _to;
  bool get canSave =>
      _from != null &&
      _to != null &&
      !sameWarehouse &&
      _quantities.isNotEmpty &&
      !_saving;

  List<WarehouseStock> get stock =>
      [for (final s in _stock) if (_matches(s, _query)) s];

  /// الأصناف المحددة التي تتجاوز كميتها المتاح (تأخذ من المحجوز لأوامر البيع)
  List<WarehouseStock> get reservedOveruse => [
        for (final s in _stock)
          if ((_quantities[s.itemCode] ?? 0) > s.availableQty + 1e-9) s,
      ];

  Future<void> _init() => _run(() async {
        _warehouses = await _repository.fetchWarehouses();
        if (_from != null && !_warehouses.any((w) => w.name == _from)) {
          _from = null;
        }
        if (_from != null) await _loadStock();
      });

  void setQuery(String value) {
    _query = value;
    _notify();
  }

  /// تغيير المصدر يعيد تحميل أصنافه ويمسح الكميات المحددة.
  Future<void> setFrom(String? value) async {
    if (value == _from) return;
    _from = value;
    _quantities.clear();
    _stock = const [];
    _notify();
    if (value != null) await _loadStock();
  }

  void setTo(String? value) {
    _to = value;
    _notify();
  }

  Future<void> reloadStock() => _loadStock();

  Future<void> _loadStock() async {
    final from = _from;
    if (from == null) return;
    _stockLoading = true;
    _stockError = null;
    _notify();
    try {
      final rows = await _repository.fetchStock(from);
      if (from != _from) return; // تغيّر المصدر أثناء التحميل
      _stock = rows;
      // كمية محددة لصنف لم يعد في المستودع لا تبقى
      _quantities.removeWhere((code, _) => !rows.any((s) => s.itemCode == code));
    } catch (e) {
      debugPrint('TransferController.loadStock failed: $e');
      if (from == _from) {
        _stockError = describeError(e, fallback: WarehouseStrings.loadFailed);
      }
    } finally {
      if (from == _from) _stockLoading = false;
      _notify();
    }
  }

  /// null = الكمية صالحة. القواعد: أكبر من صفر، لا تتجاوز الموجود في المصدر
  /// (ERPNext يرفض الرصيد السالب)، وعدد صحيح إن كانت الوحدة لا تقبل كسورًا.
  static String? validate(WarehouseStock s, double? qty) {
    if (qty == null || qty <= 0) return WarehouseStrings.qtyPositive;
    if (qty > s.actualQty + 1e-9) {
      return WarehouseStrings.qtyAboveActual(
        WarehouseStrings.qty(s.actualQty, s.uom),
      );
    }
    if (s.wholeNumber && qty != qty.roundToDouble()) {
      return WarehouseStrings.qtyWhole(s.uom);
    }
    return null;
  }

  /// تحذير (لا يمنع) إن تجاوزت الكمية المتاح = الموجود − المحجوز.
  static String? warning(WarehouseStock s, double? qty) {
    if (qty == null || s.reservedQty <= 0) return null;
    if (qty <= s.availableQty + 1e-9) return null;
    return WarehouseStrings.qtyReservedWarning(
      WarehouseStrings.qty(s.availableQty < 0 ? 0 : s.availableQty, s.uom),
    );
  }

  void setQty(WarehouseStock s, double? qty) {
    if (qty == null || qty <= 0) {
      _quantities.remove(s.itemCode);
    } else {
      _quantities[s.itemCode] = qty;
    }
    _notify();
  }

  /// يحفظ النقل مسودة. يعيد (رقم القيد، null) أو (null، رسالة الخطأ).
  Future<(String?, String?)> save() async {
    final from = _from, to = _to;
    if (from == null || to == null) return (null, WarehouseStrings.chooseWarehouse);
    if (from == to) return (null, WarehouseStrings.sameWarehouse);
    if (_quantities.isEmpty) return (null, WarehouseStrings.noLines);
    for (final s in _stock) {
      final q = _quantities[s.itemCode];
      if (q == null) continue;
      final error = validate(s, q);
      if (error != null) return (null, '${s.itemName}: $error');
    }

    _saving = true;
    _notify();
    try {
      final name = await _repository.createTransfer(
        from: from,
        to: to,
        quantities: Map.of(_quantities),
        remarks: remarks,
      );
      _quantities.clear();
      return (name, null);
    } catch (e) {
      debugPrint('TransferController.save failed: $e');
      return (null, _withDetail(e, WarehouseStrings.saveFailed));
    } finally {
      _saving = false;
      _notify();
    }
  }
}

/// 4) قيود النقل المسودة: التفاصيل، والاعتماد أو الرفض.
class PendingTransfersController extends _LoadingController {
  PendingTransfersController(this._repository) {
    load();
  }

  final ErpWarehouseRepository _repository;

  List<StockTransfer> _transfers = const [];
  final Map<String, StockTransfer> _details = {};
  final Set<String> _detailsLoading = {};
  final Set<String> _busy = {};

  List<StockTransfer> get transfers => _transfers;
  StockTransfer? details(String name) => _details[name];
  bool isLoadingDetails(String name) => _detailsLoading.contains(name);
  bool isBusy(String name) => _busy.contains(name);

  Future<void> load() => _run(() async {
        _transfers = await _repository.fetchPending();
        _details.removeWhere((k, _) => !_transfers.any((t) => t.name == k));
      });

  /// أصناف القيد (GET Stock Entry/{ID})؛ تُجلب مرة واحدة.
  Future<void> loadDetails(String name) async {
    if (_details.containsKey(name) || _detailsLoading.contains(name)) return;
    _detailsLoading.add(name);
    _notify();
    try {
      _details[name] = await _repository.fetchTransfer(name);
    } catch (e) {
      debugPrint('PendingTransfersController.loadDetails failed: $e');
    } finally {
      _detailsLoading.remove(name);
      _notify();
    }
  }

  /// null = نجح.
  Future<String?> approve(StockTransfer t) =>
      _act(t, () => _repository.approve(t.name), WarehouseStrings.approveFailed);

  /// null = نجح.
  Future<String?> reject(StockTransfer t) =>
      _act(t, () => _repository.reject(t.name), WarehouseStrings.rejectFailed);

  Future<String?> _act(
    StockTransfer t,
    Future<void> Function() action,
    String fallback,
  ) async {
    if (_busy.contains(t.name)) return null;
    _busy.add(t.name);
    _notify();
    try {
      await action();
      _transfers = [for (final x in _transfers) if (x.name != t.name) x];
      _details.remove(t.name);
      return null;
    } catch (e) {
      debugPrint('PendingTransfersController failed on ${t.name}: $e');
      return _withDetail(e, fallback);
    } finally {
      _busy.remove(t.name);
      _notify();
    }
  }
}
