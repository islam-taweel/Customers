import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/invoice.dart';
import '../../customers/widgets/draft_list.dart';
import '../../customers/widgets/offline_banner.dart';
import '../../order/controllers/order_controller.dart';
import '../../order/screens/new_order_screen.dart';
import '../controllers/orders_controller.dart';
import '../controllers/sales_invoices_controller.dart';
import '../widgets/delivery_tile.dart';
import '../widgets/order_list_tile.dart';
import 'invoices_tabs_view.dart';
import 'order_details_screen.dart';

/// قسم «الطلبات»: شريط تنقل سفلي بثلاثة أقسام (الطلبيات، التسليمات، الفواتير).
/// «الطلبيات» تحوي أربعة تبويبات بحسب مرحلة الطلبية:
/// مسودة ← بانتظار التسليم ← بانتظار الفوترة ← مكتملة.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<OrdersController>(
            create: (ctx) =>
                ctx.read<OrdersControllerFactory>().create()..load(),
          ),
          // فواتير المبيعات ودفعاتها (تبويب «الفواتير»)
          ChangeNotifierProvider<SalesInvoicesController>(
            create: (ctx) =>
                ctx.read<SalesInvoicesControllerFactory>().create()..load(),
          ),
        ],
        child: const OrdersScreen(),
      ),
    );
  }

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // كل قسم له Scaffold وشريط عنوانه الخاص
      body: IndexedStack(
        index: _index,
        children: [
          const _OrdersTabsView(),
          const _DeliveriesTabsView(),
          const InvoicesTabsView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: AppStrings.navOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: const Icon(Icons.local_shipping),
            label: AppStrings.navDeliveries,
          ),
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon: const Icon(Icons.description),
            label: AppStrings.navInvoices,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── الطلبيات: أربعة تبويبات ─────────────────────────

class _OrdersTabsView extends StatelessWidget {
  const _OrdersTabsView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrdersController>();

    return DefaultTabController(
      // ترتيب التبويبات = ترتيب OrderStage
      length: OrderStage.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.navOrders),
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
              Tab(text: AppStrings.tabToDeliver),
              Tab(text: AppStrings.tabToBill),
              Tab(text: AppStrings.tabCompleted),
            ],
          ),
        ),
        body: Column(
          children: [
            if (controller.notice != null)
              OfflineBanner(message: controller.notice!),
            if (controller.refreshing)
              const LinearProgressIndicator(minHeight: 2),
            const Expanded(
              child: TabBarView(
                children: [
                  _DraftsPage(),
                  _StagePage(stage: OrderStage.toDeliver),
                  _StagePage(stage: OrderStage.toBill),
                  _StagePage(stage: OrderStage.completed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// تبويب المسودة: زر ثابت دائمًا لإضافة طلبية جديدة، وتحته المسودات
/// بأزرار التعديل والحذف والاعتماد.
class _DraftsPage extends StatelessWidget {
  const _DraftsPage();

  Future<void> _newOrder(BuildContext context) async {
    final orders = context.read<OrdersController>();
    // متحكم جديد لكل طلبية: تبدأ دائمًا من الخطوة الأولى (اختيار العميل)
    final controller = context.read<OrderControllerFactory>().create();
    await Navigator.push(context, NewOrderScreen.route(controller));
    // الطلبية الجديدة تظهر هنا كمسودة
    await orders.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrdersController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newOrder(context),
        icon: const Icon(Icons.add),
        label: Text(AppStrings.addNewOrder),
      ),
      body: _body(context, controller),
    );
  }

  Widget _body(BuildContext context, OrdersController controller) {
    if (!controller.loaded) return const LoadingView();

    final drafts = controller.byStage(OrderStage.draft);
    if (drafts.isEmpty) {
      return EmptyView(
        icon: Icons.edit_note_outlined,
        title: AppStrings.draftsEmptyTitle,
        message: AppStrings.ordersDraftsEmptyMessage,
      );
    }

    final tabs = DefaultTabController.of(context);
    return DraftList(
      drafts: drafts,
      showCustomer: true,
      // مسافة تحت القائمة كي لا يغطي الزر العائم أزرار آخر مسودة
      bottomPadding: 96,
      openDraft: controller.openDraft,
      onChanged: controller.reloadLocal,
      // بعد الاعتماد تنتقل الطلبية وحدها إلى «بانتظار التسليم»
      onSubmitted: () => tabs.animateTo(OrderStage.toDeliver.index),
    );
  }
}

/// تبويب مرحلة بعد الاعتماد (بانتظار التسليم / بانتظار الفوترة / مكتملة).
class _StagePage extends StatelessWidget {
  final OrderStage stage;

  const _StagePage({required this.stage});

  Future<void> _open(BuildContext context, Invoice invoice) async {
    final orders = context.read<OrdersController>();
    final tabs = DefaultTabController.of(context);

    final delivered = await Navigator.push<bool>(
      context,
      OrderDetailsScreen.route(invoice, orders),
    );
    // بعد التسليم تنتقل الطلبية وحدها: نفتح التبويب الذي صارت فيه
    if (delivered == true) {
      final next = orders.stageOf(invoice.id!);
      if (next != null) tabs.animateTo(next.index);
    }
  }

  ({IconData icon, String title, String message}) get _empty => switch (stage) {
        OrderStage.toDeliver => (
            icon: Icons.local_shipping_outlined,
            title: AppStrings.toDeliverEmptyTitle,
            message: AppStrings.toDeliverEmptyMessage,
          ),
        OrderStage.toBill => (
            icon: Icons.request_quote_outlined,
            title: AppStrings.toBillEmptyTitle,
            message: AppStrings.toBillEmptyMessage,
          ),
        _ => (
            icon: Icons.check_circle_outline,
            title: AppStrings.completedEmptyTitle,
            message: AppStrings.completedEmptyMessage,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrdersController>();
    if (!controller.loaded) return const LoadingView();

    final orders = controller.byStage(stage);
    if (orders.isEmpty) {
      final e = _empty;
      return EmptyView(icon: e.icon, title: e.title, message: e.message);
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => OrderListTile(
          invoice: orders[i],
          onTap: () => _open(context, orders[i]),
        ),
      ),
    );
  }
}

// ───────────────────────── التسليمات: ثلاثة تبويبات ─────────────────────────

/// مسودة ← انتظار الفوترة ← مكتملة.
class _DeliveriesTabsView extends StatelessWidget {
  const _DeliveriesTabsView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrdersController>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.navDeliveries),
          actions: [
            IconButton(
              tooltip: AppStrings.ordersRefresh,
              onPressed: controller.refreshing ? null : controller.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: AppStrings.tabDraft),
              Tab(text: AppStrings.tabToBill),
              Tab(text: AppStrings.tabCompleted),
            ],
          ),
        ),
        body: Column(
          children: [
            if (controller.notice != null)
              OfflineBanner(message: controller.notice!),
            if (controller.refreshing)
              const LinearProgressIndicator(minHeight: 2),
            const Expanded(
              child: TabBarView(
                children: [
                  _DeliveriesPage(mode: DeliveryTileMode.draft),
                  _DeliveriesPage(mode: DeliveryTileMode.toBill),
                  _DeliveriesPage(mode: DeliveryTileMode.completed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveriesPage extends StatelessWidget {
  final DeliveryTileMode mode;

  const _DeliveriesPage({required this.mode});

  List<Invoice> _items(OrdersController c) => switch (mode) {
        DeliveryTileMode.draft => c.deliveryDrafts,
        DeliveryTileMode.toBill => c.deliveriesToBill,
        DeliveryTileMode.completed => c.deliveriesCompleted,
      };

  ({IconData icon, String title, String message}) get _empty => switch (mode) {
        DeliveryTileMode.draft => (
            icon: Icons.edit_note_outlined,
            title: AppStrings.deliveriesDraftEmptyTitle,
            message: AppStrings.deliveriesDraftEmptyMessage,
          ),
        DeliveryTileMode.toBill => (
            icon: Icons.request_quote_outlined,
            title: AppStrings.deliveriesToBillEmptyTitle,
            message: AppStrings.deliveriesToBillEmptyMessage,
          ),
        DeliveryTileMode.completed => (
            icon: Icons.check_circle_outline,
            title: AppStrings.deliveriesCompletedEmptyTitle,
            message: AppStrings.deliveriesCompletedEmptyMessage,
          ),
      };

  Future<void> _open(BuildContext context, Invoice invoice) async {
    final orders = context.read<OrdersController>();
    await Navigator.push<bool>(
      context,
      OrderDetailsScreen.route(invoice, orders),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrdersController>();
    if (!controller.loaded) return const LoadingView();

    final items = _items(controller);
    if (items.isEmpty) {
      final e = _empty;
      return EmptyView(icon: e.icon, title: e.title, message: e.message);
    }

    final tabs = DefaultTabController.of(context);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => DeliveryTile(
          // مفتاح باسم الطلبية كي لا تنتقل حالة «جارٍ» من بطاقة إلى أخرى
          key: ValueKey(items[i].id),
          invoice: items[i],
          mode: mode,
          onTap: () => _open(context, items[i]),
          // بعد الفوترة تنتقل الطلبية وحدها إلى «مكتملة»
          onBilled: () => tabs.animateTo(2),
        ),
      ),
    );
  }
}
