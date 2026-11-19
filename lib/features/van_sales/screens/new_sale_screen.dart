import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/constants/warehouse_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/van_sale_models.dart';
import '../../../data/models/warehouse_models.dart';
import '../../../data/repositories/erp_van_sales_repository.dart';
import '../../../data/repositories/erp_warehouse_repository.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../../inventory/screens/barcode_scanner_screen.dart';
import '../controllers/new_sale_controller.dart';
import '../widgets/credit_summary.dart';
import '../widgets/customer_picker_sheet.dart';

/// فاتورة بيع جديدة من الفان: العميل من ERPNext، المنتجات من مخزون الفان (بحث
/// بالاسم أو الكود أو مسح الباركود)، وحدة البيع (Piece/Box…) والكمية لكل منتج،
/// ومراجعة قبل الحفظ مسودة مع Update Stock من مستودع الفان.
class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const NewSaleScreen());

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  late final NewSaleController _c;

  @override
  void initState() {
    super.initState();
    // متحكم مستقل للشاشة: يُنشأ عند فتحها ويُحذف عند إغلاقها
    _c = Get.put(
      NewSaleController(
        context.read<ErpVanSalesRepository>(),
        context.read<ErpWarehouseRepository>(),
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<NewSaleController>();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final picked = await CustomerPickerSheet.show(
      context,
      customers: _c.customers,
      loading: _c.customersLoading,
      error: _c.customersError,
      filter: _c.filterCustomers,
      onRetry: _c.loadCustomers,
      selectedId: _c.customer.value?.id,
    );
    if (picked != null) _c.customer.value = picked;
  }

  Future<void> _addProduct() async {
    final picked = await showModalBottomSheet<WarehouseStock>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProductPicker(controller: _c),
    );
    if (picked != null && mounted) await _editLine(picked);
  }

  Future<void> _scan() async {
    final messenger = ScaffoldMessenger.of(context);
    final code = await Navigator.of(context).push(BarcodeScannerScreen.route());
    if (code == null || !mounted) return;
    try {
      final hit = await _c.findByBarcode(code);
      if (!mounted) return;
      if (hit == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(VanStrings.notInVan(code))),
        );
        return;
      }
      await _editLine(hit);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(describeError(e, fallback: VanStrings.scanFailed)),
        ),
      );
    }
  }

  /// نافذة الوحدة والكمية: لإضافة منتج، أو لتعديل البند رقم [index]
  Future<void> _editLine(WarehouseStock s, {int? index}) async {
    final line = await showModalBottomSheet<SaleLine>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LineSheet(
        controller: _c,
        stock: s,
        existing: index == null ? null : _c.lines[index],
        index: index,
      ),
    );
    if (line != null) _c.putLine(line, editing: index);
  }

  Future<void> _review() async {
    final messenger = ScaffoldMessenger.of(context);
    final invalid = _c.validateSale();
    if (invalid != null) {
      messenger.showSnackBar(SnackBar(content: Text(invalid)));
      return;
    }
    final saved = await Navigator.of(context).push<CreatedSale>(
      MaterialPageRoute(builder: (_) => _ReviewScreen(controller: _c)),
    );
    if (saved == null || !mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          VanStrings.saved(
            saved.name,
            formatAmount(
              saved.grandTotal,
              currency: displayCurrency(saved.currency),
            ),
          ),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<bool> _confirmLeave() async {
    if (!_c.isDirty) return true;
    return ConfirmDialog.show(
      context,
      title: VanStrings.discardTitle,
      message: VanStrings.discardMessage,
      confirmLabel: VanStrings.discard,
      icon: Icons.delete_outline,
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(VanStrings.newSale),
          actions: [
            IconButton(
              tooltip: VanStrings.scan,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scan,
            ),
          ],
        ),
        body: Obx(() {
          final customer = _c.customer.value;
          final lines = _c.lines.toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // العميل
              InkWell(
                onTap: _pickCustomer,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: VanStrings.customer,
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    customer?.name ?? VanStrings.chooseCustomer,
                    style: customer == null
                        ? TextStyle(color: scheme.onSurfaceVariant)
                        : const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // المنتجات
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${VanStrings.products} (${lines.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _scan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(VanStrings.scan),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (lines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    VanStrings.noLines,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              else
                for (var i = 0; i < lines.length; i++)
                  _LineCard(
                    line: lines[i],
                    onEdit: () {
                      final s = _c.stockOf(lines[i].itemCode);
                      if (s != null) _editLine(s, index: i);
                    },
                    onRemove: () => _c.removeLine(i),
                  ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: Text(VanStrings.addProduct),
              ),
            ],
          );
        }),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Obx(() {
              final total = _c.estimatedTotal;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_c.lines.isNotEmpty && total != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(VanStrings.estimatedTotal)),
                          Text(
                            formatAmount(total),
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _review,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(VanStrings.reviewAndSave),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// بند في الفاتورة: المنتج، الكمية بالوحدة، السعر التقديري، تعديل وحذف
class _LineCard extends StatelessWidget {
  final SaleLine line;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _LineCard({
    required this.line,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = line;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.itemName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l.itemCode,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        WarehouseStrings.qty(l.qty, l.unit.uom),
                        if (l.price != null)
                          '× ${formatAmount(l.price!)}'
                        else
                          VanStrings.noPrice,
                      ].join('  '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (l.amount != null)
                Text(
                  formatAmount(l.amount!),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              IconButton(
                tooltip: VanStrings.remove,
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline, color: scheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// اختيار المنتج من مخزون الفان: بحث بالاسم أو الكود، أو مسح الباركود
class _ProductPicker extends StatefulWidget {
  final NewSaleController controller;

  const _ProductPicker({required this.controller});

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final code = await navigator.push(BarcodeScannerScreen.route());
    if (code == null || !mounted) return;
    try {
      final hit = await widget.controller.findByBarcode(code);
      if (!mounted) return;
      if (hit != null) {
        navigator.pop(hit);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(VanStrings.notInVan(code))),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(describeError(e, fallback: VanStrings.scanFailed)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: VanStrings.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: VanStrings.scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scan,
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final list = c.filterStock(_query);
              if (c.stockLoading.value && c.stock.isEmpty) {
                return LoadingView(message: VanStrings.loading);
              }
              final error = c.stockError.value;
              if (error != null && c.stock.isEmpty) {
                return ErrorView(
                  message: describeError(
                    error,
                    fallback: VanStrings.loadFailed,
                  ),
                  onRetry: c.loadStock,
                );
              }
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    c.stock.isEmpty ? VanStrings.empty : VanStrings.noMatch,
                  ),
                );
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: scheme.primary,
                      ),
                    ),
                    title: Text(s.itemName),
                    subtitle: Text(s.itemCode),
                    trailing: Text(
                      VanStrings.inVan(
                        WarehouseStrings.qty(s.actualQty, s.uom),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(s),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// وحدة البيع والكمية لمنتج، مع السعر التقديري والتحقق من المخزون
class _LineSheet extends StatefulWidget {
  final NewSaleController controller;
  final WarehouseStock stock;
  final SaleLine? existing;
  final int? index;

  const _LineSheet({
    required this.controller,
    required this.stock,
    this.existing,
    this.index,
  });

  @override
  State<_LineSheet> createState() => _LineSheetState();
}

class _LineSheetState extends State<_LineSheet> {
  late final TextEditingController _qty = TextEditingController(
    text: widget.existing == null
        ? '1'
        : WarehouseStrings.qty(widget.existing!.qty),
  );
  List<SaleUnit>? _units;
  Object? _unitsError;
  SaleUnit? _unit;
  double? _price;
  bool _pricing = false;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    setState(() => _unitsError = null);
    try {
      final units = await widget.controller.unitsOf(widget.stock);
      if (!mounted) return;
      final current = widget.existing?.unit.uom;
      setState(() {
        _units = units;
        _unit = units.firstWhere(
          (u) => u.uom == current,
          orElse: () => units.first,
        );
      });
      await _loadPrice();
    } catch (e) {
      debugPrint('LineSheet.loadUnits failed: $e');
      if (mounted) setState(() => _unitsError = e);
    }
  }

  Future<void> _loadPrice() async {
    final unit = _unit;
    if (unit == null) return;
    setState(() => _pricing = true);
    final price = await widget.controller.priceOf(widget.stock, unit);
    if (!mounted || unit != _unit) return;
    setState(() {
      _price = price;
      _pricing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = widget.stock;
    final unit = _unit;
    final qty = parseAmount(_qty.text);
    final error = unit == null
        ? null
        : widget.controller.validateQty(s, unit, qty, editing: widget.index);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.itemName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${s.itemCode}  •  ${VanStrings.inVan(WarehouseStrings.qty(s.actualQty, s.uom))}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // وحدة البيع
            Text(VanStrings.unit, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            if (_unitsError != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      describeError(
                        _unitsError!,
                        fallback: VanStrings.unitsFailed,
                      ),
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadUnits,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              )
            else if (_units == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(VanStrings.loadingUnits),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final u in _units!)
                    ChoiceChip(
                      label: Text(u.uom),
                      selected: u.uom == unit?.uom,
                      onSelected: (_) {
                        setState(() => _unit = u);
                        _loadPrice();
                      },
                    ),
                ],
              ),
            if (unit != null && unit.factor != 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  VanStrings.unitFactor(
                    unit.uom,
                    WarehouseStrings.qty(unit.factor),
                    s.uom,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // الكمية
            TextField(
              controller: _qty,
              keyboardType: TextInputType.numberWithOptions(
                decimal: !(unit?.wholeNumber ?? false),
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: VanStrings.quantity,
                suffixText: unit?.uom,
                border: const OutlineInputBorder(),
                errorText: error,
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 12),

            // السعر التقديري
            Row(
              children: [
                Expanded(child: Text(VanStrings.estimatedPrice)),
                if (_pricing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    _price == null
                        ? VanStrings.noPrice
                        : formatAmount(_price! * (qty ?? 0)),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: unit == null || error != null
                  ? null
                  : () => Navigator.of(context).pop(
                      SaleLine(
                        itemCode: s.itemCode,
                        itemName: s.itemName,
                        unit: unit,
                        qty: qty!,
                        price: _price,
                      ),
                    ),
              icon: Icon(widget.existing == null ? Icons.add : Icons.check),
              label: Text(
                widget.existing == null ? VanStrings.add : VanStrings.update,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مراجعة قبل الحفظ: العميل، المستودع، تفاصيل المنتجات والكميات، والإجمالي
/// التقديري، ثم «حفظ كمسودة». يعيد الفاتورة المحفوظة.
class _ReviewScreen extends StatelessWidget {
  final NewSaleController controller;

  const _ReviewScreen({required this.controller});

  Future<void> _save(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // تحذير واضح قبل الحفظ إن تجاوزت الفاتورة الحد الائتماني
    if (controller.exceedsCredit) {
      final credit = controller.credit.value!;
      final over =
          credit.balance + controller.estimatedTotal! - credit.creditLimit;
      final ok = await ConfirmDialog.show(
        context,
        title: VanStrings.exceedsTitle,
        message: VanStrings.exceedsLimit(
          formatAmount(over, currency: displayCurrency(credit.currency)),
        ),
        confirmLabel: VanStrings.saveAnyway,
        icon: Icons.warning_amber_rounded,
        destructive: true,
      );
      if (!ok) return;
    }
    final (sale, error) = await controller.save();
    if (sale != null) {
      navigator.pop(sale);
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
    final c = controller;
    final lines = c.lines.toList();
    final total = c.estimatedTotal;

    Widget header(String label, String value, {bool ltr = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
      appBar: AppBar(title: Text(VanStrings.review)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  header(VanStrings.customer, c.customer.value?.name ?? ''),
                  header(
                    VanStrings.warehouseLabel,
                    ErpConfig.vanWarehouse,
                    ltr: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // فحص الحد الائتماني للعميل مع هذه الفاتورة
          Obx(() {
            final credit = c.credit.value;
            if (c.creditLoading.value) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 2),
              );
            }
            if (credit == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        VanStrings.creditCheck,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CreditSummary(
                        credit: credit,
                        extra: total,
                        unknownExtra: total == null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Text(
            '${VanStrings.products} (${lines.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    title: Text(
                      lines[i].itemName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${lines[i].itemCode}  •  '
                      '${WarehouseStrings.qty(lines[i].qty, lines[i].unit.uom)}'
                      '${lines[i].unit.factor != 1 ? ' (${WarehouseStrings.qty(lines[i].stockQty, '')})' : ''}',
                    ),
                    trailing: Text(
                      lines[i].amount == null
                          ? VanStrings.noPrice
                          : formatAmount(lines[i].amount!),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
                if (total != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      VanStrings.estimatedTotal,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    trailing: Text(
                      formatAmount(total),
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleMedium?.copyWith(
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    VanStrings.reviewNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Obx(
            () => FilledButton.icon(
              onPressed: c.saving.value ? null : () => _save(context),
              icon: c.saving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(VanStrings.saveDraft),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
