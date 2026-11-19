import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/constants/warehouse_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/van_sale_models.dart';
import '../../../data/models/warehouse_models.dart';
import '../../../data/repositories/erp_van_sales_repository.dart';
import '../../../data/repositories/erp_warehouse_repository.dart';
import '../controllers/replenishment_controller.dart';

/// طلب تزويد الفان: منتجات الفان بكمياتها (الأقل أولًا)، اختيار المنتج والكمية
/// المطلوبة، ثم Material Request (Material Transfer) مسودة من Main Store - RTC
/// إلى Van - Ahmad - RTC، وعرض تفاصيله بعد الحفظ.
class ReplenishmentScreen extends StatefulWidget {
  const ReplenishmentScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ReplenishmentScreen());

  @override
  State<ReplenishmentScreen> createState() => _ReplenishmentScreenState();
}

class _ReplenishmentScreenState extends State<ReplenishmentScreen> {
  late final ReplenishmentController _c;

  @override
  void initState() {
    super.initState();
    // متحكم مستقل للشاشة: يُنشأ عند فتحها ويُحذف عند إغلاقها
    _c = Get.put(
      ReplenishmentController(
        context.read<ErpVanSalesRepository>(),
        context.read<ErpWarehouseRepository>(),
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<ReplenishmentController>();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final (request, error) = await _c.save();
    if (request != null) {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => _RequestDetails(request: request),
        ),
      );
    } else if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), duration: const Duration(seconds: 8)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(VanStrings.refillTitle)),
      body: Column(
        children: [
          // من / إلى
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _WarehouseChip(
                    label: VanStrings.from,
                    name: ErpConfig.mainStore,
                    icon: Icons.warehouse_outlined,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward),
                ),
                Expanded(
                  child: _WarehouseChip(
                    label: VanStrings.to,
                    name: ErpConfig.vanWarehouse,
                    icon: Icons.local_shipping_outlined,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => _c.query.value = v,
              decoration: InputDecoration(
                hintText: VanStrings.searchHint,
                prefixIcon: const Icon(Icons.search),
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
          Expanded(
            child: Obx(() {
              if (_c.loading.value && _c.stock.isEmpty) {
                return LoadingView(message: VanStrings.loading);
              }
              final error = _c.error.value;
              if (error != null && _c.stock.isEmpty) {
                return ErrorView(
                  message: describeError(
                    error,
                    fallback: VanStrings.loadFailed,
                  ),
                  onRetry: _c.load,
                );
              }
              if (_c.stock.isEmpty) {
                return EmptyView(
                  icon: Icons.local_shipping_outlined,
                  title: VanStrings.empty,
                );
              }
              final list = _c.visible;
              return RefreshIndicator(
                onRefresh: _c.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    Text(
                      VanStrings.refillHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final s in list)
                      _RefillCard(
                        key: ValueKey(s.itemCode),
                        controller: _c,
                        stock: s,
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Obx(() {
            final count = _c.requested.length;
            return FilledButton.icon(
              onPressed: _c.saving.value || count == 0 ? null : _save,
              icon: _c.saving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_shopping_cart_outlined),
              label: Text(
                count == 0
                    ? VanStrings.needRequestLines
                    : '${VanStrings.saveRequest} (${VanStrings.requestedCount(count)})',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _WarehouseChip extends StatelessWidget {
  final String label;
  final String name;
  final IconData icon;

  const _WarehouseChip({
    required this.label,
    required this.name,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSecondaryContainer),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// منتج في الفان: الكمية المتوفرة، وتحديده مع الكمية المطلوبة
class _RefillCard extends StatefulWidget {
  final ReplenishmentController controller;
  final WarehouseStock stock;

  const _RefillCard({super.key, required this.controller, required this.stock});

  @override
  State<_RefillCard> createState() => _RefillCardState();
}

class _RefillCardState extends State<_RefillCard> {
  late final TextEditingController _qty = TextEditingController(
    text: widget.controller.requested[widget.stock.itemCode] == null
        ? ''
        : WarehouseStrings.qty(
            widget.controller.requested[widget.stock.itemCode]!,
          ),
  );

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = widget.controller;
    final s = widget.stock;

    return Obx(() {
      final qty = c.requested[s.itemCode];
      final selected = c.requested.containsKey(s.itemCode);
      final error = selected ? ReplenishmentController.validate(s, qty) : null;

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: selected
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: scheme.primary, width: 2),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (v) {
                      if (v == true) {
                        c.setRequested(s, 1);
                        _qty.text = '1';
                      } else {
                        c.setRequested(s, null);
                        _qty.clear();
                      }
                    },
                  ),
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
                        Text(
                          s.itemCode,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        WarehouseStrings.qty(s.actualQty),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${s.uom} • ${VanStrings.available}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
                  child: TextField(
                    controller: _qty,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: !s.wholeNumber,
                    ),
                    onChanged: (v) => c.setRequested(s, parseAmount(v) ?? 0),
                    decoration: InputDecoration(
                      labelText: VanStrings.requestedQty,
                      suffixText: s.uom,
                      isDense: true,
                      border: const OutlineInputBorder(),
                      errorText: error,
                      errorMaxLines: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// تفاصيل الطلب بعد الحفظ كما قرأها التطبيق من ERPNext
class _RequestDetails extends StatelessWidget {
  final ReplenishmentRequest request;

  const _RequestDetails({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final r = request;

    Widget row(String label, String value, {bool ltr = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(VanStrings.requestSavedTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  row(VanStrings.requestNo, r.name, ltr: true),
                  row(VanStrings.requestStatus, r.status),
                  if (r.transactionDate != null)
                    row(
                      VanStrings.requestDate,
                      loc.formatMediumDate(r.transactionDate!),
                    ),
                  if (r.scheduleDate != null)
                    row(
                      VanStrings.requiredBy,
                      loc.formatMediumDate(r.scheduleDate!),
                    ),
                  row(VanStrings.from, r.fromWarehouse, ltr: true),
                  row(VanStrings.to, r.toWarehouse, ltr: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${VanStrings.products} (${r.lines.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < r.lines.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    title: Text(
                      r.lines[i].itemName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(r.lines[i].itemCode),
                    trailing: Text(
                      WarehouseStrings.qty(r.lines[i].qty, r.lines[i].uom),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            VanStrings.requestSavedNote,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(VanStrings.done),
          ),
        ),
      ),
    );
  }
}
