/// الأرقام والقيم الثابتة المشتركة في التطبيق.
class AppConstants {
  AppConstants._();

  /// رمز العملة المعروض بجانب المبالغ
  static const String currencySymbol = '₪';

  /// مفتاح الدولة (فلسطين 970) لتحويل الهاتف المحلي 05XXXXXXXX إلى الصيغة الدولية
  static const String phoneCountryCode = '970';

  /// عدد العملاء في كل دفعة عند التصفح اللانهائي
  static const int customersPageSize = 20;

  /// المسافة المتبقية (بالبكسل) حتى نهاية القائمة التي نطلب عندها الدفعة التالية
  static const double loadMoreThreshold = 200;

  /// المهلة بعد توقف الكتابة قبل تنفيذ البحث
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// أقصى مدة ننتظرها قبل إخفاء شاشة البداية (Splash) إن تأخر التحميل
  static const Duration splashTimeout = Duration(seconds: 10);

  /// عدد العملاء الوهميين الذين يضيفهم زر التطوير (debug فقط)
  static const int fakeCustomersCount = 200;

  // أبعاد مشتركة
  static const double pagePadding = 16;
  static const double borderRadius = 12;
}