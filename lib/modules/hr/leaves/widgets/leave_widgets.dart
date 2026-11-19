import 'package:flutter/material.dart';

import '../../../../core/constants/ess_strings.dart';
import '../models/leave_models.dart';

/// (R5) أجزاء عرض «إجازاتي» نُقلت كما هي من LeavesScreen.

const green = Color(0xFF2E7D32);

const orange = Color(0xFFEF6C00);

/// بطاقة لكل نوع مخصص (المتبقي بارز، والإجمالي والمأخوذ والمعلّق)، ثم الأنواع
/// بدون راتب
class Balances extends StatelessWidget {
  final LeaveDetails details;

  const Balances({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String n(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

    if (details.balances.isEmpty && details.withoutPayTypes.isEmpty) {
      return Text(
        EssStrings.noBalances,
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }

    final cards = <Widget>[
      for (final b in details.balances)
        BalanceCard(
          title: b.leaveType,
          icon: _iconFor(b.leaveType),
          color: b.remaining > 0 ? scheme.primary : scheme.error,
          value: n(b.remaining),
          valueLabel: EssStrings.remaining,
          detail: EssStrings.balanceDetail(n(b.total), n(b.taken)),
          pending: b.pending > 0
              ? EssStrings.pendingApproval(EssStrings.daysValue(b.pending))
              : null,
          progress: b.total > 0 ? (b.remaining / b.total).clamp(0, 1) : 0,
        ),
      for (final t in details.withoutPayTypes)
        if (details.balanceOf(t) == null)
          BalanceCard(
            title: t,
            icon: Icons.money_off_outlined,
            color: orange,
            value: '—',
            valueLabel: EssStrings.withoutPay,
            detail: EssStrings.noBalanceLimit,
          ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 600 ? 3 : 2;
        final width = (box.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final c in cards) SizedBox(width: width, child: c)],
        );
      },
    );
  }

  /// أيقونة تقريبية حسب اسم النوع (الأسماء تختلف بين المواقع)
  static IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('sick') || t.contains('مرض')) {
      return Icons.medical_services_outlined;
    }
    if (t.contains('without pay') || t.contains('بدون')) {
      return Icons.money_off_outlined;
    }
    if (t.contains('annual') || t.contains('privilege') || t.contains('سنو')) {
      return Icons.beach_access_outlined;
    }
    return Icons.event_available_outlined;
  }
}

class BalanceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String value;
  final String valueLabel;
  final String detail;
  final double? progress;

  /// leaves_pending_approval: أيام في طلبات لم يُوافق عليها بعد (منفصلة عن المتبقي)
  final String? pending;

  const BalanceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.valueLabel,
    required this.detail,
    this.progress,
    this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(valueLabel, style: theme.textTheme.bodySmall),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ],
          if (pending != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top, size: 14, color: orange),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      pending!,
                      style: const TextStyle(
                        color: orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// طلب سابق: النوع، الفترة، عدد الأيام، تاريخ التقديم، الحالة
class RequestCard extends StatelessWidget {
  final LeaveRequest request;

  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final r = request;
    final (color, icon, label) = switch (r.status) {
      LeaveRequestStatus.pending => (
        orange,
        Icons.hourglass_top,
        EssStrings.statusPending,
      ),
      LeaveRequestStatus.approved => (
        green,
        Icons.check_circle_outline,
        EssStrings.statusApproved,
      ),
      LeaveRequestStatus.rejected => (
        scheme.error,
        Icons.cancel_outlined,
        EssStrings.statusRejected,
      ),
      LeaveRequestStatus.cancelled => (
        scheme.outline,
        Icons.block,
        EssStrings.statusCancelled,
      ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.leaveType,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
                        label,
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
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    EssStrings.period(
                      loc.formatMediumDate(r.from),
                      loc.formatMediumDate(r.to),
                    ),
                  ),
                ),
                Text(
                  EssStrings.daysValue(r.days),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (r.reason.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                r.reason.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (r.postedOn != null) ...[
              const SizedBox(height: 4),
              Text(
                EssStrings.submittedOn(loc.formatMediumDate(r.postedOn!)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
