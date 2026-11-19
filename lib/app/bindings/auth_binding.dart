import 'package:get/get.dart';

import '../../features/auth/controllers/login_controller.dart';
import '../services/session_service.dart';

/// متحكم شاشة الدخول: يُسجَّل كدالة إنشاء فقط (lazyPut)، فلا يُنشأ إن كانت
/// الجلسة صالحة ولم تُعرض شاشة الدخول. fenix: يُعاد إنشاؤه إن حُذف مساره.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(Get.find<SessionService>()),
      fenix: true,
    );
  }
}
