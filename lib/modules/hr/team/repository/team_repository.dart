import '../../../../data/api/erp_api_client.dart';
import '../../expenses/models/expense_models.dart';
import '../../expenses/repository/expenses_repository.dart';
import '../../leaves/models/leave_models.dart';
import '../../shared/repository/hr_employee_identity.dart';
import '../models/team_models.dart';

/// «فريقي» (للعرض فقط): صلاحية المعتمِد من أدوار ERPNext، وطلبات الإجازات
/// والمصاريف المعلقة التي المستخدم معتمِدها فقط. (R6) منقولة حرفيًا.
class TeamRepository {
  TeamRepository(this._api, this._identity, this._expenses);

  final ErpApiClient _api;
  final HrEmployeeIdentity _identity;

  /// أول بند لكل طلب مصروف (نفس الدالة التي يستخدمها «مصاريفي»)
  final ExpensesRepository _expenses;

  /// هل المستخدم الحالي Leave Approver أو Expense Approver (من أدواره في ERPNext).
  Future<({bool leaves, bool expenses})> fetchApproverAccess() async {
    final roles = {
      if ((await _identity.userInfo())['roles'] case final List list)
        for (final r in list) r.toString(),
    };
    return (
      leaves: roles.contains('Leave Approver'),
      expenses: roles.contains('Expense Approver'),
    );
  }

  /// طلبات الإجازة المعلقة (Open، مسودة) التي المستخدم الحالي هو معتمِدها فقط
  /// (leave_approver)، فلا تظهر طلبات موظفين ليس مسؤولًا عنهم.
  Future<List<TeamLeaveRequest>> fetchTeamLeaves() async {
    final user = await _identity.loggedUser();
    if (user.isEmpty) return const [];
    final rows = await _api.getAll(
      'Leave Application',
      fields: [...LeaveRequest.fields, 'employee', 'employee_name'],
      filters: [
        ['leave_approver', '=', user],
        ['status', '=', 'Open'],
        ['docstatus', '=', 0],
      ],
      orderBy: 'from_date asc',
    );
    return [for (final r in rows) TeamLeaveRequest.fromJson(r)];
  }

  /// طلبات المصاريف المعلقة (مسودة لم يُوافق عليها) التي المستخدم الحالي هو
  /// معتمِدها فقط (expense_approver).
  Future<List<TeamExpenseRequest>> fetchTeamExpenses() async {
    final user = await _identity.loggedUser();
    if (user.isEmpty) return const [];
    final rows = await _api.getAll(
      'Expense Claim',
      fields: [...ExpenseClaimSummary.fields, 'employee', 'employee_name'],
      filters: [
        ['expense_approver', '=', user],
        ['docstatus', '=', 0],
        ['approval_status', '=', 'Draft'],
      ],
      orderBy: 'posting_date asc',
    );
    if (rows.isEmpty) return const [];
    final details = await _expenses.expenseDetails([
      for (final r in rows) r['name'].toString(),
    ]);
    return [
      for (final r in rows)
        TeamExpenseRequest.fromJson(r, detail: details[r['name'].toString()]),
    ];
  }
}
