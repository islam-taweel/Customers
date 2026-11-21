import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../shared/hr_approver_access.dart';
import '../../shared/hr_errors.dart';

import '../../team/models/team_models.dart';
import '../repository/team_repository.dart';

/// فريقي (GetX، للعرض فقط): طلبات الإجازات والمصاريف المعلقة للموظفين الذين
/// المستخدم معتمِدهم فقط. تُفحص الصلاحية أولًا، ولا يُجلب قسم بلا صلاحيته.
class TeamController extends GetxController {
  TeamController(this._repository, this._access);

  final TeamRepository _repository;
  final HrApproverAccess _access;

  final leaves = <TeamLeaveRequest>[].obs;
  final expenses = <TeamExpenseRequest>[].obs;
  final canApproveLeaves = false.obs;
  final canApproveExpenses = false.obs;

  /// تم فحص الصلاحية (قبله لا يُعرض شيء)
  final checked = false.obs;
  final loading = false.obs;
  final error = Rxn<Object>();

  /// رسالة الخطأ للعرض (R6: كانت دالة في الواجهة)
  String? get errorMessage {
    final e = error.value;
    return e == null
        ? null
        : hrErrorMessage(
            e,
            fallback: EssStrings.teamLoadFailed,
            notLinked: false,
          );
  }

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
      _access.update(leaves: access.leaves, expenses: access.expenses);
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
