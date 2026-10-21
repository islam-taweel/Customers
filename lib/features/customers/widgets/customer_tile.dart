import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/customer_with_balance.dart';
import '../../../data/repositories/outstanding_repository.dart';

/// صف عميل في القائمة: الاسم والهاتف، وديونه (total outstanding من ERPNext) فقط.
/// [outstanding] = null قبل وصول الرد أو لعميل غير مرتبط بـ ERPNext، فتظهر شرطة.
/// يظهر ما هو مستحق على العميل فقط (المبالغ الموجبة)، سطر لكل عملة.
class CustomerTile extends StatelessWidget {
  final CustomerWithBalance item;
  final List<CurrencyAmount>? outstanding;
  final VoidCallback onTap;

  const CustomerTile({
    super.key,
    required this.item,
    required this.outstanding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = item.customer.name;
    final debts = [
      for (final row in outstanding ?? const <CurrencyAmount>[])
        if (row.amount > 0) row,
    ];
    final debtColor = AppColors.forBalance(1);
    final settledColor = AppColors.forBalance(0);

    final Widget trailing;
    if (outstanding == null) {
      trailing = const Text('—');
    } else if (debts.isEmpty) {
      trailing = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatAmount(0),
            style: TextStyle(
              color: settledColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            AppStrings.settled,
            style: TextStyle(color: settledColor, fontSize: 12),
          ),
        ],
      );
    } else {
      trailing = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final row in debts)
            Text(
              formatAmount(row.amount, currency: row.currency),
              style: TextStyle(
                color: debtColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textDirection: TextDirection.ltr,
            ),
          Text(AppStrings.owed, style: TextStyle(color: debtColor, fontSize: 12)),
        ],
      );
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(name.isNotEmpty ? name[0] : AppStrings.unknownInitial),
      ),
      title: Text(name),
      subtitle: Text(item.customer.phone),
      trailing: trailing,
    );
  }
}
