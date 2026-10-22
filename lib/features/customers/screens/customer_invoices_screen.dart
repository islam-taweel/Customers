import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/invoice.dart';
import '../../../data/models/sales_invoice.dart';
import '../controllers/customer_details_controller.dart';
import '../controllers/customer_invoices_controller.dart';
import '../controllers/draft_invoice_controller.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sales_invoice_tile.dart';
import 'draft_invoice_screen.dart';
import 'edit_draft_screen.dart';
import 'invoice_details_screen.dart';

/// فواتير العميل في تبويبين:
/// * **مسودة**: طلبيات لم تُعتمد بعد، تقبل التعديل والحذف والاعتماد.
/// * **معتمدة**: فواتير ERPNext والطلبيات المعتمدة، تُعرض كملف PDF وتُطبع.
class CustomerInvoicesScreen extends StatelessWidget {
  const CustomerInvoicesScreen({super.key});

  /// تشارك متحكم تفاصيل العميل (لإنشاء متحكمات المسودات والفواتير)، وتنشئ
  /// متحكم القائمة وتبدأ تحميلها، ويُتلف تلقائيًا عند الإغلاق.
  static Route<void> route(CustomerDetailsController details) {
    return MaterialPageRoute<void>(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CustomerDetailsController>.value(
            value: details,
          ),
          ChangeNotifierProvider<CustomerInvoicesController>(
            create: (_) => details.createInvoicesController()..load(),
          ),
        ],
        child: const CustomerInvoicesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerName = context.select<CustomerDetailsController, String>(
      (c) => c.customer.name,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$customerName • ${AppStrings.invoicesTitle}'),
          bottom: TabBar(
            tabs: [
              Tab(text: AppStrings.tabDraft),
              Tab(text: AppStrings.tabSubmitted),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DraftsTab(),
            _SubmittedTab(),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── تبويب المسودات ─────────────────────────

class _DraftsTab extends StatefulWidget {
  const _DraftsTab();

  @override
  State<_DraftsTab> createState() => _DraftsTabState();
}

class _DraftsTabState extends State<_DraftsTab> {
  /// المسودات التي يجري تنفيذ إجراء عليها الآن (تُعطَّل أزرارها)
  final Set<int> _busy = {};

  Future<void> _open(Invoice invoice) async {
    final details = context.read<CustomerDetailsController>();
    final list = context.read<CustomerInvoicesController>();
    await Navigator.push(
      context,
      DraftInvoiceScreen.route(details.openDraft(invoice)),
    );
    // قد تكون عُدّلت أو حُذفت أو اعتُمدت: نعيد قراءة المحلي (دون شبكة)
    await list.reloadLocal();
  }

  Future<void> _edit(Invoice invoice) async {
    final details = context.read<CustomerDetailsController>();
    final list = context.read<CustomerInvoicesController>();
    final messenger = ScaffoldMessenger.of(context);
    final controller = details.openDraft(invoice);

    final saved = await Navigator.push<bool>(
      context,
      EditDraftScreen.route(controller),
    );
    if (saved == true) {
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.draftUpdated)));
    }
    await list.reloadLocal();
  }

  Future<void> _delete(Invoice invoice) async {
    final details = context.read<CustomerDetailsController>();

    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.draftDeleteTitle,
      message: AppStrings.draftDeleteMessage,
      confirmLabel: AppStrings.delete,
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final controller = details.openDraft(invoice);
    await _perform(
      invoice,
      controller,
      controller.delete,
      AppStrings.draftDeleted,
    );
  }

  Future<void> _submit(Invoice invoice) async {
    final details = context.read<CustomerDetailsController>();
    final tabs = DefaultTabController.of(context);

    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.draftSubmitTitle,
      message: AppStrings.draftSubmitMessage,
      confirmLabel: AppStrings.draftSubmit,
      icon: Icons.task_alt_outlined,
    );
    if (!confirmed || !mounted) return;

    final controller = details.openDraft(invoice);
    final ok = await _perform(
      invoice,
      controller,
      controller.submit,
      AppStrings.draftSubmitted,
    );
    // اختفت من «مسودة» وصارت في «معتمدة»: نفتح ذلك التبويب لتظهر فيه
    if (ok && mounted) tabs.animateTo(1);
  }

  /// ينفّذ إجراءً على مسودة، ويُظهر نتيجته، ثم يعيد قراءة القائمة المحلية
  /// فتنتقل الفاتورة (أو تختفي) تلقائيًا بين التبويبين.
  Future<bool> _perform(
    Invoice invoice,
    DraftInvoiceController controller,
    Future<bool> Function() action,
    String successMessage,
  ) async {
    final list = context.read<CustomerInvoicesController>();
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
    await list.reloadLocal();
    if (mounted) setState(() => _busy.remove(id));
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerInvoicesController>();

    if (!controller.localLoaded) return const LoadingView();

    final drafts = controller.drafts;
    if (drafts.isEmpty) {
      return EmptyView(
        icon: Icons.edit_note_outlined,
        title: AppStrings.draftsEmptyTitle,
        message: AppStrings.draftsEmptyMessage,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: drafts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final draft = drafts[i];
        return _DraftTile(
          key: ValueKey(draft.id),
          invoice: draft,
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
class _DraftTile extends StatelessWidget {
  final Invoice invoice;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const _DraftTile({
    super.key,
    required this.invoice,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SalesInvoiceTile(
          invoice: invoice.toListEntry(),
          onTap: busy ? () {} : onOpen,
        ),
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

// ───────────────────────── تبويب المعتمدة ─────────────────────────

class _SubmittedTab extends StatelessWidget {
  const _SubmittedTab();

  void _open(
    BuildContext context,
    CustomerInvoicesController list,
    SalesInvoice invoice,
  ) {
    final details = context.read<CustomerDetailsController>();
    final local = invoice.isLocal ? list.localDetail(invoice.name) : null;
    Navigator.push(
      context,
      InvoiceDetailsScreen.route(
        local != null
            ? details.openLocalInvoice(local)
            : details.openInvoice(invoice.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerInvoicesController>();

    return Column(
      children: [
        // دون إنترنت أو فشل التحديث: نعرض المحفوظ مع تنبيه
        if (controller.notice != null) OfflineBanner(message: controller.notice!),
        // التحديث من ERPNext جارٍ بينما المحفوظ ظاهر
        if (controller.isRefreshing && !controller.isLoading)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildContent(context, controller)),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    CustomerInvoicesController controller,
  ) {
    if (controller.isLoading) return const LoadingView();

    if (controller.error != null) {
      return ErrorView(message: controller.error!, onRetry: controller.load);
    }

    final invoices = controller.submitted;

    // لا عميل مطابق في ERPNext وليس هناك فواتير معتمدة محلية أيضًا
    if (!controller.matched && invoices.isEmpty) {
      return EmptyView(
        icon: Icons.link_off,
        title: AppStrings.invoicesNoMatchTitle,
        message: AppStrings.invoicesNoMatchMessage,
      );
    }

    if (invoices.isEmpty) {
      return EmptyView(
        icon: Icons.receipt_long_outlined,
        title: AppStrings.noInvoicesTitle,
        message: AppStrings.noInvoicesMessage,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: invoices.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => SalesInvoiceTile(
        invoice: invoices[i],
        onTap: () => _open(context, controller, invoices[i]),
      ),
    );
  }
}
