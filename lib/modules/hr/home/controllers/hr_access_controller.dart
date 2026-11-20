import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../shared/hr_approver_access.dart';
import '../../team/repository/team_repository.dart';

/// صلاحيات قسم الموارد البشرية (GetX): تُفحص عند فتح القسم. «فريقي» يظهر فقط
/// لمن لديه دور Leave Approver أو Expense Approver، ويبقى مخفيًا أثناء الفحص
/// وعند فشله.
///
/// (R5/R6) نُقل من team_controller.dart، ويُسجَّل الآن عبر HrHomeBinding.
class HrAccessController extends GetxController {
  HrAccessController(this._repository, this._access);

  final TeamRepository _repository;

  /// الصلاحية المخزّنة التي يقرؤها ManagerMiddleware (R6)
  final HrApproverAccess _access;

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
      _access.update(leaves: access.leaves, expenses: access.expenses);
    } catch (e) {
      debugPrint('HrAccessController.check failed: $e');
      canApproveLeaves.value = false;
      canApproveExpenses.value = false;
      _access.clear();
    }
  }
}
