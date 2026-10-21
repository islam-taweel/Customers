import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/outstanding_repository.dart';

/// بطاقة إجمالي الديون في أعلى شاشة العملاء: قيمة API الـ total outstanding من
/// ERPNext فقط، سطر لكل عملة (لا تُجمع العملات معًا).
/// [amounts] = null قبل وصول الرد أو عند تعذّره، فتظهر شرطة بدل رقم.
class TotalDebtsCard extends StatelessWidget {
  final List<CurrencyAmount>? amounts;

  const TotalDebtsCard({super.key, required this.amounts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = amounts;
    final style = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: scheme.onPrimaryContainer,
    );

    return Card(
      margin: const EdgeInsets.all(AppConstants.pagePadding),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.totalDebts,
                style: TextStyle(fontSize: 16, color: scheme.onPrimaryContainer),
              ),
            ),
            if (list == null)
              Text('—', style: style)
            else if (list.isEmpty)
              Text(formatAmount(0), style: style, textDirection: TextDirection.ltr)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final row in list)
                    Text(
                      formatSignedAmount(row.amount, currency: row.currency),
                      style: style,
                      textDirection: TextDirection.ltr,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
