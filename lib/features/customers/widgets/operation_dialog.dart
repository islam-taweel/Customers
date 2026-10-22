import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/repositories/erp_payment_repository.dart';

/// القيم التي يُدخلها المستخدم في نافذة الدفعة.
class OperationInput {
  final double amount;
  final String? note;

  /// العملة المختارة (من عملات ERPNext)
  final String currency;

  /// طريقة الدفع
  final String? modeOfPayment;

  const OperationInput(
    this.amount,
    this.note, {
    required this.currency,
    this.modeOfPayment,
  });
}

/// نافذة إضافة دفعة: المبلغ، والعملة (قائمة عملات ERPNext)، وطريقة الدفع، والملاحظة.
/// عند اختيار عملة تختلف عن عملة حساب العميل تعرض النافذة المبلغ بعد التحويل وسعر
/// الصرف قبل الحفظ. تُرجع [OperationInput] أو null إن أُلغيت. التاريخ عند الحفظ.
class OperationDialog extends StatefulWidget {
  final List<String> currencies;
  final List<String> modesOfPayment;

  /// العملة المختارة افتراضيًا (عملة حساب العميل إن حُدِّدت)، وإلا عملة الشركة
  final String? initialCurrency;

  /// يجلب التحويل من العملة المختارة إلى عملة حساب العميل (null = لا تحويل)
  final Future<CurrencyConversion?> Function(String currency) previewConversion;

  const OperationDialog({
    super.key,
    required this.currencies,
    required this.modesOfPayment,
    required this.previewConversion,
    this.initialCurrency,
  });

  static Future<OperationInput?> show(
    BuildContext context, {
    required List<String> currencies,
    required List<String> modesOfPayment,
    required Future<CurrencyConversion?> Function(String currency)
        previewConversion,
    String? initialCurrency,
  }) {
    return showDialog<OperationInput>(
      context: context,
      builder: (_) => OperationDialog(
        currencies: currencies,
        modesOfPayment: modesOfPayment,
        previewConversion: previewConversion,
        initialCurrency: initialCurrency,
      ),
    );
  }

  @override
  State<OperationDialog> createState() => _OperationDialogState();
}

class _OperationDialogState extends State<OperationDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final FocusNode _amountFocus;
  late final FocusNode _noteFocus;

  late String? _currency;
  String? _modeOfPayment;

  /// معاينة التحويل لكل عملة جُلبت (القيمة null = لا تحويل أو تعذّر السعر)
  final Map<String, CurrencyConversion?> _previews = {};

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _amountFocus = FocusNode();
    _noteFocus = FocusNode();

    // العملة الافتراضية: عملة حساب العميل، وإلا عملة الشركة، وإلا أول عملة
    final currencies = widget.currencies;
    final preferred = widget.initialCurrency;
    _currency = (preferred != null && currencies.contains(preferred))
        ? preferred
        : currencies.contains(ErpConfig.priceListCurrency)
            ? ErpConfig.priceListCurrency
            : (currencies.isEmpty ? null : currencies.first);
    _loadPreview();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final currency = _currency;
    if (currency == null || _previews.containsKey(currency)) return;
    final preview = await widget.previewConversion(currency);
    if (!mounted) return;
    setState(() => _previews[currency] = preview);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final note = _noteController.text.trim();
    Navigator.pop(
      context,
      OperationInput(
        parseAmount(_amountController.text)!,
        note.isEmpty ? null : note,
        currency: _currency!,
        modeOfPayment: _modeOfPayment,
      ),
    );
  }

  /// سطر التحويل تحت العملة: جارٍ الجلب، أو المبلغ المحوَّل وسعر الصرف
  Widget? _conversionInfo(BuildContext context) {
    final currency = _currency;
    if (currency == null) return null;
    final theme = Theme.of(context);

    if (!_previews.containsKey(currency)) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(AppStrings.loadingRate, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    final conversion = _previews[currency];
    if (conversion == null) return null;

    final amount = parseAmount(_amountController.text);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.conversionNote(conversion.to),
            style: theme.textTheme.bodySmall,
          ),
          if (amount != null && amount > 0) ...[
            const SizedBox(height: 4),
            Text(
              AppStrings.conversionResult(
                formatAmount(conversion.convert(amount), currency: conversion.to),
                conversion.from,
                conversion.rateText,
                conversion.to,
              ),
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasModes = widget.modesOfPayment.isNotEmpty;
    final info = _conversionInfo(context);

    return AlertDialog(
      title: Text(AppStrings.addPayment),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocus,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                // زر «التالي» ينقل المؤشر إلى حقل الملاحظة
                onEditingComplete: () => _noteFocus.requestFocus(),
                // يُحدّث المبلغ المحوَّل أثناء الكتابة
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: AppStrings.amount,
                  suffixText: _currency,
                ),
                validator: (v) {
                  final value = parseAmount(v ?? '');
                  if (value == null) return AppStrings.amountInvalid;
                  if (value <= 0) return AppStrings.amountMustBePositive;
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                isExpanded: true,
                decoration: InputDecoration(labelText: AppStrings.currency),
                items: [
                  for (final c in widget.currencies)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) {
                  setState(() => _currency = v);
                  _loadPreview();
                },
                validator: (v) =>
                    (v == null || v.isEmpty) ? AppStrings.currencyRequired : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _modeOfPayment,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: AppStrings.modeOfPayment,
                ),
                items: [
                  for (final m in widget.modesOfPayment)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (v) => setState(() => _modeOfPayment = v),
                // إن تعذّر تحميل الطرق لا نمنع الحفظ هنا (المتحكم يتحقق عند اللزوم)
                validator: (v) => (hasModes && (v == null || v.isEmpty))
                    ? AppStrings.modeOfPaymentRequired
                    : null,
              ),
              if (!hasModes)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppStrings.modesOfPaymentUnavailable,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                focusNode: _noteFocus,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(labelText: AppStrings.noteOptional),
              ),
              // التحويل في أسفل النافذة: حقل المبلغ يبقى بالعملة المختارة كما كُتب
              if (info != null) info,
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.payment),
          child: Text(AppStrings.save),
        ),
      ],
    );
  }
}
