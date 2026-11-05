import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/constants/visit_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/attendance_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';
import '../employee_service.dart';
import '../widgets/month_year_picker.dart';

/// لون وأيقونة واسم كل حالة حضور
(Color, IconData, String) _statusStyle(
  AttendanceStatus s,
  ColorScheme scheme,
) =>
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

/// سجل حضوري من ERPNext (Attendance المعتمد): اختيار الشهر والسنة، ملخص الشهر
/// (الحضور والغياب والتأخير وساعات العمل)، ثم سجل كل يوم الأحدث أولًا.
class AttendanceLogScreen extends StatefulWidget {
  const AttendanceLogScreen({super.key});

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  late int _year;
  late int _month;
  late Future<List<AttendanceRecord>> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _load();
  }

  void _load() {
    _future =
        context.read<ErpEmployeeRepository>().fetchAttendance(_year, _month);
  }

  void _setPeriod(int year, int month) {
    if (year == _year && month == _month) return;
    setState(() {
      _year = year;
      _month = month;
      _load();
    });
  }

  String _message(Object e) {
    if (e is EmployeeNotLinkedException) return EssStrings.notLinked;
    if (e is ErpApiException && e.type == ErpErrorType.forbidden) {
      return EssStrings.noPermission;
    }
    return describeError(e, fallback: EssStrings.attendanceLoadFailed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(EmployeeService.attendance.title)),
      body: Column(
        children: [
          MonthYearPicker(year: _year, month: _month, onChanged: _setPeriod),
          Expanded(
            child: FutureBuilder<List<AttendanceRecord>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return LoadingView(message: EssStrings.loadingAttendance);
                }
                if (snapshot.hasError) {
                  return ErrorView(
                    message: _message(snapshot.error!),
                    onRetry: () => setState(_load),
                  );
                }
                final records = snapshot.data!;
                Future<void> refresh() async {
                  setState(_load);
                  await _future.then((_) {}, onError: (_) {});
                }

                return RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      _SummaryGrid(summary: AttendanceSummary.of(records)),
                      const SizedBox(height: 16),
                      if (records.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: EmptyView(
                            icon: Icons.event_busy_outlined,
                            title: EssStrings.noAttendance,
                            message: EssStrings.noAttendanceHint,
                          ),
                        )
                      else
                        for (final r in records) _RecordCard(record: r),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ملخص الشهر في أربع بطاقات
class _SummaryGrid extends StatelessWidget {
  final AttendanceSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String days(double d) =>
        d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);

    final tiles = [
      _SummaryTile(
        icon: Icons.check_circle_outline,
        color: const Color(0xFF2E7D32),
        label: EssStrings.presentDays,
        value: days(summary.presentDays),
      ),
      _SummaryTile(
        icon: Icons.cancel_outlined,
        color: scheme.error,
        label: EssStrings.absentDays,
        value: '${summary.absentDays}',
      ),
      _SummaryTile(
        icon: Icons.alarm,
        color: const Color(0xFFEF6C00),
        label: EssStrings.lateDays,
        value: '${summary.lateDays}',
      ),
      _SummaryTile(
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

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SummaryTile({
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
class _RecordCard extends StatelessWidget {
  final AttendanceRecord record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final r = record;
    final (color, icon, label) = _statusStyle(r.status, scheme);

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

    final showTimes = r.status == AttendanceStatus.present ||
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    flag(Icons.directions_run, EssStrings.earlyBy(r.earlyMinutes)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
