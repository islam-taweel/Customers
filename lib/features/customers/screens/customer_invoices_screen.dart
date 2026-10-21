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
import '../widgets/offline_banner.dart';
import '../widgets/sales_invoice_tile.dart';
import 'draft_invoice_screen.dart';
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

class _DraftsTab extends StatelessWidget {
  const _DraftsTab();

  Future<void> _open(BuildContext context, Invoice invoice) async {
    final details = context.read<CustomerDetailsController>();
    final list = context.read<CustomerInvoicesController>();
    await Navigator.push(
      context,
      DraftInvoiceScreen.route(details.openDraft(invoice)),
    );
    // قد تكون عُدّلت أو حُذفت أو اعتُمدت: نعيد قراءة المحلي (دون شبكة)
    await list.reloadLocal();
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
      itemBuilder: (_, i) => SalesInvoiceTile(
        invoice: drafts[i].toListEntry(),
        onTap: () => _open(context, drafts[i]),
      ),
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
