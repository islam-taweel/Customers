import 'package:customer/app/middleware/auth_middleware.dart';
import 'package:customer/app/routes/app_routes.dart';
import 'package:customer/app/services/session_service.dart';
import 'package:customer/data/api/erp_auth_service.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> registerSession(Map<String, String> saved) async {
    FlutterSecureStorage.setMockInitialValues(saved);
    final store = SessionStore();
    final session = SessionService(store, ErpAuthService(store));
    await session.init();
    Get.put<SessionService>(session);
  }

  tearDown(Get.reset);

  test('بلا جلسة: /home يُحوَّل إلى الدخول، و/login مسموح', () async {
    await registerSession({});
    expect(AuthMiddleware().redirect(Routes.home)?.name, Routes.login);
    expect(GuestMiddleware().redirect(Routes.login), isNull);
  });

  test('مع جلسة: /home مسموح، و/login يُحوَّل إلى البوابة', () async {
    await registerSession({'erp_session_sid': 'abc'});
    expect(AuthMiddleware().redirect(Routes.home), isNull);
    expect(GuestMiddleware().redirect(Routes.login)?.name, Routes.gate);
  });
}
