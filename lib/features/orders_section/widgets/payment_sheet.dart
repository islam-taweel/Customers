import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../data/repositories/erp_sales_invoices_repository.dart';
import '../controllers/sales_invoices_controller.dart';

/// نافذة الدفع من الأسفل: رقم الفاتورة والمبلغ المستحق، ثم المبلغ المراد دفعه وطريقة
/// الدفع (من ERPNext) وحقولها الخاصة (شيك، بطاقة، تحويل) وملاحظة، وفي آخرها زر
/// حفظ الدفعة. تُرجع true إن حُفظت الدفعة.
Future<bool> showPaymentSheet(
  BuildContext context, {
  required SalesInvoice invoice,
  required SalesInvoicesController controller,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PaymentSheet(invoice: invoice, controller: controller),
  );
  return saved == true;
}

/// نوع طريقة الدفع بحسب اسمها في ERPNext: يحدد الحقول المطلوبة.
/// أي طريقة غير نقدية لا تُعرف تُعامل كتحويل عام: رقم مرجع وتاريخ مطلوبان.
enum _ModeKind { cash, cheque, card, transfer, other }

_ModeKind _kindOf(String? mode) {
  final m = (mode ?? '').toLowerCase().trim();
  if (m.isEmpty) return _ModeKind.cash;
  if (m.contains('cheque') || m.contains('check')) return _ModeKind.cheque;
  if (m.contains('card')) return _ModeKind.card;
  if (m.contains('transfer')) return _ModeKind.transfer;
  if (m == 'cash') return _ModeKind.cash;
  return _ModeKind.other;
}

class _PaymentSheet extends StatefulWidget {
  final SalesInvoice invoice;
  final SalesInvoicesController controller;

  const _PaymentSheet({required this.invoice, required this.controller});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // حقول الطرق غير النقدية
  final _refController = TextEditingController();
  final _chequeBankController = TextEditingController();
  final _drawerController = TextEditingController();
  final _cardLast4Controller = TextEditingController();
  final _cardBrandController = TextEditingController();
  final _senderBankController = TextEditingController();
  DateTime? _refDate;

  List<String> _modes = [];
  bool _modesLoading = true;
  bool _modesFailed = false;
  String? _mode;

  bool _saving = false;
  String? _saveError;

  SalesInvoice get _invoice => widget.invoice;
  double get _due => _invoice.outstandingAmount;
  String get _dueText =>
      formatAmount(_due, currency: displayCurrency(_invoice.currency));
  _ModeKind get _kind => _kindOf(_mode);

  @override
  void initState() {
    super.initState();
    _loadModes();
  }

  @override
  void dispose() {
    for (final c in [
      _amountController,
      _noteController,
      _refController,
      _chequeBankController,
      _drawerController,
      _cardLast4Controller,
      _cardBrandController,
      _senderBankController,
    ]) {
      c.dispose();
    }
    super.dispose();
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
        // طريقة واحدة فقط: نختارها تلقائيًا
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

  /// null = لم يُكتب شيء بعد (بلا تحذير)
  double? get _amount => parseAmount(_amountController.text);

  /// تحذير المبلغ: صفر أو سالب، أو أكثر من المستحق، أو نص غير صالح
  String? get _amountWarning {
    if (_amountController.text.trim().isEmpty) return null;
    final value = _amount;
    if (value == null) return AppStrings.payAmountRequired;
    if (value <= 0) return AppStrings.payAmountPositive;
    if (value > _due + 0.005) return AppStrings.payAmountExceeds(_dueText);
    return null;
  }

  String get _last4 => normalizeDigits(_cardLast4Controller.text.trim());

  bool get _last4Valid => RegExp(r'^\d{4}$').hasMatch(_last4);

  /// الحقول الخاصة بطريقة الدفع مكتملة؟
  bool get _extrasValid {
    final kind = _kind;
    if (kind == _ModeKind.cash) return true;
    if (_refController.text.trim().isEmpty || _refDate == null) return false;
    if (kind == _ModeKind.cheque) {
      return _chequeBankController.text.trim().isNotEmpty &&
          _drawerController.text.trim().isNotEmpty;
    }
    if (kind == _ModeKind.card) {
      return _last4Valid && _cardBrandController.text.trim().isNotEmpty;
    }
    return true;
  }

  bool get _canSave {
    final value = _amount;
    return !_saving &&
        value != null &&
        value > 0 &&
        value <= _due + 0.005 &&
        _mode != null &&
        _extrasValid;
  }

  PaymentDetails _details() {
    final kind = _kind;
    if (kind == _ModeKind.cash) return const PaymentDetails();
    return PaymentDetails(
      referenceNo: _refController.text.trim(),
      referenceDate: _refDate,
      extra: switch (kind) {
        _ModeKind.cheque => {
            'custom_cheque_bank': _chequeBankController.text.trim(),
            'custom_drawer_name': _drawerController.text.trim(),
          },
        // آخر 4 أرقام فقط: لا رقم بطاقة كاملًا ولا تاريخ انتهاء ولا CVV
        _ModeKind.card => {
            'custom_card_last4': _last4,
            'custom_card_brand': _cardBrandController.text.trim(),
          },
        _ModeKind.transfer => {
            'custom_sender_bank': _senderBankController.text.trim(),
          },
        _ => const <String, String>{},
      },
    );
  }

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

  Future<void> _save() async {
    final value = _amount;
    if (!_canSave || value == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final note = _noteController.text.trim();
    final error = await widget.controller.pay(
      _invoice,
      amount: value,
      modeOfPayment: _mode!,
      note: note.isEmpty ? null : note,
      details: _details(),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
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
    final warning = _amountWarning;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.payInvoiceTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoLine(
              label: AppStrings.invoiceNumber,
              value: _invoice.name,
              isLtr: true,
            ),
            _InfoLine(
              label: AppStrings.amountDue,
              value: _dueText,
              isLtr: true,
              emphasize: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              enabled: !_saving,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: AppStrings.payAmountLabel,
                border: const OutlineInputBorder(),
                // التحذير يظهر فور الكتابة، لا عند الحفظ فقط
                errorText: warning,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            _buildModeField(context),
            ..._buildModeFields(context),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              enabled: !_saving,
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
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
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(AppStrings.paySave),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_modesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_modesFailed) {
      return Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.modesOfPaymentUnavailable,
              style: TextStyle(color: scheme.error),
            ),
          ),
          IconButton(
            tooltip: AppStrings.retry,
            onPressed: _loadModes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _mode,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: AppStrings.modeOfPayment,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final m in _modes) DropdownMenuItem(value: m, child: Text(m)),
      ],
      onChanged: _saving ? null : (v) => setState(() => _mode = v),
    );
  }

  /// الحقول الخاصة بالطريقة المختارة (النقد بلا حقول إضافية)
  List<Widget> _buildModeFields(BuildContext context) {
    final kind = _kind;
    if (_mode == null || kind == _ModeKind.cash) return const [];

    final (refLabel, dateLabel) = switch (kind) {
      _ModeKind.cheque => (AppStrings.payRefCheque, AppStrings.payDateCheque),
      _ModeKind.card => (AppStrings.payRefCard, AppStrings.payDateCard),
      _ModeKind.transfer => (
          AppStrings.payRefTransfer,
          AppStrings.payDateTransfer,
        ),
      _ => (AppStrings.payRefGeneric, AppStrings.payDateGeneric),
    };

    Widget gap() => const SizedBox(height: 16);

    return [
      gap(),
      _textField(_refController, refLabel, ltr: true),
      gap(),
      _DateField(
        label: dateLabel,
        value: _refDate,
        enabled: !_saving,
        onTap: _pickDate,
      ),
      if (kind == _ModeKind.cheque) ...[
        gap(),
        _textField(_chequeBankController, AppStrings.payChequeBank),
        gap(),
        _textField(_drawerController, AppStrings.payDrawerName),
      ],
      if (kind == _ModeKind.card) ...[
        gap(),
        TextField(
          controller: _cardLast4Controller,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          // أربعة أرقام كحد أقصى: لا يمكن إدخال رقم بطاقة كاملًا
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]')),
            LengthLimitingTextInputFormatter(4),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: AppStrings.payCardLast4,
            helperText: AppStrings.payCardLast4Helper,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            errorText: _cardLast4Controller.text.isNotEmpty && !_last4Valid
                ? AppStrings.payCardLast4Invalid
                : null,
          ),
        ),
        gap(),
        _textField(_cardBrandController, AppStrings.payCardBrand, ltr: true),
      ],
      if (kind == _ModeKind.transfer) ...[
        gap(),
        _textField(_senderBankController, AppStrings.paySenderBank),
      ],
    ];
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool ltr = false,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      textDirection: ltr ? TextDirection.ltr : null,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// حقل تاريخ للقراءة فقط: الضغط عليه يفتح منتقي التاريخ
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  String get _text {
    final d = value;
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          _text.isEmpty ? ' ' : _text,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isLtr;
  final bool emphasize;

  const _InfoLine({
    required this.label,
    required this.value,
    this.isLtr = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                value,
                textDirection: isLtr ? TextDirection.ltr : null,
                style: TextStyle(
                  fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
                  fontSize: emphasize ? 18 : 15,
                  color: emphasize ? scheme.primary : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
