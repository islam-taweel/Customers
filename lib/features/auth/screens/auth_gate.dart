import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../customers/screens/customer_screen.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

/// بوابة التطبيق: مسجَّل الدخول ← شاشة العملاء، وإلا ← شاشة الدخول.
/// تبدّل بينهما تلقائيًا عند الدخول أو الخروج أو انتهاء الجلسة.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthController, bool>(
      (auth) => auth.isAuthenticated,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: isAuthenticated
          ? const CustomersScreen(key: ValueKey('customers'))
          : const LoginScreen(key: ValueKey('login')),
    );
  }
}
