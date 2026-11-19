import 'package:flutter/material.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/van_sale_models.dart';

/// الحد الائتماني والرصيد الحالي والمتاح، مع شريط الاستخدام. [extra]: مبلغ
/// فاتورة جديدة يُفحص معه تجاوز الحد (null = لا فاتورة).
class CreditSummary extends StatelessWidget {
  final CustomerCredit credit;
  final double? extra;

  /// الفاتورة فيها بند بلا سعر: لا يمكن فحص الحد
  final bool unknownExtra;

  const CreditSummary({
    super.key,
    required this.credit,
    this.extra,
    this.unknownExtra = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = credit;
    final cur = displayCurrency(c.currency);
    String money(double v) => formatAmount(v, currency: cur);

    final over = c.hasLimit && c.available < 0;
    final used = c.hasLimit ? (c.balance / c.creditLimit).clamp(0.0, 1.0) : 0.0;
    final barColor = over
        ? scheme.error
        : used > 0.8
        ? const Color(0xFFEF6C00)
        : const Color(0xFF2E7D32);

    Widget figure(String label, String value, {Color? color, String? hint}) =>
        Expanded(
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              if (hint != null)
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
            ],
          ),
        );

    final newBalance = extra == null ? null : c.balance + extra!;
    final exceeds = extra != null && c.exceedsWith(extra!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            figure(
              VanStrings.creditLimit,
              c.hasLimit ? money(c.creditLimit) : '—',
            ),
            figure(
              VanStrings.currentBalance,
              money(c.balance),
              hint: VanStrings.currentBalanceHint,
            ),
            figure(
              VanStrings.availableCredit,
              c.hasLimit ? money(c.available) : '—',
              color: c.hasLimit ? (over ? scheme.error : scheme.primary) : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (c.hasLimit) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: used,
              minHeight: 8,
              color: barColor,
              backgroundColor: barColor.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            over
                ? VanStrings.overLimit
                : VanStrings.usedPercent((used * 100).toStringAsFixed(0)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: over ? scheme.error : scheme.onSurfaceVariant,
              fontWeight: over ? FontWeight.w700 : null,
            ),
          ),
        ] else
          Text(
            VanStrings.noCreditLimit,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),

        // فحص الفاتورة الجديدة
        if (unknownExtra && c.hasLimit) ...[
          const SizedBox(height: 10),
          _Banner(
            color: const Color(0xFFEF6C00),
            icon: Icons.help_outline,
            text: VanStrings.cannotCheckLimit,
          ),
        ] else if (newBalance != null && c.hasLimit) ...[
          const SizedBox(height: 10),
          _Banner(
            color: exceeds ? scheme.error : const Color(0xFF2E7D32),
            icon: exceeds ? Icons.warning_amber_rounded : Icons.check_circle,
            text: exceeds
                ? VanStrings.exceedsLimit(money(newBalance - c.creditLimit))
                : '${VanStrings.withinLimit} • ${VanStrings.afterInvoice(money(newBalance))}',
            strong: exceeds,
          ),
        ],
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final bool strong;

  const _Banner({
    required this.color,
    required this.icon,
    required this.text,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: strong ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
