import 'package:customer/app/services/session_service.dart';
import 'package:customer/data/api/erp_auth_service.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:customer/features/auth/controllers/auth_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// AuthController (محوّل Provider) يعكس SessionService بنفس واجهته القديمة،
/// ويبلّغ المستمعين عند تغيّر الجلسة، ولا يبقى له أثر بعد dispose.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionService session;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'erp_session_sid': 'abc',
      'erp_session_full_name': 'Ahmad',
    });
    final store = SessionStore();
    session = SessionService(store, ErpAuthService(store));
    await session.init();
  });

  test('القيم القديمة تطابق الخدمة', () {
    final auth = AuthController(session);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.fullName, 'Ahmad');
    expect(auth.sessionExpired, isFalse);
    expect(auth.failedAttempts, 0);
    expect(AuthController.lockWarningAfter, 3);
    auth.dispose();
  });

  test('انتهاء الجلسة يبلّغ مستمعي Provider', () async {
    final auth = AuthController(session);
    var notified = 0;
    auth.addListener(() => notified++);

    await session.store.clear();
    session.handleSessionExpired();

    expect(notified, greaterThan(0));
    expect(auth.isAuthenticated, isFalse);
    expect(auth.sessionExpired, isTrue);
    auth.dispose();
  });

  test('بعد dispose لا إبلاغ ولا خطأ عند تغيّر الخدمة', () async {
    final auth = AuthController(session);
    var notified = 0;
    auth.addListener(() => notified++);
    auth.dispose();

    await session.store.clear();
    session.handleSessionExpired();

    expect(notified, 0);
  });
}
