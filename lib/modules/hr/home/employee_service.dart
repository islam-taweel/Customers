import 'package:flutter/material.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../app/routes/app_routes.dart';

/// خدمات الموظف بترتيب ظهورها: الأيقونة والعنوان والوصف واللون والشاشة.
enum EmployeeService {
  profile,
  checkin,
  attendance,
  correction,
  leaves,
  overtime,
  advances,
  expenses,
  payslips,

  /// لمعتمِدي الإجازات أو المصاريف فقط (يُخفى عن غيرهم)
  team;

  IconData get icon => switch (this) {
    profile => Icons.badge_outlined,
    checkin => Icons.fingerprint,
    attendance => Icons.event_note_outlined,
    correction => Icons.edit_calendar_outlined,
    leaves => Icons.beach_access_outlined,
    overtime => Icons.more_time_outlined,
    advances => Icons.account_balance_wallet_outlined,
    expenses => Icons.receipt_long_outlined,
    payslips => Icons.request_quote_outlined,
    team => Icons.groups_outlined,
  };

  String get title => switch (this) {
    profile => EssStrings.profile,
    checkin => EssStrings.checkin,
    attendance => EssStrings.attendance,
    correction => EssStrings.correction,
    leaves => EssStrings.leaves,
    overtime => EssStrings.overtime,
    advances => EssStrings.advances,
    expenses => EssStrings.expenses,
    payslips => EssStrings.payslips,
    team => EssStrings.team,
  };

  String get description => switch (this) {
    profile => EssStrings.profileDesc,
    checkin => EssStrings.checkinDesc,
    attendance => EssStrings.attendanceDesc,
    correction => EssStrings.correctionDesc,
    leaves => EssStrings.leavesDesc,
    overtime => EssStrings.overtimeDesc,
    advances => EssStrings.advancesDesc,
    expenses => EssStrings.expensesDesc,
    payslips => EssStrings.payslipsDesc,
    team => EssStrings.teamDesc,
  };

  /// من ألوان الثيم الحالي حتى تتناسق مع الوضع الداكن والفاتح والمخصص
  Color color(ColorScheme scheme) => switch (this) {
    profile => scheme.primary,
    checkin => scheme.tertiary,
    attendance => scheme.secondary,
    correction => scheme.error,
    leaves => scheme.primary,
    overtime => scheme.tertiary,
    advances => scheme.secondary,
    expenses => scheme.primary,
    payslips => scheme.tertiary,
    team => scheme.primary,
  };

  /// (R5) المسار المسمى للخدمة: الشاشة وBinding وMiddleware في AppPages.
  /// كان `route`/`screen` (MaterialPageRoute)، والمدخل ينتقل الآن بـ Get.toNamed.
  String get routeName => switch (this) {
    profile => Routes.hrProfile,
    checkin => Routes.hrPunch,
    attendance => Routes.hrAttendance,
    correction => Routes.hrCorrection,
    leaves => Routes.hrLeaves,
    overtime => Routes.hrOvertime,
    advances => Routes.hrAdvances,
    expenses => Routes.hrExpenses,
    payslips => Routes.hrPayslips,
    team => Routes.hrTeam,
  };
}
