import '../../expenses/models/expense_models.dart';
import '../../leaves/models/leave_models.dart';

String _s(Object? v) => v?.toString() ?? '';

/// طلب إجازة معلّق لموظف في فريق المستخدم (هو معتمِده)
class TeamLeaveRequest {
  final String employee;
  final String employeeName;
  final LeaveRequest request;

  const TeamLeaveRequest({
    required this.employee,
    required this.employeeName,
    required this.request,
  });

  factory TeamLeaveRequest.fromJson(Map<String, dynamic> json) {
    final id = _s(json['employee']);
    final name = _s(json['employee_name']);
    return TeamLeaveRequest(
      employee: id,
      employeeName: name.isEmpty ? id : name,
      request: LeaveRequest.fromJson(json),
    );
  }
}

/// طلب مصروف معلّق لموظف في فريق المستخدم (هو معتمِده)
class TeamExpenseRequest {
  final String employee;
  final String employeeName;
  final ExpenseClaimSummary claim;

  const TeamExpenseRequest({
    required this.employee,
    required this.employeeName,
    required this.claim,
  });

  factory TeamExpenseRequest.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? detail,
  }) {
    final id = _s(json['employee']);
    final name = _s(json['employee_name']);
    return TeamExpenseRequest(
      employee: id,
      employeeName: name.isEmpty ? id : name,
      claim: ExpenseClaimSummary.fromJson(json, detail: detail),
    );
  }
}
