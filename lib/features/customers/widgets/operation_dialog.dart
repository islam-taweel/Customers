import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/operation.dart';

/// القيم التي يُدخلها المستخدم في نافذة الدين/الدفعة.
class OperationInput {
  final double amount;
  final String? note;

  const OperationInput(this.amount, this.note);
}

/// نافذة إضافة دين أو دفعة (المبلغ والملاحظة).
/// تُرجع [OperationInput] أو null إن أُلغيت. التاريخ يُحدَّد عند الحفظ، لا هنا.
class OperationDialog extends StatefulWidget {
  final OperationType type;

  const OperationDialog({super.key, required this.type});

  static Future<OperationInput?> show(
    BuildContext context,
    OperationType type,
  ) {
    return showDialog<OperationInput>(
      context: context,
      builder: (_) => OperationDialog(type: type),
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

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _amountFocus = FocusNode();
    _noteFocus = FocusNode();
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDebt = widget.type == OperationType.debt;

    return AlertDialog(
      title: Text(isDebt ? AppStrings.addDebt : AppStrings.addPayment),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocus,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              // زر «التالي» ينقل المؤشر إلى حقل الملاحظة
              onEditingComplete: () => _noteFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: AppStrings.amount,
                suffixText: AppConstants.currencySymbol,
              ),
              validator: (v) {
                final value = parseAmount(v ?? '');
                if (value == null) return AppStrings.amountInvalid;
                if (value <= 0) return AppStrings.amountMustBePositive;
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              focusNode: _noteFocus,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(labelText: AppStrings.noteOptional),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: isDebt ? AppColors.debt : AppColors.payment,
          ),
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}