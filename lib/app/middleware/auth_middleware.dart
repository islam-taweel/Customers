import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../services/session_service.dart';

/// مسار يحتاج جلسة: بلا جلسة يُحوَّل إلى الدخول.
///
/// يعمل عند التنقل بالاسم فقط. انتهاء الجلسة أثناء طلب API تعالجه البوابة
/// (AuthGate) لا هذا الـ Middleware.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<SessionService>().isAuthenticated.value
      ? null
      : const RouteSettings(name: Routes.login);
}

/// مسار للضيف (الدخول): مع جلسة قائمة يُحوَّل إلى البوابة.
class GuestMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<SessionService>().isAuthenticated.value
      ? const RouteSettings(name: Routes.gate)
      : null;
}
