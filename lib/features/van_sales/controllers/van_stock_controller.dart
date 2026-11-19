import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/warehouse_models.dart';
import '../../../data/repositories/erp_warehouse_repository.dart';

/// مخزون الفان (GetX): المنتجات الموجودة في مستودع الفان فقط من ERPNext (Bin)،
/// مع البحث بالاسم أو الكود، والمسح بالباركود.
class VanStockController extends GetxController {
  VanStockController(
    this._repository, {
    this.warehouse = ErpConfig.vanWarehouse,
  });

  final ErpWarehouseRepository _repository;

  /// مستودع الفان (Van - Ahmad - RTC)
  final String warehouse;

  final _all = <WarehouseStock>[].obs;
  final query = ''.obs;
  final loading = false.obs;
  final error = Rxn<Object>();

  /// المنتج الذي طابق آخر مسح (يُعرض وحده ومميزًا)؛ null = لا مسح
  final scanned = Rxn<WarehouseStock>();

  bool get hasAny => _all.isNotEmpty;
  int get total => _all.length;

  /// القائمة المعروضة: المنتج الممسوح وحده، وإلا نتيجة البحث
  List<WarehouseStock> get items {
    final hit = scanned.value;
    if (hit != null) return [hit];
    final q = normalizeDigits(query.value.trim()).toLowerCase();
    if (q.isEmpty) return _all;
    return [
      for (final s in _all)
        if (s.itemName.toLowerCase().contains(q) ||
            s.itemCode.toLowerCase().contains(q))
          s,
    ];
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      _all.assignAll(await _repository.fetchStock(warehouse));
      // بعد التحديث: الممسوح بكميته الجديدة (أو يختفي إن نفد)
      final hit = scanned.value;
      if (hit != null) scanned.value = _find(hit.itemCode);
    } catch (e) {
      debugPrint('VanStockController.load failed: $e');
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  void setQuery(String value) {
    scanned.value = null;
    query.value = value;
  }

  void clearScan() => scanned.value = null;

  WarehouseStock? _find(String itemCode) {
    for (final s in _all) {
      if (s.itemCode == itemCode) return s;
    }
    return null;
  }

  /// يبحث عن الباركود في مخزون الفان: كود المنتج نفسه، وإلا جدول Item Barcode
  /// في ERPNext. يعيد المنتج المطابق (ويعرضه وحده) أو null إن لم يكن في الفان.
  Future<WarehouseStock?> scan(String barcode) async {
    final code = barcode.trim();
    var hit = _find(code);
    if (hit == null) {
      final itemCode = await _repository.itemCodeForBarcode(code);
      if (itemCode != null) hit = _find(itemCode);
    }
    scanned.value = hit;
    return hit;
  }
}
