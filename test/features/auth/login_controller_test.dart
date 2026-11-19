import 'dart:convert';

import 'package:customer/app/bindings/auth_binding.dart';
import 'package:customer/app/services/session_service.dart';
import 'package:customer/data/api/erp_auth_service.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:customer/features/auth/controllers/login_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LoginController يطابق منطق AuthController السابق: العدّاد، تحذير القفل،
/// الانشغال، ويُنشأ فقط عند الطلب.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// ردود الدخول بالترتيب: 'ok' أو 'wrong' (401) أو 'offline' (خطأ اتصال)
  late List<String> replies;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    replies = [];
    final store = SessionStore();
    final client = MockClient((request) async {
      final next = replies.removeAt(0);
      if (next == 'offline') throw http.ClientException('offline');
      if (next == 'wrong') return http.Response('{}', 401);
      return http.Response(
        jsonEncode({'full_name': 'Ahmad'}),
        200,
        headers: {'set-cookie': 'sid=xyz; Path=/'},
      );
    });
    final session = SessionService(
      store,
      ErpAuthService(store, client: client),
    );
    await session.init();
    Get.put<SessionService>(session, permanent: true);
    AuthBinding().dependencies();
  });

  tearDown(Get.reset);

  Future<void> attempt(LoginController c) => c.submit(
    target: 'http://158.158.74.163',
    email: 'ahmad@rtc.ps',
    password: 'x',
  );

  test('lazyPut: مسجّل كدالة إنشاء ولا يُنشأ قبل الطلب', () {
    expect(Get.isPrepared<LoginController>(), isTrue);
    Get.find<LoginController>();
    expect(Get.isPrepared<LoginController>(), isFalse);
  });

  test('محاولتان خاطئتان بلا تحذير، والثالثة تُظهر تحذير القفل', () async {
    final c = Get.find<LoginController>();
    replies = ['wrong', 'wrong', 'wrong'];

    await attempt(c);
    await attempt(c);
    expect(c.failedAttempts.value, 2);
    expect(c.failure.value, AuthFailure.invalidCredentials);
    expect(c.showLockWarning, isFalse);

    await attempt(c);
    expect(c.failedAttempts.value, LoginController.lockWarningAfter);
    expect(c.showLockWarning, isTrue);
  });

  test('خطأ الاتصال لا يزيد العدّاد، والنجاح يصفّره', () async {
    final c = Get.find<LoginController>();
    replies = ['wrong', 'offline', 'ok'];

    await attempt(c);
    await attempt(c);
    expect(c.failedAttempts.value, 1);
    expect(c.failure.value, AuthFailure.network);

    await attempt(c);
    expect(c.failedAttempts.value, 0);
    expect(c.failure.value, isNull);
    expect(c.isAuthenticated, isTrue);
    expect(c.isBusy.value, isFalse);
  });

  test('fenix: بعد حذف المتحكم يُعاد إنشاؤه من صفر بلا خطأ', () async {
    final c = Get.find<LoginController>();
    replies = ['wrong'];
    await attempt(c);
    expect(c.failedAttempts.value, 1);

    Get.delete<LoginController>();
    final again = Get.find<LoginController>();
    expect(identical(again, c), isFalse);
    expect(again.failedAttempts.value, 0);
  });
}
