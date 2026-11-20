import 'package:get/get.dart';

import '../../features/auth/screens/auth_gate.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../../modules/hr/advances/bindings/advances_binding.dart';
import '../../modules/hr/advances/views/advances_view.dart';
import '../../modules/hr/attendance/bindings/attendance_bindings.dart';
import '../../modules/hr/attendance/views/attendance_correction_view.dart';
import '../../modules/hr/attendance/views/attendance_view.dart';
import '../../modules/hr/expenses/bindings/expenses_binding.dart';
import '../../modules/hr/expenses/views/expenses_view.dart';
import '../../modules/hr/home/bindings/hr_home_binding.dart';
import '../../modules/hr/home/views/hr_home_view.dart';
import '../../modules/hr/leaves/bindings/leaves_binding.dart';
import '../../modules/hr/leaves/views/leaves_view.dart';
import '../../modules/hr/overtime/bindings/overtime_binding.dart';
import '../../modules/hr/overtime/views/overtime_view.dart';
import '../../modules/hr/payslips/bindings/payslips_binding.dart';
import '../../modules/hr/payslips/views/payslip_detail_view.dart';
import '../../modules/hr/payslips/views/payslips_view.dart';
import '../../modules/hr/profile/bindings/profile_binding.dart';
import '../../modules/hr/profile/views/profile_view.dart';
import '../../modules/hr/punch/bindings/punch_binding.dart';
import '../../modules/hr/punch/views/punch_view.dart';
import '../../modules/hr/team/bindings/team_binding.dart';
import '../../modules/hr/team/views/team_view.dart';
import '../bindings/auth_binding.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/manager_middleware.dart';
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
    // ───── خدمات الموظف (R6): بقية HR بمسار مسمى وBinding ─────
    GetPage(
      name: Routes.hrOvertime,
      page: () => const OvertimeScreen(),
      binding: OvertimeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrAdvances,
      page: () => const AdvancesScreen(),
      binding: AdvancesBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrExpenses,
      page: () => const ExpensesScreen(),
      binding: ExpensesBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrPayslips,
      page: () => const PayslipsScreen(),
      binding: PayslipsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.hrPayslipDetail,
      // رقم الكشف في arguments (Get.toNamed(..., arguments: name))
      page: () => PayslipDetailScreen(name: Get.arguments as String),
      binding: PayslipDetailBinding(),
      middlewares: [AuthMiddleware()],
    ),
    // «فريقي»: للمعتمِدين فقط، محمي بـ ManagerMiddleware لا بإخفاء الزر وحده
    GetPage(
      name: Routes.hrTeam,
      page: () => const TeamScreen(),
      binding: TeamBinding(),
      middlewares: [AuthMiddleware(), ManagerMiddleware()],
    ),
  ];
}
