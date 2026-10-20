import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إعدادات الاتصال بـ ERPNext.
///
/// عنوان الخادم يُمرَّر وقت التشغيل عبر `--dart-define` (أو `--dart-define-from-file=env.json`).
/// لا توجد مفاتيح API: كل مستخدم يدخل بحسابه في ERPNext ويحمل جلسته الخاصة (كوكي sid).
class ErpConfig {
  ErpConfig._();

  /// عنوان الخادم. من محاكي أندرويد استخدم http://10.0.2.2
  static const String baseUrl = String.fromEnvironment(
    'ERP_BASE_URL',
    defaultValue: 'http://192.168.1.130',
  );

  /// اسم الموقع الافتراضي (قبل أن يدخل المستخدم اسم موقعه)
  static const String _defaultSite = String.fromEnvironment(
    'ERP_HOST',
    defaultValue: 'erp.local',
  );

  static const String _siteKey = 'erp_site_name';

  static String _site = _defaultSite;

  /// قيمة ترويسة Host = اسم موقع المستخدم في ERPNext.
  /// عنوان الخادم ثابت، واسم الموقع هو ما يختلف من عميل لآخر،
  /// فيُدخله المستخدم في شاشة الدخول ويُحفظ على جهازه.
  static String get hostHeader => _site;

  /// يقرأ اسم الموقع المحفوظ. يُستدعى مرة عند بدء التطبيق قبل أول طلب.
  static Future<void> loadSite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_siteKey);
      if (saved != null && saved.trim().isNotEmpty) _site = saved.trim();
    } catch (e) {
      debugPrint('ErpConfig.loadSite failed: $e');
    }
  }

  /// يضبط اسم الموقع (بعد تنظيفه) ويحفظه. يُستدعى قبل تسجيل الدخول.
  static Future<void> setSite(String raw) async {
    final site = normalizeSite(raw);
    if (site.isEmpty) return;
    _site = site;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_siteKey, site);
    } catch (e) {
      debugPrint('ErpConfig.setSite failed: $e');
    }
  }

  /// يحذف ما قد يلصقه المستخدم بالخطأ: http:// أو https:// أو مسارًا بعد الاسم
  /// أو مسافات. «https://shop.example.com/app» ← «shop.example.com».
  static String normalizeSite(String raw) {
    var s = raw.trim();
    s = s.replaceFirst(RegExp(r'^[a-zA-Z]+://'), '');
    final slash = s.indexOf('/');
    if (slash >= 0) s = s.substring(0, slash);
    return s.trim();
  }

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
