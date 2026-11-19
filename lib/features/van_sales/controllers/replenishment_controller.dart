import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/van_sale_models.dart';
import '../../../data/models/warehouse_models.dart';
import '../../../data/repositories/erp_van_sales_repository.dart';
import '../../../data/repositories/erp_warehouse_repository.dart';

/// طلب تزويد الفان (GetX): منتجات الفان بكمياتها، اختيار المنتجات والكمية
/// المطلوبة، ثم Material Request (Material Transfer) مسودة من المستودع
/// الرئيسي إلى الفان.
class ReplenishmentController extends GetxController {
  ReplenishmentController(this._sales, this._stock);

  final ErpVanSalesRepository _sales;
  final ErpWarehouseRepository _stock;

  final stock = <WarehouseStock>[].obs;
  final loading = false.obs;
  final error = Rxn<Object>();
  final query = ''.obs;

  /// رمز المنتج → الكمية المطلوبة بوحدة المخزون
  final requested = <String, double>{}.obs;
  final saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      stock.assignAll(await _stock.fetchStock(ErpConfig.vanWarehouse));
      // الأقل كمية أولًا: هي غالبًا ما يحتاج تزويدًا
      stock.sort((a, b) => a.actualQty.compareTo(b.actualQty));
    } catch (e) {
      debugPrint('ReplenishmentController.load failed: $e');
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  List<WarehouseStock> get visible {
    final q = normalizeDigits(query.value.trim()).toLowerCase();
    if (q.isEmpty) return stock;
    return [
      for (final s in stock)
        if (s.itemName.toLowerCase().contains(q) ||
            s.itemCode.toLowerCase().contains(q))
          s,
    ];
  }

  /// null = صالحة. أكبر من صفر، وعدد صحيح إن كانت الوحدة لا تقبل كسورًا.
  static String? validate(WarehouseStock s, double? qty) {
    if (qty == null || qty <= 0) return VanStrings.qtyPositive;
    if (s.wholeNumber && qty != qty.roundToDouble()) {
      return VanStrings.qtyWhole(s.uom);
    }
    return null;
  }

  /// null = إزالة المنتج من الطلب
  void setRequested(WarehouseStock s, double? qty) {
    if (qty == null) {
      requested.remove(s.itemCode);
    } else {
      requested[s.itemCode] = qty;
    }
  }

  /// يحفظ الطلب مسودة. يعيد (الطلب كما حفظه ERPNext، null) أو (null، الخطأ).
  Future<(ReplenishmentRequest?, String?)> save() async {
    if (requested.isEmpty) return (null, VanStrings.needRequestLines);
    for (final s in stock) {
      final q = requested[s.itemCode];
      if (q == null) continue;
      final invalid = validate(s, q);
      if (invalid != null) return (null, '${s.itemName}: $invalid');
    }
    if (saving.value) return (null, null);
    saving.value = true;
    try {
      final uomOf = {for (final s in stock) s.itemCode: s.uom};
      final result = await _sales.createReplenishment(
        quantities: {
          for (final e in requested.entries)
            e.key: (qty: e.value, uom: uomOf[e.key] ?? ''),
        },
      );
      requested.clear();
      return (result, null);
    } catch (e) {
      debugPrint('ReplenishmentController.save failed: $e');
      final detail = e is ErpApiException && e.type == ErpErrorType.server
          ? e.detail
          : null;
      final base = describeError(e, fallback: VanStrings.requestFailed);
      return (
        null,
        (detail == null || detail.isEmpty)
            ? base
            : '${VanStrings.requestFailed}\n$detail',
      );
    } finally {
      saving.value = false;
    }
  }
}
