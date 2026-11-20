import '../../../data/api/erp_api_client.dart';
import '../advances/repository/advances_repository.dart';
import '../attendance/repository/attendance_repository.dart';
import '../expenses/repository/expenses_repository.dart';
import '../leaves/repository/leaves_repository.dart';
import '../overtime/repository/overtime_repository.dart';
import '../payslips/repository/payslips_repository.dart';
import '../profile/repository/profile_repository.dart';
import '../punch/repository/punch_repository.dart';
import '../team/repository/team_repository.dart';
import 'repository/hr_employee_identity.dart';

/// كل repositories الموارد البشرية، تُنشأ **مرة واحدة** في main() فوق نفس
/// ErpApiClient ونفس HrEmployeeIdentity، وتُسجَّل دائمًا في InitialBinding.
///
/// (R6) انتهى ErpEmployeeRepository القديم: كل وحدة لها repository خاص بها.
/// [overtime] يجب أن يبقى كائنًا واحدًا لأنه يحفظ نتيجة فحص Overtime Slip لبقية
/// الجلسة، و[team] يشارك [expenses] لجلب أول بند لكل طلب مصروف.
class HrRepositories {
  HrRepositories(ErpApiClient api) : identity = HrEmployeeIdentity(api) {
    profile = ProfileRepository(api, identity);
    punch = PunchRepository(api, identity);
    attendance = AttendanceRepository(api, identity);
    leaves = LeavesRepository(api, identity);
    overtime = OvertimeRepository(api, identity);
    advances = AdvancesRepository(api, identity);
    expenses = ExpensesRepository(api, identity);
    payslips = PayslipsRepository(api, identity);
    team = TeamRepository(api, identity, expenses);
  }

  final HrEmployeeIdentity identity;
  late final ProfileRepository profile;
  late final PunchRepository punch;
  late final AttendanceRepository attendance;
  late final LeavesRepository leaves;
  late final OvertimeRepository overtime;
  late final AdvancesRepository advances;
  late final ExpensesRepository expenses;
  late final PayslipsRepository payslips;
  late final TeamRepository team;
}
