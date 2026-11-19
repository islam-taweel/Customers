import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/models/team_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';

/// صلاحيات قسم الموارد البشرية (GetX): تُفحص عند فتح القسم. «فريقي» يظهر فقط
/// لمن لديه دور Leave Approver أو Expense Approver، ويبقى مخفيًا أثناء الفحص
/// وعند فشله.
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

/// فريقي (GetX، للعرض فقط): طلبات الإجازات والمصاريف المعلقة للموظفين الذين
/// المستخدم معتمِدهم فقط. تُفحص الصلاحية أولًا، ولا يُجلب قسم بلا صلاحيته.
class TeamController extends GetxController {
  TeamController(this._repository);

  final ErpEmployeeRepository _repository;

  final leaves = <TeamLeaveRequest>[].obs;
  final expenses = <TeamExpenseRequest>[].obs;
  final canApproveLeaves = false.obs;
  final canApproveExpenses = false.obs;

  /// تم فحص الصلاحية (قبله لا يُعرض شيء)
  final checked = false.obs;
  final loading = false.obs;
  final error = Rxn<Object>();

  bool get hasAccess => canApproveLeaves.value || canApproveExpenses.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final access = await _repository.fetchApproverAccess();
      canApproveLeaves.value = access.leaves;
      canApproveExpenses.value = access.expenses;
      checked.value = true;
      final results = await Future.wait([
        access.leaves
            ? _repository.fetchTeamLeaves()
            : Future.value(const <TeamLeaveRequest>[]),
        access.expenses
            ? _repository.fetchTeamExpenses()
            : Future.value(const <TeamExpenseRequest>[]),
      ]);
      leaves.assignAll(results[0] as List<TeamLeaveRequest>);
      expenses.assignAll(results[1] as List<TeamExpenseRequest>);
    } catch (e) {
      debugPrint('TeamController.load failed: $e');
      error.value = e;
    } finally {
      loading.value = false;
    }
  }
}
