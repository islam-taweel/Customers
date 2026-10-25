import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/purchase_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/purchase_models.dart';
import '../controllers/purchases_controller.dart';

/// أمر شراء جديد: المورد، تاريخ الاستلام المطلوب، الأصناف (كمية وسعر). يُحفظ مسودة
/// في ERPNext وتضاف الضريبة الافتراضية للشركة تلقائيًا. يرجع true إن حُفظ.
class NewPurchaseOrderScreen extends StatefulWidget {
  const NewPurchaseOrderScreen({super.key});

  static Route<bool> route(PurchasesController controller) {
    return MaterialPageRoute<bool>(
      builder: (_) => ChangeNotifierProvider<PurchasesController>.value(
        value: controller,
        child: const NewPurchaseOrderScreen(),
      ),
    );
  }

  @override
  State<NewPurchaseOrderScreen> createState() => _NewPurchaseOrderScreenState();
}

class _NewPurchaseOrderScreenState extends State<NewPurchaseOrderScreen> {
  ErpSupplier? _supplier;
  DateTime _scheduleDate = DateTime.now().add(const Duration(days: 7));
  final List<NewPurchaseLine> _lines = [];
  bool _saving = false;

  double get _subtotal => _lines.fold(0, (s, l) => s + l.total);

  bool get _canSave => !_saving && _supplier != null && _lines.isNotEmpty;

  Future<void> _pickSupplier() async {
    final controller = context.read<PurchasesController>();
    final picked = await showModalBottomSheet<ErpSupplier>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SearchSheet<ErpSupplier>(
        title: PurchaseStrings.chooseSupplier,
        hint: PurchaseStrings.searchSupplier,
        search: controller.searchSuppliers,
        label: (s) => s.name,
        sublabel: (s) => s.id == s.name ? null : s.id,
      ),
    );
    if (picked != null && mounted) setState(() => _supplier = picked);
  }

  Future<void> _addItem() async {
    final controller = context.read<PurchasesController>();
    final item = await showModalBottomSheet<PurchasableItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SearchSheet<PurchasableItem>(
        title: PurchaseStrings.addItem,
        hint: PurchaseStrings.searchItem,
        search: controller.searchItems,
        label: (i) => i.name,
        sublabel: (i) => i.code,
      ),
    );
    if (item == null || !mounted) return;
    // سعر الشراء من Standard Buying؛ إن لم يوجد يكتبه المستخدم
    double? rate;
    try {
      rate = await controller.buyingRate(item.code);
    } catch (_) {}
    if (!mounted) return;
    final priced = PurchasableItem(
      code: item.code,
      name: item.name,
      uom: item.uom,
      rate: rate ?? 0,
    );
    final line = await showDialog<NewPurchaseLine>(
      context: context,
      builder: (_) => _LineDialog(item: priced),
    );
    if (line != null && mounted) setState(() => _lines.add(line));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) setState(() => _scheduleDate = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final controller = context.read<PurchasesController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final error = await controller.createOrder(
      supplier: _supplier!,
      lines: List.of(_lines),
      scheduleDate: _scheduleDate,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      messenger.showSnackBar(SnackBar(content: Text(PurchaseStrings.orderSaved)));
      navigator.pop(true);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  String _d(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(PurchaseStrings.newOrderTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(PurchaseStrings.supplier),
              subtitle: Text(_supplier?.name ?? PurchaseStrings.chooseSupplier),
              trailing: const Icon(Icons.chevron_right),
              onTap: _saving ? null : _pickSupplier,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(PurchaseStrings.requiredBy),
              subtitle: Text(_d(_scheduleDate), textDirection: TextDirection.ltr),
              onTap: _saving ? null : _pickDate,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                PurchaseStrings.itemsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _saving ? null : _addItem,
                icon: const Icon(Icons.add),
                label: Text(PurchaseStrings.addItem),
              ),
            ],
          ),
          if (_lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  PurchaseStrings.noItemsYet,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            for (var i = 0; i < _lines.length; i++)
              Card(
                child: ListTile(
                  title: Text(_lines[i].item.name),
                  subtitle: Text(
                    '${_n(_lines[i].qty)} × ${formatAmount(_lines[i].rate)}',
                    textDirection: TextDirection.ltr,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatAmount(_lines[i].total),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        tooltip: AppStrings.delete,
                        onPressed: _saving
                            ? null
                            : () => setState(() => _lines.removeAt(i)),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(PurchaseStrings.subtotal),
                  const Spacer(),
                  Text(
                    formatAmount(_subtotal),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(PurchaseStrings.saveDraft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

/// نافذة بحث عامة (مورّدون / أصناف) تجلب النتائج من ERPNext أثناء الكتابة.
class _SearchSheet<T> extends StatefulWidget {
  final String title;
  final String hint;
  final Future<List<T>> Function(String query) search;
  final String Function(T) label;
  final String? Function(T) sublabel;

  const _SearchSheet({
    required this.title,
    required this.hint,
    required this.search,
    required this.label,
    required this.sublabel,
  });

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<T> _results = [];
  bool _loading = true;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () => _run(q));
  }

  Future<void> _run(String q) async {
    final id = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.search(q);
      if (!mounted || id != _request) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _request) return;
      setState(() {
        _error = AppStrings.loadInvoicesError;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _results.isEmpty
                          ? Center(child: Text(PurchaseStrings.noResults))
                          : ListView.separated(
                              itemCount: _results.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final r = _results[i];
                                final sub = widget.sublabel(r);
                                return ListTile(
                                  title: Text(widget.label(r)),
                                  subtitle: sub == null ? null : Text(sub),
                                  onTap: () => Navigator.pop(context, r),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// كمية وسعر الوحدة لصنف مختار (السعر معبّأ بآخر سعر شراء إن وُجد).
class _LineDialog extends StatefulWidget {
  final PurchasableItem item;

  const _LineDialog({required this.item});

  @override
  State<_LineDialog> createState() => _LineDialogState();
}

class _LineDialogState extends State<_LineDialog> {
  final _qty = TextEditingController(text: '1');
  late final TextEditingController _rate;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.item.rate;
    _rate = TextEditingController(
      text: r <= 0 ? '' : (r == r.roundToDouble() ? '${r.toInt()}' : '$r'),
    );
  }

  @override
  void dispose() {
    _qty.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _ok() {
    final q = parseAmount(_qty.text);
    final r = parseAmount(_rate.text);
    if (q == null || q <= 0 || r == null || r <= 0) {
      setState(() => _error = PurchaseStrings.invalidLine);
      return;
    }
    Navigator.pop(context, NewPurchaseLine(item: widget.item, qty: q, rate: r));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _qty,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: PurchaseStrings.qty,
              suffixText: widget.item.uom,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: PurchaseStrings.unitPrice,
              border: const OutlineInputBorder(),
              errorText: _error,
              errorMaxLines: 2,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _ok, child: Text(PurchaseStrings.addItem)),
      ],
    );
  }
}
