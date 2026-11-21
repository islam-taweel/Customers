import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../shared/hr_errors.dart';

import '../../payslips/models/payslip_models.dart';
import '../repository/payslips_repository.dart';

/// كشوف رواتبي (GetX): كشوف الموظف الحالي المعتمدة فقط من ERPNext، تُحدَّث عند
/// فتح الشاشة. للعرض فقط.
class PayslipsController extends GetxController
    with StateMixin<List<PayslipSummary>> {
  PayslipsController(this._repository);

  final PayslipsRepository _repository;

  final payslips = <PayslipSummary>[].obs;
  final loading = false.obs;
  final error = Rxn<Object>();

  /// رسالة الخطأ للعرض (R6: كانت دالة في الواجهة)
  String? get errorMessage {
    final e = error.value;
    return e == null
        ? null
        : hrErrorMessage(e, fallback: EssStrings.payslipsLoadFailed);
  }

  /// (R7) حالة العرض لـ controller.obx، محسوبة من نفس الشروط وبنفس ترتيبها:
  /// تحميل والقائمة فارغة ← loading؛ خطأ والقائمة فارغة ← error؛ فارغة ←
  /// empty؛ وإلا success (القائمة تبقى ظاهرة أثناء إعادة التحميل كما كانت).
  Worker? _statusWorker;

  void _syncStatus() {
    final list = payslips.toList();
    if (loading.value && list.isEmpty) {
      change(list, status: RxStatus.loading());
    } else if (error.value != null && list.isEmpty) {
      change(list, status: RxStatus.error(errorMessage));
    } else if (list.isEmpty) {
      change(list, status: RxStatus.empty());
    } else {
      change(list, status: RxStatus.success());
    }
  }

  @override
  void onClose() {
    _statusWorker?.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    _statusWorker = everAll([loading, error, payslips], (_) => _syncStatus());
    _syncStatus();
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

  final PayslipsRepository _repository;

  /// رقم الكشف (Salary Slip.name)
  final String name;

  final payslip = Rxn<PayslipDetail>();
  final loading = false.obs;
  final error = Rxn<Object>();

  /// رسالة الخطأ للعرض (R6: كانت دالة في الواجهة)
  String? get errorMessage {
    final e = error.value;
    return e == null
        ? null
        : hrErrorMessage(e, fallback: EssStrings.payslipLoadFailed);
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
      payslip.value = await _repository.fetchPayslip(name);
    } catch (e) {
      debugPrint('PayslipDetailController.load failed: $e');
      error.value = e;
    } finally {
      loading.value = false;
    }
  }
}
