import 'dart:convert';

import 'package:customer/data/api/erp_api_client.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// يثبّت سلوك الجلسة الحالي في ErpApiClient قبل إعادة الهيكلة (R1):
/// انتهاء الجلسة المتزامن يحذفها مرة واحدة، و403 الصلاحية لا يُخرج المستخدم.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore store;
  late int checks;
  late int expiredCalls;

  /// الطلبات العادية ترجع [status]، وفحص get_logged_user يرجع [loggedUser]
  /// بعد تأخير قصير حتى تصل كل الطلبات المرفوضة أثناء الفحص.
  ErpApiClient clientWith({required int status, required String loggedUser}) {
    final mock = MockClient((request) async {
      if (request.url.path.contains('frappe.auth.get_logged_user')) {
        checks++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(jsonEncode({'message': loggedUser}), 200);
      }
      return http.Response('{}', status);
    });
    final api = ErpApiClient(session: store, client: mock);
    api.onSessionExpired = () => expiredCalls++;
    return api;
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'erp_session_sid': 'abc',
      'erp_session_full_name': 'Ahmad',
    });
    store = SessionStore();
    await store.load();
    checks = 0;
    expiredCalls = 0;
  });

  for (final status in [401, 403]) {
    test('$status متزامن بعد انتهاء الجلسة: فحص واحد وخروج واحد', () async {
      final api = clientWith(status: status, loggedUser: 'Guest');

      final results = await Future.wait([
        for (var i = 0; i < 3; i++)
          api
              .getDoc('Customer', 'C-$i')
              .then<Object?>((_) => null, onError: (Object e) => e),
      ]);

      expect(checks, 1, reason: 'الطلبات المرفوضة معًا تنتظر فحصًا واحدًا');
      expect(expiredCalls, 1, reason: 'onSessionExpired يُستدعى مرة واحدة');
      expect(store.sid, isNull, reason: 'الجلسة تُحذف');
      for (final r in results) {
        expect(r, isA<ErpApiException>());
        expect((r as ErpApiException).type, ErpErrorType.sessionExpired);
      }
    });
  }

  test('403 صلاحية بمستخدم حقيقي: لا خروج ولا مسح للجلسة', () async {
    final api = clientWith(status: 403, loggedUser: 'ahmad@rtc.ps');

    await expectLater(
      api.getDoc('Customer', 'C-1'),
      throwsA(
        isA<ErpApiException>().having(
          (e) => e.type,
          'type',
          ErpErrorType.forbidden,
        ),
      ),
    );
    expect(expiredCalls, 0);
    expect(store.sid, 'abc');
    expect(store.hasSession, isTrue);
  });
}
