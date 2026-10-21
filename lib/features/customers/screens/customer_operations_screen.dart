import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/whatsapp_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/operation.dart';
import '../controllers/customer_details_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/operation_dialog.dart';
import '../widgets/operation_tile.dart';

/// شاشة عمليات العميل (ديون ودفعات وسجلّها). كانت تبويبًا في تفاصيل العميل
/// وصارت شاشة مستقلة تُفتح من زر «العمليات».
class CustomerOperationsScreen extends StatelessWidget {
  const CustomerOperationsScreen({super.key});

  /// تشارك المتحكم نفسه مع شاشة التفاصيل، فيبقى الرصيد واحدًا في الشاشتين.
  static Route<void> route(CustomerDetailsController controller) {
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<CustomerDetailsController>.value(
        value: controller,
        child: const CustomerOperationsScreen(),
      ),
    );
  }

  Future<void> _addOperation(BuildContext context, OperationType type) async {
    final controller = context.read<CustomerDetailsController>();
    final messenger = ScaffoldMessenger.of(context);

    // العملات وطرق الدفع من ERPNext قبل فتح النافذة (فشل التحميل لا يمنع فتحها)
    await controller.loadLookups();
    if (!context.mounted) return;

    final input = await OperationDialog.show(
      context,
      type,
      currencies: controller.currencies,
      modesOfPayment: controller.modesOfPayment,
    );
    if (input == null) return;

    final ok = await controller.addOperation(
      type: type,
      amount: input.amount,
      currency: input.currency,
      modeOfPayment: input.modeOfPayment,
      note: input.note,
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          !ok
              ? (controller.saveError ?? AppStrings.operationSaveFailed)
              : type == OperationType.debt
                  ? AppStrings.debtAdded
                  : AppStrings.paymentAdded,
        ),
      ),
    );
  }

  /// يفتح واتساب برسالة جاهزة. عند التعذر تُعرض رسالة عربية واضحة بدل توقف التطبيق.
  Future<void> _sendWhatsApp(BuildContext context) async {
    final controller = context.read<CustomerDetailsController>();

    final result = await controller.sendWhatsAppReminder();

    // أثناء الانتظار قد يغادر المستخدم الشاشة، فلا نستخدم context بعدها
    if (!context.mounted) return;

    final errorMessage = _whatsAppErrorMessage(result);
    if (errorMessage == null) return; // فُتح واتساب بنجاح

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }

  /// رسالة الخطأ المناسبة لنتيجة فتح واتساب، أو null إن فُتح بنجاح.
  String? _whatsAppErrorMessage(WhatsAppResult result) {
    return switch (result) {
      WhatsAppResult.opened => null,
      WhatsAppResult.notInstalled => AppStrings.whatsappNotInstalled,
      WhatsAppResult.invalidPhone => AppStrings.whatsappInvalidPhone,
      WhatsAppResult.noDebt => AppStrings.whatsappNoDebt,
      WhatsAppResult.failed => AppStrings.whatsappFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerDetailsController>();

    return Scaffold(
      // لوحة مفاتيح نافذة الدين/الدفعة لا تضغط هذه الشاشة خلفها (النافذة تتعامل
      // مع لوحة المفاتيح بنفسها)، فلا يُعاد تخطيط الصفحة مع كل ظهور واختفاء لها
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('${controller.customer.name} • ${AppStrings.tabOperations}'),
      ),
      body: _buildBodyGuard(context, controller),
    );
  }

  Widget _buildBodyGuard(
    BuildContext context,
    CustomerDetailsController controller,
  ) {
    if (controller.isLoading) return const LoadingView();
    if (controller.error != null) {
      return ErrorView(message: controller.error!, onRetry: controller.load);
    }
    return _buildOperations(context, controller);
  }

  /// الرصيد، إضافة دين/دفعة، واتساب، سجل العمليات
  Widget _buildOperations(
    BuildContext context,
    CustomerDetailsController controller,
  ) {
    final operations = controller.operations;

    // الشاشة كلها تتمرر معًا (الرصيد والأزرار والسجل)، فلا تفيض على الشاشات
    // الصغيرة عندما تزيد أرصدة العملات أو يظهر زر واتساب.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
        BalanceCard(customer: controller.customer, balances: controller.balances),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addOperation(context, OperationType.debt),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.debt,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(AppStrings.addDebt),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addOperation(context, OperationType.payment),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.payment,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(AppStrings.addPayment),
                ),
              ),
            ],
          ),
        ),
        // زر واتساب: يظهر فقط إذا كان على العميل مبلغ مستحق (الرصيد أكبر من صفر)
        if (controller.hasDebt)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _sendWhatsApp(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.whatsapp,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.chat_outlined),
                label: Text(AppStrings.whatsappButton),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              AppStrings.operationsLog,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const Divider(height: 1),
            ],
          ),
        ),
        if (operations.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.noOperationsTitle,
              message: AppStrings.noOperationsMessage,
            ),
          )
        else
          SliverList.separated(
            itemCount: operations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => OperationTile(operation: operations[i]),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
