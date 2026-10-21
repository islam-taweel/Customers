import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'erp_config.dart';
import 'session_store.dart';

/// أنواع الأخطاء التي تفرّق بينها الواجهة لتعرض رسالة مناسبة لكل نوع.
enum ErpErrorType {
  /// لا توجد جلسة دخول أو انتهت: يجب تسجيل الدخول من جديد
  sessionExpired,

  /// الجلسة سليمة لكن المستخدم لا يملك صلاحية هذا الإجراء
  forbidden,

  /// المورد غير موجود (404)
  notFound,

  /// تعذّر الوصول للخادم (شبكة، مهلة، عنوان خاطئ)
  network,

  /// ردّ الخادم بخطأ آخر (5xx، 417...)
  server,

  /// ردّ بصيغة غير متوقعة
  badResponse,
}

class ErpApiException implements Exception {
  final ErpErrorType type;
  final int? statusCode;
  final String? detail;

  const ErpApiException(this.type, {this.statusCode, this.detail});

  @override
  String toString() =>
      'ErpApiException($type, status: $statusCode, detail: $detail)';
}

/// يتكلم مع ERPNext REST API: يضيف الترويسات المطلوبة ويحوّل الأخطاء إلى
/// [ErpApiException]. لا يعرف شيئًا عن نماذج التطبيق ولا الواجهة.
class ErpApiClient {
  ErpApiClient({required SessionStore session, http.Client? client})
      : _session = session,
        _client = client ?? http.Client();

  final SessionStore _session;
  final http.Client _client;

  /// يُستدعى حين نتأكد أن الجلسة انتهت (بعد حذف الكوكي): يعيد التطبيق لشاشة الدخول.
  VoidCallback? onSessionExpired;

  /// فحص «هل الجلسة منتهية؟» الجاري حاليًا. الطلبات المتوازية التي رُفضت معًا
  /// تشاركه بدل أن يرسل كل منها فحصًا مستقلًا.
  Future<bool>? _sessionCheck;

  /// وقت آخر فشل في الوصول للخادم. يُستخدم لتجاوز الانتظار (المهلة 10 ثوانٍ)
  /// وقراءة النسخة المحلية مباشرة بينما الخادم غير متاح.
  DateTime? _lastNetworkFailure;

  static const Duration _unreachableWindow = Duration(seconds: 30);

  bool get recentlyUnreachable {
    final at = _lastNetworkFailure;
    return at != null && DateTime.now().difference(at) < _unreachableWindow;
  }

  /// فحص سريع لتوفر الخادم (/api/method/ping لا يحتاج مفاتيح).
  /// true = ردّ الخادم، false = تعذّر الوصول إليه.
  Future<bool> ping() async {
    final uri = Uri.parse(ErpConfig.baseUrl).replace(
      pathSegments: ['api', 'method', 'ping'],
    );
    try {
      final response = await _client
          .get(uri, headers: {'Host': ErpConfig.hostHeader})
          .timeout(const Duration(seconds: 5));
      _lastNetworkFailure = null;
      return response.statusCode < 500;
    } on TimeoutException {
      _lastNetworkFailure = DateTime.now();
      return false;
    } on SocketException {
      _lastNetworkFailure = DateTime.now();
      return false;
    } on http.ClientException {
      _lastNetworkFailure = DateTime.now();
      return false;
    }
  }

  /// حد أمان لحلقة جلب الصفحات حتى لا تدور بلا نهاية عند خلل في الخادم
  static const int _maxPages = 500;

  /// كل طلب بعد الدخول يحمل كوكي الجلسة وترويسة Host (لا مفاتيح API).
  Map<String, String> _headers(String sid) => {
        'Cookie': 'sid=$sid',
        'Host': ErpConfig.hostHeader,
        'Accept': 'application/json',
      };

  /// /api/resource/{doctype}[/{name}] — pathSegments تُرمِّز المسافة والرموز
  /// الخاصة بشكل صحيح، فيُرسل رقم الفاتورة كما وصل تمامًا.
  Uri _uri(List<String> segments, [Map<String, String>? query]) {
    return Uri.parse(ErpConfig.baseUrl).replace(
      pathSegments: ['api', 'resource', ...segments],
      queryParameters: query,
    );
  }

  /// صفحة واحدة من قائمة مستندات.
  Future<List<Map<String, dynamic>>> getList(
    String doctype, {
    required List<String> fields,
    List<List<Object>>? filters,
    String? groupBy,
    int limitStart = 0,
    int limitPageLength = ErpConfig.pageSize,
  }) async {
    final uri = _uri([doctype], {
      'fields': jsonEncode(fields),
      if (filters != null) 'filters': jsonEncode(filters),
      if (groupBy != null) 'group_by': groupBy,
      'limit_start': '$limitStart',
      'limit_page_length': '$limitPageLength',
    });

    final data = (await _get(uri))['data'];
    if (data is! List) {
      throw const ErpApiException(ErpErrorType.badResponse);
    }
    return [for (final row in data) Map<String, dynamic>.from(row as Map)];
  }

  /// كل الصفحات: نكرر الطلب (كل مرة 100 صف) حتى تأتي صفحة ناقصة.
  /// ضروري لأن رصيد العميل مجموع كل فواتيره، وأي صفحة ناقصة تعني رصيدًا خاطئًا.
  Future<List<Map<String, dynamic>>> getAll(
    String doctype, {
    required List<String> fields,
    List<List<Object>>? filters,
    String? groupBy,
  }) async {
    final all = <Map<String, dynamic>>[];
    var start = 0;

    for (var page = 0; page < _maxPages; page++) {
      final rows = await getList(
        doctype,
        fields: fields,
        filters: filters,
        groupBy: groupBy,
        limitStart: start,
      );
      all.addAll(rows);
      if (rows.length < ErpConfig.pageSize) break;
      start += ErpConfig.pageSize;
    }
    return all;
  }

  /// مستند واحد كامل (مثل فاتورة بأصنافها).
  Future<Map<String, dynamic>> getDoc(String doctype, String name) async {
    final data = (await _get(_uri([doctype, name])))['data'];
    if (data is! Map) {
      throw const ErpApiException(ErpErrorType.badResponse);
    }
    return Map<String, dynamic>.from(data);
  }

  /// ينشئ مستندًا جديدًا (POST /api/resource/{doctype}) ويعيد المستند المحفوظ
  /// كما ردّ به الخادم (مثلًا data.name = رقم الطلبية).
  Future<Map<String, dynamic>> postDoc(
    String doctype,
    Map<String, dynamic> body,
  ) async {
    final uri = _uri([doctype]);
    final decoded = await _send(
      uri,
      (headers) => _client.post(
        uri,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    final data = decoded['data'];
    if (data is! Map) {
      throw const ErpApiException(ErpErrorType.badResponse);
    }
    return Map<String, dynamic>.from(data);
  }

  /// يعدّل مستندًا موجودًا (PUT /api/resource/{doctype}/{name}). الحقول المرسلة فقط
  /// تتغير، وحقل الجدول (مثل items) يُستبدل كله بالقائمة المرسلة.
  Future<Map<String, dynamic>> putDoc(
    String doctype,
    String name,
    Map<String, dynamic> body,
  ) async {
    final uri = _uri([doctype, name]);
    final decoded = await _send(
      uri,
      (headers) => _client.put(
        uri,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    final data = decoded['data'];
    if (data is! Map) {
      throw const ErpApiException(ErpErrorType.badResponse);
    }
    return Map<String, dynamic>.from(data);
  }

  /// يحذف مستندًا (DELETE /api/resource/{doctype}/{name}). مسموح للمسودات فقط.
  Future<void> deleteDoc(String doctype, String name) async {
    final uri = _uri([doctype, name]);
    await _send(uri, (headers) => _client.delete(uri, headers: headers));
  }

  /// يستدعي دالة في الخادم (POST /api/method/{method}) ويعيد الرد كاملًا.
  Future<Map<String, dynamic>> postMethod(
    String method,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse(ErpConfig.baseUrl).replace(
      pathSegments: ['api', 'method', ...method.split('/')],
    );
    return _send(
      uri,
      (headers) => _client.post(
        uri,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
  }

  /// يستدعي دالة في الخادم بطلب GET (GET /api/method/{method}?...) ويعيد الرد كاملًا.
  /// مثل: جلب تفاصيل طرف في Payment Entry أو سعر الصرف أو API الرصيد المستحق.
  Future<Map<String, dynamic>> getMethod(
    String method, [
    Map<String, String>? query,
  ]) {
    final uri = Uri.parse(ErpConfig.baseUrl).replace(
      pathSegments: ['api', 'method', ...method.split('/')],
      queryParameters: query,
    );
    return _get(uri);
  }

  /// ملف PDF لمستند عبر frappe.utils.print_format.download_pdf (قالب الطباعة
  /// الافتراضي في ERPNext). يرمي [ErpApiException] إن لم يصل ملف PDF سليم.
  Future<Uint8List> downloadPdf(String doctype, String name) async {
    final uri = Uri.parse(ErpConfig.baseUrl).replace(
      pathSegments: [
        'api',
        'method',
        'frappe.utils.print_format.download_pdf',
      ],
      queryParameters: {'doctype': doctype, 'name': name, 'no_letterhead': '0'},
    );
    final response = await _execute(
      uri,
      (headers) => _client.get(
        uri,
        headers: {...headers, 'Accept': 'application/pdf'},
      ),
    );
    final bytes = response.bodyBytes;
    // ملف PDF يبدأ بـ %PDF
    final isPdf = bytes.length > 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
    if (!isPdf) throw const ErpApiException(ErpErrorType.badResponse);
    return bytes;
  }

  Future<Map<String, dynamic>> _get(Uri uri) =>
      _send(uri, (headers) => _client.get(uri, headers: headers));

  /// ينفّذ الطلب ويفكّ ردّ JSON (مشترك بين GET و POST و PUT و DELETE).
  Future<Map<String, dynamic>> _send(
    Uri uri,
    Future<http.Response> Function(Map<String, String> headers) call,
  ) async {
    final response = await _execute(uri, call);
    try {
      // نفك الترميز بأنفسنا بـ UTF-8 حتى تصل الأسماء العربية سليمة
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException catch (e) {
      throw ErpApiException(ErpErrorType.badResponse, detail: e.message);
    }
    throw const ErpApiException(ErpErrorType.badResponse);
  }

  /// ينفّذ الطلب ويحوّل الأخطاء إلى [ErpApiException] ثم يعيد الردّ الناجح كما هو.
  Future<http.Response> _execute(
    Uri uri,
    Future<http.Response> Function(Map<String, String> headers) call,
  ) async {
    final sid = _session.sid;
    if (sid == null || sid.isEmpty) {
      throw const ErpApiException(ErpErrorType.sessionExpired);
    }

    final http.Response response;
    try {
      response = await call(_headers(sid)).timeout(ErpConfig.requestTimeout);
    } on TimeoutException {
      _lastNetworkFailure = DateTime.now();
      throw const ErpApiException(ErpErrorType.network, detail: 'timeout');
    } on SocketException catch (e) {
      _lastNetworkFailure = DateTime.now();
      throw ErpApiException(ErpErrorType.network, detail: e.message);
    } on http.ClientException catch (e) {
      _lastNetworkFailure = DateTime.now();
      throw ErpApiException(ErpErrorType.network, detail: e.message);
    }
    _lastNetworkFailure = null;

    final status = response.statusCode;
    if (status == 401 || status == 403) {
      throw await _denied(status, sid);
    }
    if (status == 404) {
      throw ErpApiException(ErpErrorType.notFound, statusCode: status);
    }
    if (status < 200 || status >= 300) {
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      debugPrint('ERP $status for $uri: $body');
      throw ErpApiException(
        ErpErrorType.server,
        statusCode: status,
        detail: _friendlyDetail(body),
      );
    }

    return response;
  }

  /// 403 يعني إما انتهاء الجلسة وإما عدم وجود صلاحية لهذا الإجراء، ولا يفرّق
  /// بينهما الرمز نفسه (ولا حقل session_expired في الرد). نسأل الخادم من هو المستخدم:
  /// Guest أو فشل السؤال = الجلسة انتهت، فنحذف الكوكي ونعود لشاشة الدخول.
  /// اسم مستخدم = مشكلة صلاحية حقيقية.
  Future<ErpApiException> _denied(int status, String sid) async {
    final expired = await (_sessionCheck ??=
        _isSessionExpired(sid).whenComplete(() => _sessionCheck = null));

    if (!expired) {
      return ErpApiException(ErpErrorType.forbidden, statusCode: status);
    }
    // لا نحذف جلسة أحدث إن سجّل المستخدم دخوله من جديد أثناء الفحص
    if (_session.sid == sid) {
      await _session.clear();
      onSessionExpired?.call();
    }
    return ErpApiException(ErpErrorType.sessionExpired, statusCode: status);
  }

  Future<bool> _isSessionExpired(String sid) async {
    try {
      final uri = Uri.parse(ErpConfig.baseUrl).replace(
        pathSegments: ['api', 'method', 'frappe.auth.get_logged_user'],
      );
      final response = await _client
          .get(uri, headers: _headers(sid))
          .timeout(ErpConfig.requestTimeout);
      if (response.statusCode != 200) return true;

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final user = body is Map ? body['message']?.toString() ?? '' : '';
      return user.isEmpty || user == 'Guest';
    } catch (_) {
      return true;
    }
  }

  /// يستخرج رسالة مقروءة من ردّ خطأ ERPNext (_server_messages أو exception)
  /// ليعرف المستخدم أي حقل ناقص، وإلا يعيد بداية النص كما هو.
  String _friendlyDetail(String body) {
    String strip(String html) => html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        final raw = json['_server_messages'];
        if (raw is String) {
          final list = jsonDecode(raw) as List;
          final messages = [
            for (final m in list)
              strip((jsonDecode(m as String) as Map)['message']?.toString() ?? ''),
          ].where((m) => m.isNotEmpty);
          if (messages.isNotEmpty) return messages.join(' | ');
        }
        final exception = json['exception'];
        if (exception is String && exception.isNotEmpty) {
          return strip(exception);
        }
      }
    } catch (_) {
      // الردّ ليس JSON بالصيغة المتوقعة: نعرض بدايته كما هي
    }
    return body.length > 300 ? body.substring(0, 300) : body;
  }
}
