import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/services/session_service.dart';
import '../../../data/api/erp_auth_service.dart';
import '../../../data/api/erp_config.dart';

/// نموذج تسجيل الدخول (GetX): الانشغال، سبب الفشل، وعدد المحاولات الخاطئة
/// المتتالية. نفس منطق AuthController السابق حرفيًا؛ الجلسة نفسها في [SessionService].
///
/// يُسجَّل بـ lazyPut في AuthBinding ولا يُنشأ إلا حين تحتاجه شاشة الدخول.
class LoginController extends GetxController {
  LoginController(this._session);

  final SessionService _session;

  /// بعد هذا العدد من المحاولات الخاطئة المتتالية نحذّر من قفل الحساب
  static const int lockWarningAfter = 3;

  final isBusy = false.obs;
  final failure = Rxn<AuthFailure>();
  final failedAttempts = 0.obs;

  bool get isAuthenticated => _session.isAuthenticated.value;

  /// انتهت الجلسة (تعرض الشاشة تنبيهًا بذلك)
  bool get sessionExpired => _session.sessionExpired.value;

  /// تحذير قفل الحساب بعد محاولات خاطئة متتالية
  bool get showLockWarning =>
      failure.value == AuthFailure.invalidCredentials &&
      failedAttempts.value >= lockWarningAfter;

  /// يضبط الموقع ثم يدخل. لا يرمي: النتيجة في [failure] و [isAuthenticated].
  Future<void> submit({
    required String target,
    required String email,
    required String password,
  }) async {
    if (isBusy.value) return;
    // يجب ضبط الموقع قبل الدخول: اسم الموقع يحدد أي موقع يتصل به الطلب
    await ErpConfig.setTarget(target);

    isBusy.value = true;
    failure.value = null;
    try {
      await _session.login(email: email.trim(), password: password);
      failedAttempts.value = 0;
    } on AuthException catch (e) {
      failure.value = e.failure;
      if (e.failure == AuthFailure.invalidCredentials) failedAttempts.value++;
    } catch (e) {
      debugPrint('LoginController.submit failed: ${e.runtimeType}');
      failure.value = AuthFailure.server;
    }
    isBusy.value = false;
  }
}
