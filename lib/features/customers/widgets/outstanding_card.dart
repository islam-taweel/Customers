import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/outstanding_repository.dart';

/// بطاقة المستحق من ERPNext: «مستحق الفواتير» لكل عملة على حدة،
/// و«رصيد الحساب» بعملة الشركة (يشمل الدفعات غير المربوطة بفواتير).
class OutstandingCard extends StatelessWidget {
  final CustomerOutstanding outstanding;

  const OutstandingCard({super.key, required this.outstanding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final balance = outstanding.accountBalance;

    return Card(
      margin: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding,
        0,
        AppConstants.pagePadding,
        AppConstants.pagePadding,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.invoicesOutstandingTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (outstanding.invoiceOutstanding.isEmpty)
              Text(
                AppStrings.noInvoiceOutstanding,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              )
            else
              for (final row in outstanding.invoiceOutstanding)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    formatSignedAmount(row.amount, currency: row.currency),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.forBalance(row.amount),
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
            if (balance != null) ...[
              const Divider(height: 24),
              Text(
                AppStrings.accountBalance,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatSignedAmount(balance),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.forBalance(balance),
                ),
                textDirection: TextDirection.ltr,
              ),
              Text(
                AppStrings.accountBalanceHint,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
