/// أسماء المسارات المسماة (R1). التنقل الحالي بـ Navigator.push و static route()
/// يبقى كما هو؛ هذه المسارات تُضاف بجانبه.
abstract class Routes {
  Routes._();

  /// البوابة: تعرض الدخول أو MainShell حسب الجلسة (المسار الجذري، لا يُغلق)
  static const gate = '/';
  static const login = '/login';
  static const home = '/home';

  /// خدمات الموظف (R5/R6): المدخل وكل خدمة بمسار مسمى (Get.toNamed)
  static const hr = '/hr';
  static const hrProfile = '/hr/profile';
  static const hrPunch = '/hr/punch';
  static const hrAttendance = '/hr/attendance';
  static const hrCorrection = '/hr/attendance/correction';
  static const hrLeaves = '/hr/leaves';
  static const hrOvertime = '/hr/overtime';
  static const hrAdvances = '/hr/advances';
  static const hrExpenses = '/hr/expenses';
  static const hrPayslips = '/hr/payslips';
  static const hrPayslipDetail = '/hr/payslips/detail';
  static const hrTeam = '/hr/team';
}
