import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/palestine_time.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/van_sale_models.dart';
import '../../../data/models/warehouse_models.dart';
import '../../../data/repositories/erp_van_sales_repository.dart';
import '../../../data/repositories/erp_warehouse_repository.dart';

/// نهاية اليوم (GetX): جرد الفان (كمية النظام مقابل الكمية الفعلية والفروقات،
/// ثم تسوية مخزون مسودة)، وملخص مبيعات اليوم وإرجاعاته من ERPNext.
class EndOfDayController extends GetxController {
  EndOfDayController(this._sales, this._stock);

  final ErpVanSalesRepository _sales;
  final ErpWarehouseRepository _stock;

  // الجرد
  final stock = <WarehouseStock>[].obs;
  final stockLoading = false.obs;
  final stockError = Rxn<Object>();

  /// رمز المنتج → الكمية الفعلية (تبدأ بكمية النظام)
  final counted = <String, double>{}.obs;

  /// منتجات كُتبت كميتها بصيغة غير صالحة (فارغة أو سالبة)
  final invalid = <String>{}.obs;
  final onlyDifferences = false.obs;
  final query = ''.obs;
  final reconciling = false.obs;

  // مبيعات اليوم
  final sales = <DaySale>[].obs;
  final salesLoading = false.obs;
  final salesError = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    loadStock();
    loadSales();
  }

  Future<void> loadStock() async {
    stockLoading.value = true;
    stockError.value = null;
    try {
      // كل صفوف Bin حتى الرصيد صفر: قد يكون مع المندوب ما لا يراه النظام
      final rows = await _stock.fetchStock(
        ErpConfig.vanWarehouse,
        includeZero: true,
      );
      stock.assignAll(rows);
      // الكمية الفعلية تبدأ بكمية النظام؛ ما عدّله المندوب يبقى
      for (final s in rows) {
        counted.putIfAbsent(s.itemCode, () => s.actualQty);
      }
    } catch (e) {
      debugPrint('EndOfDayController.loadStock failed: $e');
      stockError.value = e;
    } finally {
      stockLoading.value = false;
    }
  }

  Future<void> loadSales() async {
    salesLoading.value = true;
    salesError.value = null;
    try {
      sales.assignAll(await _sales.fetchDaySales(PalestineTime.today()));
    } catch (e) {
      debugPrint('EndOfDayController.loadSales failed: $e');
      salesError.value = e;
    } finally {
      salesLoading.value = false;
    }
  }

  // ───────── الجرد ─────────

  double physicalOf(WarehouseStock s) => counted[s.itemCode] ?? s.actualQty;

  /// الفعلية − النظام (موجب = زيادة، سالب = نقص)
  double differenceOf(WarehouseStock s) => physicalOf(s) - s.actualQty;

  bool hasDifference(WarehouseStock s) => differenceOf(s).abs() > 1e-9;

  /// [qty] = null أو سالبة: إدخال غير صالح يُعلَّم ولا يُحفظ
  void setPhysical(WarehouseStock s, double? qty) {
    if (qty == null || qty < 0) {
      invalid.add(s.itemCode);
      return;
    }
    invalid.remove(s.itemCode);
    counted[s.itemCode] = qty;
  }

  List<WarehouseStock> get differences => [
    for (final s in stock)
      if (hasDifference(s)) s,
  ];

  List<WarehouseStock> get visibleStock {
    final q = normalizeDigits(query.value.trim()).toLowerCase();
    return [
      for (final s in stock)
        if ((!onlyDifferences.value || hasDifference(s)) &&
            (q.isEmpty ||
                s.itemName.toLowerCase().contains(q) ||
                s.itemCode.toLowerCase().contains(q)))
          s,
    ];
  }

  /// تسوية مخزون مسودة بالمنتجات التي فيها فرق فقط. يعيد (الرقم، null) أو
  /// (null، الخطأ).
  Future<(String?, String?)> reconcile() async {
    if (invalid.isNotEmpty) return (null, VanStrings.qtyNotNegative);
    final diffs = differences;
    if (diffs.isEmpty) return (null, VanStrings.noDifferences);
    if (reconciling.value) return (null, null);
    reconciling.value = true;
    try {
      final name = await _sales.createReconciliation({
        for (final s in diffs) s.itemCode: physicalOf(s),
      });
      return (name, null);
    } catch (e) {
      debugPrint('EndOfDayController.reconcile failed: $e');
      final detail = e is ErpApiException && e.type == ErpErrorType.server
          ? e.detail
          : null;
      final base = describeError(e, fallback: VanStrings.reconcileFailed);
      return (
        null,
        (detail == null || detail.isEmpty)
            ? base
            : '${VanStrings.reconcileFailed}\n$detail',
      );
    } finally {
      reconciling.value = false;
    }
  }

  // ───────── ملخص المبيعات (المعتمدة فقط تُحتسب) ─────────

  List<DaySale> get submittedSales => [
    for (final s in sales)
      if (!s.isDraft && !s.isReturn) s,
  ];

  List<DaySale> get submittedReturns => [
    for (final s in sales)
      if (!s.isDraft && s.isReturn) s,
  ];

  List<DaySale> get drafts => [
    for (final s in sales)
      if (s.isDraft) s,
  ];

  double get totalSales => submittedSales.fold(0, (t, s) => t + s.total);

  /// موجب (قيمة المرتجعات بلا إشارة)
  double get totalReturns =>
      submittedReturns.fold(0, (t, s) => t + s.total.abs());

  double get draftsTotal => drafts.fold(0, (t, s) => t + s.total);
}
