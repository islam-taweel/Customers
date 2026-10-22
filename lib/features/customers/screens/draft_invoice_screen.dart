import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/draft_invoice_controller.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/invoice_card.dart';
import 'edit_draft_screen.dart';

/// مسودة واحدة: تُعرض كفاتورة، وتحتها أزرار التعديل والحذف والاعتماد.
class DraftInvoiceScreen extends StatelessWidget {
  const DraftInvoiceScreen({super.key});

  static Route<void> route(DraftInvoiceController controller) {
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<DraftInvoiceController>(
        create: (_) => controller,
        child: const DraftInvoiceScreen(),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final controller = context.read<DraftInvoiceController>();
    controller.resetEdit();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.push<bool>(
      context,
      EditDraftScreen.route(controller),
    );
    if (saved == true) {
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.draftUpdated)));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final controller = context.read<DraftInvoiceController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.draftDeleteTitle,
      message: AppStrings.draftDeleteMessage,
      confirmLabel: AppStrings.delete,
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!confirmed) return;

    if (await controller.delete()) {
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.draftDeleted)));
      navigator.pop();
    }
  }

  Future<void> _submit(BuildContext context) async {
    final controller = context.read<DraftInvoiceController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.draftSubmitTitle,
      message: AppStrings.draftSubmitMessage,
      confirmLabel: AppStrings.draftSubmit,
      icon: Icons.task_alt_outlined,
    );
    if (!confirmed) return;

    if (await controller.submit()) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.draftSubmitted)),
      );
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DraftInvoiceController>();
    final invoice = controller.invoice;
    final detail = invoice.toDetail();
    final scheme = Theme.of(context).colorScheme;
    final busy = controller.busy;

    return Scaffold(
      appBar: AppBar(title: Text(invoice.displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InvoiceCard(
                  number: detail.name,
                  customerName: detail.customerName,
                  customerPhone: invoice.customerPhone,
                  amount: detail.grandTotal,
                  date: detail.postingDate,
                  dueDate: detail.dueDate,
                  status: detail.status,
                  currency: displayCurrency(detail.currency),
                  items: detail.items,
                  notes: invoice.notes,
                ),
                if (controller.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.error!,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
                if (!controller.isUploaded) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.draftNeedsUploadNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : () => _edit(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(AppStrings.draftEdit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : () => _delete(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          side: BorderSide(color: scheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(AppStrings.delete),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: (busy || !controller.isUploaded)
                      ? null
                      : () => _submit(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.task_alt_outlined),
                  label: Text(AppStrings.draftSubmit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
