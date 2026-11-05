import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/warehouse_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/warehouse_models.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/warehouses_controller.dart';
import '../widgets/stock_tile.dart';

/// نقل أصناف بين مستودعين: المصدر والهدف من ERPNext، ثم أصناف المصدر
/// بكمياتها، والضغط على صنف يحدد الكمية المنقولة. يُحفظ النقل مسودة
/// (Stock Entry / Material Transfer) ولا يتحرك المخزون إلا بعد الاعتماد.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  static Route<void> route(BuildContext context, {String? from}) {
    final factory = context.read<WarehousesControllerFactory>();
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<TransferController>(
        create: (_) => factory.createTransfer(from: from),
        child: const TransferScreen(),
      ),
    );
  }

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _editQty(WarehouseStock s) async {
    final c = context.read<TransferController>();
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _QtyDialog(stock: s, current: c.quantities[s.itemCode]),
    );
    // null = إلغاء، 0 = إزالة
    if (result != null) c.setQty(s, result);
  }

  Future<void> _save() async {
    final c = context.read<TransferController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // تحذير: كمية من المحجوز لأوامر البيع
    final overuse = c.reservedOveruse;
    if (overuse.isNotEmpty) {
      final ok = await ConfirmDialog.show(
        context,
        title: WarehouseStrings.reservedConfirmTitle,
        message: WarehouseStrings.reservedConfirmMessage(
          overuse.map((s) => '• ${s.itemName}').join('\n'),
        ),
        confirmLabel: WarehouseStrings.continueAnyway,
        icon: Icons.warning_amber_rounded,
      );
      if (!ok) return;
    }

    final (name, error) = await c.save();
    if (name != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(WarehouseStrings.savedDraft(name)),
          duration: const Duration(seconds: 5),
        ),
      );
      navigator.pop();
    } else if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), duration: const Duration(seconds: 6)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TransferController>();

    if (c.loading && c.warehouses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(WarehouseStrings.newTransfer)),
        body: LoadingView(message: WarehouseStrings.loadingWarehouses),
      );
    }
    if (c.error != null && c.warehouses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(WarehouseStrings.newTransfer)),
        body: ErrorView(
          message: c.error!,
          onRetry: () => Navigator.of(context)
              .pushReplacement(TransferScreen.route(context, from: c.from)),
        ),
      );
    }

    final count = c.quantities.length;
    return Scaffold(
      appBar: AppBar(title: Text(WarehouseStrings.newTransfer)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(child: _Header(search: _search)),
          ),
          ..._items(context, c),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: c.canSave ? _save : null,
            icon: c.saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              count == 0
                  ? WarehouseStrings.noLines
                  : WarehouseStrings.saveDraft(count),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _items(BuildContext context, TransferController c) {
    Widget fill(Widget child) => SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        );

    if (c.from == null) return [fill(Text(WarehouseStrings.chooseSourceFirst))];
    if (c.stockLoading && !c.hasStock) {
      return [
        fill(LoadingView(message: WarehouseStrings.loadingItems)),
      ];
    }
    if (c.stockError != null && !c.hasStock) {
      return [
        fill(ErrorView(message: c.stockError!, onRetry: c.reloadStock)),
      ];
    }
    final stock = c.stock;
    if (stock.isEmpty) return [fill(Text(WarehouseStrings.noItems))];

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        sliver: SliverList.builder(
          itemCount: stock.length,
          itemBuilder: (_, i) {
            final s = stock[i];
            final qty = c.quantities[s.itemCode];
            return StockTile(
              stock: s,
              selected: qty != null,
              onTap: () => _editQty(s),
              trailing: qty == null
                  ? IconButton(
                      tooltip: WarehouseStrings.add,
                      onPressed: () => _editQty(s),
                      icon: const Icon(Icons.add_circle_outline),
                    )
                  : ActionChip(
                      avatar: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(WarehouseStrings.qty(qty, s.uom)),
                      onPressed: () => _editQty(s),
                    ),
            );
          },
        ),
      ),
    ];
  }
}

/// المصدر والهدف والسبب والبحث
class _Header extends StatelessWidget {
  final TextEditingController search;

  const _Header({required this.search});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TransferController>();
    final theme = Theme.of(context);
    final items = [
      for (final w in c.warehouses)
        DropdownMenuItem(
          value: w.name,
          child: Text(w.label, overflow: TextOverflow.ellipsis),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: c.from,
          isExpanded: true,
          items: items,
          onChanged: c.saving ? null : c.setFrom,
          decoration: InputDecoration(
            labelText: WarehouseStrings.from,
            hintText: WarehouseStrings.chooseWarehouse,
            prefixIcon: const Icon(Icons.outbox_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: c.to,
          isExpanded: true,
          items: items,
          onChanged: c.saving ? null : c.setTo,
          decoration: InputDecoration(
            labelText: WarehouseStrings.to,
            hintText: WarehouseStrings.chooseWarehouse,
            prefixIcon: const Icon(Icons.move_to_inbox_outlined),
            border: const OutlineInputBorder(),
            errorText: c.sameWarehouse ? WarehouseStrings.sameWarehouse : null,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: c.remarks,
          onChanged: (v) => c.remarks = v,
          decoration: InputDecoration(
            labelText: WarehouseStrings.remarks,
            prefixIcon: const Icon(Icons.notes_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        if (c.from != null && c.hasStock) ...[
          const SizedBox(height: 12),
          TextField(
            controller: search,
            onChanged: c.setQuery,
            decoration: InputDecoration(
              hintText: WarehouseStrings.searchItems,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: c.query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        search.clear();
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
          if (c.quantities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                WarehouseStrings.selectedCount(c.quantities.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
        if (c.stockLoading && c.hasStock)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// إدخال الكمية مع التحقق المباشر: خطأ يمنع الحفظ، وتحذير المحجوز لا يمنعه.
/// يعيد الكمية، أو 0 للإزالة، أو null للإلغاء.
class _QtyDialog extends StatefulWidget {
  final WarehouseStock stock;
  final double? current;

  const _QtyDialog({required this.stock, this.current});

  @override
  State<_QtyDialog> createState() => _QtyDialogState();
}

class _QtyDialogState extends State<_QtyDialog> {
  late final _field = TextEditingController(
    text: widget.current == null ? '' : WarehouseStrings.qty(widget.current!),
  );
  bool _touched = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  double? get _qty => parseAmount(_field.text);

  @override
  Widget build(BuildContext context) {
    final s = widget.stock;
    final scheme = Theme.of(context).colorScheme;
    final qty = _qty;
    final error = TransferController.validate(s, qty);
    final warning = error == null ? TransferController.warning(s, qty) : null;

    return AlertDialog(
      title: Text(s.itemName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${WarehouseStrings.actual}: ${WarehouseStrings.qty(s.actualQty, s.uom)}'
            '   ${WarehouseStrings.available}: ${WarehouseStrings.qty(s.availableQty, s.uom)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _field,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(
              decimal: !s.wholeNumber,
            ),
            onChanged: (_) => setState(() => _touched = true),
            decoration: InputDecoration(
              labelText: WarehouseStrings.quantity,
              suffixText: s.uom,
              border: const OutlineInputBorder(),
              errorText: _touched ? error : null,
              errorMaxLines: 3,
            ),
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: scheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    warning,
                    style: TextStyle(color: scheme.tertiary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(0.0),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: Text(WarehouseStrings.remove),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(WarehouseStrings.cancel),
        ),
        FilledButton(
          onPressed: error == null ? () => Navigator.of(context).pop(qty) : null,
          child: Text(WarehouseStrings.add),
        ),
      ],
    );
  }
}
