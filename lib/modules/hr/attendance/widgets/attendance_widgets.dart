import 'package:flutter/material.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../../../core/constants/visit_strings.dart';
import '../models/attendance_models.dart';

/// (R5) أجزاء عرض «حضوري» نُقلت كما هي من AttendanceLogScreen.

/// لون وأيقونة واسم كل حالة حضور
(Color, IconData, String) statusStyle(AttendanceStatus s, ColorScheme scheme) =>
    switch (s) {
      AttendanceStatus.present => (
        const Color(0xFF2E7D32),
        Icons.check_circle_outline,
        EssStrings.statusPresent,
      ),
      AttendanceStatus.absent => (
        scheme.error,
        Icons.cancel_outlined,
        EssStrings.statusAbsent,
      ),
      AttendanceStatus.halfDay => (
        const Color(0xFFEF6C00),
        Icons.timelapse,
        EssStrings.statusHalfDay,
      ),
      AttendanceStatus.onLeave => (
        const Color(0xFF1565C0),
        Icons.beach_access_outlined,
        EssStrings.statusOnLeave,
      ),
      AttendanceStatus.workFromHome => (
        const Color(0xFF00838F),
        Icons.home_work_outlined,
        EssStrings.statusWorkFromHome,
      ),
    };

/// ملخص الشهر في أربع بطاقات
class SummaryGrid extends StatelessWidget {
  final AttendanceSummary summary;

  const SummaryGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String days(double d) =>
        d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);

    final tiles = [
      SummaryTile(
        icon: Icons.check_circle_outline,
        color: const Color(0xFF2E7D32),
        label: EssStrings.presentDays,
        value: days(summary.presentDays),
      ),
      SummaryTile(
        icon: Icons.cancel_outlined,
        color: scheme.error,
        label: EssStrings.absentDays,
        value: '${summary.absentDays}',
      ),
      SummaryTile(
        icon: Icons.alarm,
        color: const Color(0xFFEF6C00),
        label: EssStrings.lateDays,
        value: '${summary.lateDays}',
      ),
      SummaryTile(
        icon: Icons.schedule,
        color: scheme.primary,
        label: EssStrings.workHours,
        value: EssStrings.hoursValue(summary.workingHours),
      ),
    ];

    return Column(
      children: [
        Row(children: [tiles[0], const SizedBox(width: 10), tiles[1]]),
        const SizedBox(height: 10),
        Row(children: [tiles[2], const SizedBox(width: 10), tiles[3]]),
      ],
    );
  }
}

class SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const SummaryTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// يوم واحد: التاريخ واليوم، الحالة، الحضور والانصراف والساعات، والتأخير
/// أو الخروج المبكر
class RecordCard extends StatelessWidget {
  final AttendanceRecord record;

  const RecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final r = record;
    final (color, icon, label) = statusStyle(r.status, scheme);

    String time(DateTime? d) =>
        d == null ? '—' : loc.formatTimeOfDay(TimeOfDay.fromDateTime(d));

    Widget cell(String title, String value) => Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    Widget flag(IconData i, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEF6C00).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 14, color: const Color(0xFFEF6C00)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFEF6C00),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    final showTimes =
        r.status == AttendanceStatus.present ||
        r.status == AttendanceStatus.halfDay ||
        r.status == AttendanceStatus.workFromHome;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          border: BorderDirectional(start: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        VisitStrings.weekday(r.date.weekday),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        loc.formatMediumDate(r.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(
                        r.status == AttendanceStatus.onLeave &&
                                r.leaveType.isNotEmpty
                            ? '$label • ${r.leaveType}'
                            : label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showTimes) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  cell(EssStrings.inTime, time(r.inTime)),
                  cell(EssStrings.outTime, time(r.outTime)),
                  cell(EssStrings.hours, EssStrings.hoursValue(r.workingHours)),
                ],
              ),
            ],
            if (r.lateEntry || r.earlyExit) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (r.lateEntry)
                    flag(Icons.alarm, EssStrings.lateBy(r.lateMinutes)),
                  if (r.earlyExit)
                    flag(
                      Icons.directions_run,
                      EssStrings.earlyBy(r.earlyMinutes),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
