import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/erp_employee_repository.dart';

/// صلاحيات قسم الموارد البشرية (GetX): تُفحص عند فتح القسم. «فريقي» يظهر فقط
/// لمن لديه دور Leave Approver أو Expense Approver، ويبقى مخفيًا أثناء الفحص
/// وعند فشله.
///
/// (R5) نُقل كما هو من team_controller.dart، ويُسجَّل الآن عبر HrHomeBinding.
class HrAccessController extends GetxController {
  HrAccessController(this._repository);

  final ErpEmployeeRepository _repository;

  final canApproveLeaves = false.obs;
  final canApproveExpenses = false.obs;

  bool get canSeeTeam => canApproveLeaves.value || canApproveExpenses.value;

  @override
  void onInit() {
    super.onInit();
    check();
  }

  Future<void> check() async {
    try {
      final access = await _repository.fetchApproverAccess();
      canApproveLeaves.value = access.leaves;
      canApproveExpenses.value = access.expenses;
    } catch (e) {
      debugPrint('HrAccessController.check failed: $e');
      canApproveLeaves.value = false;
      canApproveExpenses.value = false;
    }
  }
}
