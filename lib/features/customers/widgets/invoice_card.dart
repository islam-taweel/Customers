import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/sales_invoice.dart';

/// ورقة الفاتورة: رقمها، اسم العميل، رقم هاتفه، والمبلغ.
/// وإن مُرِّرت التفاصيل (التاريخ، الحالة، الأصناف، الضرائب، المتبقي) تظهر أيضًا.
/// خلفيتها بيضاء وألوانها ثابتة (لا تتبع الثيم) لأنها تُلتقط كصورة وتُحوَّل إلى PDF.
class InvoiceCard extends StatelessWidget {
  final String number;
  final String customerName;
  final String customerPhone;
  final double amount;

  final String? date;
  final String? dueDate;
  final String? status;
  final List<InvoiceItem> items;
  final double? taxes;
  final double? outstanding;

  const InvoiceCard({
    super.key,
    required this.number,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    this.date,
    this.dueDate,
    this.status,
    this.items = const [],
    this.taxes,
    this.outstanding,
  });

  static const Color _text = Color(0xFF212121);
  static const Color _label = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final hasTaxes = taxes != null && taxes != 0;
    final hasOutstanding = outstanding != null && outstanding! > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: _text, fontSize: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      color: AppColors.seed,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  AppStrings.invoiceTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 28),
            _InfoRow(label: AppStrings.invoiceNumber, value: number, isLtr: true),
            _InfoRow(label: AppStrings.invoiceCustomer, value: customerName),
            _InfoRow(label: AppStrings.phone, value: customerPhone, isLtr: true),
            if (date != null && date!.isNotEmpty)
              _InfoRow(label: AppStrings.invoicePostingDate, value: date!, isLtr: true),
            if (dueDate != null && dueDate!.isNotEmpty)
              _InfoRow(label: AppStrings.invoiceDueDate, value: dueDate!, isLtr: true),
            if (status != null && status!.isNotEmpty)
              _InfoRow(
                label: AppStrings.invoiceStatusLabel,
                value: AppStrings.invoiceStatus(status!),
              ),
            if (items.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                AppStrings.invoiceItems,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final item in items) _ItemRow(item: item),
            ],
            const Divider(height: 28),
            if (hasTaxes)
              _InfoRow(
                label: AppStrings.invoiceTaxes,
                value: formatSignedAmount(taxes!),
                isLtr: true,
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.invoiceAmount,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  formatSignedAmount(amount),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: AppColors.seed,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (hasOutstanding)
              _InfoRow(
                label: AppStrings.invoiceOutstanding,
                value: formatAmount(outstanding!),
                isLtr: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  /// الأرقام ورموز الفاتورة تُكتب دائمًا من اليسار لليمين حتى في العربية
  final bool isLtr;

  const _InfoRow({required this.label, required this.value, this.isLtr = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: InvoiceCard._label)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                value,
                textDirection: isLtr ? TextDirection.ltr : null,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2.0 ← "2"، و 1.5 ← "1.5"
String _formatQty(double qty) =>
    qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();

/// صف صنف: اسمه وتحته «الكمية × السعر»، وإجماليه في الطرف الآخر
class _ItemRow extends StatelessWidget {
  final InvoiceItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${_formatQty(item.qty)} × ${formatSignedAmount(item.rate)}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: InvoiceCard._label, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatSignedAmount(item.amount),
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
