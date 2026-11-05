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

/// العمل الإضافي من ERPNext: Additional Salary بمكوّن Overtime المعتمد. يحفظ
/// المبلغ فقط (بالشيكل) دون الساعات، فيُعرض المبلغ والساعات «يُتفق عليها».
/// ملخص الشهر، رسم بياني للمبالغ خلال الشهر، ثم السجل.
class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key});

  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
  late int _year;
  late int _month;
  late Future<List<OvertimePayment>> _future;

  @override
  void initState() {
    super.initState();
    final today = PalestineTime.today();
    _year = today.year;
    _month = today.month;
    _load();
  }

  void _load() {
    _future =
        context.read<ErpEmployeeRepository>().fetchOvertime(_year, _month);
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
            child: FutureBuilder<List<OvertimePayment>>(
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
                final entries = snapshot.data!;
                final total = entries.fold<double>(0, (s, e) => s + e.amount);
                final days = {for (final e in entries) e.payrollDate}.length;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_load);
                    await _future.then((_) {}, onError: (_) {});
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      _Summary(total: total, days: days, entries: entries.length),
                      const SizedBox(height: 8),
                      Text(
                        EssStrings.overtimeAmountSource,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: EmptyView(
                            icon: Icons.more_time_outlined,
                            title: EssStrings.noOvertimeAmount,
                            message: EssStrings.noOvertimeAmountHint,
                          ),
                        )
                      else ...[
                        _DailyChart(
                          year: _year,
                          month: _month,
                          entries: entries,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          EssStrings.overtimeLog,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final e in entries) _EntryCard(entry: e),
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

/// إجمالي المبلغ، عدد الأيام، والساعات (يُتفق على عرضها)
class _Summary extends StatelessWidget {
  final double total;
  final int days;
  final int entries;

  const _Summary({
    required this.total,
    required this.days,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget tile(IconData icon, String label, String value,
            {bool muted = false}) =>
        Expanded(
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
                Text(
                  value,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: (muted
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.titleMedium)
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: muted ? scheme.outline : null,
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

    return Column(
      children: [
        Row(
          children: [
            tile(
              Icons.payments_outlined,
              EssStrings.overtimeAmount,
              formatAmount(total),
            ),
            const SizedBox(width: 10),
            tile(Icons.event_available_outlined, EssStrings.overtimeDays,
                '$days'),
            const SizedBox(width: 10),
            tile(Icons.receipt_long_outlined, EssStrings.overtimeEntries,
                '$entries'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.schedule, size: 18, color: scheme.outline),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                EssStrings.overtimeHoursPending,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// أعمدة لمبلغ كل يوم في الشهر (سلسلة واحدة بلون الثيم). الضغط على عمود
/// يعرض اليوم ومبلغه.
class _DailyChart extends StatefulWidget {
  final int year;
  final int month;
  final List<OvertimePayment> entries;

  const _DailyChart({
    required this.year,
    required this.month,
    required this.entries,
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
    final days = DateTime(widget.year, widget.month + 1, 0).day;
    final amounts = List<double>.filled(days, 0);
    for (final e in widget.entries) {
      amounts[e.payrollDate.day - 1] += e.amount;
    }
    final max = amounts.fold<double>(0, (m, a) => a > m ? a : m);
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
              EssStrings.overtimeAmountChart,
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
                        formatAmount(amounts[sel]),
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
                            onTap: amounts[i] <= 0
                                ? null
                                : () => setState(
                                      () => _selected =
                                          _selected == i ? null : i,
                                    ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                // فراغ 2px بين الأعمدة
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                child: Container(
                                  height: amounts[i] <= 0
                                      ? 0
                                      : (amounts[i] / top * chartHeight)
                                          .clamp(3, chartHeight),
                                  decoration: BoxDecoration(
                                    color: sel == null || sel == i
                                        ? scheme.primary
                                        : scheme.primary.withValues(alpha: 0.35),
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

/// دفعة عمل إضافي: التاريخ، المبلغ، الحالة (معتمد)، والساعات غير محفوظة
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_outlined,
                            size: 14, color: green),
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
