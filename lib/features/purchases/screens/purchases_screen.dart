import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/purchase_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/purchase_models.dart';
import '../controllers/purchases_controller.dart';
import '../widgets/purchase_invoice_card.dart';
import '../widgets/purchase_order_tile.dart';
import '../widgets/purchase_receipt_tile.dart';
import 'new_purchase_order_screen.dart';
import 'purchase_details_screen.dart';

/// قسم «المشتريات»: شريط تنقل سفلي بثلاثة أقسام (أوامر الشراء، الاستلامات، الفواتير).
/// أوامر الشراء: مسودة ← انتظار الاستلام ← انتظار الفوترة ← مكتملة.
/// الاستلامات: مسودة ← انتظار الفوترة ← مكتملة.
/// الفواتير: مسودة ← غير مدفوعة ← مدفوعة جزئيًا ← مدفوعة.
class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<PurchasesController>(
        create: (ctx) => ctx.read<PurchasesControllerFactory>().create()..load(),
        child: const PurchasesScreen(),
      ),
    );
  }

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          _OrdersTabs(),
          _ReceiptsTabs(),
          _InvoicesTabs(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: PurchaseStrings.navOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.move_to_inbox_outlined),
            selectedIcon: const Icon(Icons.move_to_inbox),
            label: PurchaseStrings.navReceipts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon: const Icon(Icons.description),
            label: PurchaseStrings.navInvoices,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── مشترك ─────────────────────────

AppBar _appBar(
  PurchasesController c, {
  required String title,
  required List<Tab> tabs,
}) {
  return AppBar(
    title: Text(title),
    actions: [
      IconButton(
        tooltip: AppStrings.ordersRefresh,
        onPressed: c.refreshing ? null : c.refresh,
        icon: const Icon(Icons.refresh),
      ),
    ],
    bottom: TabBar(
      isScrollable: tabs.length > 3,
      tabAlignment: tabs.length > 3 ? TabAlignment.start : null,
      tabs: tabs,
    ),
  );
}

/// صفحة تبويب: تحميل/خطأ/فراغ/قائمة مع سحب للتحديث.
class _TabPage extends StatelessWidget {
  final PurchasesController controller;
  final int count;
  final ({IconData icon, String title, String message}) empty;
  final Widget Function(int index) itemBuilder;
  final double bottomPadding;

  const _TabPage({
    required this.controller,
    required this.count,
    required this.empty,
    required this.itemBuilder,
    this.bottomPadding = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.error != null && !controller.loaded) {
      return ErrorView(message: controller.error!, onRetry: controller.refresh);
    }
    if (!controller.loaded) return const LoadingView();

    if (count == 0) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: LayoutBuilder(
          builder: (_, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: EmptyView(
                icon: empty.icon,
                title: empty.title,
                message: empty.message,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomPadding),
        itemCount: count,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => itemBuilder(i),
      ),
    );
  }
}

// ───────────────────────── أوامر الشراء ─────────────────────────

class _OrdersTabs extends StatelessWidget {
  const _OrdersTabs();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PurchasesController>();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: _appBar(
          c,
          title: PurchaseStrings.navOrders,
          tabs: [
            Tab(text: AppStrings.tabDraft),
            Tab(text: PurchaseStrings.tabToReceive),
            Tab(text: AppStrings.tabToBill),
            Tab(text: AppStrings.tabCompleted),
          ],
        ),
        body: Column(
          children: [
            if (c.refreshing && c.loaded)
              const LinearProgressIndicator(minHeight: 2),
            const Expanded(
              child: TabBarView(
                children: [
                  _OrdersPage(stage: PurchaseStage.draft),
                  _OrdersPage(stage: PurchaseStage.toReceive),
                  _OrdersPage(stage: PurchaseStage.toBill),
                  _OrdersPage(stage: PurchaseStage.completed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersPage extends StatelessWidget {
  final PurchaseStage stage;

  const _OrdersPage({required this.stage});

  ({IconData icon, String title, String message}) get _empty => switch (stage) {
        PurchaseStage.draft => (
            icon: Icons.edit_note_outlined,
            title: PurchaseStrings.orderDraftsEmptyTitle,
            message: PurchaseStrings.orderDraftsEmptyMessage,
          ),
        PurchaseStage.toReceive => (
            icon: Icons.move_to_inbox_outlined,
            title: PurchaseStrings.toReceiveEmptyTitle,
            message: PurchaseStrings.toReceiveEmptyMessage,
          ),
        PurchaseStage.toBill => (
            icon: Icons.request_quote_outlined,
            title: PurchaseStrings.orderToBillEmptyTitle,
            message: PurchaseStrings.orderToBillEmptyMessage,
          ),
        PurchaseStage.completed => (
            icon: Icons.check_circle_outline,
            title: PurchaseStrings.orderCompletedEmptyTitle,
            message: PurchaseStrings.orderCompletedEmptyMessage,
          ),
      };

  Future<void> _newOrder(BuildContext context) async {
    final c = context.read<PurchasesController>();
    await Navigator.push(context, NewPurchaseOrderScreen.route(c));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PurchasesController>();
    final orders = c.ordersByStage(stage);
    final isDraft = stage == PurchaseStage.draft;

    final page = _TabPage(
      controller: c,
      count: orders.length,
      empty: _empty,
      // مسافة تحت القائمة كي لا يغطي الزر العائم أزرار آخر مسودة
      bottomPadding: isDraft ? 96 : 24,
      itemBuilder: (i) => PurchaseOrderTile(
        key: ValueKey(orders[i].name),
        order: orders[i],
        onTap: () => Navigator.push(
          context,
          PurchaseDetailsScreen.route(
            c,
            doctype: 'Purchase Order',
            name: orders[i].name,
          ),
        ),
      ),
    );

    if (!isDraft) return page;

    // تبويب المسودة: زر ثابت بالأسفل «أمر شراء جديد»
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newOrder(context),
        icon: const Icon(Icons.add),
        label: Text(PurchaseStrings.newOrder),
      ),
      body: page,
    );
  }
}

// ───────────────────────── الاستلامات ─────────────────────────

class _ReceiptsTabs extends StatelessWidget {
  const _ReceiptsTabs();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PurchasesController>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: _appBar(
          c,
          title: PurchaseStrings.navReceipts,
          tabs: [
            Tab(text: AppStrings.tabDraft),
            Tab(text: AppStrings.tabToBill),
            Tab(text: AppStrings.tabCompleted),
          ],
        ),
        body: Column(
          children: [
            if (c.refreshing && c.loaded)
              const LinearProgressIndicator(minHeight: 2),
            const Expanded(
              child: TabBarView(
                children: [
                  _ReceiptsPage(bucket: ReceiptBucket.draft),
                  _ReceiptsPage(bucket: ReceiptBucket.toBill),
                  _ReceiptsPage(bucket: ReceiptBucket.completed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptsPage extends StatelessWidget {
  final ReceiptBucket bucket;

  const _ReceiptsPage({required this.bucket});

  ({IconData icon, String title, String message}) get _empty => switch (bucket) {
        ReceiptBucket.draft => (
            icon: Icons.edit_note_outlined,
            title: PurchaseStrings.receiptsDraftEmptyTitle,
            message: PurchaseStrings.receiptsDraftEmptyMessage,
          ),
        ReceiptBucket.toBill => (
            icon: Icons.request_quote_outlined,
            title: PurchaseStrings.receiptsToBillEmptyTitle,
            message: PurchaseStrings.receiptsToBillEmptyMessage,
          ),
        ReceiptBucket.completed => (
            icon: Icons.check_circle_outline,
            title: PurchaseStrings.receiptsCompletedEmptyTitle,
            message: PurchaseStrings.receiptsCompletedEmptyMessage,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PurchasesController>();
    final items = c.receiptsByBucket(bucket);
    return _TabPage(
      controller: c,
      count: items.length,
      empty: _empty,
      itemBuilder: (i) => PurchaseReceiptTile(
        key: ValueKey(items[i].name),
        receipt: items[i],
        // زر «فوترة» على الاستلام المعتمد فقط (بانتظار الفوترة)
        showActions: bucket == ReceiptBucket.toBill,
      ),
    );
  }
}

// ───────────────────────── الفواتير ─────────────────────────

class _InvoicesTabs extends StatelessWidget {
  const _InvoicesTabs();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PurchasesController>();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: _appBar(
          c,
          title: PurchaseStrings.navInvoices,
          tabs: [
            Tab(text: AppStrings.tabDraft),
            Tab(text: AppStrings.tabUnpaid),
            Tab(text: AppStrings.tabPartlyPaid),
            Tab(text: AppStrings.tabPaid),
          ],
        ),
        body: Column(
          children: [
            if (c.refreshing && c.loaded)
              const LinearProgressIndicator(minHeight: 2),
            const Expanded(
              child: TabBarView(
                children: [
                  _InvoicesPage(bucket: PurchaseInvoiceBucket.draft),
                  _InvoicesPage(bucket: PurchaseInvoiceBucket.unpaid),
                  _InvoicesPage(bucket: PurchaseInvoiceBucket.partlyPaid),
                  _InvoicesPage(bucket: PurchaseInvoiceBucket.paid),
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
  final PurchaseInvoiceBucket bucket;

  const _InvoicesPage({required this.bucket});

  ({IconData icon, String title, String message}) get _empty => switch (bucket) {
        PurchaseInvoiceBucket.draft => (
            icon: Icons.edit_note_outlined,
            title: PurchaseStrings.invoicesDraftEmptyTitle,
            message: PurchaseStrings.invoicesDraftEmptyMessage,
          ),
        PurchaseInvoiceBucket.unpaid => (
            icon: Icons.request_quote_outlined,
            title: PurchaseStrings.invoicesUnpaidEmptyTitle,
            message: PurchaseStrings.invoicesUnpaidEmptyMessage,
          ),
        PurchaseInvoiceBucket.partlyPaid => (
            icon: Icons.timelapse_outlined,
            title: PurchaseStrings.invoicesPartlyEmptyTitle,
            message: PurchaseStrings.invoicesPartlyEmptyMessage,
          ),
        _ => (
            icon: Icons.check_circle_outline,
            title: PurchaseStrings.invoicesPaidEmptyTitle,
            message: PurchaseStrings.invoicesPaidEmptyMessage,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PurchasesController>();
    final items = c.invoicesByBucket(bucket);
    return _TabPage(
      controller: c,
      count: items.length,
      empty: _empty,
      itemBuilder: (i) => PurchaseInvoiceCard(
        // مفتاح باسم الفاتورة كي لا تنتقل حالة «جارٍ» من بطاقة إلى أخرى
        key: ValueKey(items[i].name),
        invoice: items[i],
        bucket: bucket,
        pendingAmount: c.pendingAmount(items[i].name),
      ),
    );
  }
}
