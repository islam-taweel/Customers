import 'package:get/get.dart';

import '../../features/auth/screens/auth_gate.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../bindings/auth_binding.dart';
import '../middleware/auth_middleware.dart';
import 'app_routes.dart';

/// صفحات المسارات المسماة (R1). البوابة هي المسار الجذري ومرجع حالة الدخول.
abstract class AppPages {
  AppPages._();

  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: Routes.gate,
      page: () => const AuthGate(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: Routes.home,
      page: () => const MainShell(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
