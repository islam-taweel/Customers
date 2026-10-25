import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/invoice.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/orders_controller.dart';
import '../controllers/sales_invoices_controller.dart';

/// أي تبويب في قسم التسليمات تُعرض فيه البطاقة
enum DeliveryTileMode {
  /// مسودة: سند تسليم لم يُعتمد بعد، بلا أزرار
  draft,

  /// انتظار الفوترة: زر «فوترة» (مظلل حتى الاعتماد) وبجانبه زر «طباعة»
  toBill,

  /// مكتملة: فواتير فُوتِرت، بلا أزرار
  completed,
}

/// بطاقة تسليم في قسم «التسليمات»: بيانات الطلبية، وتحتها الأزرار بحسب التبويب.
class DeliveryTile extends StatefulWidget {
  final Invoice invoice;
  final DeliveryTileMode mode;
  final VoidCallback onTap;

  /// يُستدعى بعد نجاح الفوترة (لننتقل إلى تبويب «مكتملة»)
  final VoidCallback? onBilled;

  const DeliveryTile({
    super.key,
    required this.invoice,
    required this.mode,
    required this.onTap,
    this.onBilled,
  });

  @override
  State<DeliveryTile> createState() => _DeliveryTileState();
}

class _DeliveryTileState extends State<DeliveryTile> {
  bool _busy = false;

  Invoice get _invoice => widget.invoice;

  String get _statusLabel => switch (widget.mode) {
        DeliveryTileMode.draft => AppStrings.deliveryDraftStatus,
        DeliveryTileMode.toBill => AppStrings.invoiceStatus('To Bill'),
        // الفاتورة مسودة ينتظر اعتمادها في ERPNext حتى تصير الطلبية مفوترة فعلًا
        DeliveryTileMode.completed => _invoice.billed
            ? AppStrings.invoiceStatus('Completed')
            : AppStrings.invoiceAwaitingApproval,
      };

  String get _fileName =>
      'delivery-${_invoice.displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.pdf';

  Future<void> _bill() async {
    if (_busy) return;
    final orders = context.read<OrdersController>();
    final invoices = context.read<SalesInvoicesController>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.billTitle,
      message: AppStrings.billMessage,
      confirmLabel: AppStrings.bill,
      icon: Icons.request_quote_outlined,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final error = await orders.bill(_invoice);
    if (!mounted) return;
    setState(() => _busy = false);

    if (error == null) {
      // الفاتورة المسودة تظهر فورًا في تبويب «غير مدفوعة» بقسم الفواتير
      invoices.refresh();
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.orderBilled)));
      widget.onBilled?.call();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _print() async {
    if (_busy) return;
    final orders = context.read<OrdersController>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final pdf = await orders.downloadDeliveryPdf(_invoice);
      await Printing.layoutPdf(onLayout: (_) async => pdf, name: _fileName);
    } catch (e) {
      debugPrint('delivery print failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.invoicePdfFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entry = _invoice.toListEntry();
    final color = widget.mode == DeliveryTileMode.completed
        ? AppColors.payment
        : scheme.primary;
    final canBill = _invoice.canBill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          onTap: widget.onTap,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.local_shipping_outlined, color: color),
          ),
          title: Text(
            _invoice.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${_invoice.displayName} • ${entry.postingDate} • $_statusLabel',
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
        ),
        if (widget.mode == DeliveryTileMode.toBill)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      // مظلل (معطّل) حتى يُعتمد التسليم في ERPNext
                      child: FilledButton.icon(
                        onPressed: (!canBill || _busy) ? null : _bill,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.request_quote_outlined),
                        label: Text(AppStrings.bill),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _print,
                        icon: const Icon(Icons.print_outlined),
                        label: Text(AppStrings.printInvoice),
                      ),
                    ),
                  ],
                ),
                if (!canBill)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      AppStrings.billWaitingApproval,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
