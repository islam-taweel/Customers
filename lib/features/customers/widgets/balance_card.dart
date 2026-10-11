import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/customer.dart';

/// بطاقة رصيد العميل الحالي في أعلى شاشة التفاصيل.
class BalanceCard extends StatelessWidget {
  final Customer customer;
  final double balance;

  const BalanceCard({super.key, required this.customer, required this.balance});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forBalance(balance);
    final label = balance > 0
        ? AppStrings.balanceOwedLong
        : balance < 0
            ? AppStrings.balanceCreditLong
            : AppStrings.balanceSettledLong;

    return Card(
      margin: const EdgeInsets.all(AppConstants.pagePadding),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                formatAmount(balance.abs()),
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customer.phone,
                style: Theme.of(context).textTheme.bodyMedium,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}