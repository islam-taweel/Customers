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
import '../../../data/models/van_sale_models.dart';
import '../../../data/models/warehouse_models.dart';
import '../../../data/repositories/erp_van_sales_repository.dart';
import '../../../data/repositories/erp_warehouse_repository.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/end_of_day_controller.dart';

const _green = Color(0xFF2E7D32);
const _orange = Color(0xFFEF6C00);

/// نهاية اليوم لمندوب الفان: تبويب «جرد الفان» (كمية النظام، الكمية الفعلية،
/// الفرق، وتسوية مخزون مسودة) وتبويب «مبيعات اليوم» (الفواتير وإجمالي المبيعات
/// والإرجاعات).
class EndOfDayScreen extends StatefulWidget {
  const EndOfDayScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const EndOfDayScreen());

  @override
  State<EndOfDayScreen> createState() => _EndOfDayScreenState();
}

class _EndOfDayScreenState extends State<EndOfDayScreen> {
  late final EndOfDayController _c;

  @override
  void initState() {
    super.initState();
    // متحكم مستقل للشاشة: يُنشأ عند فتحها ويُحذف عند إغلاقها
    _c = Get.put(
      EndOfDayController(
        context.read<ErpVanSalesRepository>(),
        context.read<ErpWarehouseRepository>(),
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<EndOfDayController>();
    super.dispose();
  }

  Future<void> _reconcile() async {
    final messenger = ScaffoldMessenger.of(context);
    final diffs = _c.differences.length;
    if (diffs > 0 && _c.invalid.isEmpty) {
      final ok = await ConfirmDialog.show(
        context,
        title: VanStrings.reconcileTitle,
        message: VanStrings.reconcileMessage(diffs),
        confirmLabel: VanStrings.createReconciliation,
        icon: Icons.inventory_outlined,
      );
      if (!ok) return;
    }
    final (name, error) = await _c.reconcile();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? VanStrings.reconcileSaved(name!)),
        duration: Duration(seconds: error == null ? 4 : 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(VanStrings.eodTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: VanStrings.stockCountTab),
              Tab(text: VanStrings.daySalesTab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CountTab(controller: _c, onReconcile: _reconcile),
            _SalesTab(controller: _c),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── جرد الفان ─────────────────────────

class _CountTab extends StatelessWidget {
  final EndOfDayController controller;
  final VoidCallback onReconcile;

  const _CountTab({required this.controller, required this.onReconcile});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Obx(() {
      if (c.stockLoading.value && c.stock.isEmpty) {
        return LoadingView(message: VanStrings.loading);
      }
      final error = c.stockError.value;
      if (error != null && c.stock.isEmpty) {
        return ErrorView(
          message: describeError(error, fallback: VanStrings.loadFailed),
          onRetry: c.loadStock,
        );
      }
      if (c.stock.isEmpty) {
        return EmptyView(
          icon: Icons.local_shipping_outlined,
          title: VanStrings.empty,
        );
      }
      final list = c.visibleStock;
      final diffs = c.differences.length;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (v) => c.query.value = v,
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
          SwitchListTile(
            value: c.onlyDifferences.value,
            onChanged: (v) => c.onlyDifferences.value = v,
            title: Text(VanStrings.onlyDifferences),
            subtitle: Text(
              VanStrings.differencesCount(diffs),
              style: TextStyle(
                color: diffs > 0 ? _orange : _green,
                fontWeight: FontWeight.w700,
              ),
            ),
            dense: true,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: c.loadStock,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    VanStrings.countHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final s in list)
                    _CountCard(
                      key: ValueKey(s.itemCode),
                      controller: c,
                      stock: s,
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: FilledButton.icon(
                onPressed: c.reconciling.value ? null : onReconcile,
                icon: c.reconciling.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.inventory_outlined),
                label: Text(VanStrings.createReconciliation),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// منتج في الجرد: كمية النظام، حقل الكمية الفعلية، والفرق (ملوّن)
class _CountCard extends StatefulWidget {
  final EndOfDayController controller;
  final WarehouseStock stock;

  const _CountCard({super.key, required this.controller, required this.stock});

  @override
  State<_CountCard> createState() => _CountCardState();
}

class _CountCardState extends State<_CountCard> {
  late final TextEditingController _field = TextEditingController(
    text: WarehouseStrings.qty(widget.controller.physicalOf(widget.stock)),
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = widget.controller;
    final s = widget.stock;

    return Obx(() {
      // يُعاد البناء عند تغيّر الكمية الفعلية أو صلاحيتها
      final diff = c.differenceOf(s);
      final bad = c.invalid.contains(s.itemCode);
      final has = diff.abs() > 1e-9;
      final color = !has
          ? _green
          : diff > 0
          ? scheme.primary
          : scheme.error;

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: has
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color, width: 1.5),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      has
                          ? '${VanStrings.difference}: ${diff > 0 ? '+' : ''}${WarehouseStrings.qty(diff, s.uom)}'
                          : '✓',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          VanStrings.systemQty,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          WarehouseStrings.qty(s.actualQty, s.uom),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _field,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: !s.wholeNumber,
                      ),
                      onChanged: (v) => c.setPhysical(s, parseAmount(v)),
                      decoration: InputDecoration(
                        labelText: VanStrings.physicalQty,
                        suffixText: s.uom,
                        isDense: true,
                        border: const OutlineInputBorder(),
                        errorText: bad ? VanStrings.qtyNotNegative : null,
                        errorMaxLines: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ───────────────────────── مبيعات اليوم ─────────────────────────

class _SalesTab extends StatelessWidget {
  final EndOfDayController controller;

  const _SalesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Obx(() {
      if (c.salesLoading.value && c.sales.isEmpty) {
        return LoadingView(message: VanStrings.loadingDaySales);
      }
      final error = c.salesError.value;
      if (error != null && c.sales.isEmpty) {
        return ErrorView(
          message: describeError(error, fallback: VanStrings.daySalesFailed),
          onRetry: c.loadSales,
        );
      }
      final sales = c.submittedSales;
      final returns = c.submittedReturns;
      final drafts = c.drafts;

      Widget tile(String label, String value, String sub, Color color) =>
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  Text(
                    sub,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );

      return RefreshIndicator(
        onRefresh: c.loadSales,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                tile(
                  VanStrings.totalSales,
                  formatAmount(c.totalSales),
                  VanStrings.invoicesCount(sales.length),
                  _green,
                ),
                const SizedBox(width: 10),
                tile(
                  VanStrings.totalReturns,
                  formatAmount(c.totalReturns),
                  VanStrings.returnsCount(returns.length),
                  scheme.error,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                title: Text(
                  VanStrings.netSales,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: Text(
                  formatAmount(c.totalSales - c.totalReturns),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
            if (drafts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, color: _orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        VanStrings.draftsPending(
                          drafts.length,
                          formatAmount(c.draftsTotal),
                        ),
                        style: const TextStyle(
                          color: _orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              VanStrings.dayTotalsNote,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 12),
            if (c.sales.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: EmptyView(
                  icon: Icons.receipt_long_outlined,
                  title: VanStrings.noDaySales,
                ),
              )
            else
              for (final s in c.sales) _SaleTile(sale: s),
          ],
        ),
      );
    });
  }
}

class _SaleTile extends StatelessWidget {
  final DaySale sale;

  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = sale;
    final color = s.isReturn ? scheme.error : _green;

    final card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            s.isReturn
                ? Icons.assignment_return_outlined
                : Icons.receipt_long_outlined,
            color: color,
          ),
        ),
        title: Text(
          s.customerName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            s.name,
            if (s.isReturn) VanStrings.returnLabel,
            if (s.isDraft) VanStrings.draftLabel else s.status,
          ].join('  •  '),
        ),
        trailing: Text(
          formatAmount(s.total),
          textDirection: TextDirection.ltr,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
    // المسودات باهتة: غير محتسبة في الإجماليات
    return s.isDraft ? Opacity(opacity: 0.55, child: card) : card;
  }
}
