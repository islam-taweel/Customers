import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/constants/warehouse_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/return_models.dart';
import '../../../data/models/van_sale_models.dart';
import '../../../data/repositories/erp_van_sales_repository.dart';

/// إرجاع منتجات من فاتورة فان معتمدة (GetX): الفواتير، ثم بنود الفاتورة بما
/// بقي قابلًا للإرجاع، وكميات الإرجاع، ثم الحفظ مسودة Sales Invoice (Return).
class VanReturnController extends GetxController {
  VanReturnController(this._repository);

  final ErpVanSalesRepository _repository;

  // الفواتير
  final invoices = <VanInvoice>[].obs;
  final invoicesLoading = false.obs;
  final invoicesError = Rxn<Object>();
  final query = ''.obs;

  // الفاتورة المختارة وبنودها
  final invoice = Rxn<VanInvoice>();
  final items = <ReturnableItem>[].obs;
  final itemsLoading = false.obs;
  final itemsError = Rxn<Object>();

  /// رقم صف الفاتورة → كمية الإرجاع (موجبة)
  final quantities = <String, double>{}.obs;
  final saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadInvoices();
  }

  List<VanInvoice> get filteredInvoices {
    final q = normalizeDigits(query.value.trim()).toLowerCase();
    if (q.isEmpty) return invoices;
    return [
      for (final i in invoices)
        if (i.name.toLowerCase().contains(q) ||
            i.customerName.toLowerCase().contains(q) ||
            i.customer.toLowerCase().contains(q))
          i,
    ];
  }

  Future<void> loadInvoices() async {
    invoicesLoading.value = true;
    invoicesError.value = null;
    try {
      invoices.assignAll(await _repository.fetchSubmittedInvoices());
    } catch (e) {
      debugPrint('VanReturnController.loadInvoices failed: $e');
      invoicesError.value = e;
    } finally {
      invoicesLoading.value = false;
    }
  }

  /// يختار الفاتورة ويجلب بنودها (يمسح أي كميات سابقة)
  Future<void> selectInvoice(VanInvoice i) async {
    invoice.value = i;
    quantities.clear();
    await loadItems();
  }

  Future<void> loadItems() async {
    final i = invoice.value;
    if (i == null) return;
    itemsLoading.value = true;
    itemsError.value = null;
    items.clear();
    try {
      final rows = await _repository.fetchReturnableItems(i.name);
      if (invoice.value?.name == i.name) items.assignAll(rows);
    } catch (e) {
      debugPrint('VanReturnController.loadItems failed: $e');
      itemsError.value = e;
    } finally {
      itemsLoading.value = false;
    }
  }

  /// null = صالحة. أكبر من صفر، عدد صحيح إن كانت الوحدة لا تقبل كسورًا، ولا
  /// تتجاوز المسموح إرجاعه (المباع − ما أُرجع في مرتجعات معتمدة).
  static String? validate(ReturnableItem item, double? qty) {
    if (qty == null || qty <= 0) return VanStrings.qtyPositive;
    if (item.wholeNumber && qty != qty.roundToDouble()) {
      return VanStrings.qtyWhole(item.uom);
    }
    if (qty > item.returnable + 1e-9) {
      return VanStrings.qtyAboveReturnable(
        WarehouseStrings.qty(item.returnable, item.uom),
      );
    }
    return null;
  }

  bool isSelected(ReturnableItem item) => quantities.containsKey(item.rowName);

  /// تحديد منتج للإرجاع: بكل الكمية المسموحة افتراضيًا
  void toggle(ReturnableItem item, bool selected) {
    if (!selected) {
      quantities.remove(item.rowName);
    } else if (item.returnable > 0) {
      quantities[item.rowName] = item.returnable;
    }
  }

  /// الكمية كما كُتبت (حتى غير الصالحة، ليظهر خطأها)
  void setQty(ReturnableItem item, double? qty) {
    quantities[item.rowName] = qty ?? 0;
  }

  /// كل الكميات المحددة صالحة وفيها بند واحد على الأقل
  String? validateAll() {
    if (quantities.isEmpty) return VanStrings.needReturnLines;
    for (final item in items) {
      final q = quantities[item.rowName];
      if (q == null) continue;
      final error = validate(item, q);
      if (error != null) return '${item.itemName}: $error';
    }
    return null;
  }

  /// يحفظ مستند الإرجاع مسودة. يعيد (المستند من ERPNext، null) أو (null، الخطأ).
  Future<(VanReturnResult?, String?)> save() async {
    final i = invoice.value;
    final invalid = i == null ? VanStrings.chooseInvoice : validateAll();
    if (invalid != null) return (null, invalid);
    if (saving.value) return (null, null);
    saving.value = true;
    try {
      final result = await _repository.createReturn(
        invoice: i!.name,
        items: items.toList(),
        quantities: Map.of(quantities),
      );
      quantities.clear();
      return (result, null);
    } catch (e) {
      debugPrint('VanReturnController.save failed: $e');
      final detail = e is ErpApiException && e.type == ErpErrorType.server
          ? e.detail
          : null;
      final base = describeError(e, fallback: VanStrings.returnFailed);
      return (
        null,
        (detail == null || detail.isEmpty)
            ? base
            : '${VanStrings.returnFailed}\n$detail',
      );
    } finally {
      saving.value = false;
    }
  }
}
