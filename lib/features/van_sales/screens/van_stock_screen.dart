import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/constants/warehouse_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/warehouse_models.dart';
import '../../../data/repositories/erp_warehouse_repository.dart';
import '../../inventory/screens/barcode_scanner_screen.dart';
import '../controllers/van_stock_controller.dart';

/// مخزون الفان: منتجات مستودع الفان فقط من ERPNext (Bin) باسمها وكودها
/// وكميتها ووحدتها، مع البحث بالاسم أو الكود، ومسح الباركود بالكاميرا لإظهار
/// المنتج المطابق.
class VanStockScreen extends StatefulWidget {
  const VanStockScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const VanStockScreen());

  @override
  State<VanStockScreen> createState() => _VanStockScreenState();
}

class _VanStockScreenState extends State<VanStockScreen> {
  late final VanStockController _c;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // متحكم مستقل للشاشة: يُنشأ عند فتحها ويُحذف عند إغلاقها
    _c = Get.put(VanStockController(context.read<ErpWarehouseRepository>()));
  }

  @override
  void dispose() {
    _search.dispose();
    Get.delete<VanStockController>();
    super.dispose();
  }

  Future<void> _scan() async {
    final messenger = ScaffoldMessenger.of(context);
    final code = await Navigator.of(context).push(BarcodeScannerScreen.route());
    if (code == null || !mounted) return;
    _search.clear();
    try {
      final hit = await _c.scan(code);
      if (hit == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(VanStrings.notInVan(code))),
        );
      }
    } catch (e) {
      debugPrint('VanStockScreen.scan failed: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(describeError(e, fallback: VanStrings.scanFailed)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(VanStrings.stockTitle),
            Text(
              _c.warehouse,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: VanStrings.scan,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scan,
          ),
        ],
      ),
      body: Column(
        children: [
          // البحث بالاسم أو الكود
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Obx(
              () => TextField(
                controller: _search,
                onChanged: _c.setQuery,
                decoration: InputDecoration(
                  hintText: VanStrings.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _c.query.value.isEmpty
                      ? IconButton(
                          tooltip: VanStrings.scan,
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _scan,
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            _c.setQuery('');
                          },
                        ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () => _c.loading.value && _c.hasAny
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox(height: 2),
          ),
          Expanded(child: Obx(_body)),
        ],
      ),
    );
  }

  Widget _body() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _c.items;
    final hit = _c.scanned.value;

    if (_c.loading.value && !_c.hasAny) {
      return LoadingView(message: VanStrings.loading);
    }
    final error = _c.error.value;
    if (error != null && !_c.hasAny) {
      return ErrorView(
        message: describeError(error, fallback: VanStrings.loadFailed),
        onRetry: _c.load,
      );
    }
    if (!_c.hasAny) {
      return RefreshIndicator(
        onRefresh: _c.load,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            EmptyView(
              icon: Icons.local_shipping_outlined,
              title: VanStrings.empty,
              message: VanStrings.emptyHint,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _c.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // نتيجة المسح: المنتج المطابق وحده مع زر لإظهار الكل
          if (hit != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      VanStrings.scanned(hit.itemCode),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _c.clearScan,
                    child: Text(VanStrings.clearScan),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                VanStrings.productsCount(items.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyView(
                icon: Icons.search_off,
                title: VanStrings.noMatch,
              ),
            )
          else
            for (final s in items)
              _ProductCard(stock: s, highlighted: hit != null),
        ],
      ),
    );
  }
}

/// منتج في الفان: الاسم والكود، والكمية المتوفرة بوحدة القياس
class _ProductCard extends StatelessWidget {
  final WarehouseStock stock;
  final bool highlighted;

  const _ProductCard({required this.stock, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = stock;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.inventory_2_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.itemName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${VanStrings.code}: ${s.itemCode}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  WarehouseStrings.qty(s.actualQty),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                Text(
                  s.uom,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  VanStrings.available,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
