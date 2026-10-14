import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/customer.dart';

/// نافذة إضافة عميل (الاسم والهاتف). تُرجع [Customer] أو null إن أُلغيت.
/// قواعد التحقق نفسها المستخدمة في شاشة التعديل ([Validators]):
/// الاسم مطلوب، والهاتف 10 أرقام ويبدأ بـ 05.
class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  static Future<Customer?> show(BuildContext context) {
    return showDialog<Customer>(
      context: context,
      builder: (_) => const AddCustomerDialog(),
    );
  }

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final FocusNode _nameFocus;
  late final FocusNode _phoneFocus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _nameFocus = FocusNode();
    _phoneFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _submit() {
    // يعرض رسائل الخطأ أسفل الحقول غير الصحيحة ويتوقف
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Customer(
        name: _nameController.text.trim(),
        phone: normalizeDigits(_phoneController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.addCustomerTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              autofocus: true,
              textInputAction: TextInputAction.next,
              // زر «التالي» في لوحة المفاتيح ينقل المؤشر إلى حقل الهاتف
              onEditingComplete: () => _phoneFocus.requestFocus(),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(labelText: AppStrings.name),
              validator: Validators.name,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              // أرقام فقط (لاتينية أو عربية)، وبحد أقصى 10 خانات
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]')),
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: AppStrings.phone,
                hintText: AppStrings.phoneHint,
              ),
              validator: Validators.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _submit, child: const Text(AppStrings.save)),
      ],
    );
  }
}