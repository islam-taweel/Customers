import 'package:flutter/material.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/constants/visit_strings.dart';

/// الشهر والسنة: قائمتان منسدلتان مع سهمين للشهر السابق والتالي
class MonthYearPicker extends StatelessWidget {
  final int year;
  final int month;
  final void Function(int year, int month) onChanged;

  const MonthYearPicker({
    super.key,
    required this.year,
    required this.month,
    required this.onChanged,
  });

  void _shift(int delta) {
    final d = DateTime(year, month + delta);
    onChanged(d.year, d.month);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final now = DateTime.now();
    final isCurrent = year == now.year && month == now.month;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: VisitStrings.previousMonth,
            onPressed: () => _shift(-1),
            icon: Icon(rtl ? Icons.chevron_right : Icons.chevron_left),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              key: ValueKey('m$year-$month'),
              initialValue: month,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: EssStrings.month,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(
                    value: m,
                    // لا أشهر في المستقبل
                    enabled: !(year == now.year && m > now.month),
                    child: Text(EssStrings.monthName(m)),
                  ),
              ],
              onChanged: (m) => m == null ? null : onChanged(year, m),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              key: ValueKey('y$year-$month'),
              initialValue: year,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: EssStrings.year,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (var y = now.year; y >= now.year - 5; y--)
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (y) {
                if (y == null) return;
                // سنة حالية مع شهر لم يأتِ بعد: الشهر الحالي
                final m = (y == now.year && month > now.month) ? now.month : month;
                onChanged(y, m);
              },
            ),
          ),
          IconButton(
            tooltip: VisitStrings.nextMonth,
            onPressed: isCurrent ? null : () => _shift(1),
            icon: Icon(rtl ? Icons.chevron_left : Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
