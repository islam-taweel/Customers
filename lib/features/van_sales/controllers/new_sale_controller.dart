import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/constants/warehouse_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/erp_customer.dart';
import '../../../data/models/van_sale_models.dart';
import '../../../data/models/warehouse_models.dart';
import '../../../data/repositories/erp_van_sales_repository.dart';
import '../../../data/repositories/erp_warehouse_repository.dart';

/// فاتورة بيع جديدة من الفان (GetX): اختيار العميل، المنتجات من مخزون الفان
/// (بحث أو باركود)، وحدة البيع والكمية لكل منتج، ثم الحفظ مسودة في ERPNext
/// مع Update Stock من مستودع الفان.
class NewSaleController extends GetxController {
  NewSaleController(this._sales, this._stock);

  final ErpVanSalesRepository _sales;
  final ErpWarehouseRepository _stock;

  // العملاء
  final customers = <ErpCustomer>[].obs;
  final customersLoading = false.obs;
  final customersError = Rxn<Object>();
  final customer = Rxn<ErpCustomer>();

  // مخزون الفان (المنتجات المتاحة للبيع)
  final stock = <WarehouseStock>[].obs;
  final stockLoading = false.obs;
  final stockError = Rxn<Object>();

  // رصيد العميل المختار وحده الائتماني (لفحص تجاوز الحد قبل الحفظ)
  final credit = Rxn<CustomerCredit>();
  final creditLoading = false.obs;

  // البنود
  final lines = <SaleLine>[].obs;
  final saving = false.obs;

  /// وحدات كل منتج (تُجلب مرة واحدة)
  final _units = <String, List<SaleUnit>>{};

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
    loadStock();
    // عند اختيار عميل: يُجلب حده الائتماني ورصيده
    ever<ErpCustomer?>(customer, (_) => loadCredit());
  }

  Future<void> loadCredit() async {
    final c = customer.value;
    credit.value = null;
    if (c == null) return;
    creditLoading.value = true;
    try {
      final result = await _sales.fetchCredit(c.id);
      if (customer.value?.id == c.id) credit.value = result;
    } catch (e) {
      // الفحص تحذيري: فشله لا يمنع الفاتورة، وERPNext يفحص الحد عند الاعتماد
      debugPrint('NewSaleController.loadCredit failed: $e');
    } finally {
      creditLoading.value = false;
    }
  }

  /// الفاتورة (بإجماليها التقديري) ستتجاوز الحد الائتماني للعميل
  bool get exceedsCredit {
    final c = credit.value;
    final total = estimatedTotal;
    return c != null && total != null && c.exceedsWith(total);
  }

  Future<void> loadCustomers() async {
    customersLoading.value = true;
    customersError.value = null;
    try {
      customers.assignAll(await _sales.fetchCustomers());
    } catch (e) {
      debugPrint('NewSaleController.loadCustomers failed: $e');
      customersError.value = e;
    } finally {
      customersLoading.value = false;
    }
  }

  Future<void> loadStock() async {
    stockLoading.value = true;
    stockError.value = null;
    try {
      stock.assignAll(await _stock.fetchStock(ErpConfig.vanWarehouse));
    } catch (e) {
      debugPrint('NewSaleController.loadStock failed: $e');
      stockError.value = e;
    } finally {
      stockLoading.value = false;
    }
  }

  List<ErpCustomer> filterCustomers(String query) {
    final q = normalizeDigits(query.trim()).toLowerCase();
    if (q.isEmpty) return customers;
    return [
      for (final c in customers)
        if (c.name.toLowerCase().contains(q) ||
            c.id.toLowerCase().contains(q) ||
            c.phone.contains(q))
          c,
    ];
  }

  List<WarehouseStock> filterStock(String query) {
    final q = normalizeDigits(query.trim()).toLowerCase();
    if (q.isEmpty) return stock;
    return [
      for (final s in stock)
        if (s.itemName.toLowerCase().contains(q) ||
            s.itemCode.toLowerCase().contains(q))
          s,
    ];
  }

  WarehouseStock? stockOf(String itemCode) {
    for (final s in stock) {
      if (s.itemCode == itemCode) return s;
    }
    return null;
  }

  /// المنتج المطابق للباركود من مخزون الفان: كوده نفسه، وإلا Item Barcode.
  Future<WarehouseStock?> findByBarcode(String barcode) async {
    final code = barcode.trim();
    final direct = stockOf(code);
    if (direct != null) return direct;
    final itemCode = await _stock.itemCodeForBarcode(code);
    return itemCode == null ? null : stockOf(itemCode);
  }

  Future<List<SaleUnit>> unitsOf(WarehouseStock s) async {
    final cached = _units[s.itemCode];
    if (cached != null) return cached;
    final units = await _sales.fetchUnits(s.itemCode);
    // احتياط: وحدة المخزون من Bin إن لم يعد Item أي وحدة
    final list = units.isNotEmpty
        ? units
        : [SaleUnit(uom: s.uom, factor: 1, wholeNumber: s.wholeNumber)];
    _units[s.itemCode] = list;
    return list;
  }

  Future<double?> priceOf(WarehouseStock s, SaleUnit unit) async {
    try {
      return await _sales.estimatePrice(s.itemCode, unit, stockUom: s.uom);
    } catch (e) {
      debugPrint('NewSaleController.priceOf failed: $e');
      return null;
    }
  }

  /// كمية المنتج بوحدة المخزون في البنود، عدا البند رقم [except]
  double _stockQtyInLines(String itemCode, {int? except}) {
    var total = 0.0;
    for (var i = 0; i < lines.length; i++) {
      if (i == except) continue;
      if (lines[i].itemCode == itemCode) total += lines[i].stockQty;
    }
    return total;
  }

  /// null = صالحة. أكبر من صفر، عدد صحيح إن كانت الوحدة لا تقبل كسورًا، ولا
  /// تتجاوز (مع بنود المنتج الأخرى) الموجود في الفان.
  String? validateQty(
    WarehouseStock s,
    SaleUnit unit,
    double? qty, {
    int? editing,
  }) {
    if (qty == null || qty <= 0) return VanStrings.qtyPositive;
    if (unit.wholeNumber && qty != qty.roundToDouble()) {
      return VanStrings.qtyWhole(unit.uom);
    }
    final left = s.actualQty - _stockQtyInLines(s.itemCode, except: editing);
    if (qty * unit.factor > left + 1e-9) {
      final inUnit = left / unit.factor;
      return VanStrings.qtyAboveStock(
        WarehouseStrings.qty(inUnit < 0 ? 0 : inUnit, unit.uom),
      );
    }
    return null;
  }

  /// يضيف بندًا، أو يزيد كمية بند بنفس المنتج والوحدة. [editing] = تعديل بند.
  void putLine(SaleLine line, {int? editing}) {
    if (editing != null) {
      lines[editing] = line;
      return;
    }
    final i = lines.indexWhere(
      (l) => l.itemCode == line.itemCode && l.unit.uom == line.unit.uom,
    );
    if (i >= 0) {
      lines[i] = lines[i].copyWith(qty: lines[i].qty + line.qty);
    } else {
      lines.add(line);
    }
  }

  void removeLine(int index) => lines.removeAt(index);

  /// الإجمالي التقديري؛ null إن كان لبند ما بلا سعر معروف
  double? get estimatedTotal {
    var total = 0.0;
    for (final l in lines) {
      final a = l.amount;
      if (a == null) return null;
      total += a;
    }
    return total;
  }

  bool get isDirty => customer.value != null || lines.isNotEmpty;

  /// null = صالحة للحفظ
  String? validateSale() {
    if (customer.value == null) return VanStrings.needCustomer;
    if (lines.isEmpty) return VanStrings.needLines;
    return null;
  }

  /// يحفظ Sales Invoice مسودة. يعيد (الفاتورة، null) أو (null، رسالة الخطأ).
  Future<(CreatedSale?, String?)> save() async {
    final invalid = validateSale();
    if (invalid != null) return (null, invalid);
    if (saving.value) return (null, null);
    saving.value = true;
    try {
      final sale = await _sales.createDraftInvoice(
        customerId: customer.value!.id,
        lines: lines.toList(),
      );
      lines.clear();
      customer.value = null;
      return (sale, null);
    } catch (e) {
      debugPrint('NewSaleController.save failed: $e');
      final detail = e is ErpApiException && e.type == ErpErrorType.server
          ? e.detail
          : null;
      final base = describeError(e, fallback: VanStrings.saveFailed);
      return (
        null,
        (detail == null || detail.isEmpty)
            ? base
            : '${VanStrings.saveFailed}\n$detail',
      );
    } finally {
      saving.value = false;
    }
  }
}
