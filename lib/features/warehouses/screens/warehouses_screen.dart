import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/warehouse_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../controllers/warehouses_controller.dart';
import 'pending_transfers_screen.dart';
import 'transfer_screen.dart';
import 'warehouse_stock_screen.dart';

/// قسم «المستودعات»: كل مستودعات الشركة من ERPNext. الضغط على مستودع يعرض
/// أصنافه بكمياتها؛ «نقل أصناف» ينشئ نقلًا مسودة، والأيقونة بالأعلى تعرض
/// النقل الذي ينتظر الاعتماد.
class WarehousesScreen extends StatelessWidget {
  const WarehousesScreen({super.key});

  static Route<void> route(BuildContext context) {
    final factory = context.read<WarehousesControllerFactory>();
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<WarehousesController>(
        create: (_) => factory.create(),
        child: const WarehousesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<WarehousesController>();
    final theme = Theme.of(context);

    Widget body;
    if (c.loading && c.warehouses.isEmpty) {
      body = LoadingView(message: WarehouseStrings.loadingWarehouses);
    } else if (c.error != null && c.warehouses.isEmpty) {
      body = ErrorView(message: c.error!, onRetry: c.load);
    } else if (c.warehouses.isEmpty) {
      body = EmptyView(
        icon: Icons.warehouse_outlined,
        title: WarehouseStrings.noWarehouses,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: c.load,
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: c.warehouses.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final w = c.warehouses[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: const Icon(Icons.warehouse_outlined),
              ),
              title: Text(w.label),
              subtitle: Text(
                w.parent.isEmpty
                    ? w.name
                    : '${w.name}\n${WarehouseStrings.parent(w.parent)}',
              ),
              isThreeLine: w.parent.isNotEmpty,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .push(WarehouseStockScreen.route(context, w)),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(WarehouseStrings.section),
        actions: [
          IconButton(
            tooltip: WarehouseStrings.pendingTitle,
            icon: const Icon(Icons.pending_actions_outlined),
            onPressed: () =>
                Navigator.of(context).push(PendingTransfersScreen.route(context)),
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).push(TransferScreen.route(context)),
        icon: const Icon(Icons.swap_horiz),
        label: Text(WarehouseStrings.newTransfer),
      ),
    );
  }
}
