import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/warehouse_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/warehouse_models.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/warehouses_controller.dart';

/// النقل المحفوظ مسودة: المصدر والهدف والسبب، وأصناف كل نقل عند فتحه،
/// مع «اعتماد» (يتحرك المخزون الآن) أو «رفض» (حذف المسودة).
class PendingTransfersScreen extends StatelessWidget {
  const PendingTransfersScreen({super.key});

  static Route<void> route(BuildContext context) {
    final factory = context.read<WarehousesControllerFactory>();
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<PendingTransfersController>(
        create: (_) => factory.createPending(),
        child: const PendingTransfersScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PendingTransfersController>();

    Widget body;
    if (c.loading && c.transfers.isEmpty) {
      body = LoadingView(message: WarehouseStrings.loadingPending);
    } else if (c.error != null && c.transfers.isEmpty) {
      body = ErrorView(message: c.error!, onRetry: c.load);
    } else if (c.transfers.isEmpty) {
      body = RefreshIndicator(
        onRefresh: c.load,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            EmptyView(
              icon: Icons.task_alt_outlined,
              title: WarehouseStrings.noPending,
            ),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: c.load,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: c.transfers.length,
          itemBuilder: (_, i) => _TransferCard(transfer: c.transfers[i]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(WarehouseStrings.pendingTitle)),
      body: body,
    );
  }
}

class _TransferCard extends StatelessWidget {
  final StockTransfer transfer;

  const _TransferCard({required this.transfer});

  Future<void> _approve(BuildContext context) async {
    final c = context.read<PendingTransfersController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: WarehouseStrings.approveTitle(transfer.name),
      message: WarehouseStrings.approveMessage,
      confirmLabel: WarehouseStrings.approve,
      icon: Icons.verified_outlined,
    );
    if (!ok) return;
    final error = await c.approve(transfer);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? WarehouseStrings.approved(transfer.name)),
        duration: Duration(seconds: error == null ? 3 : 6),
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final c = context.read<PendingTransfersController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: WarehouseStrings.rejectTitle(transfer.name),
      message: WarehouseStrings.rejectMessage,
      confirmLabel: WarehouseStrings.reject,
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!ok) return;
    final error = await c.reject(transfer);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? WarehouseStrings.rejected(transfer.name)),
        duration: Duration(seconds: error == null ? 3 : 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PendingTransfersController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = transfer;
    final details = c.details(t.name);
    final busy = c.isBusy(t.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpansionTile(
            onExpansionChanged: (open) {
              if (open) c.loadDetails(t.name);
            },
            title: Text(
              t.name,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(child: Text(t.fromWarehouse)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 16),
                    ),
                    Flexible(child: Text(t.toWarehouse)),
                  ],
                ),
                Text(
                  t.remarks.isEmpty
                      ? t.postingDate
                      : '${t.postingDate}  •  ${t.remarks}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            children: [
              if (c.isLoadingDetails(t.name))
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (details != null)
                for (final item in details.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.itemName),
                              Text(
                                item.itemCode,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          WarehouseStrings.qty(item.qty, item.uom),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _reject(context),
                        style:
                            TextButton.styleFrom(foregroundColor: scheme.error),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(WarehouseStrings.reject),
                      ),
                      const SizedBox(width: 4),
                      FilledButton.icon(
                        onPressed: () => _approve(context),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(WarehouseStrings.approve),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
