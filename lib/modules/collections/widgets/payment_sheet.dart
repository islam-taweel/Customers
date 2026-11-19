import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/sales_invoice.dart';
import '../bindings/collections_bindings.dart';
import '../controllers/payment_sheet_controller.dart';

/// نافذة الدفع من الأسفل: رقم الفاتورة والمبلغ المستحق، ثم المبلغ المراد دفعه وطريقة
/// الدفع (من ERPNext) وحقولها الخاصة (شيك، بطاقة، تحويل) وملاحظة، وفي آخرها زر
/// حفظ الدفعة. تُرجع true إن حُفظت الدفعة.
///
/// الحالة والتحقق في [PaymentSheetController] (يُسجَّل لهذه النافذة فقط ويُحذف عند
/// إغلاقها)؛ هنا العرض وحقول النص فقط.
Future<bool> showPaymentSheet(
  BuildContext context, {
  required SalesInvoice invoice,
}) async {
  final tag = nextCollectionsTag('pay:${invoice.name}');
  PaymentSheetBinding(invoice, tag: tag).dependencies();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PaymentSheet(tag: tag),
  );
  return saved == true;
}

class _PaymentSheet extends StatefulWidget {
  final String tag;

  const _PaymentSheet({required this.tag});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  /// يُنشأ عند أول طلب (lazyPut في PaymentSheetBinding)، لا داخل build
  late final PaymentSheetController _c = Get.find<PaymentSheetController>(
    tag: widget.tag,
  );

  // حقول النص (عناصر واجهة): قيمها تُرسل إلى المتحكم مع كل تغيير
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _refController = TextEditingController();
  final _chequeBankController = TextEditingController();
  final _drawerController = TextEditingController();
  final _cardLast4Controller = TextEditingController();
  final _cardBrandController = TextEditingController();
  final _senderBankController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c; // يبدأ تحميل طرق الدفع (onInit) كما كان في initState
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
    // بعد إزالة النافذة من الشجرة (لا أثناء حركة الإغلاق)
    Get.delete<PaymentSheetController>(tag: widget.tag);
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _c.referenceDate.value ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) _c.referenceDate.value = picked;
  }

  Future<void> _save() async {
    final saved = await _c.save();
    if (saved && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final warning = _c.amountWarning;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
              value: _c.invoice.name,
              isLtr: true,
            ),
            _InfoLine(
              label: AppStrings.amountDue,
              value: _c.dueText,
              isLtr: true,
              emphasize: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              enabled: !_c.saving.value,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textDirection: TextDirection.ltr,
              onChanged: (v) => _c.amountText.value = v,
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
              enabled: !_c.saving.value,
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              onChanged: (v) => _c.note.value = v,
              decoration: InputDecoration(
                labelText: AppStrings.payNoteLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_c.saveError.value != null) ...[
              const SizedBox(height: 12),
              Text(_c.saveError.value!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _c.canSave ? _save : null,
              icon: _c.saving.value
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

    if (_c.modesLoading.value) {
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

    if (_c.modesFailed.value) {
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
            onPressed: _c.loadModes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _c.mode.value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: AppStrings.modeOfPayment,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final m in _c.modes) DropdownMenuItem(value: m, child: Text(m)),
      ],
      onChanged: _c.saving.value ? null : _c.selectMode,
    );
  }

  /// الحقول الخاصة بالطريقة المختارة (النقد بلا حقول إضافية)
  List<Widget> _buildModeFields(BuildContext context) {
    final kind = _c.kind;
    if (_c.mode.value == null || kind == PaymentModeKind.cash) return const [];

    final (refLabel, dateLabel) = switch (kind) {
      PaymentModeKind.cheque => (
        AppStrings.payRefCheque,
        AppStrings.payDateCheque,
      ),
      PaymentModeKind.card => (AppStrings.payRefCard, AppStrings.payDateCard),
      PaymentModeKind.transfer => (
        AppStrings.payRefTransfer,
        AppStrings.payDateTransfer,
      ),
      _ => (AppStrings.payRefGeneric, AppStrings.payDateGeneric),
    };

    Widget gap() => const SizedBox(height: 16);

    return [
      gap(),
      _textField(
        _refController,
        refLabel,
        (v) => _c.referenceNo.value = v,
        ltr: true,
      ),
      gap(),
      _DateField(
        label: dateLabel,
        value: _c.referenceDate.value,
        enabled: !_c.saving.value,
        onTap: _pickDate,
      ),
      if (kind == PaymentModeKind.cheque) ...[
        gap(),
        _textField(
          _chequeBankController,
          AppStrings.payChequeBank,
          (v) => _c.chequeBank.value = v,
        ),
        gap(),
        _textField(
          _drawerController,
          AppStrings.payDrawerName,
          (v) => _c.drawerName.value = v,
        ),
      ],
      if (kind == PaymentModeKind.card) ...[
        gap(),
        TextField(
          controller: _cardLast4Controller,
          enabled: !_c.saving.value,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          // أربعة أرقام كحد أقصى: لا يمكن إدخال رقم بطاقة كاملًا
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]')),
            LengthLimitingTextInputFormatter(4),
          ],
          onChanged: (v) => _c.cardLast4.value = v,
          decoration: InputDecoration(
            labelText: AppStrings.payCardLast4,
            helperText: AppStrings.payCardLast4Helper,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            errorText: _c.cardLast4.value.isNotEmpty && !_c.last4Valid
                ? AppStrings.payCardLast4Invalid
                : null,
          ),
        ),
        gap(),
        _textField(
          _cardBrandController,
          AppStrings.payCardBrand,
          (v) => _c.cardBrand.value = v,
          ltr: true,
        ),
      ],
      if (kind == PaymentModeKind.transfer) ...[
        gap(),
        _textField(
          _senderBankController,
          AppStrings.paySenderBank,
          (v) => _c.senderBank.value = v,
        ),
      ],
    ];
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    ValueChanged<String> onChanged, {
    bool ltr = false,
  }) {
    return TextField(
      controller: controller,
      enabled: !_c.saving.value,
      textDirection: ltr ? TextDirection.ltr : null,
      onChanged: onChanged,
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
