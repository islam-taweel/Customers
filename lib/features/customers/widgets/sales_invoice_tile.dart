import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/sales_invoice.dart';

/// صف فاتورة في قائمة فواتير العميل: رقمها وتاريخها وحالتها، وإجماليها،
/// ويظهر «المتبقي» فقط إذا كان على الفاتورة مبلغ غير مدفوع (outstanding_amount > 0).
class SalesInvoiceTile extends StatelessWidget {
  final SalesInvoice invoice;
  final VoidCallback onTap;

  const SalesInvoiceTile({super.key, required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final outstanding = invoice.outstandingAmount;
    // أحمر: عليها مبلغ غير مدفوع، أخضر: مرتجع (رصيد للعميل)، رمادي: مسددة
    final color = outstanding > 0
        ? AppColors.debt
        : outstanding < 0
            ? AppColors.payment
            : AppColors.settled;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(Icons.receipt_long_outlined, color: color),
      ),
      title: Text(
        invoice.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${invoice.postingDate} • ${AppStrings.invoiceStatus(invoice.status)}',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatSignedAmount(
              invoice.grandTotal,
              currency: displayCurrency(invoice.currency),
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            textDirection: TextDirection.ltr,
          ),
          if (outstanding > 0)
            Text(
              '${AppStrings.invoiceRemaining} ${formatAmount(outstanding, currency: displayCurrency(invoice.currency))}',
              style: TextStyle(color: AppColors.debt, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
