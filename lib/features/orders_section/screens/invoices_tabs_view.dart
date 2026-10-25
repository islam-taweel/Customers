import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/sales_invoice.dart';
import '../../customers/widgets/offline_banner.dart';
import '../controllers/sales_invoices_controller.dart';
import '../widgets/sales_invoice_card.dart';

/// قسم «الفواتير» في شريط التنقل السفلي: أربعة تبويبات بحسب مستحق الفاتورة
/// في ERPNext: مسودة ← غير مدفوعة ← مدفوعة جزئيًا ← مدفوعة.
class InvoicesTabsView extends StatelessWidget {
  const InvoicesTabsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SalesInvoicesController>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.navInvoices),
          actions: [
            IconButton(
              tooltip: AppStrings.ordersRefresh,
              onPressed: controller.refreshing ? null : controller.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: AppStrings.tabDraft),
              Tab(text: AppStrings.tabUnpaid),
              Tab(text: AppStrings.tabPartlyPaid),
              Tab(text: AppStrings.tabPaid),
            ],
          ),
        ),
        body: Column(
          children: [
            if (controller.notice != null)
              OfflineBanner(message: controller.notice!),
            if (controller.refreshing && controller.loaded)
              const LinearProgressIndicator(minHeight: 2),
            const Expanded(
              child: TabBarView(
                children: [
                  _InvoicesPage(bucket: InvoiceBucket.draft),
                  _InvoicesPage(bucket: InvoiceBucket.unpaid),
                  _InvoicesPage(bucket: InvoiceBucket.partlyPaid),
                  _InvoicesPage(bucket: InvoiceBucket.paid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoicesPage extends StatelessWidget {
  final InvoiceBucket bucket;

  const _InvoicesPage({required this.bucket});

  ({IconData icon, String title, String message}) get _empty => switch (bucket) {
        InvoiceBucket.draft => (
            icon: Icons.edit_note_outlined,
            title: AppStrings.invoicesDraftEmptyTitle,
            message: AppStrings.invoicesDraftEmptyMessage,
          ),
        InvoiceBucket.unpaid => (
            icon: Icons.request_quote_outlined,
            title: AppStrings.invoicesUnpaidEmptyTitle,
            message: AppStrings.invoicesUnpaidEmptyMessage,
          ),
        InvoiceBucket.partlyPaid => (
            icon: Icons.timelapse_outlined,
            title: AppStrings.invoicesPartlyEmptyTitle,
            message: AppStrings.invoicesPartlyEmptyMessage,
          ),
        _ => (
            icon: Icons.check_circle_outline,
            title: AppStrings.invoicesPaidEmptyTitle,
            message: AppStrings.invoicesPaidEmptyMessage,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SalesInvoicesController>();

    if (controller.error != null && !controller.loaded) {
      return ErrorView(message: controller.error!, onRetry: controller.refresh);
    }
    if (!controller.loaded) return const LoadingView();

    final items = controller.byBucket(bucket);
    if (items.isEmpty) {
      final e = _empty;
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: LayoutBuilder(
          builder: (_, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: EmptyView(icon: e.icon, title: e.title, message: e.message),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => SalesInvoiceCard(
          // مفتاح باسم الفاتورة كي لا تنتقل حالة «جارٍ» من بطاقة إلى أخرى
          key: ValueKey(items[i].name),
          invoice: items[i],
          bucket: bucket,
          pendingAmount: controller.pendingAmount(items[i].name),
        ),
      ),
    );
  }
}
