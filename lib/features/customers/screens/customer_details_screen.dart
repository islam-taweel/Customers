import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/customer.dart';
import '../controllers/customer_details_controller.dart';
import 'customer_invoices_screen.dart';
import 'customer_operations_screen.dart';
import 'edit_customer_screen.dart';

/// تفاصيل العميل: بطاقة الرصيد وزرّان ينقلان إلى شاشة «العمليات» وشاشة «الفواتير».
/// واجهة فقط: تقرأ من [CustomerDetailsController] وتستدعي دوالَه.
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
      SnackBar(content: Text(AppStrings.customerUpdated)),
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
      return ErrorView(message: controller.error!, onRetry: controller.load);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 8),
        _NavButton(
          icon: Icons.swap_vert_rounded,
          title: AppStrings.tabOperations,
          subtitle: AppStrings.operationsCount(controller.operations.length),
          onTap: () => Navigator.push(
            context,
            CustomerOperationsScreen.route(controller),
          ),
        ),
        _NavButton(
          icon: Icons.receipt_long_outlined,
          title: AppStrings.invoicesTitle,
          subtitle: AppStrings.invoicesButtonHint,
          onTap: () => Navigator.push(
            context,
            CustomerInvoicesScreen.route(controller),
          ),
        ),
      ],
    );
  }
}

/// زر كبير ينقل إلى شاشة فرعية: أيقونة وعنوان ووصف قصير.
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
