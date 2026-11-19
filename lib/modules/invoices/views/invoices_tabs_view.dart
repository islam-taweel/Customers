import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../features/customers/widgets/offline_banner.dart';
import '../../collections/controllers/invoice_collections_controller.dart';
import '../controllers/sales_invoices_controller.dart';
import '../widgets/sales_invoice_card.dart';

/// قسم «الفواتير» في شريط التنقل السفلي: أربعة تبويبات بحسب مستحق الفاتورة
/// في ERPNext: مسودة ← غير مدفوعة ← مدفوعة جزئيًا ← مدفوعة.
/// الحالة في [SalesInvoicesController] (SalesInvoicesBinding على مسار «الطلبات»).
class InvoicesTabsView extends GetView<SalesInvoicesController> {
  const InvoicesTabsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.navInvoices),
          actions: [
            Obx(
              () => IconButton(
                tooltip: AppStrings.ordersRefresh,
                onPressed: controller.refreshing.value
                    ? null
                    : controller.reload,
                icon: const Icon(Icons.refresh),
              ),
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
            Obx(
              () => controller.notice.value != null
                  ? OfflineBanner(message: controller.notice.value!)
                  : const SizedBox.shrink(),
            ),
            Obx(
              () => controller.refreshing.value && controller.loaded.value
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox.shrink(),
            ),
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

  ({IconData icon, String title, String message}) get _empty =>
      switch (bucket) {
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
    final controller = Get.find<SalesInvoicesController>();
    final collections = Get.find<InvoiceCollectionsController>();
    return Obx(() => _build(controller, collections));
  }

  Widget _build(
    SalesInvoicesController controller,
    InvoiceCollectionsController collections,
  ) {
    if (controller.error.value != null && !controller.loaded.value) {
      return ErrorView(
        message: controller.error.value!,
        onRetry: controller.reload,
      );
    }
    if (!controller.loaded.value) return const LoadingView();

    final items = controller.byBucket(bucket);
    if (items.isEmpty) {
      final e = _empty;
      return RefreshIndicator(
        onRefresh: controller.reload,
        child: LayoutBuilder(
          builder: (_, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: EmptyView(
                icon: e.icon,
                title: e.title,
                message: e.message,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.reload,
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
          pendingAmount: collections.pendingAmount(items[i].name),
        ),
      ),
    );
  }
}
