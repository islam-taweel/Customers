import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../models/payslip_models.dart';
import '../controllers/payslips_controller.dart';
import '../models/payslip_explainer.dart';

/// تفاصيل كشف راتب: المستحقات (الأساسي، المواصلات، العمل الإضافي، وغيرها
/// وإجماليها)، الخصومات (كل خصم منفصلًا باسمه العربي وقيمته وشرح سببه)، وملخص
/// الراتب (الإجمالي، الخصومات، الصافي، أيام الدفع، الفترة، تاريخ الكشف).
class PayslipDetailScreen extends GetView<PayslipDetailController> {
  const PayslipDetailScreen({super.key, required this.name});

  /// رقم الكشف (Salary Slip.name)، وهو أيضًا tag المتحكم
  final String name;

  @override
  String? get tag => name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(EssStrings.payslips),
            Text(
              name,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Obx(() {
        final slip = controller.payslip.value;
        if (controller.loading.value && slip == null) {
          return LoadingView(message: EssStrings.loadingPayslip);
        }
        final error = controller.error.value;
        if (error != null && slip == null) {
          return ErrorView(
            message: controller.errorMessage ?? '',
            onRetry: controller.load,
          );
        }
        if (slip == null) return const SizedBox.shrink();
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _NetHeader(slip: slip),
              const SizedBox(height: 16),
              _EarningsSection(slip: slip),
              const SizedBox(height: 12),
              _DeductionsSection(slip: slip),
              const SizedBox(height: 12),
              _SummarySection(slip: slip),
            ],
          ),
        );
      }),
    );
  }
}

String _money(double v, PayslipDetail slip) =>
    formatAmount(v, currency: displayCurrency(slip.currency));

/// صافي الراتب بارزًا مع شهر الكشف
class _NetHeader extends StatelessWidget {
  final PayslipDetail slip;

  const _NetHeader({required this.slip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final month = slip.startDate ?? slip.postingDate;

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
        children: [
          if (month != null)
            Text(
              loc.formatMonthYear(month),
              style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.9)),
            ),
          const SizedBox(height: 4),
          Text(
            _money(slip.netPay, slip),
            textDirection: TextDirection.ltr,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(EssStrings.netPay, style: TextStyle(color: scheme.onPrimary)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// سطر: أيقونة واسم وقيمة، وشرح اختياري تحته
class _Line extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? note;
  final bool strong;
  final bool muted;
  final Color? valueColor;

  /// المبالغ تُعرض من اليسار لليمين
  final bool ltr;

  const _Line({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.strong = false,
    this.muted = false,
    this.valueColor,
    this.ltr = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      (strong
                              ? theme.textTheme.titleSmall
                              : theme.textTheme.bodyMedium)
                          ?.copyWith(
                            fontWeight: strong
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                ),
                if (note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textDirection: ltr ? TextDirection.ltr : null,
            style:
                (strong
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                      fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
                      color: muted ? scheme.outline : valueColor,
                    ),
          ),
        ],
      ),
    );
  }
}

/// المستحقات: الأساسي والمواصلات والعمل الإضافي دائمًا (أو «غير موجود»)،
/// ثم أي مستحقات أخرى بأسمائها، ثم الإجمالي
class _EarningsSection extends StatelessWidget {
  final PayslipDetail slip;

  const _EarningsSection({required this.slip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final byKind = <EarningKind, double>{};
    final others = <SalaryLine>[];
    for (final l in slip.earnings) {
      final kind = EarningKind.of(l);
      if (kind == EarningKind.other) {
        others.add(l);
      } else {
        byKind[kind] = (byKind[kind] ?? 0) + l.amount;
      }
    }

    return _Section(
      title: EssStrings.earnings,
      icon: Icons.trending_up,
      color: const Color(0xFF2E7D32),
      children: [
        for (final kind in [
          EarningKind.basic,
          EarningKind.transport,
          EarningKind.overtime,
        ])
          _Line(
            icon: kind.icon,
            label: kind.label,
            ltr: byKind.containsKey(kind),
            value: byKind.containsKey(kind)
                ? _money(byKind[kind]!, slip)
                : EssStrings.notOnSlip,
            muted: !byKind.containsKey(kind),
          ),
        for (final l in others)
          _Line(
            icon: EarningKind.other.icon,
            label: l.component,
            ltr: true,
            value: _money(l.amount, slip),
          ),
        const Divider(height: 16),
        _Line(
          icon: Icons.functions,
          label: EssStrings.totalEarnings,
          ltr: true,
          value: _money(slip.grossPay, slip),
          strong: true,
          valueColor: scheme.primary,
        ),
      ],
    );
  }
}

/// الخصومات: كل خصم منفصلًا (الاسم العربي، القيمة، شرح سببه)، ومعلومة
/// الأيام غير المدفوعة إن نقصت أيام الدفع دون بند خصم لها
class _DeductionsSection extends StatelessWidget {
  final PayslipDetail slip;

  const _DeductionsSection({required this.slip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kinds = [for (final l in slip.deductions) DeductionKind.of(l)];
    final unpaid = slip.leaveWithoutPay + slip.absentDays;
    final hasUnpaidLine =
        kinds.contains(DeductionKind.leaveWithoutPay) ||
        kinds.contains(DeductionKind.absence);

    return _Section(
      title: EssStrings.deductions,
      icon: Icons.trending_down,
      color: scheme.error,
      children: [
        if (slip.deductions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              EssStrings.noDeductions,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        for (var i = 0; i < slip.deductions.length; i++) ...[
          if (i > 0) const Divider(height: 8),
          _Line(
            icon: kinds[i].icon,
            label: kinds[i].label(slip.deductions[i]),
            ltr: true,
            value: _money(slip.deductions[i].amount, slip),
            note: kinds[i].explanation(slip.deductions[i], slip),
            valueColor: scheme.error,
          ),
        ],
        // الإجازة بدون راتب والغياب تُنقص أيام الدفع غالبًا دون بند خصم
        if (unpaid > 0 && !hasUnpaidLine) ...[
          const Divider(height: 8),
          _Line(
            icon: Icons.money_off_outlined,
            label: EssStrings.unpaidDaysNote,
            value: EssStrings.days(unpaid),
            note: EssStrings.unpaidDaysWhy(EssStrings.days(unpaid)),
            valueColor: scheme.error,
          ),
        ],
        const Divider(height: 16),
        _Line(
          icon: Icons.functions,
          label: EssStrings.totalDeductions,
          ltr: true,
          value: _money(slip.totalDeduction, slip),
          strong: true,
          valueColor: scheme.error,
        ),
        if (slip.deductions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              EssStrings.explanationNote,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
          ),
      ],
    );
  }
}

/// الملخص: الإجمالي، الخصومات، الصافي، أيام الدفع، الفترة، تاريخ الكشف
class _SummarySection extends StatelessWidget {
  final PayslipDetail slip;

  const _SummarySection({required this.slip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = MaterialLocalizations.of(context);
    String n(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

    return _Section(
      title: EssStrings.salarySummary,
      icon: Icons.summarize_outlined,
      color: scheme.primary,
      children: [
        _Line(
          icon: Icons.trending_up,
          label: EssStrings.grossPay,
          ltr: true,
          value: _money(slip.grossPay, slip),
        ),
        _Line(
          icon: Icons.trending_down,
          label: EssStrings.totalDeductions,
          ltr: true,
          value: _money(slip.totalDeduction, slip),
          valueColor: scheme.error,
        ),
        _Line(
          icon: Icons.account_balance_wallet_outlined,
          label: EssStrings.netPay,
          ltr: true,
          value: _money(slip.netPay, slip),
          strong: true,
          valueColor: scheme.primary,
        ),
        const Divider(height: 16),
        _Line(
          icon: Icons.event_available_outlined,
          label: EssStrings.paymentDays,
          value: slip.workingDays > 0
              ? EssStrings.paymentDaysOf(
                  n(slip.paymentDays),
                  n(slip.workingDays),
                )
              : n(slip.paymentDays),
        ),
        if (slip.startDate != null && slip.endDate != null)
          _Line(
            icon: Icons.date_range_outlined,
            label: EssStrings.salaryPeriod,
            value:
                '${loc.formatShortDate(slip.startDate!)} – ${loc.formatShortDate(slip.endDate!)}',
          ),
        if (slip.postingDate != null)
          _Line(
            icon: Icons.today_outlined,
            label: EssStrings.slipDate,
            value: loc.formatMediumDate(slip.postingDate!),
          ),
      ],
    );
  }
}
