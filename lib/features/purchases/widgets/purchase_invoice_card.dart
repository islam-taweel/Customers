import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/purchase_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/purchase_models.dart';
import '../controllers/purchases_controller.dart';
import '../screens/purchase_details_screen.dart';
import 'pay_supplier_sheet.dart';
import 'purchase_print.dart';

/// بطاقة فاتورة مشتريات: اسم المورد، رقم أمر الشراء، تاريخ الاستحقاق، عدد القطع
/// والمبلغ. الأزرار بحسب التبويب: غير مدفوعة / مدفوعة جزئيًا ← «دفع للمورد» و«طباعة»،
/// مدفوعة ← «طباعة» فقط، مسودة ← بلا أزرار.
class PurchaseInvoiceCard extends StatelessWidget {
  final PurchaseInvoice invoice;
  final PurchaseInvoiceBucket bucket;

  /// دفعات محفوظة مسودة بانتظار اعتمادها في ERPNext
  final double pendingAmount;

  const PurchaseInvoiceCard({
    super.key,
    required this.invoice,
    required this.bucket,
    this.pendingAmount = 0,
  });

  Future<void> _pay(BuildContext context) async {
    final controller = context.read<PurchasesController>();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showPayToSupplierSheet(
      context,
      invoice: invoice,
      controller: controller,
    );
    if (saved) {
      messenger.showSnackBar(
        SnackBar(content: Text(PurchaseStrings.paymentSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.read<PurchasesController>();
    final currency = displayCurrency(invoice.currency);
    final isPaid = bucket == PurchaseInvoiceBucket.paid;
    final isDraft = bucket == PurchaseInvoiceBucket.draft;
    final showPay = bucket == PurchaseInvoiceBucket.unpaid ||
        bucket == PurchaseInvoiceBucket.partlyPaid;
    final color = isPaid ? AppColors.payment : scheme.primary;
    final due = invoice.dueDate ?? '';
    final qty = invoice.totalQty;
    final qtyText = qty == qty.roundToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(2);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        PurchaseDetailsScreen.route(
          controller,
          doctype: 'Purchase Invoice',
          name: invoice.name,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    invoice.displaySupplier,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDraft
                        ? AppStrings.tabDraft
                        : isPaid
                            ? AppStrings.tabPaid
                            : bucket == PurchaseInvoiceBucket.partlyPaid
                                ? AppStrings.tabPartlyPaid
                                : AppStrings.tabUnpaid,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InfoLine(
              label: AppStrings.invoiceNumber,
              value: invoice.name,
              isLtr: true,
            ),
            if (invoice.purchaseOrder.isNotEmpty)
              InfoLine(
                label: PurchaseStrings.purchaseOrderNumber,
                value: invoice.purchaseOrder,
                isLtr: true,
              ),
            if (due.isNotEmpty)
              InfoLine(
                label: AppStrings.invoiceDueDate,
                value: due,
                isLtr: true,
              ),
            InfoLine(
              label: PurchaseStrings.itemsCount,
              value: qtyText,
              isLtr: true,
            ),
            InfoLine(
              label: AppStrings.invoiceAmount,
              value: formatSignedAmount(invoice.grandTotal, currency: currency),
              isLtr: true,
              emphasize: !showPay,
            ),
            if (!isDraft)
              InfoLine(
                label: AppStrings.amountDue,
                value: formatSignedAmount(
                  invoice.outstandingAmount,
                  currency: currency,
                ),
                isLtr: true,
                emphasize: true,
              ),
            if (pendingAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  PurchaseStrings.paymentPending(
                    formatAmount(pendingAmount, currency: currency),
                  ),
                  style: TextStyle(fontSize: 12, color: scheme.tertiary),
                ),
              ),
            if (!isDraft) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (showPay) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _pay(context),
                        icon: const Icon(Icons.payments_outlined),
                        label: Text(PurchaseStrings.payToSupplierAction),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: PrintButton(
                      controller: controller,
                      doctype: 'Purchase Invoice',
                      name: invoice.name,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
