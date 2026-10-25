import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/purchase_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/purchase_models.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/purchases_controller.dart';

/// صف أمر شراء: اسم المورد، رقم الأمر وتاريخه وحالته، والمبلغ. في تبويب «مسودة»
/// تظهر تحته أزرار «اعتماد» و«حذف».
class PurchaseOrderTile extends StatefulWidget {
  final PurchaseOrder order;
  final VoidCallback onTap;

  const PurchaseOrderTile({super.key, required this.order, required this.onTap});

  @override
  State<PurchaseOrderTile> createState() => _PurchaseOrderTileState();
}

class _PurchaseOrderTileState extends State<PurchaseOrderTile> {
  bool _busy = false;

  PurchaseOrder get _order => widget.order;

  String get _statusLabel => switch (_order.stage) {
        PurchaseStage.draft => AppStrings.tabDraft,
        PurchaseStage.toReceive => PurchaseStrings.tabToReceive,
        PurchaseStage.toBill => _order.awaitingReceiptApproval
            ? PurchaseStrings.receiptAwaitingApproval
            : AppStrings.tabToBill,
        PurchaseStage.completed => AppStrings.tabCompleted,
      };

  Future<void> _approve() async {
    final controller = context.read<PurchasesController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: PurchaseStrings.approveOrderTitle,
      message: PurchaseStrings.approveOrderMessage,
      confirmLabel: PurchaseStrings.approve,
      icon: Icons.verified_outlined,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final error = await controller.approveOrder(_order);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? PurchaseStrings.orderApproved)),
    );
  }

  Future<void> _delete() async {
    final controller = context.read<PurchasesController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: PurchaseStrings.deleteOrderTitle,
      message: PurchaseStrings.deleteOrderMessage,
      confirmLabel: AppStrings.delete,
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final error = await controller.deleteOrder(_order);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? PurchaseStrings.orderDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _order.stage == PurchaseStage.completed
        ? AppColors.payment
        : scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          onTap: widget.onTap,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.shopping_cart_outlined, color: color),
          ),
          title: Text(
            _order.displaySupplier,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${_order.name} • ${_order.transactionDate} • $_statusLabel',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          trailing: Text(
            formatSignedAmount(
              _order.grandTotal,
              currency: displayCurrency(_order.currency),
            ),
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        if (_order.stage == PurchaseStage.draft)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _approve,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: Text(PurchaseStrings.approve),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(AppStrings.delete),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
