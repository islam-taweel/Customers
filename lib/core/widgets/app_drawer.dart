import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../localization/language_controller.dart';

/// القائمة الجانبية: الشعار بالأعلى، زر لوحة التحكم، ومبدّل اللغة بالأسفل.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const _logoAsset = 'assets/splash/logo.png';

  void _openDashboard(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop(); // إغلاق القائمة
    // لوحة التحكم = شاشة العملاء (أول شاشة في التطبيق)
    navigator.popUntil((route) => route.isFirst);
  }

  void _changeLanguage(BuildContext context, AppLanguage language) {
    final controller = context.read<LanguageController>();
    if (controller.language == language) return;
    Navigator.of(context).pop();
    // ننتظر انتهاء حركة إغلاق القائمة حتى لا تقفز لجهة الاتجاه الجديد
    Future.delayed(
      const Duration(milliseconds: 260),
      () => controller.setLanguage(language),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LanguageController>().language;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) الشعار في الأعلى بالمنتصف
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Image.asset(
                  _logoAsset,
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // 2) لوحة التحكم (= شاشة العملاء)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                selected: true,
                selectedTileColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.dashboard_outlined),
                title: Text(AppStrings.dashboard),
                onTap: () => _openDashboard(context),
              ),
            ),

            const Spacer(),

            // 3) زرّان متلاصقان للتبديل بين العربية والإنجليزية
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<AppLanguage>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: AppLanguage.arabic,
                    label: Text('العربية'),
                  ),
                  ButtonSegment(
                    value: AppLanguage.english,
                    label: Text('English'),
                  ),
                ],
                selected: {current},
                onSelectionChanged: (s) => _changeLanguage(context, s.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
