import 'package:flutter/material.dart';

import '../../../core/constants/statement_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/statement_models.dart';

/// (R4) نُقلت من CustomerStatementScreen كما هي: عرض فقط. الرصيد الجاري
/// والمجاميع والختامي محسوبة مسبقًا في [CustomerStatement] (لا في الـ Widget).

/// الافتتاحي (لفترة) ومجموع المدين والدائن والرصيد الختامي
class StatementSummary extends StatelessWidget {
  final CustomerStatement statement;

  const StatementSummary({super.key, required this.statement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final closing = statement.closing;
    final state = closing > 0.005
        ? StatementStrings.owesUs
        : closing < -0.005
        ? StatementStrings.inCredit
        : StatementStrings.settled;

    Widget line(String label, double v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
            formatSignedAmount(v),
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (statement.from != null)
            line(StatementStrings.openingBalance, statement.opening),
          line(StatementStrings.totalDebit, statement.totalDebit),
          line(StatementStrings.totalCredit, statement.totalCredit),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StatementStrings.closingBalance,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      state,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.forBalance(closing),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatSignedAmount(closing),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.forBalance(closing),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// حركة واحدة: نوع المستند ورقمه وتاريخه، المدين أو الدائن، والرصيد بعدها
class StatementLineTile extends StatelessWidget {
  final StatementLine line;
  final VoidCallback onTap;

  const StatementLineTile({super.key, required this.line, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDebit = line.debit > 0.005;
    final amount = isDebit ? line.debit : line.credit;
    // المرتجع فاتورة مبيعات أيضًا لكنه يظهر دائنًا
    final label = line.voucherType == 'Sales Invoice' && !isDebit
        ? StatementStrings.creditNote
        : StatementStrings.voucherType(line.voucherType);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${line.voucherNo}  •  ${line.postingDate}',
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? StatementStrings.debit : StatementStrings.credit}  ${formatAmount(amount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDebit ? AppColors.debt : AppColors.payment,
                    ),
                  ),
                  Text(
                    '${StatementStrings.balance}: ${formatSignedAmount(line.balance)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
