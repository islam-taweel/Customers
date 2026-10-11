import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';

/// بطاقة إجمالي الديون في أعلى شاشة العملاء.
class TotalDebtsCard extends StatelessWidget {
  final double total;

  const TotalDebtsCard({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(AppConstants.pagePadding),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: scheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.totalDebts,
                style: TextStyle(fontSize: 16, color: scheme.onPrimaryContainer),
              ),
            ),
            Text(
              formatAmount(total),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}