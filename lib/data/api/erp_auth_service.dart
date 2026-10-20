import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'erp_config.dart';
import 'session_store.dart';

/// سبب فشل تسجيل الدخول، لتعرض الشاشة رسالة مناسبة لكل سبب.
enum AuthFailure {
  /// 401: البريد أو كلمة المرور خطأ
  invalidCredentials,

  /// تعذّر الوصول للخادم
  network,

  /// ردّ الخادم بخطأ غير متوقع
  server,
}

class AuthException implements Exception {
  final AuthFailure failure;

  const AuthException(this.failure);

  @override
  String toString() => 'AuthException($failure)';
}

/// تسجيل الدخول والخروج في ERPNext بحساب المستخدم نفسه (بدل المفتاح المشترك).
///
/// الدخول: POST /api/method/login ثم نقرأ `sid` من ترويسة Set-Cookie ونحفظه.
/// الخروج: GET /api/method/logout ثم نحذف الكوكي المحفوظ.
class ErpAuthService {
  ErpAuthService(this._session, {http.Client? client})
      : _client = client ?? http.Client();

  final SessionStore _session;
  final http.Client _client;

  Uri _uri(String method) => Uri.parse(ErpConfig.baseUrl).replace(
        pathSegments: ['api', 'method', method],
      );

  /// ترمي [AuthException] عند الفشل. لا تعيد المحاولة تلقائيًا أبدًا:
  /// تكرار 401 يقفل الحساب مؤقتًا في ERPNext.
  Future<void> login({required String email, required String password}) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            _uri('login'),
            headers: {
              'Host': ErpConfig.hostHeader,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'usr': email, 'pwd': password}),
          )
          .timeout(ErpConfig.requestTimeout);
    } on TimeoutException {
      throw const AuthException(AuthFailure.network);
    } on SocketException {
      throw const AuthException(AuthFailure.network);
    } on http.ClientException {
      throw const AuthException(AuthFailure.network);
    }

    // لا نطبع الرد ولا الطلب: فيهما بيانات الدخول
    debugPrint('ERP login status: ${response.statusCode}');

    if (response.statusCode == 401) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }
    if (response.statusCode != 200) {
      throw const AuthException(AuthFailure.server);
    }

    final sid = _extractSid(response.headers['set-cookie']);
    if (sid == null) throw const AuthException(AuthFailure.server);

    await _session.save(sid: sid, fullName: _fullNameOf(response));
  }

  /// يخرج من الخادم (إن تيسّر الاتصال) ثم يحذف الكوكي دائمًا،
  /// فلا يبقى المستخدم داخل التطبيق لو فشل الاتصال.
  Future<void> logout() async {
    final sid = _session.sid;
    try {
      if (sid != null && sid.isNotEmpty) {
        await _client.get(
          _uri('logout'),
          headers: {
            'Cookie': 'sid=$sid',
            'Host': ErpConfig.hostHeader,
            'Accept': 'application/json',
          },
        ).timeout(ErpConfig.requestTimeout);
      }
    } catch (e) {
      debugPrint('ERP logout request failed: $e');
    } finally {
      await _session.clear();
    }
  }

  /// ردّ الدخول يحمل عدة كوكيز (sid, full_name, user_id...) ويدمجها حزمة http
  /// في سلسلة واحدة مفصولة بفواصل، فنستخرج sid بتعبير نمطي.
  /// القيمة Guest تعني جلسة غير مسجّلة فنتجاهلها.
  static final RegExp _sidPattern = RegExp(r'(?:^|[\s,;])sid=([^;,\s]+)');

  String? _extractSid(String? setCookie) {
    if (setCookie == null) return null;
    final value = _sidPattern.firstMatch(setCookie)?.group(1);
    if (value == null || value.isEmpty || value == 'Guest') return null;
    return value;
  }

  String? _fullNameOf(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) {
        final name = body['full_name']?.toString().trim();
        if (name != null && name.isNotEmpty) return name;
      }
    } catch (_) {
      // الاسم للعرض فقط: غيابه لا يمنع الدخول
    }
    return null;
  }
}
