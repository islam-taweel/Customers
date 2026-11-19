import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/services/session_service.dart';
import '../../../data/api/erp_auth_service.dart';

/// حالة تسجيل الدخول في التطبيق كله: داخل أم لا، وأخطاء الدخول.
/// لا تحفظ كلمة المرور: تمرّرها للخدمة فقط.
///
/// (R1) محوّل لـ Provider فوق [SessionService]: نفس الواجهة العامة السابقة حتى
/// لا تتغير الشاشات القديمة التي تقرؤها عبر Provider. حالة الجلسة (داخل، الاسم،
/// انتهاء الجلسة) من الخدمة؛ عامل واحد يبلّغ المستمعين عند تغيّرها ويُلغى في
/// [dispose]. حالة نموذج الدخول هنا للتوافق فقط: شاشة الدخول تستخدم LoginController.
class AuthController extends ChangeNotifier {
  AuthController(this._session) {
    _worker = everAll([
      _session.isAuthenticated,
      _session.fullName,
      _session.sessionExpired,
    ], (_) => _notify());
  }

  final SessionService _session;
  late final Worker _worker;

  bool _busy = false;
  AuthFailure? _failure;
  int _failedAttempts = 0;
  bool _disposed = false;

  /// بعد هذا العدد من المحاولات الخاطئة المتتالية نحذّر من قفل الحساب
  static const int lockWarningAfter = 3;

  bool get isAuthenticated => _session.isAuthenticated.value;
  bool get isBusy => _busy;
  AuthFailure? get failure => _failure;

  /// انتهت الجلسة (يعرض شاشة الدخول تنبيهًا بذلك)
  bool get sessionExpired => _session.sessionExpired.value;
  int get failedAttempts => _failedAttempts;
  String? get fullName => _session.fullName.value;

  Future<void> login(String email, String password) async {
    if (_busy) return;
    _busy = true;
    _failure = null;
    _notify();

    try {
      await _session.login(email: email.trim(), password: password);
      _failedAttempts = 0;
    } on AuthException catch (e) {
      _failure = e.failure;
      if (e.failure == AuthFailure.invalidCredentials) _failedAttempts++;
    } catch (e) {
      debugPrint('AuthController.login failed: ${e.runtimeType}');
      _failure = AuthFailure.server;
    }

    _busy = false;
    _notify();
  }

  Future<void> logout() async {
    if (!isAuthenticated) return;
    await _session.logout();
    _failure = null;
    _failedAttempts = 0;
    _notify();
  }

  /// يمرّر إلى [SessionService.handleSessionExpired] (الجلسة حُذفت أصلًا).
  void handleSessionExpired() => _session.handleSessionExpired();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _worker.dispose();
    super.dispose();
  }
}
