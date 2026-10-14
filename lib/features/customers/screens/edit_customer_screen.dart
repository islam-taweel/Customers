import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/customer.dart';
import '../controllers/customer_details_controller.dart';

/// شاشة تعديل اسم العميل وهاتفه. الحقول معبّأة ببياناته الحالية.
///
/// الحفظ يمر عبر [CustomerDetailsController] (ثم الـ repository)، وعند النجاح
/// تُغلق الشاشة بـ `Navigator.pop` مع إرجاع [Customer] المحدَّث لمن فتحها.
/// واجهة فقط: لا SQL ولا DatabaseHelper ولا setState.
class EditCustomerScreen extends StatefulWidget {
  const EditCustomerScreen({super.key});

  /// مسار الشاشة. نمرّر متحكم التفاصيل الموجود (لا ننشئ واحدًا جديدًا) لأن
  /// الـ Provider الخاص به معرَّف داخل مسار شاشة التفاصيل ولا يراه هذا المسار.
  /// الـ `.value` لا يُتلف المتحكم عند الإغلاق، فيبقى لشاشة التفاصيل.
  static Route<Customer> route(CustomerDetailsController controller) {
    return MaterialPageRoute<Customer>(
      builder: (_) => ChangeNotifierProvider<CustomerDetailsController>.value(
        value: controller,
        child: const EditCustomerScreen(),
      ),
    );
  }

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final FocusNode _nameFocus;
  late final FocusNode _phoneFocus;

  @override
  void initState() {
    super.initState();
    final customer = context.read<CustomerDetailsController>().customer;
    _nameController = TextEditingController(text: customer.name);
    _phoneController = TextEditingController(text: customer.phone);
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

  Future<void> _save() async {
    // يعرض رسائل الخطأ أسفل الحقول غير الصحيحة ويتوقف
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<CustomerDetailsController>();
    final messenger = ScaffoldMessenger.of(context);

    final updated = await controller.updateCustomer(
      name: _nameController.text,
      phone: _phoneController.text,
    );

    if (updated == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.customerUpdateFailed)),
      );
      return;
    }

    // إن غادر المستخدم الشاشة أثناء الحفظ فلا نغلق شاشة أخرى بالخطأ
    if (!mounted) return;
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<CustomerDetailsController>().isSavingCustomer;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editCustomerTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                autofocus: true,
                textInputAction: TextInputAction.next,
                // زر «التالي» في لوحة المفاتيح ينقل المؤشر إلى حقل الهاتف
                onEditingComplete: () => _phoneFocus.requestFocus(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: AppStrings.name,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: border,
                ),
                validator: Validators.name,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                // أرقام فقط (لاتينية أو عربية)، وبحد أقصى 10 خانات
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: AppStrings.phone,
                  hintText: AppStrings.phoneHint,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: border,
                ),
                validator: Validators.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text(AppStrings.saveChanges),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}