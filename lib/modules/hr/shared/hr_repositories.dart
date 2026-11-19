import '../../../data/api/erp_api_client.dart';
import '../../../data/repositories/erp_employee_repository.dart';
import '../attendance/repository/attendance_repository.dart';
import '../leaves/repository/leaves_repository.dart';
import '../profile/repository/profile_repository.dart';
import '../punch/repository/punch_repository.dart';
import 'repository/hr_employee_identity.dart';

/// كل repositories الموارد البشرية، تُنشأ **مرة واحدة** في main() فوق نفس
/// ErpApiClient ونفس HrEmployeeIdentity، وتُسجَّل دائمًا في InitialBinding.
///
/// [legacy]: ما بقي من ErpEmployeeRepository لوحدات لم تُرحَّل بعد (R6)، وهو
/// نفس الكائن الذي يقدّمه MultiProvider لشاشاتها.
class HrRepositories {
  HrRepositories(ErpApiClient api) : identity = HrEmployeeIdentity(api) {
    profile = ProfileRepository(api, identity);
    punch = PunchRepository(api, identity);
    attendance = AttendanceRepository(api, identity);
    leaves = LeavesRepository(api, identity);
    legacy = ErpEmployeeRepository(api, identity);
  }

  final HrEmployeeIdentity identity;
  late final ProfileRepository profile;
  late final PunchRepository punch;
  late final AttendanceRepository attendance;
  late final LeavesRepository leaves;
  late final ErpEmployeeRepository legacy;
}
