import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/sales_invoice.dart';
import '../../customers/screens/gl_entries_screen.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/orders_controller.dart';
import '../controllers/sales_invoices_controller.dart';
import 'payment_sheet.dart';

/// بطاقة فاتورة مبيعات في قسم «الفواتير»: رقمها واسم العميل والمجموع وتاريخ
/// الاستحقاق والمبلغ المستحق، وتحتها الأزرار بحسب التبويب:
/// غير مدفوعة / مدفوعة جزئيًا: «دفع» و«طباعة»، مدفوعة: «طباعة» فقط، مسودة: بلا أزرار.
class SalesInvoiceCard extends StatefulWidget {
  final SalesInvoice invoice;

  /// مجموع دفعات محفوظة مسودة بانتظار اعتمادها في ERPNext
  final double pendingAmount;

  /// التبويب الذي تُعرض فيه (المسودة التي أنشأها التطبيق بالفوترة تُعرض «غير مدفوعة»)
  final InvoiceBucket bucket;

  const SalesInvoiceCard({
    super.key,
    required this.invoice,
    required this.bucket,
    this.pendingAmount = 0,
  });

  @override
  State<SalesInvoiceCard> createState() => _SalesInvoiceCardState();
}

class _SalesInvoiceCardState extends State<SalesInvoiceCard> {
  bool _printing = false;
  bool _reopening = false;

  SalesInvoice get _invoice => widget.invoice;

  Future<void> _pay() async {
    final controller = context.read<SalesInvoicesController>();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showPaymentSheet(
      context,
      invoice: _invoice,
      controller: controller,
    );
    if (saved) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.paymentSavedPending)),
      );
    }
  }

  /// يلغي الفاتورة (ومعها التسليم والطلبية) ويعيد الطلبية مسودة لتعديل أصنافها.
  /// المدفوع على الفاتورة يبقى رصيدًا في حساب العميل.
  Future<void> _reopen() async {
    if (_reopening) return;
    final orders = context.read<OrdersController>();
    final invoices = context.read<SalesInvoicesController>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.reopenTitle,
      message: AppStrings.reopenMessage,
      confirmLabel: AppStrings.reopenOrder,
      icon: Icons.edit_note_outlined,
    );
    if (!confirmed || !mounted) return;

    setState(() => _reopening = true);
    final result = await orders.reopenFromSalesInvoice(_invoice.name);
    if (mounted) setState(() => _reopening = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.result != null
              ? reopenSuccessMessage(result.result!)
              : result.error!,
        ),
        duration: const Duration(seconds: 6),
      ),
    );
    // الفاتورة أُلغيت أو حُذفت: تختفي من التبويبات
    if (result.result != null) await invoices.refresh();
  }

  Future<void> _print() async {
    if (_printing) return;
    final controller = context.read<SalesInvoicesController>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _printing = true);
    try {
      final pdf = await controller.downloadPdf(_invoice.name);
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name: '${_invoice.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.pdf',
      );
    } catch (e) {
      debugPrint('invoice print failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.invoicePdfFailed)),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bucket = widget.bucket;
    // فاتورة مسودة لم يعتمدها المسؤول بعد: مستحقها مجموعها ولا يمكن الدفع عليها
    final awaitingApproval = _invoice.docstatus == 0;
    final currency = displayCurrency(_invoice.currency);
    final settlement = _invoice.settlement;
    // المتبقي والمسدد بعملة حساب العميل إن اختلفت عن عملة الفاتورة
    final dueCurrency = displayCurrency(
      settlement?.displayIn(_invoice.currency) ?? _invoice.currency,
    );
    final showPay =
        bucket == InvoiceBucket.unpaid || bucket == InvoiceBucket.partlyPaid;
    // الدفع يحتاج فاتورة معتمدة (get_payment_entry)
    final canPay = showPay && !awaitingApproval;
    final canPrint = bucket != InvoiceBucket.draft;
    final due = _invoice.dueDate ?? '';
    final statusLabel = bucket == InvoiceBucket.draft
        ? AppStrings.tabDraft
        : awaitingApproval
            ? AppStrings.invoiceAwaitingApproval
            : AppStrings.invoiceStatus(_invoice.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _invoice.customerName.isEmpty
                      ? _invoice.customer
                      : _invoice.customerName,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: (bucket == InvoiceBucket.paid
                          ? AppColors.payment
                          : scheme.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: bucket == InvoiceBucket.paid
                        ? AppColors.payment
                        : scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Line(label: AppStrings.invoiceNumber, value: _invoice.name, isLtr: true),
          // قيمة الفاتورة كاملة، ثم المسدد منها، ثم المتبقي (كلها من ERPNext)
          _Line(
            label: AppStrings.invoiceTotalValue,
            value: formatSignedAmount(_invoice.invoiceTotal, currency: currency),
            isLtr: true,
          ),
          if (due.isNotEmpty)
            _Line(label: AppStrings.invoiceDueDate, value: due, isLtr: true),
          if (!awaitingApproval && settlement != null) ...[
            if (settlement.fromAdvance > 0.005)
              _Line(
                label: AppStrings.invoicePaidFromCredit,
                value: formatAmount(settlement.fromAdvance, currency: dueCurrency),
                isLtr: true,
              ),
            if (settlement.paid > 0.005)
              _Line(
                label: AppStrings.invoicePaid,
                value: formatAmount(settlement.paid, currency: dueCurrency),
                isLtr: true,
              ),
          ],
          if (bucket != InvoiceBucket.draft)
            _Line(
              label: AppStrings.amountDue,
              value: formatSignedAmount(
                awaitingApproval
                    ? _invoice.invoiceTotal
                    : _invoice.outstandingAmount,
                currency: awaitingApproval ? currency : dueCurrency,
              ),
              isLtr: true,
              emphasize: true,
            ),
          if (widget.pendingAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                AppStrings.paymentPending(
                  formatAmount(widget.pendingAmount, currency: currency),
                ),
                style: TextStyle(fontSize: 12, color: scheme.tertiary),
              ),
            ),
          if (canPrint) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (showPay) ...[
                  Expanded(
                    // مظلل حتى يعتمد المسؤول الفاتورة في ERPNext
                    child: FilledButton.icon(
                      onPressed: canPay ? _pay : null,
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(AppStrings.payAction),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _printing ? null : _print,
                    icon: _printing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_outlined),
                    label: Text(AppStrings.printInvoice),
                  ),
                ),
              ],
            ),
            if (showPay && !canPay)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  AppStrings.payWaitingInvoiceApproval,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
            // غير مدفوعة / مدفوعة جزئيًا / مدفوعة: إرجاع الطلبية للتعديل
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _reopening ? null : _reopen,
              icon: _reopening
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit_note_outlined),
              label: Text(AppStrings.reopenOrder),
            ),
          ],
          // كل الحالات (حتى المسودة: تظهر «بانتظار الاعتماد» دون طلب قيودها)
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              GlEntriesScreen.forInvoice(_invoice.name),
            ),
            icon: const Icon(Icons.account_balance_outlined),
            label: Text(AppStrings.glEntriesTitle),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool isLtr;
  final bool emphasize;

  const _Line({
    required this.label,
    required this.value,
    this.isLtr = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                value,
                textDirection: isLtr ? TextDirection.ltr : null,
                style: TextStyle(
                  fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
                  fontSize: emphasize ? 16 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
