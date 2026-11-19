import 'dart:convert';

import 'package:customer/app/services/session_service.dart';
import 'package:customer/data/api/erp_auth_service.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// تخزين آمن يعدّ مرات القراءة (للتحقق من أن الجلسة تُحمَّل مرة واحدة)
class _CountingStorage extends FlutterSecureStorage {
  int reads = 0;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    reads++;
    return super.read(key: key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// ردود الخادم: الدخول [loginStatus]، والخروج ينجح أو يفشل اتصاله
  MockClient server({int loginStatus = 200, bool logoutFails = false}) =>
      MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/login')) {
          if (loginStatus != 200) return http.Response('{}', loginStatus);
          return http.Response(
            jsonEncode({'message': 'Logged In', 'full_name': 'Ahmad'}),
            200,
            headers: {'set-cookie': 'sid=xyz; Path=/; HttpOnly'},
          );
        }
        if (path.endsWith('/logout')) {
          if (logoutFails) throw http.ClientException('offline');
          return http.Response('{}', 200);
        }
        return http.Response('{}', 404);
      });

  Future<SessionService> service(
    Map<String, String> saved, {
    MockClient? client,
  }) async {
    FlutterSecureStorage.setMockInitialValues(saved);
    final store = SessionStore();
    final s = SessionService(store, ErpAuthService(store, client: client));
    await s.init();
    return s;
  }

  test('استعادة الجلسة المحفوظة عند البدء', () async {
    final s = await service({
      'erp_session_sid': 'abc',
      'erp_session_full_name': 'Ahmad',
    });
    expect(s.isAuthenticated.value, isTrue);
    expect(s.fullName.value, 'Ahmad');
    expect(s.store.sid, 'abc');
    expect(s.sessionExpired.value, isFalse);
  });

  test('init تحمّل الجلسة مرة واحدة فقط', () async {
    FlutterSecureStorage.setMockInitialValues({'erp_session_sid': 'abc'});
    final storage = _CountingStorage();
    final store = SessionStore(storage: storage);
    final s = SessionService(store, ErpAuthService(store));
    await Future.wait([s.init(), s.init()]);
    await s.init();
    // load() يقرأ مفتاحين (sid والاسم): قراءة واحدة لكل منهما
    expect(storage.reads, 2);
    expect(s.isAuthenticated.value, isTrue);
  });

  test('دخول ناجح يحفظ الجلسة ويحدّث الحالة', () async {
    final s = await service({}, client: server());
    expect(s.isAuthenticated.value, isFalse);

    await s.login(email: 'ahmad@rtc.ps', password: 'secret');

    expect(s.store.sid, 'xyz');
    expect(s.isAuthenticated.value, isTrue);
    expect(s.fullName.value, 'Ahmad');
    expect(s.sessionExpired.value, isFalse);
  });

  test('فشل الدخول (401) يرمي invalidCredentials ولا ينشئ جلسة', () async {
    final s = await service({}, client: server(loginStatus: 401));

    await expectLater(
      s.login(email: 'ahmad@rtc.ps', password: 'wrong'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.invalidCredentials,
        ),
      ),
    );
    expect(s.store.sid, isNull);
    expect(s.isAuthenticated.value, isFalse);
  });

  test('الخروج يحذف الجلسة حتى عند فشل طلب الخادم', () async {
    final s = await service({
      'erp_session_sid': 'abc',
      'erp_session_full_name': 'Ahmad',
    }, client: server(logoutFails: true));

    await s.logout();

    expect(s.store.sid, isNull);
    expect(s.isAuthenticated.value, isFalse);
    expect(s.fullName.value, isNull);
  });

  test('انتهاء الجلسة المتكرر يُطبَّق مرة واحدة', () async {
    final s = await service({'erp_session_sid': 'abc'});
    var changes = 0;
    final worker = ever<bool>(s.isAuthenticated, (_) => changes++);

    // ErpApiClient يحذف الجلسة قبل أن يستدعي handleSessionExpired
    await s.store.clear();
    s.handleSessionExpired();
    s.handleSessionExpired();
    s.handleSessionExpired();

    expect(s.isAuthenticated.value, isFalse);
    expect(s.sessionExpired.value, isTrue);
    expect(changes, 1);
    worker.dispose();
  });

  test('الدخول بعد انتهاء الجلسة يزيل تنبيه الانتهاء', () async {
    final s = await service({'erp_session_sid': 'abc'}, client: server());
    await s.store.clear();
    s.handleSessionExpired();
    expect(s.sessionExpired.value, isTrue);

    await s.login(email: 'ahmad@rtc.ps', password: 'secret');

    expect(s.sessionExpired.value, isFalse);
    expect(s.isAuthenticated.value, isTrue);
  });
}
