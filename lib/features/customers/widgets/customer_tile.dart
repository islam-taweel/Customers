import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/customer_with_balance.dart';

/// صف عميل في القائمة: الاسم والهاتف، ورصيده بلون يدل على حالته.
class CustomerTile extends StatelessWidget {
  final CustomerWithBalance item;
  final VoidCallback onTap;

  const CustomerTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    debugPrint('build: CustomerTile');

    final balance = item.balance;
    final color = AppColors.forBalance(balance);
    final label = balance > 0
        ? AppStrings.owed
        : balance < 0
        ? AppStrings.hasCredit
        : AppStrings.settled;
    final name = item.customer.name;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(name.isNotEmpty ? name[0] : AppStrings.unknownInitial),
      ),
      title: Text(name),
      subtitle: Text(item.customer.phone),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatAmount(balance.abs()),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
