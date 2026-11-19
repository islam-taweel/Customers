import 'package:get/get.dart';

import '../../features/auth/screens/auth_gate.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/employee_services/screens/advances_screen.dart';
import '../../features/employee_services/screens/expenses_screen.dart';
import '../../features/employee_services/screens/overtime_screen.dart';
import '../../features/employee_services/screens/payslips_screen.dart';
import '../../features/employee_services/screens/team_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../../modules/hr/attendance/bindings/attendance_bindings.dart';
import '../../modules/hr/attendance/views/attendance_correction_view.dart';
import '../../modules/hr/attendance/views/attendance_view.dart';
import '../../modules/hr/home/bindings/hr_home_binding.dart';
import '../../modules/hr/home/views/hr_home_view.dart';
import '../../modules/hr/leaves/bindings/leaves_binding.dart';
import '../../modules/hr/leaves/views/leaves_view.dart';
import '../../modules/hr/profile/bindings/profile_binding.dart';
import '../../modules/hr/profile/views/profile_view.dart';
import '../../modules/hr/punch/bindings/punch_binding.dart';
import '../../modules/hr/punch/views/punch_view.dart';
import '../bindings/auth_binding.dart';
import '../middleware/auth_middleware.dart';
import 'app_routes.dart';

/// صفحات المسارات المسماة (R1). البوابة هي المسار الجذري ومرجع حالة الدخول.
abstract class AppPages {
  AppPages._();

  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: Routes.gate,
      page: () => const AuthGate(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: Routes.home,
      page: () => const MainShell(),
      middlewares: [AuthMiddleware()],
    ),

    // ───── خدمات الموظف (R5): كل خدمة بمسار مسمى وBinding ─────
    GetPage(
      name: Routes.hr,
      page: () => const EmployeeServicesScreen(),
      binding: HrHomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrProfile,
      page: () => const MyAccountScreen(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrPunch,
      page: () => const CheckinScreen(),
      binding: PunchBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrAttendance,
      page: () => const AttendanceLogScreen(),
      binding: AttendanceBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrCorrection,
      page: () => const AttendanceCorrectionScreen(),
      binding: CorrectionBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrLeaves,
      page: () => const LeavesScreen(),
      binding: LeavesBinding(),
      middlewares: [AuthMiddleware()],
    ),
    // R6: هذه الشاشات ما زالت تنشئ متحكماتها بنفسها حتى ترحيلها
    GetPage(
      name: Routes.hrOvertime,
      page: () => const OvertimeScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrAdvances,
      page: () => const AdvancesScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrExpenses,
      page: () => const ExpensesScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrPayslips,
      page: () => const PayslipsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrTeam,
      page: () => const TeamScreen(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
