import 'package:get/get.dart';

/// نصوص قسم «خدمات الموظف» (عربي/إنجليزي). النصوص في lib/app/translations (ar.dart / en.dart) وتُقرأ هنا بـ .tr.
class EssStrings {
  EssStrings._();

  static String get section => 'ess.section'.tr;
  static String get intro => 'ess.intro'.tr;

  // الخدمات: العنوان والوصف القصير
  static String get profile => 'ess.profile'.tr;
  static String get profileDesc => 'ess.profileDesc'.tr;

  static String get checkin => 'ess.checkin'.tr;
  static String get checkinDesc => 'ess.checkinDesc'.tr;

  static String get attendance => 'ess.attendance'.tr;
  static String get attendanceDesc => 'ess.attendanceDesc'.tr;

  static String get correction => 'ess.correction'.tr;
  static String get correctionDesc => 'ess.correctionDesc'.tr;

  static String get leaves => 'ess.leaves'.tr;
  static String get leavesDesc => 'ess.leavesDesc'.tr;

  static String get overtime => 'ess.overtime'.tr;
  static String get overtimeDesc => 'ess.overtimeDesc'.tr;

  // حسابي
  static String get loadingProfile => 'ess.loadingProfile'.tr;
  static String get profileLoadFailed => 'ess.profileLoadFailed'.tr;
  static String get notLinked => 'ess.notLinked'.tr;
  static String get noPermission => 'ess.noPermission'.tr;
  static String get employeeId => 'ess.employeeId'.tr;
  static String get department => 'ess.department'.tr;
  static String get designation => 'ess.designation'.tr;
  static String get email => 'ess.email'.tr;
  static String get phone => 'ess.phone'.tr;
  static String get jobInfo => 'ess.jobInfo'.tr;
  static String get contactInfo => 'ess.contactInfo'.tr;
  static String get shiftInfo => 'ess.shiftInfo'.tr;
  static String get shiftName => 'ess.shiftName'.tr;
  static String get shiftStart => 'ess.shiftStart'.tr;
  static String get shiftEnd => 'ess.shiftEnd'.tr;
  static String get noShift => 'ess.noShift'.tr;
  static String get notSet => 'ess.notSet'.tr;

  // تسجيل الحضور والانصراف (تجريبي)
  static String get statusNotCheckedIn => 'ess.statusNotCheckedIn'.tr;
  static String get statusOnDuty => 'ess.statusOnDuty'.tr;
  static String get statusFinished => 'ess.statusFinished'.tr;
  static String get checkIn => 'ess.checkIn'.tr;
  static String get checkOut => 'ess.checkOut'.tr;
  static String get inLabel => 'IN';
  static String get outLabel => 'OUT';
  static String get checkInTime => 'ess.checkInTime'.tr;
  static String get checkOutTime => 'ess.checkOutTime'.tr;
  static String get workedTime => 'ess.workedTime'.tr;
  static String hoursMinutes(int h, int m) =>
      'ess.hoursMinutes'.trParams({'h': '$h', 'm': '$m'});
  static String get checkedIn => 'ess.checkedIn'.tr;
  static String get checkedOut => 'ess.checkedOut'.tr;
  static String get location => 'ess.location'.tr;
  static String get locationPlaceholder => 'ess.locationPlaceholder'.tr;
  static String get locationNote => 'ess.locationNote'.tr;

  // سجل الحضور
  static String get loadingAttendance => 'ess.loadingAttendance'.tr;
  static String get attendanceLoadFailed => 'ess.attendanceLoadFailed'.tr;
  static String get month => 'ess.month'.tr;

  /// [m] من 1 إلى 12؛ خارجه RangeError كما كانت القائمة القديمة ([m - 1])
  static String monthName(int m) {
    RangeError.checkValueInInterval(m, 1, 12, 'm');
    return 'ess.monthName.$m'.tr;
  }

  static String get year => 'ess.year'.tr;
  static String get presentDays => 'ess.presentDays'.tr;
  static String get absentDays => 'ess.absentDays'.tr;
  static String get lateDays => 'ess.lateDays'.tr;
  static String get workHours => 'ess.workHours'.tr;
  static String get noAttendance => 'ess.noAttendance'.tr;
  static String get noAttendanceHint => 'ess.noAttendanceHint'.tr;
  static String get statusPresent => 'ess.statusPresent'.tr;
  static String get statusAbsent => 'ess.statusAbsent'.tr;
  static String get statusHalfDay => 'ess.statusHalfDay'.tr;
  static String get statusOnLeave => 'ess.statusOnLeave'.tr;
  static String get inTime => 'ess.inTime'.tr;
  static String get outTime => 'ess.outTime'.tr;
  static String get hours => 'ess.hours'.tr;
  static String lateBy(int? minutes) => minutes == null
      ? 'ess.lateBy'.tr
      : 'ess.lateBy_2'.trParams({'minutes': '$minutes'});
  static String earlyBy(int? minutes) => minutes == null
      ? 'ess.earlyBy'.tr
      : 'ess.earlyBy_2'.trParams({'minutes': '$minutes'});
  static String hoursValue(double h) {
    final text = h == h.roundToDouble()
        ? h.toInt().toString()
        : h.toStringAsFixed(1);
    return 'ess.hoursValue'.trParams({'text': text});
  }

  // طلب تصحيح الحضور (تجريبي)
  static String get newRequest => 'ess.newRequest'.tr;
  static String get requestDate => 'ess.requestDate'.tr;
  static String get correctionType => 'ess.correctionType'.tr;
  static String get forgotCheckIn => 'ess.forgotCheckIn'.tr;
  static String get forgotCheckOut => 'ess.forgotCheckOut'.tr;
  static String get correctInTime => 'ess.correctInTime'.tr;
  static String get correctOutTime => 'ess.correctOutTime'.tr;
  static String get reason => 'ess.reason'.tr;
  static String get extraNotes => 'ess.extraNotes'.tr;
  static String get submitRequest => 'ess.submitRequest'.tr;
  static String get requiredField => 'ess.requiredField'.tr;
  static String get chooseDate => 'ess.chooseDate'.tr;
  static String get chooseTime => 'ess.chooseTime'.tr;
  static String get reasonTooShort => 'ess.reasonTooShort'.tr;
  static String get requestSent => 'ess.requestSent'.tr;
  static String get previousRequests => 'ess.previousRequests'.tr;
  static String get noRequests => 'ess.noRequests'.tr;
  static String get statusPending => 'ess.statusPending'.tr;
  static String get statusApproved => 'ess.statusApproved'.tr;
  static String get statusRejected => 'ess.statusRejected'.tr;
  static String submittedOn(String d) => 'ess.submittedOn'.trParams({'d': d});

  // الإجازات
  static String get loadingLeaves => 'ess.loadingLeaves'.tr;
  static String get leavesLoadFailed => 'ess.leavesLoadFailed'.tr;
  static String get balances => 'ess.balances'.tr;
  static String get noBalances => 'ess.noBalances'.tr;
  static String get remaining => 'ess.remaining'.tr;
  static String balanceDetail(String total, String taken) =>
      'ess.balanceDetail'.trParams({'total': total, 'taken': taken});
  static String pendingApproval(String days) =>
      'ess.pendingApproval'.trParams({'days': days});
  static String get withoutPay => 'ess.withoutPay'.tr;
  static String get noBalanceLimit => 'ess.noBalanceLimit'.tr;
  static String get newLeave => 'ess.newLeave'.tr;
  static String get leaveType => 'ess.leaveType'.tr;
  static String get chooseLeaveType => 'ess.chooseLeaveType'.tr;
  static String get fromDate => 'ess.fromDate'.tr;
  static String get toDate => 'ess.toDate'.tr;
  static String get daysCount => 'ess.daysCount'.tr;
  static String daysValue(double d) {
    final text = d == d.roundToDouble()
        ? d.toInt().toString()
        : d.toStringAsFixed(1);
    return 'ess.daysValue'.trParams({'text': text});
  }

  static String get daysByErp => 'ess.daysByErp'.tr;
  static String get leaveReason => 'ess.leaveReason'.tr;
  static String get endBeforeStart => 'ess.endBeforeStart'.tr;
  static String exceedsBalance(String remaining) =>
      'ess.exceedsBalance'.trParams({'remaining': remaining});
  static String get salaryWarning => 'ess.salaryWarning'.tr;
  static String get salaryWarningLwp => 'ess.salaryWarningLwp'.tr;
  static String get leaveSent => 'ess.leaveSent'.tr;
  static String get leaveSendFailed => 'ess.leaveSendFailed'.tr;
  static String get leaveHistory => 'ess.leaveHistory'.tr;
  static String get noLeaveRequests => 'ess.noLeaveRequests'.tr;
  static String period(String from, String to) =>
      'ess.period'.trParams({'from': from, 'to': to});

  // العمل الإضافي
  static String get loadingOvertime => 'ess.loadingOvertime'.tr;
  static String get overtimeDays => 'ess.overtimeDays'.tr;
  static String get overtimeAmount => 'ess.overtimeAmount'.tr;
  static String chartTooltip(String day, String hours) =>
      'ess.chartTooltip'.trParams({'day': day, 'hours': hours});
  static String get overtimeLog => 'ess.overtimeLog'.tr;
  static String get otApproved => 'ess.otApproved'.tr;

  // البصمة الحقيقية (Employee Checkin)
  static String get punchNote => 'ess.punchNote'.tr;
  static String get loadingPunches => 'ess.loadingPunches'.tr;
  static String get punchesLoadFailed => 'ess.punchesLoadFailed'.tr;
  static String get punchFailed => 'ess.punchFailed'.tr;
  static String get todayPunches => 'ess.todayPunches'.tr;
  static String get noPunchesToday => 'ess.noPunchesToday'.tr;

  // طلب الحضور (Attendance Request)
  static String get requestKind => 'ess.requestKind'.tr;
  static String get onDuty => 'ess.onDuty'.tr;
  static String get workFromHome => 'ess.workFromHome'.tr;
  static String get loadingRequests => 'ess.loadingRequests'.tr;
  static String get requestsLoadFailed => 'ess.requestsLoadFailed'.tr;
  static String get requestSendFailed => 'ess.requestSendFailed'.tr;
  static String get pendingSameDay => 'ess.pendingSameDay'.tr;
  static String get requestApprovalNote => 'ess.requestApprovalNote'.tr;

  // أخطاء الإجازة من الخادم بالعربية
  static String get insufficientBalance => 'ess.insufficientBalance'.tr;
  static String get leaveOverlap => 'ess.leaveOverlap'.tr;
  static String get noAllocation => 'ess.noAllocation'.tr;
  static String get lwpConfirmTitle => 'ess.lwpConfirmTitle'.tr;
  static String lwpConfirmMessage(String days) =>
      'ess.lwpConfirmMessage'.trParams({'days': days});
  static String get sendAnyway => 'ess.sendAnyway'.tr;
  static String get statusCancelled => 'ess.statusCancelled'.tr;
  static String get statusWorkFromHome => 'ess.statusWorkFromHome'.tr;

  // العمل الإضافي (Additional Salary)
  static String get overtimeEntries => 'ess.overtimeEntries'.tr;
  static String get overtimeAmountChart => 'ess.overtimeAmountChart'.tr;
  static String get noOvertimeAmount => 'ess.noOvertimeAmount'.tr;
  static String get noOvertimeAmountHint => 'ess.noOvertimeAmountHint'.tr;
  static String get overtimeLoadFailed => 'ess.overtimeLoadFailed'.tr;
  static String get payrollDate => 'ess.payrollDate'.tr;
  static String get amount => 'ess.amount'.tr;

  // سلفي (Employee Advance)
  static String get advances => 'ess.advances'.tr;
  static String get advancesDesc => 'ess.advancesDesc'.tr;
  static String get loadingAdvances => 'ess.loadingAdvances'.tr;
  static String get advancesLoadFailed => 'ess.advancesLoadFailed'.tr;
  static String get requestAdvance => 'ess.requestAdvance'.tr;
  static String get newAdvance => 'ess.newAdvance'.tr;
  static String get advanceAmountLabel => 'ess.advanceAmountLabel'.tr;
  static String get advancePurpose => 'ess.advancePurpose'.tr;
  static String get amountInvalid => 'ess.amountInvalid'.tr;
  static String get advanceSent => 'ess.advanceSent'.tr;
  static String get advanceSendFailed => 'ess.advanceSendFailed'.tr;
  static String get advanceApprovalNote => 'ess.advanceApprovalNote'.tr;
  static String get noAdvances => 'ess.noAdvances'.tr;
  static String get noAdvancesHint => 'ess.noAdvancesHint'.tr;
  static String get originalAmount => 'ess.originalAmount'.tr;
  static String get paidAmount => 'ess.paidAmount'.tr;
  static String get claimedAmount => 'ess.claimedAmount'.tr;
  static String get returnedAmount => 'ess.returnedAmount'.tr;
  static String get remainingAmount => 'ess.remainingAmount'.tr;
  static String get pendingAmount => 'ess.pendingAmount'.tr;
  static String get advStatusPending => 'ess.advStatusPending'.tr;
  static String get advStatusUnpaid => 'ess.advStatusUnpaid'.tr;
  static String get advStatusPaid => 'ess.advStatusPaid'.tr;
  static String get advStatusClaimed => 'ess.advStatusClaimed'.tr;
  static String get advStatusReturned => 'ess.advStatusReturned'.tr;
  static String get advStatusPartly => 'ess.advStatusPartly'.tr;
  static String get advStatusCancelled => 'ess.advStatusCancelled'.tr;
  static String get advancesTotal => 'ess.advancesTotal'.tr;

  // مصاريفي (Expense Claim)
  static String get expenses => 'ess.expenses'.tr;
  static String get expensesDesc => 'ess.expensesDesc'.tr;
  static String get loadingExpenses => 'ess.loadingExpenses'.tr;
  static String get expensesLoadFailed => 'ess.expensesLoadFailed'.tr;
  static String get addExpense => 'ess.addExpense'.tr;
  static String get newExpense => 'ess.newExpense'.tr;
  static String get expenseType => 'ess.expenseType'.tr;
  static String get transport => 'ess.transport'.tr;
  static String get meals => 'ess.meals'.tr;
  static String get typeMissing => 'ess.typeMissing'.tr;
  static String get expenseAmount => 'ess.expenseAmount'.tr;
  static String get expenseDate => 'ess.expenseDate'.tr;
  static String get expenseNotes => 'ess.expenseNotes'.tr;
  static String get receipt => 'ess.receipt'.tr;
  static String get takePhoto => 'ess.takePhoto'.tr;
  static String get fromGallery => 'ess.fromGallery'.tr;
  static String get removePhoto => 'ess.removePhoto'.tr;
  static String get noReceipt => 'ess.noReceipt'.tr;
  static String get photoFailed => 'ess.photoFailed'.tr;
  static String get linkAdvance => 'ess.linkAdvance'.tr;
  static String get noAdvanceLink => 'ess.noAdvanceLink'.tr;
  static String get noOpenAdvances => 'ess.noOpenAdvances'.tr;
  static String advanceOption(String name, String unclaimed) =>
      'ess.advanceOption'.trParams({'name': name, 'unclaimed': unclaimed});
  static String advanceDeduction(String amount) =>
      'ess.advanceDeduction'.trParams({'amount': amount});
  static String get futureDate => 'ess.futureDate'.tr;
  static String get sendExpense => 'ess.sendExpense'.tr;
  static String get expenseSent => 'ess.expenseSent'.tr;
  static String expenseSentNoReceipt(String detail) =>
      'ess.expenseSentNoReceipt'.trParams({'detail': detail});
  static String get expenseSendFailed => 'ess.expenseSendFailed'.tr;
  static String get expenseApprovalNote => 'ess.expenseApprovalNote'.tr;
  static String get noExpenses => 'ess.noExpenses'.tr;
  static String get noExpensesHint => 'ess.noExpensesHint'.tr;
  static String get expenseStatusDraft => 'ess.expenseStatusDraft'.tr;
  static String get expenseStatusApproved => 'ess.expenseStatusApproved'.tr;
  static String get expenseStatusSubmitted => 'ess.expenseStatusSubmitted'.tr;
  static String get expenseStatusPaid => 'ess.expenseStatusPaid'.tr;
  static String get expenseStatusRejected => 'ess.expenseStatusRejected'.tr;
  static String get expenseStatusCancelled => 'ess.expenseStatusCancelled'.tr;

  // كشوف رواتبي (Salary Slip)
  static String get payslips => 'ess.payslips'.tr;
  static String get payslipsDesc => 'ess.payslipsDesc'.tr;
  static String get loadingPayslips => 'ess.loadingPayslips'.tr;
  static String get payslipsLoadFailed => 'ess.payslipsLoadFailed'.tr;
  static String get loadingPayslip => 'ess.loadingPayslip'.tr;
  static String get payslipLoadFailed => 'ess.payslipLoadFailed'.tr;
  static String get noPayslips => 'ess.noPayslips'.tr;
  static String get noPayslipsHint => 'ess.noPayslipsHint'.tr;
  static String get readOnlyNote => 'ess.readOnlyNote'.tr;
  static String get netPay => 'ess.netPay'.tr;
  static String get grossPay => 'ess.grossPay'.tr;
  static String get earnings => 'ess.earnings'.tr;
  static String get totalEarnings => 'ess.totalEarnings'.tr;
  static String get deductions => 'ess.deductions'.tr;
  static String get totalDeductions => 'ess.totalDeductions'.tr;
  static String get noDeductions => 'ess.noDeductions'.tr;
  static String get salarySummary => 'ess.salarySummary'.tr;
  static String get paymentDays => 'ess.paymentDays'.tr;
  static String paymentDaysOf(String paid, String total) =>
      'ess.paymentDaysOf'.trParams({'paid': paid, 'total': total});
  static String get salaryPeriod => 'ess.salaryPeriod'.tr;
  static String get slipDate => 'ess.slipDate'.tr;
  static String get basicSalary => 'ess.basicSalary'.tr;
  static String get transportAllowance => 'ess.transportAllowance'.tr;
  static String get overtimePay => 'ess.overtimePay'.tr;
  static String get notOnSlip => 'ess.notOnSlip'.tr;
  static String get otherEarnings => 'ess.otherEarnings'.tr;

  // أسماء الخصومات وشرحها بالعربية (حسب اسم مكوّن الراتب)
  static String get dedAdvance => 'ess.dedAdvance'.tr;
  static String get dedAdvanceWhy => 'ess.dedAdvanceWhy'.tr;
  static String get dedLwp => 'ess.dedLwp'.tr;
  static String dedLwpWhy(String days) =>
      'ess.dedLwpWhy'.trParams({'days': days});
  static String get dedAbsence => 'ess.dedAbsence'.tr;
  static String dedAbsenceWhy(String days) =>
      'ess.dedAbsenceWhy'.trParams({'days': days});
  static String get dedLate => 'ess.dedLate'.tr;
  static String get dedLateWhy => 'ess.dedLateWhy'.tr;
  static String get dedTax => 'ess.dedTax'.tr;
  static String get dedTaxWhy => 'ess.dedTaxWhy'.tr;
  static String get dedSocial => 'ess.dedSocial'.tr;
  static String get dedSocialWhy => 'ess.dedSocialWhy'.tr;
  static String get dedHealth => 'ess.dedHealth'.tr;
  static String get dedHealthWhy => 'ess.dedHealthWhy'.tr;
  static String get dedLoan => 'ess.dedLoan'.tr;
  static String get dedLoanWhy => 'ess.dedLoanWhy'.tr;
  static String get dedPenalty => 'ess.dedPenalty'.tr;
  static String get dedPenaltyWhy => 'ess.dedPenaltyWhy'.tr;
  static String dedOtherWhy(String component) =>
      'ess.dedOtherWhy'.trParams({'component': component});
  static String get unpaidDaysNote => 'ess.unpaidDaysNote'.tr;
  static String unpaidDaysWhy(String days) =>
      'ess.unpaidDaysWhy'.trParams({'days': days});
  static String days(double d) {
    final text = d == d.roundToDouble()
        ? d.toInt().toString()
        : d.toStringAsFixed(1);
    if (d == 1) return 'ess.days.one'.tr;
    if (d == 2) return 'ess.days.two'.trParams({'text': text});
    return 'ess.days.many'.trParams({'text': text});
  }

  static String get explanationNote => 'ess.explanationNote'.tr;

  // فريقي (للمعتمِدين فقط، عرض فقط)
  static String get team => 'ess.team'.tr;
  static String get teamDesc => 'ess.teamDesc'.tr;
  static String get loadingTeam => 'ess.loadingTeam'.tr;
  static String get teamLoadFailed => 'ess.teamLoadFailed'.tr;
  static String get teamNoAccess => 'ess.teamNoAccess'.tr;
  static String get teamViewOnly => 'ess.teamViewOnly'.tr;
  static String teamLeavesTab(int n) =>
      'ess.teamLeavesTab'.trParams({'n': '$n'});
  static String teamExpensesTab(int n) =>
      'ess.teamExpensesTab'.trParams({'n': '$n'});
  static String get noTeamLeaves => 'ess.noTeamLeaves'.tr;
  static String get noTeamExpenses => 'ess.noTeamExpenses'.tr;
  static String get notLeaveApprover => 'ess.notLeaveApprover'.tr;
  static String get notExpenseApprover => 'ess.notExpenseApprover'.tr;
  static String get leaveRequestType => 'ess.leaveRequestType'.tr;
  static String get expenseRequestType => 'ess.expenseRequestType'.tr;
  static String get statusAwaiting => 'ess.statusAwaiting'.tr;

  // مصدر العمل الإضافي (Overtime Slip أو Additional Salary)
  static String get overtimeTotalHours => 'ess.overtimeTotalHours'.tr;
  static String get hoursUnavailable => 'ess.hoursUnavailable'.tr;
  static String duration(double seconds) {
    final minutes = (seconds / 60).round();
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return 'ess.duration'.trParams({'h': '$h', 'm': '$m'});
  }

  static String get sourceOvertimeSlip => 'ess.sourceOvertimeSlip'.tr;
  static String get sourceNoOvertimeSlip => 'ess.sourceNoOvertimeSlip'.tr;
  static String get sourceNoSlipAccess => 'ess.sourceNoSlipAccess'.tr;
  static String sourceLabel(String source) =>
      'ess.sourceLabel'.trParams({'source': source});
  static String get overtimeHoursChart => 'ess.overtimeHoursChart'.tr;
  static String get overtimeHoursLog => 'ess.overtimeHoursLog'.tr;
  static String get overtimeAmountsLog => 'ess.overtimeAmountsLog'.tr;
}
