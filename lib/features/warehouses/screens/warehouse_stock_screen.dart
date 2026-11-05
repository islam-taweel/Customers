import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/warehouse_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/warehouse_models.dart';
import '../controllers/warehouses_controller.dart';
import '../widgets/stock_tile.dart';
import 'transfer_screen.dart';

/// أصناف مستودع بكمياتها (Bin): الموجود والمحجوز والمتاح، مع البحث وزر النقل منه.
class WarehouseStockScreen extends StatefulWidget {
  const WarehouseStockScreen({super.key});

  static Route<void> route(BuildContext context, Warehouse warehouse) {
    final factory = context.read<WarehousesControllerFactory>();
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<WarehouseStockController>(
        create: (_) => factory.createStock(warehouse),
        child: const WarehouseStockScreen(),
      ),
    );
  }

  @override
  State<WarehouseStockScreen> createState() => _WarehouseStockScreenState();
}

class _WarehouseStockScreenState extends State<WarehouseStockScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    final c = context.read<WarehouseStockController>();
    await Navigator.of(context)
        .push(TransferScreen.route(context, from: c.warehouse.name));
    // بعد الاعتماد قد تتغير الكميات
    if (mounted) await c.load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<WarehouseStockController>();
    final theme = Theme.of(context);
    final items = c.items;

    Widget body;
    if (c.loading && !c.hasAny) {
      body = LoadingView(message: WarehouseStrings.loadingItems);
    } else if (c.error != null && !c.hasAny) {
      body = ErrorView(message: c.error!, onRetry: c.load);
    } else if (items.isEmpty) {
      body = EmptyView(
        icon: c.query.isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
        title: WarehouseStrings.noItems,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: c.load,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          itemCount: items.length,
          itemBuilder: (_, i) => StockTile(stock: items[i]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.warehouse.label),
            if (c.hasAny)
              Text(
                WarehouseStrings.itemsCount(items.length),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: c.setQuery,
              decoration: InputDecoration(
                hintText: WarehouseStrings.searchItems,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: c.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          c.setQuery('');
                        },
                      ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (c.loading && c.hasAny) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: c.hasAny
          ? FloatingActionButton.extended(
              onPressed: _transfer,
              icon: const Icon(Icons.swap_horiz),
              label: Text(WarehouseStrings.transferFromHere),
            )
          : null,
    );
  }
}
