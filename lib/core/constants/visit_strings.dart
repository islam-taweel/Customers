import 'app_strings.dart';

/// نصوص الرئيسية ومواعيد الزيارات (عربي/إنجليزي). اللغة الحالية من [AppStrings.isArabic].
class VisitStrings {
  VisitStrings._();

  static String _t(String ar, String en) => AppStrings.isArabic ? ar : en;

  // الشريط السفلي
  static String get home => _t('الرئيسية', 'Home');
  static String get dashboard => AppStrings.dashboard;
  static String get settings => AppStrings.settings;

  // الترحيب
  static String greeting(int hour) => hour < 12
      ? _t('صباح الخير', 'Good morning')
      : hour < 18
          ? _t('مساء الخير', 'Good afternoon')
          : _t('مساء الخير', 'Good evening');
  static String welcome(String? name) => (name == null || name.isEmpty)
      ? _t('أهلًا بك', 'Welcome')
      : _t('أهلًا بك، $name', 'Welcome, $name');
  static String visitsToday(int n) => n == 0
      ? _t('لا مواعيد لديك اليوم', 'You have no appointments today')
      : _t('لديك $n موعد اليوم', 'You have $n appointments today');

  // الأقسام
  static String get section => _t('المواعيد', 'Appointments');
  static String get todayTitle => _t('مواعيد اليوم', "Today's appointments");
  static String get allVisits => _t('كل المواعيد', 'All appointments');
  static String get newVisit => _t('موعد جديد', 'New appointment');
  static String get editVisit => _t('تعديل الموعد', 'Edit appointment');
  static String get loading => _t('جارٍ تحميل المواعيد...', 'Loading appointments...');
  static String get loadFailed =>
      _t('تعذّر تحميل المواعيد', 'Could not load the appointments');
  static String get noToday =>
      _t('لا توجد مواعيد اليوم', 'No appointments today');
  static String get noVisits => _t('لا توجد مواعيد', 'No appointments');
  static String get showCancelled => _t('إظهار الملغاة', 'Show cancelled');

  // عنوان الموعد في ERPNext
  static String subject(String customer) =>
      _t('زيارة: $customer', 'Visit: $customer');

  // الحالة
  static String status(String s) => switch (s) {
        'Completed' => _t('منجز', 'Completed'),
        'Cancelled' => _t('ملغى', 'Cancelled'),
        'Closed' => _t('مغلق', 'Closed'),
        _ => _t('مفتوح', 'Open'),
      };

  // التكرار
  static String weekday(int d) => switch (d) {
        1 => _t('الإثنين', 'Mon'),
        2 => _t('الثلاثاء', 'Tue'),
        3 => _t('الأربعاء', 'Wed'),
        4 => _t('الخميس', 'Thu'),
        5 => _t('الجمعة', 'Fri'),
        6 => _t('السبت', 'Sat'),
        _ => _t('الأحد', 'Sun'),
      };
  static String weeklyOn(String days) =>
      _t('أسبوعيًا: $days', 'Weekly: $days');
  static String until(String date) => _t('حتى $date', 'until $date');
  static String get forever => _t('بلا نهاية', 'no end');
  static String get oneOff => _t('مرة واحدة', 'One-off');

  // النموذج
  static String get customer => _t('العميل', 'Customer');
  static String get chooseCustomer => _t('اختر العميل', 'Choose a customer');
  static String get searchCustomer =>
      _t('ابحث بالاسم أو الرقم', 'Search by name or ID');
  static String get loadingCustomers =>
      _t('جارٍ تحميل العملاء...', 'Loading customers...');
  static String get noCustomers => _t('لا يوجد عملاء', 'No customers');
  static String get date => _t('التاريخ', 'Date');
  static String get startTime => _t('من الساعة', 'From');
  static String get endTime => _t('إلى الساعة', 'To');
  static String get notes => _t('ملاحظات (اختياري)', 'Notes (optional)');
  static String get weekly => _t('موعد أسبوعي متكرر', 'Repeat weekly');
  static String get weeklyHint => _t(
        'يتكرر في الأيام المحددة. يوم التاريخ محدد دائمًا',
        'Repeats on the chosen days. The date\'s weekday is always included',
      );
  static String get repeatTill => _t('يتكرر حتى', 'Repeat until');
  static String get noEndDate => _t('بلا تاريخ نهاية', 'No end date');
  static String get seriesNote => _t(
        'التعديل يُطبَّق على كل تكرارات هذا الموعد',
        'Changes apply to every occurrence of this appointment',
      );
  static String get save => _t('حفظ', 'Save');
  static String get customerRequired =>
      _t('اختر العميل أولًا', 'Choose the customer first');
  static String get endBeforeStart => _t(
        'وقت النهاية يجب أن يكون بعد وقت البداية',
        'The end time must be after the start time',
      );
  static String get tillBeforeStart => _t(
        'تاريخ نهاية التكرار يجب ألا يسبق تاريخ الموعد',
        'The repeat end date can\'t be before the appointment date',
      );
  static String conflict(String subject, DateTime start, DateTime end) {
    String two(int n) => n.toString().padLeft(2, '0');
    final day = '${start.year}-${two(start.month)}-${two(start.day)}';
    final time = '${two(start.hour)}:${two(start.minute)}–${two(end.hour)}:${two(end.minute)}';
    return _t(
      'يتعارض مع موعد آخر في نفس الوقت: «$subject» يوم $day الساعة $time. اختر وقتًا آخر.',
      'Clashes with another appointment at the same time: "$subject" on $day at $time. Choose another time.',
    );
  }
  static String get noVisitsDay =>
      _t('لا مواعيد في هذا اليوم', 'No appointments on this day');
  static String get previousMonth => _t('الشهر السابق', 'Previous month');
  static String get nextMonth => _t('الشهر التالي', 'Next month');
  static String get today => _t('اليوم', 'Today');
  static String get created => _t('حُفظ الموعد', 'Appointment saved');
  static String get updated => _t('عُدِّل الموعد', 'Appointment updated');
  static String get saveFailed =>
      _t('تعذّر حفظ الموعد', 'Could not save the appointment');

  // الإجراءات
  static String get edit => _t('تعديل', 'Edit');
  static String get complete => _t('تم الإنجاز', 'Mark done');
  static String get reopen => _t('إعادة فتح', 'Reopen');
  static String get cancel => _t('إلغاء الموعد', 'Cancel appointment');
  static String get delete => _t('حذف نهائي', 'Delete permanently');

  static String cancelTitle(String subject) =>
      _t('إلغاء «$subject»؟', 'Cancel "$subject"?');
  static String cancelMessage(bool recurring) => recurring
      ? _t(
          'سيُلغى الموعد بكل تكراراته (لا يمكن إلغاء أسبوع واحد). يبقى في النظام بحالة «ملغى».',
          'The whole series will be cancelled (a single week can\'t be). It stays in the system as Cancelled.',
        )
      : _t(
          'يبقى الموعد في النظام بحالة «ملغى».',
          'The appointment stays in the system as Cancelled.',
        );
  static String deleteTitle(String subject) =>
      _t('حذف «$subject» نهائيًا؟', 'Delete "$subject" permanently?');
  static String get deleteMessage => _t(
        'سيُحذف من ERPNext ولا يمكن استرجاعه. استخدم «إلغاء الموعد» إن أردت الاحتفاظ بسجل.',
        'It will be removed from ERPNext for good. Use "Cancel appointment" to keep a record.',
      );
  static String editClosedTitle(String status) =>
      _t('الموعد $status', 'This appointment is $status');
  static String get editClosedMessage => _t(
        'هل تريد تعديله رغم ذلك؟',
        'Do you want to edit it anyway?',
      );
  static String get editAnyway => _t('تعديل', 'Edit');

  static String get cancelled => _t('أُلغي الموعد', 'Appointment cancelled');
  static String get completed => _t('سُجِّل الموعد منجزًا', 'Marked as done');
  static String get reopened => _t('أُعيد فتح الموعد', 'Appointment reopened');
  static String get deleted => _t('حُذف الموعد', 'Appointment deleted');
  static String get actionFailed =>
      _t('تعذّر تنفيذ العملية', 'The action failed');
}
