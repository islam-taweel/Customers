import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/operation.dart';
import '../controllers/customer_details_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/operation_dialog.dart';
import '../widgets/operation_tile.dart';
import 'edit_customer_screen.dart';

/// واجهة فقط: تقرأ من [CustomerDetailsController] وتستدعي دوالَه.
/// لا SQL ولا DatabaseHelper ولا setState.
class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({super.key});

  /// مسار الشاشة: يربط المتحكم بها ويبدأ التحميل، ويُتلفه تلقائيًا عند الإغلاق.
  static Route<void> route(CustomerDetailsController controller) {
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<CustomerDetailsController>(
        create: (_) => controller..load(),
        child: const CustomerDetailsScreen(),
      ),
    );
  }

  Future<void> _addOperation(BuildContext context, OperationType type) async {
    final controller = context.read<CustomerDetailsController>();
    final messenger = ScaffoldMessenger.of(context);

    final input = await OperationDialog.show(context, type);
    if (input == null) return;

    final ok = await controller.addOperation(
      type: type,
      amount: input.amount,
      note: input.note,
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          !ok
              ? AppStrings.operationSaveFailed
              : type == OperationType.debt
                  ? AppStrings.debtAdded
                  : AppStrings.paymentAdded,
        ),
      ),
    );
  }

  /// يفتح شاشة التعديل وينتظر نتيجتها: [Customer] المحدَّث إن حُفظت التغييرات،
  /// أو null إن رجع المستخدم دون حفظ. الشاشة تتحدث وحدها لأن المتحكم نفسه تغيّر.
  Future<void> _editCustomer(BuildContext context) async {
    final controller = context.read<CustomerDetailsController>();
    final messenger = ScaffoldMessenger.of(context);

    final updated = await Navigator.push<Customer>(
      context,
      EditCustomerScreen.route(controller),
    );
    if (updated == null) return;

    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.customerUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerDetailsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.editCustomer,
            onPressed: () => _editCustomer(context),
          ),
        ],
      ),
      body: _buildBody(context, controller),
    );
  }

  Widget _buildBody(BuildContext context, CustomerDetailsController controller) {
    if (controller.isLoading) return const LoadingView();

    if (controller.error != null) {
      return ErrorView(
        message: controller.error!,
        onRetry: controller.load,
      );
    }

    final operations = controller.operations;

    return Column(
      children: [
        BalanceCard(customer: controller.customer, balance: controller.balance),
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
                  label: const Text(AppStrings.addDebt),
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
                  label: const Text(AppStrings.addPayment),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              AppStrings.operationsLog,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: operations.isEmpty
              ? const EmptyView(
                  icon: Icons.receipt_long_outlined,
                  title: AppStrings.noOperationsTitle,
                  message: AppStrings.noOperationsMessage,
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: operations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => OperationTile(operation: operations[i]),
                ),
        ),
      ],
    );
  }
}