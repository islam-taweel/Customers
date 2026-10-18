import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'erp_config.dart';

/// أنواع الأخطاء التي تفرّق بينها الواجهة لتعرض رسالة مناسبة لكل نوع.
enum ErpErrorType {
  /// لم تُمرَّر مفاتيح API وقت التشغيل
  missingCredentials,

  /// رفض الخادم المفاتيح (401 / 403)
  unauthorized,

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
  ErpApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// حد أمان لحلقة جلب الصفحات حتى لا تدور بلا نهاية عند خلل في الخادم
  static const int _maxPages = 500;

  Map<String, String> get _headers => {
        'Authorization': 'token ${ErpConfig.apiKey}:${ErpConfig.apiSecret}',
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
    int limitStart = 0,
    int limitPageLength = ErpConfig.pageSize,
  }) async {
    final uri = _uri([doctype], {
      'fields': jsonEncode(fields),
      if (filters != null) 'filters': jsonEncode(filters),
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
  }) async {
    final all = <Map<String, dynamic>>[];
    var start = 0;

    for (var page = 0; page < _maxPages; page++) {
      final rows = await getList(
        doctype,
        fields: fields,
        filters: filters,
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

  Future<Map<String, dynamic>> _get(Uri uri) async {
    if (!ErpConfig.hasCredentials) {
      throw const ErpApiException(ErpErrorType.missingCredentials);
    }

    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers)
          .timeout(ErpConfig.requestTimeout);
    } on TimeoutException {
      throw const ErpApiException(ErpErrorType.network, detail: 'timeout');
    } on SocketException catch (e) {
      throw ErpApiException(ErpErrorType.network, detail: e.message);
    } on http.ClientException catch (e) {
      throw ErpApiException(ErpErrorType.network, detail: e.message);
    }

    final status = response.statusCode;
    if (status == 401 || status == 403) {
      throw ErpApiException(ErpErrorType.unauthorized, statusCode: status);
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
        detail: body.length > 200 ? body.substring(0, 200) : body,
      );
    }

    try {
      // نفك الترميز بأنفسنا بـ UTF-8 حتى تصل الأسماء العربية سليمة
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException catch (e) {
      throw ErpApiException(ErpErrorType.badResponse, detail: e.message);
    }
    throw const ErpApiException(ErpErrorType.badResponse);
  }
}
