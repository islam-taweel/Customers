/// إعدادات الاتصال بـ ERPNext.
///
/// القيم تُمرَّر وقت التشغيل عبر `--dart-define` (أو `--dart-define-from-file=env.json`)،
/// فلا تُكتب المفاتيح داخل الكود ولا تصل إلى GitHub.
class ErpConfig {
  ErpConfig._();

  /// عنوان الخادم. من محاكي أندرويد استخدم http://10.0.2.2
  static const String baseUrl = String.fromEnvironment(
    'ERP_BASE_URL',
    defaultValue: 'http://192.168.1.130',
  );

  /// قيمة ترويسة Host المطلوبة (الموقع في ERPNext)
  static const String hostHeader = String.fromEnvironment(
    'ERP_HOST',
    defaultValue: 'erp.local',
  );

  static const String apiKey = String.fromEnvironment('ERP_API_KEY');
  static const String apiSecret = String.fromEnvironment('ERP_API_SECRET');

  static bool get hasCredentials => apiKey.isNotEmpty && apiSecret.isNotEmpty;

  /// حجم الصفحة الواحدة في كل طلب (limit_page_length)
  static const int pageSize = 100;

  /// مهلة قصيرة: دون إنترنت يظهر المحفوظ بسرعة بدل انتظار طويل
  static const Duration requestTimeout = Duration(seconds: 10);

  /// مدة بقاء البيانات المحمّلة في الذاكرة قبل إعادة جلبها من الخادم
  static const Duration cacheTtl = Duration(minutes: 2);

  /// حقل رابط العميل في جدول Dynamic Link (جدول فرعي داخل Contact).
  /// الأقواس المائلة (backticks) هي صيغة Frappe لحقول الجداول الفرعية.
  static const String contactLinkField = '`tabDynamic Link`.link_name';

  // ───────── طلبيات العملاء (Sales Order) ─────────

  /// الشركة التي تُنشأ لها الطلبية
  static const String company = 'Ramallah Tools Co.';

  /// قائمة الأسعار المستخدمة للبيع (السعر يُقرأ منها، لا من standard_rate)
  static const String sellingPriceList = 'Standard Selling';

  /// عملة قائمة الأسعار، وسعر تحويلها إلى عملة الشركة
  static const String priceListCurrency = 'ILS';
  static const num priceListConversionRate = 1;

  /// المستودع الذي يُقرأ منه المخزون وتُسحب منه الأصناف
  static const String warehouse = 'Main Warehouse - RTC';
}
