import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/purchase_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/purchase_models.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/purchases_controller.dart';
import '../screens/purchase_details_screen.dart';
import 'purchase_print.dart';

/// بطاقة استلام. «بانتظار الفوترة»: زر «فوترة» (على الاستلام المعتمد فقط) و«طباعة».
/// «مسودة» و«مكتملة»: بلا أزرار.
class PurchaseReceiptTile extends StatefulWidget {
  final PurchaseReceipt receipt;
  final bool showActions;

  const PurchaseReceiptTile({
    super.key,
    required this.receipt,
    this.showActions = false,
  });

  @override
  State<PurchaseReceiptTile> createState() => _PurchaseReceiptTileState();
}

class _PurchaseReceiptTileState extends State<PurchaseReceiptTile> {
  bool _busy = false;

  PurchaseReceipt get _receipt => widget.receipt;

  Future<void> _bill() async {
    final controller = context.read<PurchasesController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: PurchaseStrings.billTitle,
      message: PurchaseStrings.billMessage,
      confirmLabel: PurchaseStrings.bill,
      icon: Icons.request_quote_outlined,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final error = await controller.billReceipt(_receipt);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? PurchaseStrings.billed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = context.read<PurchasesController>();
    final done = _receipt.docstatus == 1 && _receipt.billed;
    final color = done ? AppColors.payment : scheme.primary;
    final status = _receipt.docstatus == 0
        ? PurchaseStrings.receiptDraftStatus
        : done
            ? AppStrings.tabCompleted
            : AppStrings.tabToBill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          onTap: () => Navigator.push(
            context,
            PurchaseDetailsScreen.route(
              controller,
              doctype: 'Purchase Receipt',
              name: _receipt.name,
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.move_to_inbox_outlined, color: color),
          ),
          title: Text(
            _receipt.displaySupplier,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${_receipt.name} • ${_receipt.postingDate} • $status',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          trailing: Text(
            formatSignedAmount(
              _receipt.grandTotal,
              currency: displayCurrency(_receipt.currency),
            ),
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        if (widget.showActions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_busy || !_receipt.canBill) ? null : _bill,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.request_quote_outlined),
                    label: Text(PurchaseStrings.bill),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrintButton(
                    controller: controller,
                    doctype: 'Purchase Receipt',
                    name: _receipt.name,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
