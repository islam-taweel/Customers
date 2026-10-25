import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/inventory_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../data/models/inventory_models.dart';
import '../../../data/repositories/erp_inventory_repository.dart';
import '../controllers/inventory_controller.dart';
import 'barcode_scanner_screen.dart';

/// قسم «الجرد»: مسح عدة أصناف (كتابة/قارئ خارجي/كاميرا) ← تعديل كمية كل صنف
/// على حدة ← زر «اعتماد وإرسال» يرسل القائمة كاملة لـ ERPNext دفعة واحدة.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<InventoryController>(
        create: (ctx) => ctx.read<InventoryControllerFactory>().create(),
        child: const InventoryScreen(),
      ),
    );
  }

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

String _plain(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

class _InventoryScreenState extends State<InventoryScreen> {
  final _barcode = TextEditingController();
  final _barcodeFocus = FocusNode();

  @override
  void dispose() {
    _barcode.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  Future<void> _add(String raw) async {
    if (raw.trim().isEmpty) return;
    final controller = context.read<InventoryController>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await controller.addByBarcode(raw);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          duration: const Duration(seconds: 2),
        ),
      );
    // جاهز لباركود الصنف التالي (قارئ خارجي)
    _barcode.clear();
    _barcodeFocus.requestFocus();
  }

  Future<void> _scan() async {
    FocusScope.of(context).unfocus();
    final code = await Navigator.of(context).push<String>(
      BarcodeScannerScreen.route(),
    );
    if (code == null || !mounted) return;
    await _add(code);
  }

  Future<void> _send() async {
    final controller = context.read<InventoryController>();
    final messenger = ScaffoldMessenger.of(context);

    if (!controller.allValid) {
      // يُظهر أخطاء الحقول ثم يعلم المستخدم
      final r = await controller.send();
      if (!mounted) return;
      if (r.error != null) {
        messenger.showSnackBar(SnackBar(content: Text(r.error!)));
      }
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(InventoryStrings.confirmTitle),
        content: Text(InventoryStrings.confirmBody(controller.lines.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(InventoryStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(InventoryStrings.send),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final result = await controller.send();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.error ?? InventoryStrings.sent(result.id ?? ''),
        ),
        duration: Duration(seconds: result.error == null ? 5 : 8),
      ),
    );
    if (result.error == null) _barcodeFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InventoryController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(InventoryStrings.section),
        actions: [
          if (c.lines.isNotEmpty)
            IconButton(
              tooltip: InventoryStrings.clearAll,
              onPressed: c.sending ? null : c.clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcode,
                    focusNode: _barcodeFocus,
                    textInputAction: TextInputAction.search,
                    // قارئ الباركود الخارجي يرسل Enter بعد الرمز
                    onSubmitted: _add,
                    decoration: InputDecoration(
                      labelText: InventoryStrings.barcodeLabel,
                      hintText: InventoryStrings.barcodeHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.qr_code_2),
                      suffixIcon: IconButton(
                        tooltip: InventoryStrings.search,
                        onPressed:
                            c.searching ? null : () => _add(_barcode.text),
                        icon: const Icon(Icons.add),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: IconButton.filled(
                    tooltip: InventoryStrings.scanWithCamera,
                    onPressed: c.searching ? null : _scan,
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                ),
              ],
            ),
          ),
          if (c.searching) const LinearProgressIndicator(),
          Expanded(
            child: c.lines.isEmpty
                ? EmptyView(
                    icon: Icons.inventory_2_outlined,
                    title: InventoryStrings.listEmptyTitle,
                    message: InventoryStrings.listEmptyMessage,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: c.lines.length,
                    itemBuilder: (_, i) {
                      final line = c.lines[i];
                      return _LineCard(
                        key: ValueKey(line.item.code),
                        line: line,
                        showErrors: c.showErrors,
                        enabled: !c.sending,
                      );
                    },
                  ),
          ),
          _BottomBar(onSend: _send),
        ],
      ),
    );
  }
}

/// سطر صنف: اسمه + الكمية الحالية + حقل الكمية المعدودة (+ التكلفة إن لزمت).
class _LineCard extends StatefulWidget {
  const _LineCard({
    super.key,
    required this.line,
    required this.showErrors,
    required this.enabled,
  });

  final CountLine line;
  final bool showErrors;
  final bool enabled;

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  late final TextEditingController _qty;
  late final TextEditingController _rate;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(text: _plain(widget.line.qty ?? 0));
    _rate = TextEditingController();
  }

  @override
  void dispose() {
    _qty.dispose();
    _rate.dispose();
    super.dispose();
  }

  String? _qtyError() {
    final text = _qty.text;
    if (text.trim().isEmpty) return InventoryStrings.invalidNumber;
    final v = InventoryController.parseQty(text);
    if (v == null) return InventoryStrings.invalidNumber;
    if (v < 0) return InventoryStrings.negativeNotAllowed;
    return null;
  }

  String? _rateError() {
    final line = widget.line;
    if (!line.needsRate) return null;
    if (_rate.text.isEmpty && !widget.showErrors) return null;
    return line.rateValid ? null : InventoryStrings.rateRequired;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.read<InventoryController>();
    final item = widget.line.item;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${item.code}'
                        '${item.uom.isEmpty ? '' : '  •  ${item.uom}'}'
                        '  •  ${InventoryStrings.currentQty}: ${_plain(item.qty)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: InventoryStrings.remove,
                  onPressed:
                      widget.enabled ? () => c.remove(widget.line) : null,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qty,
              enabled: widget.enabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: InventoryStrings.countedQty,
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: _qtyError(),
              ),
              onChanged: (t) => c.setQty(widget.line, t),
            ),
            if (widget.line.needsRate) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _rate,
                enabled: widget.enabled,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: InventoryStrings.valuationRate,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: _rateError(),
                ),
                onChanged: (t) => c.setRate(widget.line, t),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// الشريط السفلي: نوع العملية + زر «اعتماد وإرسال».
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onSend});

  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InventoryController>();
    final n = c.lines.length;

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: ErpInventoryRepository.purposeReconciliation,
                    label: Text(InventoryStrings.purposeCount),
                  ),
                  ButtonSegment(
                    value: ErpInventoryRepository.purposeOpening,
                    label: Text(InventoryStrings.purposeOpening),
                  ),
                ],
                selected: {c.purpose},
                onSelectionChanged:
                    c.sending ? null : (s) => c.setPurpose(s.first),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: (n == 0 || c.sending) ? null : onSend,
                icon: c.sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(InventoryStrings.approveAndSend(n)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
