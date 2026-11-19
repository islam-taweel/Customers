import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/gl_entry.dart';

/// رقم بفواصل الآلاف وخانتين عشريتين، بلا رمز عملة (العملة في رأس العمود)
String _num(double v) {
  final parts = v.abs().toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '-' : ''}$intPart.${parts[1]}';
}

/// جدول القيود (البيان، مدين، دائن) بعملة حساب العميل
class GlLedgerTable extends StatelessWidget {
  final CustomerLedger ledger;

  const GlLedgerTable({super.key, required this.ledger});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    final symbol = formatAmount(
      0,
      currency: displayCurrency(ledger.currency),
    ).split(' ').last;
    const pad = EdgeInsets.symmetric(vertical: 10, horizontal: 8);

    Widget amount(double v) => Text(
      v == 0 ? '—' : _num(v),
      textAlign: TextAlign.end,
      textDirection: TextDirection.ltr,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: v == 0 ? scheme.onSurfaceVariant : null,
        fontWeight: v == 0 ? null : FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1.2),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(AppStrings.glDescription, style: headerStyle),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  '${AppStrings.glDebit} ($symbol)',
                  style: headerStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  '${AppStrings.glCredit} ($symbol)',
                  style: headerStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          for (final l in ledger.lines)
            TableRow(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              children: [
                Padding(
                  padding: pad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.voucherTypeLabel(l.voucherType),
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${l.voucherNo}  ${l.postingDate}',
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(padding: pad, child: amount(l.debit)),
                Padding(padding: pad, child: amount(l.credit)),
              ],
            ),
        ],
      ),
    );
  }
}

/// مجموع المدين والدائن والتحقق من التوازن: متوازنة = الفاتورة مسددة بالكامل.
class GlTotals extends StatelessWidget {
  final CustomerLedger ledger;

  const GlTotals({super.key, required this.ledger});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currency = displayCurrency(ledger.currency);
    final balanced = ledger.isBalanced;
    final diff = ledger.difference;
    final color = balanced ? AppColors.payment : scheme.error;

    Widget line(String label, double value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            formatAmount(value, currency: currency),
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    final message = balanced
        ? AppStrings.glBalanced
        : diff > 0
        ? AppStrings.glUnbalanced(formatAmount(diff, currency: currency))
        : AppStrings.glOverpaid(formatAmount(-diff, currency: currency));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(AppStrings.glTotalDebit, ledger.totalDebit),
          line(AppStrings.glTotalCredit, ledger.totalCredit),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                balanced
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
