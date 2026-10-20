import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إعدادات الاتصال بـ ERPNext.
///
/// عنوان الخادم يُمرَّر وقت التشغيل عبر `--dart-define` (أو `--dart-define-from-file=env.json`).
/// لا توجد مفاتيح API: كل مستخدم يدخل بحسابه في ERPNext ويحمل جلسته الخاصة (كوكي sid).
class ErpConfig {
  ErpConfig._();

  /// الخادم الافتراضي: يُستخدم حين يُدخل المستخدم «اسم موقع» فقط.
  /// من محاكي أندرويد استخدم http://10.0.2.2
  static const String _defaultServer = String.fromEnvironment(
    'ERP_BASE_URL',
    defaultValue: 'http://192.168.1.130',
  );

  /// اسم الموقع الافتراضي قبل أن يدخل المستخدم شيئًا
  static const String _defaultSite = String.fromEnvironment(
    'ERP_HOST',
    defaultValue: 'erp.local',
  );

  static const String _serverKey = 'erp_server_url';
  static const String _siteKey = 'erp_site_name';

  static String _server = _defaultServer;
  static String _site = _defaultSite;

  /// عنوان الخادم الحالي
  static String get baseUrl => _server;

  /// ما يظهر في حقل الدخول: اسم الموقع إن وُجد، وإلا عنوان الخادم.
  static String get currentInput => _site.isNotEmpty ? _site : _server;

  /// قيمة ترويسة Host. اسم الموقع إن أُدخل، وإلا مضيف عنوان الخادم نفسه
  /// (مواقع يطابق اسمها نطاقها أو عنوانها).
  static String get hostHeader {
    if (_site.isNotEmpty) return _site;
    final uri = Uri.tryParse(_server);
    if (uri == null || uri.host.isEmpty) return _server;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }

  /// يقرأ المحفوظ عند بدء التطبيق، قبل أول طلب.
  static Future<void> loadSite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final site = prefs.getString(_siteKey);
      final server = prefs.getString(_serverKey);
      if (site != null || server != null) {
        _site = (site ?? '').trim();
        final s = (server ?? '').trim();
        if (s.isNotEmpty) _server = s;
      }
    } catch (e) {
      debugPrint('ErpConfig.loadSite failed: $e');
    }
  }

  static final RegExp _scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');
  static final RegExp _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

  /// يفسّر ما كتبه المستخدم في الحقل الواحد:
  ///  • عنوان خادم: فيه http:// أو https://، أو رقم IP، أو منفذ (:8000)، أو localhost
  ///    ← الخادم هو هذا العنوان، واسم الموقع يُؤخذ من مضيفه.
  ///  • غير ذلك (مثل erp.local أو client1) ← اسم موقع على الخادم الافتراضي.
  /// يعيد null إن كان المُدخل فارغًا أو غير صالح.
  static ({String server, String site})? parseTarget(String raw) {
    final s = raw.trim();
    if (s.isEmpty || s.contains(RegExp(r'\s'))) return null;

    final hostPart = s.replaceFirst(_scheme, '').split('/').first;
    final hostOnly = hostPart.split(':').first.toLowerCase();
    final isAddress = _scheme.hasMatch(s) ||
        _ipv4.hasMatch(hostOnly) ||
        hostPart.contains(':') ||
        hostOnly == 'localhost';

    if (isAddress) {
      final server = normalizeServer(s);
      return server == null ? null : (server: server, site: '');
    }
    final site = normalizeSite(s);
    return site.isEmpty ? null : (server: _defaultServer, site: site);
  }

  /// يضبط الهدف (خادم + موقع) من مُدخل المستخدم ويحفظه. قبل تسجيل الدخول.
  static Future<void> setTarget(String raw) async {
    final target = parseTarget(raw);
    if (target == null) return;
    _server = target.server;
    _site = target.site;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverKey, _server);
      await prefs.setString(_siteKey, _site);
    } catch (e) {
      debugPrint('ErpConfig.setTarget failed: $e');
    }
  }

  /// scheme://host[:port] نظيف. بلا بروتوكول: IP وlocalhost و.local ← http،
  /// وغيرها ← https. يعيد null إن لم يكن صالحًا.
  static String? normalizeServer(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (!_scheme.hasMatch(s)) {
      final host = s.split('/').first.split(':').first.toLowerCase();
      final isLocal =
          _ipv4.hasMatch(host) || host == 'localhost' || host.endsWith('.local');
      s = '${isLocal ? 'http' : 'https'}://$s';
    }
    final uri = Uri.tryParse(s);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  /// يحذف المسافات وأي بروتوكول أو مسار قد يلصقه المستخدم بالخطأ.
  static String normalizeSite(String raw) {
    var s = raw.trim().replaceFirst(_scheme, '');
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
