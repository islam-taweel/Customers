import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/constants/visit_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/palestine_time.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/attendance_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';
import '../employee_service.dart';
import '../widgets/month_year_picker.dart';

/// العمل الإضافي للشهر المختار، كما حسبه ERPNext دون أي حساب في التطبيق:
/// الساعات من Overtime Slip المعتمد إن كانت نسخة HRMS تدعمه، والمبلغ بالشيكل من
/// Additional Salary بمكوّن Overtime. بلا Overtime Slip: المبلغ فقط.
class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key});

  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
  late int _year;
  late int _month;
  late Future<OvertimeMonth> _future;

  @override
  void initState() {
    super.initState();
    final today = PalestineTime.today();
    _year = today.year;
    _month = today.month;
    _load();
  }

  void _load() {
    _future = context.read<ErpEmployeeRepository>().fetchOvertimeMonth(
      _year,
      _month,
    );
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
    return describeError(e, fallback: EssStrings.overtimeLoadFailed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(EmployeeService.overtime.title)),
      body: Column(
        children: [
          MonthYearPicker(year: _year, month: _month, onChanged: _setPeriod),
          Expanded(
            child: FutureBuilder<OvertimeMonth>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return LoadingView(message: EssStrings.loadingOvertime);
                }
                if (snapshot.hasError) {
                  return ErrorView(
                    message: _message(snapshot.error!),
                    onRetry: () => setState(_load),
                  );
                }
                final data = snapshot.data!;
                final days = DateTime(_year, _month + 1, 0).day;

                // ساعات كل يوم من بنود Overtime Slip، وإلا مبالغ كل يوم
                final hoursByDay = List<double>.filled(days, 0);
                for (final d in data.days) {
                  hoursByDay[d.date.day - 1] += d.durationSeconds;
                }
                final amountsByDay = List<double>.filled(days, 0);
                for (final p in data.payments) {
                  amountsByDay[p.payrollDate.day - 1] += p.amount;
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_load);
                    await _future.then((_) {}, onError: (_) {});
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      _Summary(data: data),
                      const SizedBox(height: 8),
                      _SourceNote(data: data),
                      const SizedBox(height: 16),
                      if (data.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: EmptyView(
                            icon: Icons.more_time_outlined,
                            title: EssStrings.noOvertimeAmount,
                            message: EssStrings.noOvertimeAmountHint,
                          ),
                        )
                      else ...[
                        if (data.days.isNotEmpty)
                          _DailyChart(
                            year: _year,
                            month: _month,
                            title: EssStrings.overtimeHoursChart,
                            values: hoursByDay,
                            format: EssStrings.duration,
                          )
                        else if (data.payments.isNotEmpty)
                          _DailyChart(
                            year: _year,
                            month: _month,
                            title: EssStrings.overtimeAmountChart,
                            values: amountsByDay,
                            format: formatAmount,
                          ),
                        if (data.days.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            EssStrings.overtimeHoursLog,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final d in data.days) _HoursCard(day: d),
                        ],
                        if (data.payments.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            EssStrings.overtimeAmountsLog,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final p in data.payments) _EntryCard(entry: p),
                        ],
                      ],
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

/// مجموع الساعات (أو «غير متاح» بلا Overtime Slip)، المبلغ بالشيكل، عدد الدفعات
class _Summary extends StatelessWidget {
  final OvertimeMonth data;

  const _Summary({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final seconds = data.totalSeconds;

    Widget tile(
      IconData icon,
      String label,
      String value, {
      bool muted = false,
    }) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: muted ? 0.04 : 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: muted ? scheme.outline : scheme.primary),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style:
                    (muted
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: muted ? scheme.outline : null,
                        ),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        tile(
          Icons.schedule,
          EssStrings.overtimeTotalHours,
          seconds == null
              ? EssStrings.hoursUnavailable
              : EssStrings.duration(seconds),
          muted: seconds == null,
        ),
        const SizedBox(width: 10),
        tile(
          Icons.payments_outlined,
          EssStrings.overtimeAmount,
          formatAmount(data.totalAmount),
        ),
        const SizedBox(width: 10),
        tile(
          Icons.receipt_long_outlined,
          EssStrings.overtimeEntries,
          '${data.payments.length}',
        ),
      ],
    );
  }
}

/// من أين جاءت الأرقام: Overtime Slip أو Additional Salary
class _SourceNote extends StatelessWidget {
  final OvertimeMonth data;

  const _SourceNote({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = switch (data.slipSupport) {
      OvertimeSlipSupport.available => EssStrings.sourceOvertimeSlip,
      OvertimeSlipSupport.missing => EssStrings.sourceNoOvertimeSlip,
      OvertimeSlipSupport.noAccess => EssStrings.sourceNoSlipAccess,
    };
    final label = data.source == OvertimeSource.overtimeSlip
        ? 'Overtime Slip + Additional Salary'
        : 'Additional Salary (Overtime)';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EssStrings.sourceLabel(label),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// أعمدة لقيمة كل يوم في الشهر (سلسلة واحدة بلون الثيم). الضغط على عمود
/// يعرض اليوم وقيمته.
class _DailyChart extends StatefulWidget {
  final int year;
  final int month;
  final String title;

  /// قيمة كل يوم (الفهرس = اليوم − 1)
  final List<double> values;
  final String Function(double) format;

  const _DailyChart({
    required this.year,
    required this.month,
    required this.title,
    required this.values,
    required this.format,
  });

  @override
  State<_DailyChart> createState() => _DailyChartState();
}

class _DailyChartState extends State<_DailyChart> {
  int? _selected;

  @override
  void didUpdateWidget(covariant _DailyChart old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month || old.year != widget.year) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final values = widget.values;
    final days = values.length;
    final max = values.fold<double>(0, (m, a) => a > m ? a : m);
    final top = max <= 0 ? 1.0 : max;
    const chartHeight = 140.0;
    final sel = _selected;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            // قيمة العمود المحدد (بدل تلميح المرور على الهاتف)
            SizedBox(
              height: 20,
              child: sel == null
                  ? null
                  : Text(
                      EssStrings.chartTooltip(
                        '${VisitStrings.weekday(DateTime(widget.year, widget.month, sel + 1).weekday)} ${sel + 1}',
                        widget.format(values[sel]),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: chartHeight,
              child: Stack(
                children: [
                  // خط الأساس فقط
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(height: 1, color: scheme.outlineVariant),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < days; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: values[i] <= 0
                                ? null
                                : () => setState(
                                    () => _selected = _selected == i ? null : i,
                                  ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                // فراغ 2px بين الأعمدة
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                child: Container(
                                  height: values[i] <= 0
                                      ? 0
                                      : (values[i] / top * chartHeight).clamp(
                                          3,
                                          chartHeight,
                                        ),
                                  decoration: BoxDecoration(
                                    color: sel == null || sel == i
                                        ? scheme.primary
                                        : scheme.primary.withValues(
                                            alpha: 0.35,
                                          ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // أرقام الأيام: كل خامس يوم حتى لا تتزاحم
            SizedBox(
              height: 18,
              child: Row(
                children: [
                  for (var i = 0; i < days; i++)
                    Expanded(
                      child: Text(
                        (i + 1) % 5 == 0 || i == 0 ? '${i + 1}' : '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
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

/// يوم من بنود Overtime Slip: التاريخ، نوع العمل الإضافي، والمدة كما حسبها ERPNext
class _HoursCard extends StatelessWidget {
  final OvertimeDay day;

  const _HoursCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final d = day;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.more_time_outlined,
                size: 20,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${VisitStrings.weekday(d.date.weekday)}  ${loc.formatMediumDate(d.date)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (d.overtimeType.isNotEmpty)
                    Text(
                      d.overtimeType,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              EssStrings.duration(d.durationSeconds),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// دفعة عمل إضافي (Additional Salary): تاريخ الاستحقاق، المبلغ، الحالة (معتمد)
class _EntryCard extends StatelessWidget {
  final OvertimePayment entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final e = entry;
    const green = Color(0xFF2E7D32);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    VisitStrings.weekday(e.payrollDate.weekday),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${EssStrings.payrollDate}: ${loc.formatMediumDate(e.payrollDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          EssStrings.otApproved,
                          style: const TextStyle(
                            color: green,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatAmount(e.amount),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  EssStrings.amount,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
