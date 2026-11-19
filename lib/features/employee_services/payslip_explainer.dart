import 'package:flutter/material.dart';

import '../../core/constants/ess_strings.dart';
import '../../data/models/payslip_models.dart';

/// نوع المستحق حسب اسم مكوّن الراتب (الأسماء تختلف بين المواقع)
enum EarningKind {
  basic,
  transport,
  overtime,
  other;

  static EarningKind of(SalaryLine l) {
    final n = '${l.component} ${l.abbr}'.toLowerCase();
    if (n.contains('basic') || n.contains('أساسي')) return basic;
    if (n.contains('transport') ||
        n.contains('travel') ||
        n.contains('conveyance') ||
        n.contains('مواصلات')) {
      return transport;
    }
    if (n.contains('overtime') || n.contains('إضافي')) return overtime;
    return other;
  }

  String get label => switch (this) {
    basic => EssStrings.basicSalary,
    transport => EssStrings.transportAllowance,
    overtime => EssStrings.overtimePay,
    other => EssStrings.otherEarnings,
  };

  IconData get icon => switch (this) {
    basic => Icons.account_balance_outlined,
    transport => Icons.directions_bus_outlined,
    overtime => Icons.more_time_outlined,
    other => Icons.add_card_outlined,
  };
}

/// نوع الخصم حسب اسم مكوّن الراتب، مع اسمه العربي وشرح مختصر لسببه.
/// Salary Slip لا يحفظ سبب الخصم، فالشرح مستنتج من اسم البند.
enum DeductionKind {
  advance,
  leaveWithoutPay,
  absence,
  late,
  tax,
  socialSecurity,
  health,
  loan,
  penalty,
  other;

  static DeductionKind of(SalaryLine l) {
    final n = '${l.component} ${l.abbr}'.toLowerCase();
    bool has(List<String> words) => words.any(n.contains);
    if (has(['advance', 'سلف'])) return advance;
    if (has(['without pay', 'lwp', 'unpaid', 'بدون راتب', 'غير مدفوع'])) {
      return leaveWithoutPay;
    }
    if (has(['absent', 'absence', 'غياب'])) return absence;
    if (has(['late', 'early', 'تأخير', 'تأخر'])) return late;
    if (has(['tax', 'tds', 'ضريب'])) return tax;
    if (has(['social', 'pension', 'provident', 'ضمان', 'تقاعد'])) {
      return socialSecurity;
    }
    if (has(['health', 'medical', 'insurance', 'صحي', 'تأمين'])) return health;
    if (has(['loan', 'قرض'])) return loan;
    if (has(['penalty', 'fine', 'جزاء', 'غرامة'])) return penalty;
    return other;
  }

  /// الاسم العربي، أو اسم المكوّن نفسه إن لم يُعرف نوعه
  String label(SalaryLine l) => switch (this) {
    advance => EssStrings.dedAdvance,
    leaveWithoutPay => EssStrings.dedLwp,
    absence => EssStrings.dedAbsence,
    late => EssStrings.dedLate,
    tax => EssStrings.dedTax,
    socialSecurity => EssStrings.dedSocial,
    health => EssStrings.dedHealth,
    loan => EssStrings.dedLoan,
    penalty => EssStrings.dedPenalty,
    other => l.component,
  };

  /// شرح مختصر للخصم؛ أيام الإجازة والغياب من الكشف نفسه
  String explanation(SalaryLine l, PayslipDetail slip) => switch (this) {
    advance => EssStrings.dedAdvanceWhy,
    leaveWithoutPay => EssStrings.dedLwpWhy(
      EssStrings.days(slip.leaveWithoutPay > 0 ? slip.leaveWithoutPay : 1),
    ),
    absence => EssStrings.dedAbsenceWhy(
      EssStrings.days(slip.absentDays > 0 ? slip.absentDays : 1),
    ),
    late => EssStrings.dedLateWhy,
    tax => EssStrings.dedTaxWhy,
    socialSecurity => EssStrings.dedSocialWhy,
    health => EssStrings.dedHealthWhy,
    loan => EssStrings.dedLoanWhy,
    penalty => EssStrings.dedPenaltyWhy,
    other => EssStrings.dedOtherWhy(l.component),
  };

  IconData get icon => switch (this) {
    advance => Icons.account_balance_wallet_outlined,
    leaveWithoutPay => Icons.money_off_outlined,
    absence => Icons.event_busy_outlined,
    late => Icons.alarm,
    tax => Icons.receipt_long_outlined,
    socialSecurity => Icons.shield_outlined,
    health => Icons.medical_services_outlined,
    loan => Icons.credit_card_outlined,
    penalty => Icons.gavel_outlined,
    other => Icons.remove_circle_outline,
  };
}
