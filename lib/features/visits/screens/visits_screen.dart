import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/visit_strings.dart';
import '../../../core/widgets/error_view.dart';
import '../controllers/visits_controller.dart';
import '../widgets/month_calendar.dart';
import '../widgets/visit_card.dart';
import 'visit_form_screen.dart';

/// «كل المواعيد»: تقويم ثابت بالأعلى (نقطة خضراء على كل يوم فيه موعد)، وتحته
/// مواعيد اليوم المحدد فقط مع إجراءاتها (تعديل، إنجاز، إلغاء، حذف).
class VisitsScreen extends StatelessWidget {
  const VisitsScreen({super.key});

  static Route<void> route(BuildContext context) {
    final factory = context.read<VisitsControllerFactory>();
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<VisitsController>(
        create: (_) => factory.list(),
        child: const VisitsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<VisitsController>();
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final visits = c.dayVisits;

    Widget list;
    if (c.loading && visits.isEmpty) {
      list = const Center(child: CircularProgressIndicator());
    } else if (c.error != null) {
      list = ErrorView(message: c.error!, onRetry: c.load);
    } else if (visits.isEmpty) {
      list = RefreshIndicator(
        onRefresh: c.load,
        child: ListView(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.event_available_outlined,
              size: 44,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Center(child: Text(VisitStrings.noVisitsDay)),
          ],
        ),
      );
    } else {
      list = RefreshIndicator(
        onRefresh: c.load,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          itemCount: visits.length,
          itemBuilder: (_, i) => VisitCard(visit: visits[i], actions: c),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(VisitStrings.allVisits),
        actions: [
          IconButton(
            tooltip: VisitStrings.today,
            icon: const Icon(Icons.today_outlined),
            onPressed: () => c.selectDay(DateTime.now()),
          ),
          IconButton(
            tooltip: VisitStrings.showCancelled,
            isSelected: c.showCancelled,
            icon: const Icon(Icons.event_busy_outlined),
            selectedIcon: const Icon(Icons.event_busy),
            onPressed: () => c.setShowCancelled(!c.showCancelled),
          ),
        ],
        bottom: c.loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: Column(
        children: [
          // التقويم ثابت: لا يتمرر مع القائمة
          MonthCalendar(
            month: c.month,
            selected: c.selectedDay,
            busyDays: c.busyDays,
            onSelect: c.selectDay,
            onMonthChange: c.changeMonth,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${VisitStrings.weekday(c.selectedDay.weekday)}  ${loc.formatMediumDate(c.selectedDay)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (visits.isNotEmpty)
                  Text(
                    '${visits.length}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: MonthCalendar.dotColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: list),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (await openVisitForm(context, day: c.selectedDay)) await c.load();
        },
        icon: const Icon(Icons.add),
        label: Text(VisitStrings.newVisit),
      ),
    );
  }
}
