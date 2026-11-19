import 'package:flutter/material.dart';

import '../../core/constants/ess_strings.dart';
import 'screens/advances_screen.dart';
import 'screens/attendance_correction_screen.dart';
import 'screens/attendance_log_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/leaves_screen.dart';
import 'screens/my_account_screen.dart';
import 'screens/overtime_screen.dart';
import 'screens/payslips_screen.dart';
import 'screens/team_screen.dart';

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

  Widget get screen => switch (this) {
    profile => const MyAccountScreen(),
    checkin => const CheckinScreen(),
    attendance => const AttendanceLogScreen(),
    correction => const AttendanceCorrectionScreen(),
    leaves => const LeavesScreen(),
    overtime => const OvertimeScreen(),
    advances => const AdvancesScreen(),
    expenses => const ExpensesScreen(),
    payslips => const PayslipsScreen(),
    team => const TeamScreen(),
  };

  Route<void> get route => MaterialPageRoute<void>(builder: (_) => screen);
}
