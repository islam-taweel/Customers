// مُولَّد: نسخة نصوص قبل R7 (مرجع اختبار التكافؤ). لا تُعدَّل يدويًا.
// ignore_for_file: type=lint, unused_import
import 'legacy_lang.dart';
import 'app_strings.dart';

/// نصوص قسم «خدمات الموظف» (عربي/إنجليزي). اللغة الحالية من [LegacyLang.isArabic].
class LegacyEssStrings {
  LegacyEssStrings._();

  static String _t(String ar, String en) => LegacyLang.isArabic ? ar : en;

  static String get section => _t('خدمات الموظف', 'Employee Self-Service');
  static String get intro => _t(
    'كل ما تحتاجه كموظف في مكان واحد',
    'Everything you need as an employee in one place',
  );

  // الخدمات: العنوان والوصف القصير
  static String get profile => _t('حسابي', 'My account');
  static String get profileDesc =>
      _t('بياناتك الوظيفية والشخصية', 'Your job and personal details');

  static String get checkin => _t('تسجيل الحضور والانصراف', 'Check in / out');
  static String get checkinDesc =>
      _t('سجّل بداية دوامك ونهايته', 'Record the start and end of your shift');

  static String get attendance => _t('سجل الحضور', 'Attendance log');
  static String get attendanceDesc =>
      _t('أيام حضورك وغيابك وتأخيرك', 'Your present, absent and late days');

  static String get correction =>
      _t('طلب تصحيح الحضور', 'Attendance correction');
  static String get correctionDesc => _t(
    'اطلب تعديل يوم سُجّل بشكل خاطئ',
    'Request a fix for a wrongly recorded day',
  );

  static String get leaves => _t('الإجازات', 'Leaves');
  static String get leavesDesc =>
      _t('رصيدك وطلبات الإجازة', 'Your balance and leave requests');

  static String get overtime => _t('العمل الإضافي', 'Overtime');
  static String get overtimeDesc =>
      _t('ساعاتك الإضافية وطلباتها', 'Your extra hours and requests');

  // حسابي
  static String get loadingProfile =>
      _t('جارٍ تحميل بياناتك...', 'Loading your details...');
  static String get profileLoadFailed =>
      _t('تعذّر تحميل بياناتك', 'Could not load your details');
  static String get notLinked => _t(
    'غير مرتبط بموظف. اطلب من مسؤول الموارد البشرية ربط حسابك بسجل الموظف في ERPNext.',
    'Not linked to an employee. Ask HR to link your account to your employee record in ERPNext.',
  );
  static String get noPermission => _t(
    'لا تملك صلاحية قراءة بيانات الموظف في ERPNext.',
    'You don\'t have permission to read employee data in ERPNext.',
  );
  static String get employeeId => _t('الرقم الوظيفي', 'Employee ID');
  static String get department => _t('القسم', 'Department');
  static String get designation => _t('المسمى الوظيفي', 'Job title');
  static String get email => _t('البريد الإلكتروني', 'Email');
  static String get phone => _t('رقم الهاتف', 'Phone');
  static String get jobInfo => _t('البيانات الوظيفية', 'Job details');
  static String get contactInfo => _t('التواصل', 'Contact');
  static String get shiftInfo => _t('معلومات الوردية', 'Shift');
  static String get shiftName => _t('اسم الوردية', 'Shift name');
  static String get shiftStart => _t('بداية الدوام', 'Starts at');
  static String get shiftEnd => _t('نهاية الدوام', 'Ends at');
  static String get noShift =>
      _t('لا توجد وردية معيّنة لك', 'No shift assigned to you');
  static String get notSet => _t('غير محدد', 'Not set');

  // تسجيل الحضور والانصراف (تجريبي)
  static String get statusNotCheckedIn =>
      _t('لم يسجل الحضور', 'Not checked in');
  static String get statusOnDuty => _t('على رأس عمله', 'On duty');
  static String get statusFinished => _t('أنهى الدوام', 'Shift finished');
  static String get checkIn => _t('تسجيل حضور', 'Check in');
  static String get checkOut => _t('تسجيل انصراف', 'Check out');
  static String get inLabel => 'IN';
  static String get outLabel => 'OUT';
  static String get checkInTime => _t('وقت الحضور', 'Check-in time');
  static String get checkOutTime => _t('وقت الانصراف', 'Check-out time');
  static String get workedTime => _t('مدة العمل', 'Worked');
  static String hoursMinutes(int h, int m) => _t('$h س $m د', '${h}h ${m}m');
  static String get checkedIn => _t('سُجّل الحضور', 'Checked in');
  static String get checkedOut => _t('سُجّل الانصراف', 'Checked out');
  static String get location => _t('الموقع الجغرافي', 'Location');
  static String get locationPlaceholder =>
      _t('سيظهر موقع التسجيل هنا', 'The check-in location will appear here');
  static String get locationNote => _t(
    'لا يُطلب إذن الموقع ولا يُستخدم GPS حاليًا',
    'No location permission is requested and GPS is not used for now',
  );

  // سجل الحضور
  static String get loadingAttendance =>
      _t('جارٍ تحميل سجل الحضور...', 'Loading attendance...');
  static String get attendanceLoadFailed =>
      _t('تعذّر تحميل سجل الحضور', 'Could not load attendance');
  static String get month => _t('الشهر', 'Month');
  static String monthName(int m) => LegacyLang.isArabic
      ? const [
          'كانون الثاني',
          'شباط',
          'آذار',
          'نيسان',
          'أيار',
          'حزيران',
          'تموز',
          'آب',
          'أيلول',
          'تشرين الأول',
          'تشرين الثاني',
          'كانون الأول',
        ][m - 1]
      : const [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ][m - 1];
  static String get year => _t('السنة', 'Year');
  static String get presentDays => _t('أيام الحضور', 'Present days');
  static String get absentDays => _t('أيام الغياب', 'Absent days');
  static String get lateDays => _t('أيام التأخير', 'Late days');
  static String get workHours => _t('ساعات العمل', 'Working hours');
  static String get noAttendance => _t(
    'لا توجد سجلات حضور لهذا الشهر',
    'No attendance records for this month',
  );
  static String get noAttendanceHint => _t(
    'اختر شهرًا آخر، أو اسحب للتحديث',
    'Pick another month, or pull to refresh',
  );
  static String get statusPresent => _t('حاضر', 'Present');
  static String get statusAbsent => _t('غائب', 'Absent');
  static String get statusHalfDay => _t('نصف يوم', 'Half day');
  static String get statusOnLeave => _t('إجازة', 'On leave');
  static String get inTime => _t('الحضور', 'In');
  static String get outTime => _t('الانصراف', 'Out');
  static String get hours => _t('الساعات', 'Hours');
  static String lateBy(int? minutes) => minutes == null
      ? _t('تأخير', 'Late')
      : _t('تأخير $minutes د', 'Late $minutes min');
  static String earlyBy(int? minutes) => minutes == null
      ? _t('خروج مبكر', 'Early exit')
      : _t('خروج مبكر $minutes د', 'Early exit $minutes min');
  static String hoursValue(double h) {
    final text = h == h.roundToDouble()
        ? h.toInt().toString()
        : h.toStringAsFixed(1);
    return _t('$text س', '$text h');
  }

  // طلب تصحيح الحضور (تجريبي)
  static String get newRequest =>
      _t('طلب تصحيح جديد', 'New correction request');
  static String get requestDate =>
      _t('تاريخ اليوم المراد تصحيحه', 'Date to correct');
  static String get correctionType => _t('نوع التصحيح', 'Correction type');
  static String get forgotCheckIn =>
      _t('نسيان تسجيل الحضور', 'Forgot to check in');
  static String get forgotCheckOut =>
      _t('نسيان تسجيل الانصراف', 'Forgot to check out');
  static String get correctInTime =>
      _t('وقت الحضور الصحيح', 'Correct check-in time');
  static String get correctOutTime =>
      _t('وقت الانصراف الصحيح', 'Correct check-out time');
  static String get reason => _t('سبب الطلب', 'Reason');
  static String get extraNotes =>
      _t('توضيحات إضافية (اختياري)', 'Additional notes (optional)');
  static String get submitRequest => _t('إرسال الطلب', 'Submit request');
  static String get requiredField =>
      _t('هذا الحقل مطلوب', 'This field is required');
  static String get chooseDate => _t('اختر التاريخ', 'Choose the date');
  static String get chooseTime => _t('اختر الوقت', 'Choose the time');
  static String get reasonTooShort => _t(
    'اكتب سببًا أوضح (5 أحرف على الأقل)',
    'Write a clearer reason (at least 5 characters)',
  );
  static String get requestSent =>
      _t('أُرسل الطلب وهو قيد المراجعة', 'Request sent and pending review');
  static String get previousRequests =>
      _t('الطلبات السابقة', 'Previous requests');
  static String get noRequests =>
      _t('لا توجد طلبات سابقة', 'No previous requests');
  static String get statusPending => _t('قيد المراجعة', 'Pending review');
  static String get statusApproved => _t('موافق عليه', 'Approved');
  static String get statusRejected => _t('مرفوض', 'Rejected');
  static String submittedOn(String d) => _t('قُدّم في $d', 'Submitted on $d');

  // الإجازات
  static String get loadingLeaves =>
      _t('جارٍ تحميل الإجازات...', 'Loading leaves...');
  static String get leavesLoadFailed =>
      _t('تعذّر تحميل الإجازات', 'Could not load leaves');
  static String get balances => _t('أرصدة الإجازات', 'Leave balances');
  static String get noBalances => _t(
    'لا توجد أرصدة إجازات مخصصة لك هذه الفترة',
    'No leave allocations for you in this period',
  );
  static String get remaining => _t('المتبقي', 'Remaining');
  static String balanceDetail(String total, String taken) =>
      _t('من $total • مأخوذ $taken', 'of $total • taken $taken');
  static String pendingApproval(String days) =>
      _t('بانتظار الموافقة: $days', 'Pending approval: $days');
  static String get withoutPay => _t('بدون راتب', 'Without pay');
  static String get noBalanceLimit =>
      _t('لا رصيد لها، تُخصم من الراتب', 'No balance, deducted from salary');
  static String get newLeave => _t('طلب إجازة جديد', 'New leave request');
  static String get leaveType => _t('نوع الإجازة', 'Leave type');
  static String get chooseLeaveType =>
      _t('اختر نوع الإجازة', 'Choose the leave type');
  static String get fromDate => _t('تاريخ البداية', 'Start date');
  static String get toDate => _t('تاريخ النهاية', 'End date');
  static String get daysCount => _t('عدد الأيام', 'Days');
  static String daysValue(double d) {
    final text = d == d.roundToDouble()
        ? d.toInt().toString()
        : d.toStringAsFixed(1);
    return _t('$text يوم', '$text days');
  }

  static String get daysByErp => _t(
    'محسوب في ERPNext (قد تُستثنى العطل الرسمية)',
    'Calculated by ERPNext (holidays may be excluded)',
  );
  static String get leaveReason => _t('سبب الإجازة', 'Reason for leave');
  static String get endBeforeStart => _t(
    'تاريخ النهاية لا يمكن أن يكون قبل تاريخ البداية',
    'The end date can\'t be before the start date',
  );
  static String exceedsBalance(String remaining) => _t(
    'عدد الأيام أكبر من رصيدك المتبقي ($remaining)',
    'The days exceed your remaining balance ($remaining)',
  );
  static String get salaryWarning => _t(
    'تنبيه: أخذ إجازة قد يؤثر على راتبك، خاصة الإجازة بدون راتب أو تجاوز الرصيد.',
    'Note: taking leave may affect your salary, especially unpaid leave or going over your balance.',
  );
  static String get salaryWarningLwp => _t(
    'هذه إجازة بدون راتب: ستُخصم أيامها من راتبك.',
    'This is unpaid leave: its days will be deducted from your salary.',
  );
  static String get leaveSent => _t(
    'أُرسل طلب الإجازة وهو قيد المراجعة',
    'Leave request sent and pending review',
  );
  static String get leaveSendFailed =>
      _t('تعذّر إرسال طلب الإجازة', 'Could not send the leave request');
  static String get leaveHistory => _t('الطلبات السابقة', 'Previous requests');
  static String get noLeaveRequests =>
      _t('لا توجد طلبات إجازة سابقة', 'No previous leave requests');
  static String period(String from, String to) =>
      _t('من $from إلى $to', 'From $from to $to');

  // العمل الإضافي
  static String get loadingOvertime =>
      _t('جارٍ تحميل العمل الإضافي...', 'Loading overtime...');
  static String get overtimeDays => _t('أيام العمل الإضافي', 'Overtime days');
  static String get overtimeAmount => _t('إجمالي المبلغ', 'Total amount');
  static String chartTooltip(String day, String hours) =>
      _t('$day: $hours', '$day: $hours');
  static String get overtimeLog => _t('سجل العمل الإضافي', 'Overtime log');
  static String get otApproved => _t('معتمد', 'Approved');

  // البصمة الحقيقية (Employee Checkin)
  static String get punchNote => _t(
    'تُسجَّل البصمة في ERPNext بتوقيت فلسطين، ويُحسب حضور اليوم لاحقًا بعد انتهاء الوردية.',
    "Punches are saved in ERPNext in Palestine time; the day's attendance is calculated later, after the shift ends.",
  );
  static String get loadingPunches =>
      _t('جارٍ تحميل بصمات اليوم...', "Loading today's punches...");
  static String get punchesLoadFailed =>
      _t('تعذّر تحميل بصمات اليوم', "Could not load today's punches");
  static String get punchFailed =>
      _t('تعذّر تسجيل البصمة', 'Could not save the punch');
  static String get todayPunches => _t('بصمات اليوم', "Today's punches");
  static String get noPunchesToday =>
      _t('لا توجد بصمات اليوم', 'No punches today');

  // طلب الحضور (Attendance Request)
  static String get requestKind => _t('نوع الطلب', 'Request type');
  static String get onDuty => _t('مهمة عمل', 'On duty');
  static String get workFromHome => _t('عمل من المنزل', 'Work from home');
  static String get loadingRequests =>
      _t('جارٍ تحميل طلباتك...', 'Loading your requests...');
  static String get requestsLoadFailed =>
      _t('تعذّر تحميل طلباتك', 'Could not load your requests');
  static String get requestSendFailed =>
      _t('تعذّر إرسال الطلب', 'Could not send the request');
  static String get pendingSameDay => _t(
    'لديك طلب قيد المراجعة لهذا اليوم',
    'You already have a pending request for this day',
  );
  static String get requestApprovalNote => _t(
    'يُحفظ الطلب في ERPNext قيد المراجعة، والموافقة أو الرفض من الموارد البشرية.',
    'The request is saved in ERPNext pending review; HR approves or rejects it.',
  );

  // أخطاء الإجازة من الخادم بالعربية
  static String get insufficientBalance => _t(
    'رصيدك من هذا النوع غير كافٍ لهذه المدة. اختر مدة أقصر أو نوعًا آخر.',
    'Your balance for this type is not enough for this period. Pick a shorter period or another type.',
  );
  static String get leaveOverlap => _t(
    'لديك طلب إجازة آخر في نفس الفترة.',
    'You already have another leave request in this period.',
  );
  static String get noAllocation => _t(
    'لا يوجد لك رصيد مخصص من هذا النوع في هذه الفترة.',
    'You have no allocation of this type for this period.',
  );
  static String get lwpConfirmTitle =>
      _t('إجازة بدون راتب', 'Leave without pay');
  static String lwpConfirmMessage(String days) => _t(
    'ستُخصم أيام هذه الإجازة ($days) من راتبك. هل تريد إرسال الطلب؟',
    'The days of this leave ($days) will be deducted from your salary. Send the request?',
  );
  static String get sendAnyway => _t('إرسال', 'Send');
  static String get statusCancelled => _t('ملغى', 'Cancelled');
  static String get statusWorkFromHome => _t('عمل من المنزل', 'Work from home');

  // العمل الإضافي (Additional Salary)
  static String get overtimeEntries => _t('عدد الدفعات', 'Entries');
  static String get overtimeAmountChart =>
      _t('مبالغ العمل الإضافي خلال الشهر', 'Overtime amounts this month');
  static String get noOvertimeAmount => _t(
    'لا يوجد عمل إضافي معتمد في هذا الشهر',
    'No approved overtime this month',
  );
  static String get noOvertimeAmountHint => _t(
    'يظهر هنا ما تعتمده الموارد البشرية من مبالغ العمل الإضافي',
    'Overtime amounts approved by HR show up here',
  );
  static String get overtimeLoadFailed =>
      _t('تعذّر تحميل العمل الإضافي', 'Could not load overtime');
  static String get payrollDate => _t('تاريخ الاستحقاق', 'Payroll date');
  static String get amount => _t('المبلغ', 'Amount');

  // سلفي (Employee Advance)
  static String get advances => _t('سلفي', 'My advances');
  static String get advancesDesc =>
      _t('اطلب سلفة وتابع حالتها', 'Request an advance and track it');
  static String get loadingAdvances =>
      _t('جارٍ تحميل السلف...', 'Loading advances...');
  static String get advancesLoadFailed =>
      _t('تعذّر تحميل السلف', 'Could not load advances');
  static String get requestAdvance => _t('طلب سلفة', 'Request advance');
  static String get newAdvance => _t('طلب سلفة جديدة', 'New advance request');
  static String get advanceAmountLabel => _t('مبلغ السلفة', 'Advance amount');
  static String get advancePurpose =>
      _t('سبب أو غرض السلفة', 'Reason or purpose');
  static String get amountInvalid =>
      _t('أدخل مبلغًا أكبر من صفر', 'Enter an amount above zero');
  static String get advanceSent => _t(
    'أُرسل طلب السلفة وهو قيد المراجعة',
    'Advance request sent and pending review',
  );
  static String get advanceSendFailed =>
      _t('تعذّر إرسال طلب السلفة', 'Could not send the advance request');
  static String get advanceApprovalNote => _t(
    'يُحفظ الطلب في ERPNext قيد المراجعة. الموافقة والدفع والإلغاء من صلاحية الموارد البشرية.',
    'The request is saved in ERPNext pending review. Approval, payment and cancellation are done by HR.',
  );
  static String get noAdvances => _t('لا توجد سلف بعد', 'No advances yet');
  static String get noAdvancesHint => _t(
    'اضغط «طلب سلفة» لتقديم أول طلب',
    'Tap "Request advance" to send your first request',
  );
  static String get originalAmount => _t('المبلغ الأصلي', 'Original');
  static String get paidAmount => _t('المدفوع', 'Paid');
  static String get claimedAmount => _t('المستخدم', 'Used');
  static String get returnedAmount => _t('المسترجع', 'Returned');
  static String get remainingAmount => _t('المتبقي', 'Remaining');
  static String get pendingAmount => _t('المعلّق', 'Pending');
  static String get advStatusPending => _t('قيد المراجعة', 'Pending review');
  static String get advStatusUnpaid =>
      _t('معتمدة، بانتظار الدفع', 'Approved, awaiting payment');
  static String get advStatusPaid => _t('مدفوعة', 'Paid');
  static String get advStatusClaimed => _t('مستخدمة بالكامل', 'Fully used');
  static String get advStatusReturned => _t('مسترجعة', 'Returned');
  static String get advStatusPartly =>
      _t('مستخدمة ومسترجعة جزئيًا', 'Partly used and returned');
  static String get advStatusCancelled => _t('ملغاة', 'Cancelled');
  static String get advancesTotal =>
      _t('المتبقي معك من السلف', 'Advance balance with you');

  // مصاريفي (Expense Claim)
  static String get expenses => _t('مصاريفي', 'My expenses');
  static String get expensesDesc => _t(
    'أضف مصروفًا مع إيصاله وتابع حالته',
    'Add an expense with its receipt',
  );
  static String get loadingExpenses =>
      _t('جارٍ تحميل المصاريف...', 'Loading expenses...');
  static String get expensesLoadFailed =>
      _t('تعذّر تحميل المصاريف', 'Could not load expenses');
  static String get addExpense => _t('إضافة مصروف', 'Add expense');
  static String get newExpense => _t('مصروف جديد', 'New expense');
  static String get expenseType => _t('نوع المصروف', 'Expense type');
  static String get transport => _t('مواصلات', 'Transport');
  static String get meals => _t('وجبات', 'Meals');
  static String get typeMissing => _t(
    'هذا النوع غير معرّف في ERPNext',
    'This type is not defined in ERPNext',
  );
  static String get expenseAmount => _t('المبلغ', 'Amount');
  static String get expenseDate => _t('تاريخ المصروف', 'Expense date');
  static String get expenseNotes =>
      _t('ملاحظات أو وصف المصروف', 'Notes or description');
  static String get receipt => _t('صورة الإيصال أو الفاتورة', 'Receipt photo');
  static String get takePhoto => _t('الكاميرا', 'Camera');
  static String get fromGallery => _t('المعرض', 'Gallery');
  static String get removePhoto => _t('إزالة الصورة', 'Remove photo');
  static String get noReceipt =>
      _t('لم تُرفق صورة بعد (اختياري)', 'No photo attached yet (optional)');
  static String get photoFailed => _t(
    'تعذّر فتح الكاميرا أو المعرض',
    'Could not open the camera or gallery',
  );
  static String get linkAdvance =>
      _t('ربط المصروف بسلفة مفتوحة', 'Link to an open advance');
  static String get noAdvanceLink => _t('بدون ربط بسلفة', 'Not linked');
  static String get noOpenAdvances => _t(
    'لا توجد سلفة مفتوحة لك: سيُرسل المصروف بدون ربط بسلفة',
    'You have no open advance: the expense will be sent without one',
  );
  static String advanceOption(String name, String unclaimed) =>
      _t('$name • غير مستخدم $unclaimed', '$name • unused $unclaimed');
  static String advanceDeduction(String amount) => _t(
    'سيُخصم $amount من السلفة المختارة',
    '$amount will be deducted from the chosen advance',
  );
  static String get futureDate => _t(
    'لا يمكن أن يكون تاريخ المصروف في المستقبل',
    'The date cannot be in the future',
  );
  static String get sendExpense => _t('إرسال المصروف', 'Send expense');
  static String get expenseSent => _t(
    'أُرسل المصروف، وهو مسودة بانتظار الموافقة',
    'Expense sent as a draft awaiting approval',
  );
  static String expenseSentNoReceipt(String detail) => _t(
    'أُرسل المصروف، لكن تعذّر رفع صورة الإيصال. أرفقها من ERPNext أو أرسل المصروف من جديد.\n$detail',
    'Expense sent, but the receipt photo could not be uploaded. Attach it in ERPNext or send again.\n$detail',
  );
  static String get expenseSendFailed =>
      _t('تعذّر إرسال المصروف', 'Could not send the expense');
  static String get expenseApprovalNote => _t(
    'يُحفظ المصروف في ERPNext مسودة. الموافقة والاعتماد والدفع من صلاحية الموارد البشرية.',
    'The expense is saved in ERPNext as a draft. Approval, submission and payment are done by HR.',
  );
  static String get noExpenses => _t('لا توجد مصاريف بعد', 'No expenses yet');
  static String get noExpensesHint => _t(
    'اضغط «إضافة مصروف» لتقديم أول مصروف',
    'Tap "Add expense" to send your first one',
  );
  static String get expenseStatusDraft => _t('مسودة', 'Draft');
  static String get expenseStatusApproved => _t('موافق عليه', 'Approved');
  static String get expenseStatusSubmitted => _t('مُقدَّم', 'Submitted');
  static String get expenseStatusPaid => _t('مدفوع', 'Paid');
  static String get expenseStatusRejected => _t('مرفوض', 'Rejected');
  static String get expenseStatusCancelled => _t('ملغى', 'Cancelled');

  // كشوف رواتبي (Salary Slip)
  static String get payslips => _t('كشوف رواتبي', 'My payslips');
  static String get payslipsDesc => _t(
    'كشوف رواتبك المعتمدة وتفاصيلها',
    'Your submitted payslips and details',
  );
  static String get loadingPayslips =>
      _t('جارٍ تحميل كشوف الرواتب...', 'Loading payslips...');
  static String get payslipsLoadFailed =>
      _t('تعذّر تحميل كشوف الرواتب', 'Could not load payslips');
  static String get loadingPayslip =>
      _t('جارٍ تحميل كشف الراتب...', 'Loading the payslip...');
  static String get payslipLoadFailed =>
      _t('تعذّر تحميل كشف الراتب', 'Could not load the payslip');
  static String get noPayslips =>
      _t('لا توجد كشوف رواتب معتمدة بعد', 'No submitted payslips yet');
  static String get noPayslipsHint => _t(
    'تظهر هنا كشوف رواتبك بعد اعتمادها من الموارد البشرية',
    'Your payslips show up here once HR submits them',
  );
  static String get readOnlyNote => _t(
    'كشوف الرواتب للعرض فقط، وأي تعديل يتم من الموارد البشرية.',
    'Payslips are view only; any change is made by HR.',
  );
  static String get netPay => _t('صافي الراتب', 'Net pay');
  static String get grossPay => _t('إجمالي الراتب', 'Gross pay');
  static String get earnings => _t('المستحقات', 'Earnings');
  static String get totalEarnings => _t('إجمالي المستحقات', 'Total earnings');
  static String get deductions => _t('الخصومات', 'Deductions');
  static String get totalDeductions => _t('مجموع الخصومات', 'Total deductions');
  static String get noDeductions =>
      _t('لا توجد خصومات في هذا الكشف', 'No deductions on this payslip');
  static String get salarySummary => _t('ملخص الراتب', 'Salary summary');
  static String get paymentDays => _t('عدد أيام الدفع', 'Payment days');
  static String paymentDaysOf(String paid, String total) =>
      _t('$paid من $total', '$paid of $total');
  static String get salaryPeriod => _t('فترة الراتب', 'Salary period');
  static String get slipDate => _t('تاريخ الكشف', 'Payslip date');
  static String get basicSalary => _t('الراتب الأساسي', 'Basic salary');
  static String get transportAllowance =>
      _t('بدل المواصلات', 'Transport allowance');
  static String get overtimePay => _t('العمل الإضافي', 'Overtime');
  static String get notOnSlip =>
      _t('غير موجود في هذا الكشف', 'Not on this payslip');
  static String get otherEarnings => _t('مستحقات أخرى', 'Other earnings');

  // أسماء الخصومات وشرحها بالعربية (حسب اسم مكوّن الراتب)
  static String get dedAdvance => _t('خصم سلفة', 'Advance deduction');
  static String get dedAdvanceWhy => _t(
    'تم خصم المبلغ المتبقي من السلفة التي حصل عليها الموظف.',
    'The remaining amount of the advance given to the employee was deducted.',
  );
  static String get dedLwp => _t('إجازة بدون راتب', 'Leave without pay');
  static String dedLwpWhy(String days) => _t(
    'تم خصم $days من الراتب بسبب إجازة غير مدفوعة.',
    '$days deducted from the salary for unpaid leave.',
  );
  static String get dedAbsence => _t('خصم غياب', 'Absence deduction');
  static String dedAbsenceWhy(String days) => _t(
    'تم خصم $days من الراتب بسبب الغياب دون إجازة.',
    '$days deducted from the salary for absence without leave.',
  );
  static String get dedLate => _t('خصم تأخير', 'Late deduction');
  static String get dedLateWhy => _t(
    'تم الخصم بسبب التأخر عن بداية الدوام أو الخروج المبكر.',
    'Deducted for arriving late or leaving early.',
  );
  static String get dedTax => _t('ضريبة الدخل', 'Income tax');
  static String get dedTaxWhy => _t(
    'ضريبة دخل تُقتطع من الراتب حسب القانون وتُورَّد للجهات الرسمية.',
    'Income tax withheld from the salary by law and paid to the authorities.',
  );
  static String get dedSocial => _t('الضمان الاجتماعي', 'Social security');
  static String get dedSocialWhy => _t(
    'حصة الموظف في الضمان أو التأمين الاجتماعي أو صندوق التقاعد.',
    'The employee share of social security or the pension fund.',
  );
  static String get dedHealth => _t('التأمين الصحي', 'Health insurance');
  static String get dedHealthWhy => _t(
    'اشتراك التأمين الصحي للموظف.',
    'The employee health insurance contribution.',
  );
  static String get dedLoan => _t('قسط قرض', 'Loan installment');
  static String get dedLoanWhy => _t(
    'قسط شهري من قرض حصل عليه الموظف.',
    'A monthly installment of a loan the employee received.',
  );
  static String get dedPenalty => _t('جزاء', 'Penalty');
  static String get dedPenaltyWhy => _t(
    'خصم بقرار إداري أو جزاء وفق لائحة الشركة.',
    'A deduction by administrative decision or company rules.',
  );
  static String dedOtherWhy(String component) => _t(
    'خصم «$component» حسب نظام الرواتب في الشركة.',
    '"$component" deducted according to the company payroll.',
  );
  static String get unpaidDaysNote => _t('أيام غير مدفوعة', 'Unpaid days');
  static String unpaidDaysWhy(String days) => _t(
    'لم يُحتسب $days في أيام الدفع (إجازة بدون راتب أو غياب)، فقلّت المستحقات بنسبتها.',
    '$days not counted as payment days (unpaid leave or absence), so earnings were reduced in proportion.',
  );
  static String days(double d) {
    final text = d == d.roundToDouble()
        ? d.toInt().toString()
        : d.toStringAsFixed(1);
    if (!LegacyLang.isArabic) return d == 1 ? '1 day' : '$text days';
    if (d == 1) return 'يوم';
    if (d == 2) return 'يومين';
    return '$text أيام';
  }

  static String get explanationNote => _t(
    'الشرح تقديري حسب اسم بند الخصم في ERPNext.',
    'Explanations are inferred from the deduction name in ERPNext.',
  );

  // فريقي (للمعتمِدين فقط، عرض فقط)
  static String get team => _t('فريقي', 'My team');
  static String get teamDesc =>
      _t('طلبات فريقك المعلقة', 'Pending requests of your team');
  static String get loadingTeam =>
      _t('جارٍ تحميل طلبات الفريق...', 'Loading team requests...');
  static String get teamLoadFailed =>
      _t('تعذّر تحميل طلبات الفريق', 'Could not load team requests');
  static String get teamNoAccess => _t(
    'هذه الشاشة لمعتمِدي الإجازات أو المصاريف فقط.',
    'This screen is only for leave or expense approvers.',
  );
  static String get teamViewOnly => _t(
    'للعرض فقط: الموافقة أو الرفض تتم من ERPNext. تظهر فقط طلبات الموظفين الذين أنت معتمِدهم.',
    'View only: approve or reject in ERPNext. Only requests of employees you approve for are shown.',
  );
  static String teamLeavesTab(int n) =>
      _t('طلبات الإجازات ($n)', 'Leave requests ($n)');
  static String teamExpensesTab(int n) =>
      _t('طلبات المصاريف ($n)', 'Expense requests ($n)');
  static String get noTeamLeaves =>
      _t('لا توجد طلبات إجازة معلقة', 'No pending leave requests');
  static String get noTeamExpenses =>
      _t('لا توجد طلبات مصاريف معلقة', 'No pending expense requests');
  static String get notLeaveApprover =>
      _t('لست معتمِدًا للإجازات', 'You are not a leave approver');
  static String get notExpenseApprover =>
      _t('لست معتمِدًا للمصاريف', 'You are not an expense approver');
  static String get leaveRequestType => _t('طلب إجازة', 'Leave request');
  static String get expenseRequestType => _t('طلب مصروف', 'Expense request');
  static String get statusAwaiting =>
      _t('بانتظار الموافقة', 'Awaiting approval');

  // مصدر العمل الإضافي (Overtime Slip أو Additional Salary)
  static String get overtimeTotalHours => _t('مجموع الساعات', 'Total hours');
  static String get hoursUnavailable => _t('غير متاح', 'Not available');
  static String duration(double seconds) {
    final minutes = (seconds / 60).round();
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return _t('$h س $m د', '${h}h ${m}m');
  }

  static String get sourceOvertimeSlip => _t(
    'الساعات من Overtime Slip المعتمد، والمبلغ من Additional Salary بمكوّن Overtime، كما حسبهما ERPNext.',
    'Hours from submitted Overtime Slips and the amount from Additional Salary (Overtime), as calculated by ERPNext.',
  );
  static String get sourceNoOvertimeSlip => _t(
    'نسخة HRMS لديكم لا تحتوي Overtime Slip، فالمبلغ من Additional Salary بمكوّن Overtime كما حسبه ERPNext، ولا يحفظ هذا المستند الساعات.',
    'Your HRMS version has no Overtime Slip, so the amount comes from Additional Salary (Overtime) as calculated by ERPNext; it does not store hours.',
  );
  static String get sourceNoSlipAccess => _t(
    'Overtime Slip موجود لكنك لا تملك صلاحية قراءته، فالمبلغ من Additional Salary بمكوّن Overtime والساعات غير متاحة.',
    'Overtime Slip exists but you cannot read it, so the amount comes from Additional Salary (Overtime) and hours are not available.',
  );
  static String sourceLabel(String source) =>
      _t('المصدر: $source', 'Source: $source');
  static String get overtimeHoursChart =>
      _t('ساعات العمل الإضافي خلال الشهر', 'Overtime hours this month');
  static String get overtimeHoursLog =>
      _t('ساعات العمل الإضافي', 'Overtime hours');
  static String get overtimeAmountsLog =>
      _t('مبالغ العمل الإضافي', 'Overtime amounts');
}
