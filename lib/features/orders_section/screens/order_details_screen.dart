import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/invoice_pdf_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/invoice.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/erp_ledger_repository.dart';
import '../../customers/screens/gl_entries_screen.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../../customers/widgets/invoice_card.dart';
import '../controllers/orders_controller.dart';

/// تفاصيل طلبية معتمدة: تظهر كفاتورة بحالتها (بانتظار التسليم / الفوترة /
/// مكتملة)، وبالأسفل زر «تسليم» (إن كانت بانتظار التسليم) وزر «طباعة».
/// قبل التسليم يمكن «إرجاعها للتعديل» فتعود مسودة. تُرجع true إن سُلِّمت الطلبية
/// أو أُعيدت مسودة من هذه الشاشة.
class OrderDetailsScreen extends StatefulWidget {
  final Invoice invoice;

  const OrderDetailsScreen({super.key, required this.invoice});

  static Route<bool> route(Invoice invoice, OrdersController controller) {
    return MaterialPageRoute<bool>(
      builder: (_) => ChangeNotifierProvider<OrdersController>.value(
        value: controller,
        child: OrderDetailsScreen(invoice: invoice),
      ),
    );
  }

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  /// يحدد الجزء الذي يُلتقط كصورة عند تعذّر PDF الرسمي
  final GlobalKey _invoiceKey = GlobalKey();
  bool _busy = false;

  Invoice get _invoice => widget.invoice;

  String get _fileName =>
      'order-${_invoice.displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.pdf';

  /// PDF الرسمي من ERPNext، وإلا ملف مولَّد من الفاتورة المعروضة.
  Future<Uint8List> _pdfBytes() async {
    try {
      final orderId = _invoice.orderId ?? '';
      if (orderId.isEmpty) throw StateError('no order id');
      return await context.read<OrdersController>().downloadPdf(orderId);
    } catch (e) {
      debugPrint('order pdf failed, using local capture: $e');
      return InvoicePdfService.fromBoundary(_invoiceKey);
    }
  }

  Future<void> _print() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final pdf = await _pdfBytes();
      await Printing.layoutPdf(onLayout: (_) async => pdf, name: _fileName);
    } catch (e) {
      debugPrint('order print failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.invoicePdfFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deliver() async {
    if (_busy) return;
    final orders = context.read<OrdersController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deliverTitle,
      message: AppStrings.deliverMessage,
      confirmLabel: AppStrings.deliver,
      icon: Icons.local_shipping_outlined,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final error = await orders.deliver(_invoice);
    if (!mounted) return;
    setState(() => _busy = false);

    if (error == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.orderDelivered)),
      );
      navigator.pop(true);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _reopen() async {
    if (_busy) return;
    final orders = context.read<OrdersController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.reopenTitle,
      message: AppStrings.reopenMessage,
      confirmLabel: AppStrings.reopenOrder,
      icon: Icons.edit_note_outlined,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final result = await orders.reopen(_invoice);
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(reopenSuccessMessage(result.result!)),
          duration: const Duration(seconds: 6),
        ),
      );
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.error!),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _invoice.toDetail();
    final canDeliver = _invoice.stage == OrderStage.toDeliver &&
        !_invoice.isErpDeliveryDraft;
    final canReopen = context.read<OrdersController>().canReopen(_invoice);
    // طلبية معتمدة في ERPNext: قيودها (تسليم/فوترة/دفعات) في كل المراحل
    final inErp = canReopen;
    final billed =
        _invoice.billed || (_invoice.salesInvoice ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(_invoice.displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(
                  key: _invoiceKey,
                  child: InvoiceCard(
                    number: detail.name,
                    customerName: detail.customerName,
                    customerPhone: _invoice.customerPhone,
                    amount: detail.grandTotal,
                    date: detail.postingDate,
                    dueDate: detail.dueDate,
                    status: detail.status,
                    currency: displayCurrency(detail.currency),
                    items: detail.items,
                    notes: _invoice.notes,
                  ),
                ),
                // فُوترت: قيمة فاتورتها والمسدد منها والمتبقي كما في ERPNext
                if (inErp && billed) ...[
                  const SizedBox(height: 16),
                  _OrderInvoicesSummary(orderId: _invoice.orderId!),
                ],
              ],
            ),
          ),
        ),
      ),
      // الأزرار ثابتة بالأسفل
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // كل المراحل: قيود التسليم والفوترة والدفعات (الطلبية وحدها بلا قيود)
                  if (inErp) ...[
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        GlEntriesScreen.forOrder(_invoice.orderId!),
                      ),
                      icon: const Icon(Icons.account_balance_outlined),
                      label: Text(AppStrings.glEntriesTitle),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // في أي مرحلة: إلغاء الاعتماد (والتسليم والفوترة) وإرجاعها مسودة
                  if (canReopen) ...[
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _reopen,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.edit_note_outlined),
                      label: Text(AppStrings.reopenOrder),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      if (canDeliver) ...[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _deliver,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.local_shipping_outlined),
                            label: Text(AppStrings.deliver),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _print,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.print_outlined),
                          label: Text(AppStrings.printInvoice),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// فواتير الطلبية في ERPNext: قيمة كل فاتورة كاملة، والمسدد من رصيد سابق،
/// والمدفوع، والمتبقي (outstanding_amount كما هو، بلا خصم مكرر).
class _OrderInvoicesSummary extends StatefulWidget {
  final String orderId;

  const _OrderInvoicesSummary({required this.orderId});

  @override
  State<_OrderInvoicesSummary> createState() => _OrderInvoicesSummaryState();
}

class _OrderInvoicesSummaryState extends State<_OrderInvoicesSummary> {
  late final Future<List<OrderInvoice>> _future =
      context.read<ErpLedgerRepository>().orderInvoices(widget.orderId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FutureBuilder<List<OrderInvoice>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        // دون اتصال أو تعذّر: لا نعرض أرقامًا تقديرية
        final invoices = snapshot.data ?? const [];
        if (snapshot.hasError || invoices.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final inv in invoices)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _SettlementLines(invoice: inv),
              ),
          ],
        );
      },
    );
  }
}

class _SettlementLines extends StatelessWidget {
  final OrderInvoice invoice;

  const _SettlementLines({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = invoice.settlement;
    final currency = displayCurrency(s.displayIn(invoice.currency));
    final draft = invoice.docstatus == 0;

    Widget line(String label, double v, {bool strong = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: strong ? null : scheme.onSurfaceVariant,
                    fontWeight: strong ? FontWeight.w700 : null,
                  ),
                ),
              ),
              Text(
                formatAmount(v, currency: currency),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.voucherTypeLabel('Sales Invoice'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              invoice.name,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        if (draft)
          Text(
            AppStrings.invoiceAwaitingApproval,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.tertiary),
          ),
        const SizedBox(height: 6),
        line(AppStrings.invoiceTotalValue, s.total, strong: true),
        // المسودة: لا مسدد ولا متبقٍ نهائي قبل اعتمادها
        if (!draft) ...[
          if (s.fromAdvance > 0.005)
            line(AppStrings.invoicePaidFromCredit, s.fromAdvance),
          if (s.paid > 0.005) line(AppStrings.invoicePaid, s.paid),
          line(
            AppStrings.invoiceOutstanding,
            s.outstanding,
            strong: true,
            color: AppColors.forBalance(s.outstanding),
          ),
        ],
      ],
    );
  }
}
