import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/new_customer.dart';

/// نافذة إضافة عميل: الاسم والهاتف ونوع العميل (شركة/فرد) ومجموعته ومنطقته وعملة حسابه.
/// تُرجع [NewCustomer] أو null إن أُلغيت. المجموعة والمنطقة من ERPNext، وإن لم تُحمَّلا
/// (دون اتصال ولا نسخة محفوظة) يُخفى حقلاهما ويُحفظ العميل على الجهاز فقط.
/// قواعد التحقق نفسها المستخدمة في شاشة التعديل ([Validators]):
/// الاسم مطلوب، والهاتف 10 أرقام ويبدأ بـ 05.
class AddCustomerDialog extends StatefulWidget {
  /// عملات ERPNext المتاحة لحساب العميل
  final List<String> currencies;

  /// مجموعات العملاء والمناطق من ERPNext (فارغة = تعذّر جلبها)
  final List<String> groups;
  final List<String> territories;

  const AddCustomerDialog({
    super.key,
    required this.currencies,
    this.groups = const [],
    this.territories = const [],
  });

  static Future<NewCustomer?> show(
    BuildContext context, {
    required List<String> currencies,
    List<String> groups = const [],
    List<String> territories = const [],
  }) {
    return showDialog<NewCustomer>(
      context: context,
      builder: (_) => AddCustomerDialog(
        currencies: currencies,
        groups: groups,
        territories: territories,
      ),
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

  /// عملة حساب العميل: عملة الشركة افتراضيًا إن وُجدت في القائمة
  late String? _accountCurrency;

  /// Company أو Individual (القيمة التي يرسلها ERPNext)
  String _type = 'Company';
  String? _group;
  String? _territory;

  @override
  void initState() {
    super.initState();
    _group = widget.groups.isEmpty ? null : widget.groups.first;
    _territory = widget.territories.isEmpty ? null : widget.territories.first;
    final currencies = widget.currencies;
    _accountCurrency = currencies.contains(ErpConfig.priceListCurrency)
        ? ErpConfig.priceListCurrency
        : (currencies.isEmpty ? null : currencies.first);
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
      NewCustomer(
        name: _nameController.text.trim(),
        phone: normalizeDigits(_phoneController.text.trim()),
        currency: _accountCurrency ?? ErpConfig.priceListCurrency,
        type: _type,
        group: _group,
        territory: _territory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.addCustomerTitle),
      content: SingleChildScrollView(
        child: Form(
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
              decoration: InputDecoration(labelText: AppStrings.name),
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
              decoration: InputDecoration(
                labelText: AppStrings.phone,
                hintText: AppStrings.phoneHint,
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            // نوع العميل: شركة أو فرد
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: 'Company',
                    label: Text(AppStrings.customerTypeCompany),
                  ),
                  ButtonSegment(
                    value: 'Individual',
                    label: Text(AppStrings.customerTypeIndividual),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
            if (widget.groups.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _group,
                isExpanded: true,
                decoration: InputDecoration(labelText: AppStrings.customerGroup),
                items: [
                  for (final g in widget.groups)
                    DropdownMenuItem(value: g, child: Text(g)),
                ],
                onChanged: (v) => setState(() => _group = v),
                validator: (v) => (v == null || v.isEmpty)
                    ? AppStrings.customerGroupRequired
                    : null,
              ),
            ],
            if (widget.territories.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _territory,
                isExpanded: true,
                decoration: InputDecoration(labelText: AppStrings.territory),
                items: [
                  for (final t in widget.territories)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (v) => setState(() => _territory = v),
                validator: (v) => (v == null || v.isEmpty)
                    ? AppStrings.territoryRequired
                    : null,
              ),
            ],
            const SizedBox(height: 8),
            // نوع حساب العميل: شيكل أو أي عملة أخرى من ERPNext
            DropdownButtonFormField<String>(
              initialValue: _accountCurrency,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: AppStrings.accountCurrency,
                helperText: AppStrings.accountCurrencyHelper,
                helperMaxLines: 2,
              ),
              items: [
                for (final c in widget.currencies)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _accountCurrency = v),
              validator: (v) =>
                  (v == null || v.isEmpty) ? AppStrings.currencyRequired : null,
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
        FilledButton(onPressed: _submit, child: Text(AppStrings.save)),
      ],
    );
  }
}