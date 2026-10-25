import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/invoice.dart';
import '../../orders_section/widgets/order_list_tile.dart';
import '../controllers/draft_invoice_controller.dart';
import '../screens/draft_invoice_screen.dart';
import '../screens/edit_draft_screen.dart';
import 'confirm_dialog.dart';
import 'sales_invoice_tile.dart';

/// قائمة مسودات بأزرار التعديل والحذف والاعتماد تحت كل مسودة.
/// تُستخدم في فواتير العميل وفي قسم «الطلبات»، والفرق بينهما في مصدر المسودات
/// ([openDraft]) وما يُحدَّث بعد كل إجراء ([onChanged]).
class DraftList extends StatefulWidget {
  final List<Invoice> drafts;

  /// ينشئ متحكم مسودة واحدة (تعديل/حذف/اعتماد)
  final DraftInvoiceController Function(Invoice invoice) openDraft;

  /// يُستدعى بعد أي تغيير (تعديل/حذف/اعتماد) لإعادة قراءة القائمة
  final Future<void> Function() onChanged;

  /// يُستدعى بعد اعتماد ناجح، مثلًا لفتح التبويب الذي انتقلت إليه الطلبية
  final VoidCallback? onSubmitted;

  /// true = يظهر اسم العميل في الصف (قائمة كل العملاء)
  final bool showCustomer;

  /// مسافة أسفل القائمة (مثلًا لئلا يغطي الزر العائم آخر صف)
  final double bottomPadding;

  const DraftList({
    super.key,
    required this.drafts,
    required this.openDraft,
    required this.onChanged,
    this.onSubmitted,
    this.showCustomer = false,
    this.bottomPadding = 24,
  });

  @override
  State<DraftList> createState() => _DraftListState();
}

class _DraftListState extends State<DraftList> {
  /// المسودات التي يجري تنفيذ إجراء عليها الآن (تُعطَّل أزرارها)
  final Set<int> _busy = {};

  Future<void> _open(Invoice invoice) async {
    await Navigator.push(
      context,
      DraftInvoiceScreen.route(widget.openDraft(invoice)),
    );
    // قد تكون عُدّلت أو حُذفت أو اعتُمدت
    await widget.onChanged();
  }

  Future<void> _edit(Invoice invoice) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = widget.openDraft(invoice);

    final saved = await Navigator.push<bool>(
      context,
      EditDraftScreen.route(controller),
    );
    if (saved == true) {
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.draftUpdated)));
    }
    await widget.onChanged();
  }

  Future<void> _delete(Invoice invoice) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.draftDeleteTitle,
      message: AppStrings.draftDeleteMessage,
      confirmLabel: AppStrings.delete,
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final controller = widget.openDraft(invoice);
    await _perform(
      invoice,
      controller,
      controller.delete,
      AppStrings.draftDeleted,
    );
  }

  Future<void> _submit(Invoice invoice) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.draftSubmitTitle,
      message: AppStrings.draftSubmitMessage,
      confirmLabel: AppStrings.draftSubmit,
      icon: Icons.task_alt_outlined,
    );
    if (!confirmed || !mounted) return;

    final controller = widget.openDraft(invoice);
    final ok = await _perform(
      invoice,
      controller,
      controller.submit,
      AppStrings.draftSubmitted,
    );
    if (ok && mounted) widget.onSubmitted?.call();
  }

  /// ينفّذ إجراءً على مسودة ويُظهر نتيجته، ثم يعيد قراءة القائمة فتنتقل
  /// الطلبية (أو تختفي) تلقائيًا.
  Future<bool> _perform(
    Invoice invoice,
    DraftInvoiceController controller,
    Future<bool> Function() action,
    String successMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final id = invoice.id!;

    setState(() => _busy.add(id));
    final ok = await action();

    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } else {
      final message = controller.error;
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    }

    // في الحالتين: نجاح، أو تغيّرت حالة المسودة فتحتاج القائمة إلى تحديث
    await widget.onChanged();
    if (mounted) setState(() => _busy.remove(id));
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final drafts = widget.drafts;
    return ListView.separated(
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      itemCount: drafts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final draft = drafts[i];
        return DraftTile(
          key: ValueKey(draft.id),
          invoice: draft,
          showCustomer: widget.showCustomer,
          busy: _busy.contains(draft.id),
          onOpen: () => _open(draft),
          onEdit: () => _edit(draft),
          onDelete: () => _delete(draft),
          onSubmit: () => _submit(draft),
        );
      },
    );
  }
}

/// مسودة في القائمة: بطاقتها، وتحتها أزرار التعديل والحذف والاعتماد مباشرة
/// دون الحاجة لفتحها.
class DraftTile extends StatelessWidget {
  final Invoice invoice;
  final bool showCustomer;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const DraftTile({
    super.key,
    required this.invoice,
    required this.showCustomer,
    required this.busy,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onSubmit,
  });

  /// false = لم تُرفع إلى ERPNext بعد (لا يمكن اعتمادها قبل الرفع)
  bool get _uploaded =>
      !invoice.pendingUpload && (invoice.orderId ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const padding = EdgeInsets.symmetric(horizontal: 8, vertical: 10);
    final onTap = busy ? () {} : onOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCustomer)
          OrderListTile(invoice: invoice, onTap: onTap)
        else
          SalesInvoiceTile(invoice: invoice.toListEntry(), onTap: onTap),
        if (!_uploaded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              AppStrings.draftNeedsUploadNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onEdit,
                  style: OutlinedButton.styleFrom(padding: padding),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(AppStrings.draftEdit),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(
                      color: busy
                          ? scheme.onSurface.withValues(alpha: 0.12)
                          : scheme.error,
                    ),
                    padding: padding,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(AppStrings.delete),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: (busy || !_uploaded) ? null : onSubmit,
                  style: FilledButton.styleFrom(padding: padding),
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.task_alt_outlined, size: 18),
                  label: Text(AppStrings.draftApprove),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
