import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/outstanding_repository.dart';

/// بطاقة رصيد العميل المحلي (من العمليات) في أعلى شاشة العمليات.
/// **كل عملة تظهر برصيدها المنفصل** بدل جمعها في رقم واحد: دين بالشيكل ودفعة
/// بالدولار لا يُطرح أحدهما من الآخر. القائمة الفارغة تعني أن الحساب مسدد.
class BalanceCard extends StatelessWidget {
  final Customer customer;
  final List<CurrencyAmount> balances;

  const BalanceCard({super.key, required this.customer, required this.balances});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final many = balances.length > 1;

    return Card(
      margin: const EdgeInsets.all(AppConstants.pagePadding),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              if (balances.isEmpty)
                _BalanceBlock(amount: 0, currency: null, big: true)
              else
                for (var i = 0; i < balances.length; i++) ...[
                  if (i > 0) Divider(color: theme.colorScheme.outlineVariant),
                  _BalanceBlock(
                    amount: balances[i].amount,
                    currency: balances[i].currency,
                    big: !many,
                  ),
                ],
              const SizedBox(height: 8),
              Text(
                customer.phone,
                style: theme.textTheme.bodyMedium,
                textDirection: TextDirection.ltr,
              ),
              if (many) ...[
                const SizedBox(height: 6),
                Text(
                  AppStrings.balancesPerCurrencyNote,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// رصيد عملة واحدة: عنوان (مستحق/له رصيد/مسدد) ومبلغ بعملته.
class _BalanceBlock extends StatelessWidget {
  final double amount;
  final String? currency;
  final bool big;

  const _BalanceBlock({
    required this.amount,
    required this.currency,
    required this.big,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forBalance(amount);
    final label = amount > 0
        ? AppStrings.balanceOwedLong
        : amount < 0
            ? AppStrings.balanceCreditLong
            : AppStrings.balanceSettledLong;

    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 14)),
        const SizedBox(height: 6),
        Text(
          formatAmount(amount.abs(), currency: currency),
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: color,
            fontSize: big ? 32 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
