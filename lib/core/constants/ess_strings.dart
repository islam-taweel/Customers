import 'app_strings.dart';

/// نصوص قسم «خدمات الموظف» (عربي/إنجليزي). اللغة الحالية من [AppStrings.isArabic].
class EssStrings {
  EssStrings._();

  static String _t(String ar, String en) => AppStrings.isArabic ? ar : en;

  static String get section => _t('خدمات الموظف', 'Employee Self-Service');
  static String get intro => _t(
        'كل ما تحتاجه كموظف في مكان واحد',
        'Everything you need as an employee in one place',
      );

  // الخدمات: العنوان والوصف القصير
  static String get profile => _t('حسابي', 'My account');
  static String get profileDesc =>
      _t('بياناتك الوظيفية والشخصية', 'Your job and personal details');

  static String get checkin =>
      _t('تسجيل الحضور والانصراف', 'Check in / out');
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
        'حسابك غير مرتبط بسجل موظف في ERPNext. اطلب من مسؤول الموارد البشرية ربط المستخدم بالموظف.',
        'Your account is not linked to an employee in ERPNext. Ask HR to link your user to the employee.',
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
  static String hoursMinutes(int h, int m) =>
      _t('$h س $m د', '${h}h ${m}m');
  static String get checkedIn => _t('سُجّل الحضور', 'Checked in');
  static String get checkedOut => _t('سُجّل الانصراف', 'Checked out');
  static String get location => _t('الموقع الجغرافي', 'Location');
  static String get locationPlaceholder => _t(
        'سيظهر موقع التسجيل هنا',
        'The check-in location will appear here',
      );
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
  static String monthName(int m) => AppStrings.isArabic
      ? const ['كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
          'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'][m - 1]
      : const ['January', 'February', 'March', 'April', 'May', 'June', 'July',
          'August', 'September', 'October', 'November', 'December'][m - 1];
  static String get year => _t('السنة', 'Year');
  static String get presentDays => _t('أيام الحضور', 'Present days');
  static String get absentDays => _t('أيام الغياب', 'Absent days');
  static String get lateDays => _t('أيام التأخير', 'Late days');
  static String get workHours => _t('ساعات العمل', 'Working hours');
  static String get noAttendance =>
      _t('لا توجد سجلات حضور لهذا الشهر', 'No attendance records for this month');
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
  static String get newRequest => _t('طلب تصحيح جديد', 'New correction request');
  static String get requestDate => _t('تاريخ اليوم المراد تصحيحه', 'Date to correct');
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
  static String get requiredField => _t('هذا الحقل مطلوب', 'This field is required');
  static String get chooseDate => _t('اختر التاريخ', 'Choose the date');
  static String get chooseTime => _t('اختر الوقت', 'Choose the time');
  static String get reasonTooShort =>
      _t('اكتب سببًا أوضح (5 أحرف على الأقل)', 'Write a clearer reason (at least 5 characters)');
  static String get requestSent =>
      _t('أُرسل الطلب وهو قيد المراجعة', 'Request sent and pending review');
  static String get previousRequests => _t('الطلبات السابقة', 'Previous requests');
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
  static String balanceDetail(String total, String taken, String pending) =>
      _t(
        'من $total • مأخوذ $taken • معلّق $pending',
        'of $total • taken $taken • pending $pending',
      );
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
    final text =
        d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
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
  static String get leaveHistory =>
      _t('الطلبات السابقة', 'Previous requests');
  static String get noLeaveRequests =>
      _t('لا توجد طلبات إجازة سابقة', 'No previous leave requests');
  static String period(String from, String to) =>
      _t('من $from إلى $to', 'From $from to $to');

  // العمل الإضافي
  static String get loadingOvertime =>
      _t('جارٍ تحميل العمل الإضافي...', 'Loading overtime...');
  static String get overtimeDays =>
      _t('أيام العمل الإضافي', 'Overtime days');
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
  static String get statusWorkFromHome =>
      _t('عمل من المنزل', 'Work from home');

  // العمل الإضافي (Additional Salary)
  static String get overtimeEntries => _t('عدد الدفعات', 'Entries');
  static String get overtimeHoursPending => _t(
        'الساعات: سيُتفق على طريقة عرضها',
        'Hours: display to be agreed',
      );
  static String get overtimeAmountSource => _t(
        'من «Additional Salary» بمكوّن Overtime المعتمد في ERPNext. يُحفظ المبلغ فقط دون الساعات.',
        'From approved Additional Salary with the Overtime component in ERPNext. Only the amount is stored, not the hours.',
      );
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
}
