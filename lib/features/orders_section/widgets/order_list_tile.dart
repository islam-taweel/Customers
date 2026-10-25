import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/invoice.dart';

/// صف طلبية في قسم «الطلبات»: اسم العميل، ثم رقم الطلبية وتاريخها وحالتها،
/// والمبلغ في الطرف الآخر.
class OrderListTile extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const OrderListTile({super.key, required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final entry = invoice.toListEntry();
    final scheme = Theme.of(context).colorScheme;
    final color = invoice.stage == OrderStage.completed
        ? AppColors.payment
        : scheme.primary;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(Icons.receipt_long_outlined, color: color),
      ),
      title: Text(
        invoice.customerName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${invoice.displayName} • ${entry.postingDate} • '
        '${AppStrings.invoiceStatus(entry.status)}',
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      trailing: Text(
        formatSignedAmount(
          entry.grandTotal,
          currency: displayCurrency(entry.currency),
        ),
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}
