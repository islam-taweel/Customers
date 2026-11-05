import 'package:flutter/material.dart';

import '../../../core/constants/visit_strings.dart';

/// تقويم شهر: أسهم للشهر السابق والتالي، أسماء الأيام حسب لغة التطبيق،
/// ونقطة خضراء تحت كل يوم فيه موعد. اليوم المحدد مملوء، واليوم الحالي بإطار.
class MonthCalendar extends StatelessWidget {
  /// أول يوم في الشهر المعروض
  final DateTime month;
  final DateTime selected;

  /// الأيام التي فيها موعد (تاريخ بلا وقت)
  final Set<DateTime> busyDays;
  final ValueChanged<DateTime> onSelect;

  /// ‎-1 الشهر السابق، ‎+1 التالي
  final ValueChanged<int> onMonthChange;

  static const dotColor = Color(0xFF2E7D32);

  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.busyDays,
    required this.onSelect,
    required this.onMonthChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // narrowWeekdays يبدأ بالأحد؛ أول عمود حسب اللغة
    final first = loc.firstDayOfWeekIndex;
    final names = [for (var i = 0; i < 7; i++) loc.narrowWeekdays[(first + i) % 7]];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = (month.weekday % 7 - first + 7) % 7;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    Widget day(int index) {
      final n = index - leading + 1;
      if (n < 1 || n > daysInMonth) return const SizedBox.shrink();
      final date = DateTime(month.year, month.month, n);
      final isSelected = date == selected;
      final isToday = date == today;
      final busy = busyDays.contains(date);
      return InkWell(
        onTap: () => onSelect(date),
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? scheme.primary : null,
                border: isToday && !isSelected
                    ? Border.all(color: scheme.primary, width: 1.5)
                    : null,
              ),
              child: Text(
                '$n',
                style: TextStyle(
                  fontWeight:
                      isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: busy ? dotColor : Colors.transparent,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: VisitStrings.previousMonth,
                onPressed: () => onMonthChange(-1),
                icon: Icon(rtl ? Icons.chevron_right : Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  loc.formatMonthYear(month),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: VisitStrings.nextMonth,
                onPressed: () => onMonthChange(1),
                icon: Icon(rtl ? Icons.chevron_left : Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final name in names)
                Expanded(
                  child: Center(
                    child: Text(
                      name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < rows; r++)
            SizedBox(
              height: 46,
              child: Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(child: day(r * 7 + c)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
