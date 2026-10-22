import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/operation.dart';

String _rateText(double rate) => rate
    .toStringAsFixed(4)
    .replaceFirst(RegExp(r'0+$'), '')
    .replaceFirst(RegExp(r'\.$'), '');

/// صف عملية (دين أو دفعة) في سجل عمليات العميل.
class OperationTile extends StatelessWidget {
  final Operation operation;

  const OperationTile({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    final isDebt = operation.type == OperationType.debt;
    final color = isDebt ? AppColors.debt : AppColors.payment;
    final note = operation.note?.trim() ?? '';
    final hasNote = note.isNotEmpty;
    final mode = operation.modeOfPayment?.trim() ?? '';
    final hasMode = !isDebt && mode.isNotEmpty;
    final hasEntry = (operation.paymentEntry ?? '').isNotEmpty;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          isDebt ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
        ),
      ),
      title: Text(
        isDebt ? AppStrings.debt : AppStrings.payment,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMode) Text('${AppStrings.modeOfPayment}: $mode'),
          if (operation.isConverted)
            Text(
              AppStrings.settledAs(
                formatAmount(
                  operation.settledAmount!,
                  currency: operation.settledCurrency,
                ),
                _rateText(operation.exchangeRate!),
              ),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          if (hasEntry)
            Text(
              AppStrings.paymentEntryRef(operation.paymentEntry!),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textDirection: TextDirection.ltr,
            ),
          if (hasNote) Text(note),
          Text(
            formatDateTime(operation.date),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      isThreeLine: hasNote || hasMode || hasEntry || operation.isConverted,
      trailing: Text(
        '${isDebt ? '+' : '-'} ${formatAmount(operation.amount, currency: operation.currency)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}