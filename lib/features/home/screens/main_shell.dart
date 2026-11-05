import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/visit_strings.dart';
import '../../customers/screens/customer_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../visits/controllers/visits_controller.dart';
import 'home_screen.dart';

/// تبويبات الشريط السفلي بترتيبها (الرئيسية في الوسط).
enum ShellTab { dashboard, home, settings }

/// الهيكل بعد الدخول: شريط سفلي فيه لوحة التحكم (العملاء) والرئيسية في الوسط
/// والإعدادات. يبدأ دائمًا من الرئيسية، وكل تبويب يحتفظ بحالته عند التنقل.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// يبدّل التبويب من أي شاشة داخل الهيكل (مثل القائمة الجانبية).
  /// يعيد false إن لم تكن الشاشة داخل الهيكل.
  static bool select(BuildContext context, ShellTab tab) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    state?._select(tab);
    return state != null;
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  ShellTab _tab = ShellTab.home;
  late final TodayVisitsController _today =
      context.read<VisitsControllerFactory>().today();

  @override
  void dispose() {
    _today.dispose();
    super.dispose();
  }

  void _select(ShellTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    // مواعيد اليوم قد تغيّرت أثناء الغياب عن الرئيسية
    if (tab == ShellTab.home) _today.load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TodayVisitsController>.value(
      value: _today,
      child: Scaffold(
        body: IndexedStack(
          index: _tab.index,
          children: const [
            CustomersScreen(),
            HomeScreen(),
            SettingsScreen(inShell: true),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (i) => _select(ShellTab.values[i]),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: VisitStrings.dashboard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: VisitStrings.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: VisitStrings.settings,
            ),
          ],
        ),
      ),
    );
  }
}
