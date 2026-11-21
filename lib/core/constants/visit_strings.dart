import 'package:get/get.dart';

import 'app_strings.dart';

/// نصوص الرئيسية ومواعيد الزيارات (عربي/إنجليزي). النصوص في lib/app/translations (ar.dart / en.dart) وتُقرأ هنا بـ .tr.
class VisitStrings {
  VisitStrings._();

  // الشريط السفلي
  static String get home => 'visit.home'.tr;
  static String get dashboard => AppStrings.dashboard;
  static String get settings => AppStrings.settings;

  // الترحيب
  static String greeting(int hour) => hour < 12
      ? 'visit.greeting'.tr
      : hour < 18
      ? 'visit.greeting_2'.tr
      : 'visit.greeting_3'.tr;
  static String welcome(String? name) => (name == null || name.isEmpty)
      ? 'visit.welcome'.tr
      : 'visit.welcome_2'.trParams({'name': name});
  static String visitsToday(int n) => n == 0
      ? 'visit.visitsToday'.tr
      : 'visit.visitsToday_2'.trParams({'n': '$n'});

  // الأقسام
  static String get section => 'visit.section'.tr;
  static String get todayTitle => 'visit.todayTitle'.tr;
  static String get allVisits => 'visit.allVisits'.tr;
  static String get newVisit => 'visit.newVisit'.tr;
  static String get editVisit => 'visit.editVisit'.tr;
  static String get loading => 'visit.loading'.tr;
  static String get loadFailed => 'visit.loadFailed'.tr;
  static String get noToday => 'visit.noToday'.tr;
  static String get noVisits => 'visit.noVisits'.tr;
  static String get showCancelled => 'visit.showCancelled'.tr;

  // عنوان الموعد في ERPNext
  static String subject(String customer) =>
      'visit.subject'.trParams({'customer': customer});

  // الحالة
  static String status(String s) => switch (s) {
    'Completed' => 'visit.status.Completed'.tr,
    'Cancelled' => 'visit.status.Cancelled'.tr,
    'Closed' => 'visit.status.Closed'.tr,
    _ => 'visit.status'.tr,
  };

  // التكرار
  static String weekday(int d) => switch (d) {
    1 => 'visit.weekday.1'.tr,
    2 => 'visit.weekday.2'.tr,
    3 => 'visit.weekday.3'.tr,
    4 => 'visit.weekday.4'.tr,
    5 => 'visit.weekday.5'.tr,
    6 => 'visit.weekday.6'.tr,
    _ => 'visit.weekday'.tr,
  };
  static String weeklyOn(String days) =>
      'visit.weeklyOn'.trParams({'days': days});
  static String until(String date) => 'visit.until'.trParams({'date': date});
  static String get forever => 'visit.forever'.tr;
  static String get oneOff => 'visit.oneOff'.tr;

  // النموذج
  static String get customer => 'visit.customer'.tr;
  static String get chooseCustomer => 'visit.chooseCustomer'.tr;
  static String get searchCustomer => 'visit.searchCustomer'.tr;
  static String get loadingCustomers => 'visit.loadingCustomers'.tr;
  static String get noCustomers => 'visit.noCustomers'.tr;
  static String get date => 'visit.date'.tr;
  static String get startTime => 'visit.startTime'.tr;
  static String get endTime => 'visit.endTime'.tr;
  static String get notes => 'visit.notes'.tr;
  static String get weekly => 'visit.weekly'.tr;
  static String get weeklyHint => 'visit.weeklyHint'.tr;
  static String get repeatTill => 'visit.repeatTill'.tr;
  static String get noEndDate => 'visit.noEndDate'.tr;
  static String get seriesNote => 'visit.seriesNote'.tr;
  static String get save => 'visit.save'.tr;
  static String get customerRequired => 'visit.customerRequired'.tr;
  static String get endBeforeStart => 'visit.endBeforeStart'.tr;
  static String get tillBeforeStart => 'visit.tillBeforeStart'.tr;
  static String conflict(String subject, DateTime start, DateTime end) {
    String two(int n) => n.toString().padLeft(2, '0');
    final day = '${start.year}-${two(start.month)}-${two(start.day)}';
    final time =
        '${two(start.hour)}:${two(start.minute)}–${two(end.hour)}:${two(end.minute)}';
    return 'visit.conflict'.trParams({
      'subject': subject,
      'day': day,
      'time': time,
    });
  }

  static String get noVisitsDay => 'visit.noVisitsDay'.tr;
  static String get previousMonth => 'visit.previousMonth'.tr;
  static String get nextMonth => 'visit.nextMonth'.tr;
  static String get today => 'visit.today'.tr;
  static String get created => 'visit.created'.tr;
  static String get updated => 'visit.updated'.tr;
  static String get saveFailed => 'visit.saveFailed'.tr;

  // الإجراءات
  static String get edit => 'visit.edit'.tr;
  static String get complete => 'visit.complete'.tr;
  static String get reopen => 'visit.reopen'.tr;
  static String get cancel => 'visit.cancel'.tr;
  static String get delete => 'visit.delete'.tr;

  static String cancelTitle(String subject) =>
      'visit.cancelTitle'.trParams({'subject': subject});
  static String cancelMessage(bool recurring) =>
      recurring ? 'visit.cancelMessage'.tr : 'visit.cancelMessage_2'.tr;
  static String deleteTitle(String subject) =>
      'visit.deleteTitle'.trParams({'subject': subject});
  static String get deleteMessage => 'visit.deleteMessage'.tr;
  static String editClosedTitle(String status) =>
      'visit.editClosedTitle'.trParams({'status': status});
  static String get editClosedMessage => 'visit.editClosedMessage'.tr;
  static String get editAnyway => 'visit.editAnyway'.tr;

  static String get cancelled => 'visit.cancelled'.tr;
  static String get completed => 'visit.completed'.tr;
  static String get reopened => 'visit.reopened'.tr;
  static String get deleted => 'visit.deleted'.tr;
  static String get actionFailed => 'visit.actionFailed'.tr;
}
