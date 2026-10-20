import 'package:flutter/foundation.dart';

import '../../../data/api/erp_auth_service.dart';
import '../../../data/api/session_store.dart';

/// حالة تسجيل الدخول في التطبيق كله: داخل أم لا، وأخطاء الدخول.
/// لا تحفظ كلمة المرور: تمرّرها للخدمة فقط.
class AuthController extends ChangeNotifier {
  AuthController(this._service, this._session)
      : _authenticated = _session.hasSession;

  final ErpAuthService _service;
  final SessionStore _session;

  bool _authenticated;
  bool _busy = false;
  AuthFailure? _failure;
  bool _sessionExpired = false;
  int _failedAttempts = 0;
  bool _disposed = false;

  /// بعد هذا العدد من المحاولات الخاطئة المتتالية نحذّر من قفل الحساب
  static const int lockWarningAfter = 3;

  bool get isAuthenticated => _authenticated;
  bool get isBusy => _busy;
  AuthFailure? get failure => _failure;

  /// انتهت الجلسة (يعرض شاشة الدخول تنبيهًا بذلك)
  bool get sessionExpired => _sessionExpired;
  int get failedAttempts => _failedAttempts;
  String? get fullName => _session.fullName;

  Future<void> login(String email, String password) async {
    if (_busy) return;
    _busy = true;
    _failure = null;
    _sessionExpired = false;
    _notify();

    try {
      await _service.login(email: email.trim(), password: password);
      _authenticated = true;
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
    if (!_authenticated) return;
    await _service.logout();
    _authenticated = false;
    _failure = null;
    _sessionExpired = false;
    _failedAttempts = 0;
    _notify();
  }

  /// يستدعيه عميل الـ API حين يتأكد أن الجلسة انتهت (الكوكي حُذف أصلًا).
  void handleSessionExpired() {
    if (!_authenticated) return;
    _authenticated = false;
    _failure = null;
    _sessionExpired = true;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
