import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/purchase_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/purchase_models.dart';
import '../controllers/purchases_controller.dart';

/// تعديل **كميات** بنود مستند مشتريات مسودة (أمر شراء / استلام / فاتورة).
/// يظهر لكل بند اسمه ومستودعه ووحدته (للعرض فقط) وحقل الكمية، بلا أي سعر.
/// الحفظ PUT واحد يحمل name والكمية لكل بند، والسعر لا يُرسل فيبقى كما هو؛
/// والإجمالي والضريبة يحسبهما ERPNext ويعيدهما.
/// تُرجع [PurchaseDocDetail] المحدَّث عند الحفظ، أو null إن رجع المستخدم.
class EditPurchaseItemsScreen extends StatefulWidget {
  final String doctype;
  final PurchaseDocDetail detail;

  const EditPurchaseItemsScreen({
    super.key,
    required this.doctype,
    required this.detail,
  });

  static Route<PurchaseDocDetail> route(
    PurchasesController controller, {
    required String doctype,
    required PurchaseDocDetail detail,
  }) {
    return MaterialPageRoute<PurchaseDocDetail>(
      builder: (_) => ChangeNotifierProvider<PurchasesController>.value(
        value: controller,
        child: EditPurchaseItemsScreen(doctype: doctype, detail: detail),
      ),
    );
  }

  @override
  State<EditPurchaseItemsScreen> createState() =>
      _EditPurchaseItemsScreenState();
}

/// حالة بند واحد أثناء التعديل
class _LineState {
  final PurchaseLine line;
  final TextEditingController qty;

  _LineState(this.line) : qty = TextEditingController(text: _plain(line.qty));

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void dispose() => qty.dispose();

  double? get qtyValue => parseAmount(qty.text);
  bool get valid => (qtyValue ?? 0) > 0;
  bool get changed =>
      ((qtyValue ?? line.qty) - line.qty).abs() > 0.0005;
}

class _EditPurchaseItemsScreenState extends State<EditPurchaseItemsScreen> {
  late final List<_LineState> _lines;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lines = [for (final l in widget.detail.lines) _LineState(l)];
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  bool get _allValid =>
      _lines.isNotEmpty &&
      _lines.every((l) => l.valid && l.line.rowName.isNotEmpty);
  bool get _anyChanged => _lines.any((l) => l.changed);

  Future<void> _save() async {
    final controller = context.read<PurchasesController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    FocusScope.of(context).unfocus();

    setState(() => _saving = true);
    // كل البنود تُرسل (الناقص يحذفه ERPNext)، وكل صف يحمل name والكمية فقط
    final result = await controller.saveItems(
      widget.doctype,
      widget.detail.name,
      [
        for (final l in _lines)
          PurchaseLineEdit(rowName: l.line.rowName, qty: l.qtyValue!),
      ],
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.error != null || result.detail == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.error ?? PurchaseStrings.itemsSaveFailed)),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(PurchaseStrings.itemsSaved)));
    navigator.pop(result.detail);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSave = !_saving && _allValid && _anyChanged;

    return Scaffold(
      appBar: AppBar(title: Text(PurchaseStrings.editItemsTitle)),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        children: [
          Text(
            '${widget.detail.supplierName} • ${widget.detail.name}',
            textDirection: TextDirection.ltr,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final l in _lines) _lineCard(l),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              PurchaseStrings.totalsFromErp,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: FilledButton.icon(
            onPressed: canSave ? _save : null,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(PurchaseStrings.saveItems),
          ),
        ),
      ),
    );
  }

  Widget _lineCard(_LineState l) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = l.qty.text.trim().isNotEmpty;
    final qtyError = (hasText && !l.valid) ? PurchaseStrings.itemsInvalid : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.line.itemName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (l.line.itemCode.isNotEmpty)
              Text(
                l.line.itemCode,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            // المستودع المسجَّل على البند (للعرض فقط)
            if (l.line.warehouse.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.warehouse_outlined,
                        size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('${PurchaseStrings.warehouseLabel}: '),
                    Expanded(
                      child: Text(
                        l.line.warehouse,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: l.qty,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: PurchaseStrings.qtyLabel,
                // الوحدة تظهر بجانب الكمية للعرض فقط
                suffixText: l.line.uom.isEmpty ? null : l.line.uom,
                border: const OutlineInputBorder(),
                errorText: qtyError,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
