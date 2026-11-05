import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/returns_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/return_models.dart';
import '../../order/widgets/qty_control.dart';
import '../controllers/sales_returns_controller.dart';

/// أصناف الفاتورة: المباع، وما أُرجع سابقًا، والمتاح للإرجاع، وكمية الإرجاع لكل صنف.
/// زر «إنشاء المرتجع» يحفظ إشعار دائن وإرجاع البضاعة مسودتين. تعود الشاشة بـ true إن حُفظ.
class ReturnItemsScreen extends StatefulWidget {
  const ReturnItemsScreen({super.key});

  static Route<bool> route(BuildContext context, ReturnInvoice invoice) {
    final factory = context.read<SalesReturnsControllerFactory>();
    return MaterialPageRoute<bool>(
      builder: (_) => ChangeNotifierProvider<ReturnItemsController>(
        create: (_) => factory.createItems(invoice),
        child: const ReturnItemsScreen(),
      ),
    );
  }

  @override
  State<ReturnItemsScreen> createState() => _ReturnItemsScreenState();
}

class _ReturnItemsScreenState extends State<ReturnItemsScreen> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String _money(ReturnItemsController c, double v) =>
      formatAmount(v, currency: displayCurrency(c.invoice.currency));

  Future<void> _create() async {
    final c = context.read<ReturnItemsController>();
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    if (c.chosenCount == 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(ReturnsStrings.nothingChosen)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ReturnsStrings.confirmTitle),
        content: Text(
          ReturnsStrings.confirmBody(c.chosenCount, _money(c, c.returnTotal)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ReturnsStrings.createReturn),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    c.reason = _reason.text;
    final result = await c.create();
    if (!mounted) return;
    final created = result.created;
    if (created == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.error ?? ReturnsStrings.createFailed),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline),
        title: Text(ReturnsStrings.createdTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ReturnsStrings.creditNoteSaved(created.creditNote)),
            for (final dn in created.stockReturns) ...[
              const SizedBox(height: 6),
              Text(ReturnsStrings.stockReturnSaved(dn)),
            ],
            for (final e in created.stockErrors.entries) ...[
              const SizedBox(height: 6),
              Text(
                ReturnsStrings.stockReturnFailed(e.key, e.value),
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ReturnsStrings.ok),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReturnItemsController>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.invoice.name),
            Text(
              c.invoice.postingDate,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: _body(context, c),
      bottomNavigationBar: c.items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ReturnsStrings.returnTotal(_money(c, c.returnTotal)),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: c.saving ? null : _create,
                      icon: c.saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.assignment_return_outlined),
                      label: Text(ReturnsStrings.createReturn),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _body(BuildContext context, ReturnItemsController c) {
    if (c.loading && c.items.isEmpty) {
      return LoadingView(message: ReturnsStrings.loadingItems);
    }
    if (c.error != null && c.items.isEmpty) {
      return ErrorView(message: c.error!, onRetry: c.load);
    }
    if (c.items.isEmpty) {
      return EmptyView(
        icon: Icons.inventory_2_outlined,
        title: ReturnsStrings.noItems,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        for (final item in c.items)
          _ItemCard(item: item, money: (v) => _money(c, v)),
        const SizedBox(height: 8),
        TextField(
          controller: _reason,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: ReturnsStrings.reasonLabel,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ReturnableItem item;
  final String Function(double) money;

  const _ItemCard({required this.item, required this.money});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReturnItemsController>();
    final theme = Theme.of(context);
    final unit = item.uom.isEmpty ? '' : ' ${item.uom}';
    final error = c.errorOf(item);
    final showError = error != null && (c.showErrors || c.qtyOf(item) > 0);
    final done = item.returnable <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: showError
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.error),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.itemName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${item.itemCode}  •  ${money(item.rate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Qty(
                  label: ReturnsStrings.soldQty,
                  value: '${formatQty(item.qty)}$unit',
                ),
                _Qty(
                  label: ReturnsStrings.returnedQty,
                  value: '${formatQty(item.returnedQty)}$unit',
                  color: item.returnedQty > 0 ? theme.colorScheme.error : null,
                ),
                _Qty(
                  label: ReturnsStrings.returnableQty,
                  value: '${formatQty(item.returnable)}$unit',
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (done)
              Text(
                ReturnsStrings.fullyReturned,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              Row(
                children: [
                  Expanded(child: Text(ReturnsStrings.returnQty)),
                  QtyControl(
                    qty: c.qtyOf(item),
                    max: item.returnable,
                    onIncrement: () => c.increment(item),
                    onDecrement: () => c.decrement(item),
                    onTyped: (v) => c.setQty(item, v),
                    dense: true,
                  ),
                ],
              ),
            if (showError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Qty extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _Qty({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
