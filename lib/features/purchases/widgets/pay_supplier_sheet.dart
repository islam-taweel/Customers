import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/purchase_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/purchase_models.dart';
import '../controllers/purchases_controller.dart';

/// نافذة «الدفع للمورد» من الأسفل: المبلغ (معبّأ بالمستحق كاملًا؛ أقل منه = دفعة
/// جزئية) وطريقة الدفع من ERPNext. تُرجع true إن حُفظت الدفعة.
Future<bool> showPayToSupplierSheet(
  BuildContext context, {
  required PurchaseInvoice invoice,
  required PurchasesController controller,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PaySheet(invoice: invoice, controller: controller),
  );
  return saved == true;
}

class _PaySheet extends StatefulWidget {
  final PurchaseInvoice invoice;
  final PurchasesController controller;

  const _PaySheet({required this.invoice, required this.controller});

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  late final TextEditingController _amount;

  List<String> _modes = [];
  bool _modesLoading = true;
  bool _modesFailed = false;
  String? _mode;
  final _note = TextEditingController();
  final _ref = TextEditingController();
  DateTime? _refDate;

  bool _saving = false;
  String? _saveError;

  PurchaseInvoice get _invoice => widget.invoice;
  double get _due => _invoice.outstandingAmount;
  String get _dueText =>
      formatAmount(_due, currency: displayCurrency(_invoice.currency));

  @override
  void initState() {
    super.initState();
    // معبّأ بالمستحق كاملًا
    _amount = TextEditingController(text: _plain(_due));
    _loadModes();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _ref.dispose();
    super.dispose();
  }

  static String _plain(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  Future<void> _loadModes() async {
    setState(() {
      _modesLoading = true;
      _modesFailed = false;
    });
    try {
      final modes = await widget.controller.modesOfPayment();
      if (!mounted) return;
      setState(() {
        _modes = modes;
        _modesFailed = modes.isEmpty;
        _modesLoading = false;
        if (modes.length == 1) _mode = modes.first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _modesFailed = true;
        _modesLoading = false;
      });
    }
  }

  double? get _value => parseAmount(_amount.text);

  /// رسالة الخطأ: فارغ/غير صالح، صفر، أو أكثر من المستحق
  String? get _amountError {
    if (_amount.text.trim().isEmpty) return PurchaseStrings.payInvalid;
    final v = _value;
    if (v == null) return PurchaseStrings.payInvalid;
    if (v <= 0) return PurchaseStrings.payZero;
    if (v > _due + 0.005) return PurchaseStrings.payExceeds(_dueText);
    return null;
  }

  /// أي طريقة غير «Cash» تحتاج رقم مرجع وتاريخًا (رقم الشيك أو مرجع التحويل)
  bool get _needsRef {
    final m = (_mode ?? '').toLowerCase().trim();
    return m.isNotEmpty && m != 'cash';
  }

  bool get _refOk =>
      !_needsRef || (_ref.text.trim().isNotEmpty && _refDate != null);

  bool get _canSave =>
      !_saving && _amountError == null && _mode != null && _refOk;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _refDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) setState(() => _refDate = picked);
  }

  String _d(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final error = await widget.controller.pay(
      _invoice,
      amount: _value!,
      modeOfPayment: _mode!,
      note: _note.text,
      referenceNo: _needsRef ? _ref.text : null,
      referenceDate: _needsRef ? _refDate : null,
    );
    if (!mounted) return;
    if (error == null) {
      navigator.pop(true);
    } else {
      setState(() {
        _saving = false;
        _saveError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              PurchaseStrings.payToSupplier,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${_invoice.displaySupplier} • ${_invoice.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              '${AppStrings.amountDue}: $_dueText',
              textDirection: AppStrings.isArabic ? null : TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: PurchaseStrings.payAmount,
                border: const OutlineInputBorder(),
                errorText: _amountError,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            if (_modesLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_modesFailed)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      PurchaseStrings.payModesFailed,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadModes,
                    child: Text(AppStrings.retry),
                  ),
                ],
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _mode,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: PurchaseStrings.payMode,
                  border: const OutlineInputBorder(),
                ),
                hint: Text(PurchaseStrings.payChooseMode),
                items: [
                  for (final m in _modes)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: _saving ? null : (v) => setState(() => _mode = v),
              ),
            if (_needsRef) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _ref,
                textDirection: TextDirection.ltr,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: PurchaseStrings.payReference,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  _refDate == null
                      ? PurchaseStrings.payReferenceDate
                      : _d(_refDate!),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: AppStrings.payNoteLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(_saveError!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
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
                  : const Icon(Icons.payments_outlined),
              label: Text(PurchaseStrings.paySave),
            ),
          ],
        ),
      ),
    );
  }
}
