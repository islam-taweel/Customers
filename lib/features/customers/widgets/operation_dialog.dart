import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/operation.dart';

/// القيم التي يُدخلها المستخدم في نافذة الدين/الدفعة.
class OperationInput {
  final double amount;
  final String? note;

  /// العملة المختارة (من عملات ERPNext)
  final String currency;

  /// طريقة الدفع (للدفعات فقط، null للديون)
  final String? modeOfPayment;

  const OperationInput(
    this.amount,
    this.note, {
    required this.currency,
    this.modeOfPayment,
  });
}

/// نافذة إضافة دين أو دفعة: المبلغ والعملة، وطريقة الدفع للدفعات، والملاحظة.
/// العملات وطرق الدفع تأتي جاهزة من ERPNext عبر المتحكم.
/// تُرجع [OperationInput] أو null إن أُلغيت. التاريخ يُحدَّد عند الحفظ، لا هنا.
class OperationDialog extends StatefulWidget {
  final OperationType type;
  final List<String> currencies;
  final List<String> modesOfPayment;

  const OperationDialog({
    super.key,
    required this.type,
    required this.currencies,
    required this.modesOfPayment,
  });

  static Future<OperationInput?> show(
    BuildContext context,
    OperationType type, {
    required List<String> currencies,
    required List<String> modesOfPayment,
  }) {
    return showDialog<OperationInput>(
      context: context,
      builder: (_) => OperationDialog(
        type: type,
        currencies: currencies,
        modesOfPayment: modesOfPayment,
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

  bool get _isDebt => widget.type == OperationType.debt;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _amountFocus = FocusNode();
    _noteFocus = FocusNode();

    // العملة الافتراضية: عملة الشركة إن وُجدت في القائمة، وإلا أول عملة
    final currencies = widget.currencies;
    _currency = currencies.contains(ErpConfig.priceListCurrency)
        ? ErpConfig.priceListCurrency
        : (currencies.isEmpty ? null : currencies.first);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
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
        modeOfPayment: _isDebt ? null : _modeOfPayment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDebt = _isDebt;
    final hasModes = widget.modesOfPayment.isNotEmpty;

    return AlertDialog(
      title: Text(isDebt ? AppStrings.addDebt : AppStrings.addPayment),
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
                onChanged: (v) => setState(() => _currency = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? AppStrings.currencyRequired : null,
              ),
              if (!isDebt) ...[
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
              ],
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
          style: FilledButton.styleFrom(
            backgroundColor: isDebt ? AppColors.debt : AppColors.payment,
          ),
          child: Text(AppStrings.save),
        ),
      ],
    );
  }
}
