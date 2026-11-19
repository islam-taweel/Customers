import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/models/payslip_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';

/// كشوف رواتبي (GetX): كشوف الموظف الحالي المعتمدة فقط من ERPNext، تُحدَّث عند
/// فتح الشاشة. للعرض فقط.
class PayslipsController extends GetxController {
  PayslipsController(this._repository);

  final ErpEmployeeRepository _repository;

  final payslips = <PayslipSummary>[].obs;
  final loading = false.obs;
  final error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      payslips.assignAll(await _repository.fetchPayslips());
    } catch (e) {
      debugPrint('PayslipsController.load failed: $e');
      error.value = e;
    } finally {
      loading.value = false;
    }
  }
}

/// تفاصيل كشف راتب واحد (GetX): المستحقات والخصومات والملخص.
class PayslipDetailController extends GetxController {
  PayslipDetailController(this._repository, this.name);

  final ErpEmployeeRepository _repository;

  /// رقم الكشف (Salary Slip.name)
  final String name;

  final payslip = Rxn<PayslipDetail>();
  final loading = false.obs;
  final error = Rxn<Object>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      payslip.value = await _repository.fetchPayslip(name);
    } catch (e) {
      debugPrint('PayslipDetailController.load failed: $e');
      error.value = e;
    } finally {
      loading.value = false;
    }
  }
}
