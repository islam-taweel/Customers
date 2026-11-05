import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/visit_strings.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../visits/controllers/visits_controller.dart';
import '../../visits/screens/visits_screen.dart';
import '../../visits/widgets/visit_card.dart';

/// الرئيسية (أول شاشة بعد الدخول): جملة ترحيبية باسم المستخدم وتاريخ اليوم،
/// ثم مواعيد اليوم من ERPNext للعرض فقط (الإنشاء والتعديل والإلغاء من «كل المواعيد»).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TodayVisitsController>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(VisitStrings.home),
        actions: [
          IconButton(
            tooltip: VisitStrings.allVisits,
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () async {
              await Navigator.of(context).push(VisitsScreen.route(context));
              await c.load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: c.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _Greeting(count: c.loading ? null : c.activeCount),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    VisitStrings.todayTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context)
                        .push(VisitsScreen.route(context));
                    await c.load();
                  },
                  child: Text(VisitStrings.allVisits),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (c.loading && c.visits.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (c.error != null && c.visits.isEmpty)
              SizedBox(
                height: 260,
                child: ErrorView(message: c.error!, onRetry: c.load),
              )
            else if (c.visits.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(VisitStrings.noToday),
                  ],
                ),
              )
            else
              for (final v in c.visits) VisitCard(visit: v),
          ],
        ),
      ),
    );
  }
}

/// «صباح الخير / مساء الخير» واسم المستخدم وتاريخ اليوم وعدد مواعيده
class _Greeting extends StatelessWidget {
  final int? count;

  const _Greeting({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final name = context.select<AuthController, String?>((a) => a.fullName);
    final loc = MaterialLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            VisitStrings.greeting(now.hour),
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            VisitStrings.welcome(name),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.today_outlined, size: 18, color: scheme.onPrimary),
              const SizedBox(width: 6),
              Text(
                '${VisitStrings.weekday(now.weekday)}  ${loc.formatMediumDate(now)}',
                style: TextStyle(color: scheme.onPrimary),
              ),
            ],
          ),
          if (count != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event_note_outlined,
                    size: 18, color: scheme.onPrimary),
                const SizedBox(width: 6),
                Text(
                  VisitStrings.visitsToday(count!),
                  style: TextStyle(color: scheme.onPrimary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
