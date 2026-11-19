import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/erp_customer.dart';
import '../../../data/models/van_sale_models.dart';
import '../../../data/repositories/erp_van_sales_repository.dart';

/// رصيد العميل (GetX): اختيار العميل، ثم حده الائتماني (Credit Limit) ورصيده
/// الحالي والمتاح من الحد من ERPNext.
class CustomerCreditController extends GetxController {
  CustomerCreditController(this._repository);

  final ErpVanSalesRepository _repository;

  final customers = <ErpCustomer>[].obs;
  final customersLoading = false.obs;
  final customersError = Rxn<Object>();

  final customer = Rxn<ErpCustomer>();
  final credit = Rxn<CustomerCredit>();
  final creditLoading = false.obs;
  final creditError = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    customersLoading.value = true;
    customersError.value = null;
    try {
      customers.assignAll(await _repository.fetchCustomers());
    } catch (e) {
      debugPrint('CustomerCreditController.loadCustomers failed: $e');
      customersError.value = e;
    } finally {
      customersLoading.value = false;
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

  Future<void> select(ErpCustomer c) async {
    customer.value = c;
    await loadCredit();
  }

  Future<void> loadCredit() async {
    final c = customer.value;
    if (c == null) return;
    creditLoading.value = true;
    creditError.value = null;
    credit.value = null;
    try {
      final result = await _repository.fetchCredit(c.id);
      if (customer.value?.id == c.id) credit.value = result;
    } catch (e) {
      debugPrint('CustomerCreditController.loadCredit failed: $e');
      creditError.value = e;
    } finally {
      creditLoading.value = false;
    }
  }
}
