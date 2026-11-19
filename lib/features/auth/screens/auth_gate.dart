import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../home/screens/main_shell.dart';
import '../../../app/services/session_service.dart';
import 'login_screen.dart';

/// بوابة التطبيق: مسجَّل الدخول ← الرئيسية (مع الشريط السفلي)، وإلا ← شاشة الدخول.
/// تبدّل بينهما تلقائيًا عند الدخول أو الخروج أو انتهاء الجلسة.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();

    return Obx(() {
      final isAuthenticated = session.isAuthenticated.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: isAuthenticated
            ? const MainShell(key: ValueKey('shell'))
            : const LoginScreen(key: ValueKey('login')),
      );
    });
  }
}
