import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/customer.dart';
import '../controllers/customer_details_controller.dart';
import '../controllers/customerscontroller.dart';
import '../widgets/add_customer_dialog.dart';
import '../widgets/customer_tile.dart';
import '../widgets/list_footer.dart';
import '../widgets/total_debts_card.dart';
import 'customer_details_screen.dart';

/// واجهة فقط: تقرأ من [CustomersController] وتستدعي دوالَه.
/// StatefulWidget هنا لإدارة دورة حياة حقول الإدخال والتمرير فقط (بلا setState).
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() => _maybeLoadMore();

  /// إذا وصل المستخدم إلى نهاية القائمة (أو اقترب منها) نطلب الدفعة التالية.
  /// الـ controller نفسه يتأكد من hasMore ومن عدم وجود تحميل جارٍ، فلا يحدث
  /// طلب مكرر ولا طلب بعد انتهاء البيانات.
  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter <=
        AppConstants.loadMoreThreshold) {
      context.read<CustomersController>().loadNextPage();
    }
  }

  void _onSearchChanged(String value) {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    context.read<CustomersController>().search(value);
  }

  void _clearSearch() {
    _searchController.clear();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    context.read<CustomersController>().clearSearch();
  }

  Future<void> _showAddCustomerDialog() async {
    final controller = context.read<CustomersController>();
    final messenger = ScaffoldMessenger.of(context);

    final customer = await AddCustomerDialog.show(context);
    if (customer == null) return;

    final ok = await controller.addCustomer(customer);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? AppStrings.customerAdded : AppStrings.customerSaveFailed,
        ),
      ),
    );
  }

  /// للتطوير فقط: إدخال عملاء وهميين لاختبار التصفح اللانهائي
  Future<void> _addFakeCustomers() async {
    final controller = context.read<CustomersController>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await controller.addFakeCustomers(
      count: AppConstants.fakeCustomersCount,
    );
    if (!mounted) return;

    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? AppStrings.fakeCustomersAdded(AppConstants.fakeCustomersCount)
              : AppStrings.fakeCustomersFailed,
        ),
      ),
    );
  }

  Future<void> _openDetails(Customer customer) async {
    final controller = context.read<CustomersController>();
    final detailsFactory = context.read<CustomerDetailsControllerFactory>();
    await Navigator.push(
      context,
      CustomerDetailsScreen.route(detailsFactory.create(customer)),
    );
    // عند العودة: تحديث الأرصدة والإجمالي بعد أي عملية جديدة
    await controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomersController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.customers),
        actions: [
          // يظهر في وضع التطوير (debug) فقط، ولا يوجد في نسخة الإنتاج
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              tooltip: AppStrings.addFakeCustomersTooltip(
                AppConstants.fakeCustomersCount,
              ),
              onPressed: _addFakeCustomers,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        tooltip: AppStrings.addCustomer,
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          TotalDebtsCard(total: controller.totalDebts),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _buildBody(controller)),
        ],
      ),
    );
  }

  Widget _buildBody(CustomersController controller) {
    final customers = controller.customers;

    // 1) التحميل الأولي (أو إعادة التحميل بعد بحث لم يُرجع شيئًا بعد)
    if (controller.isLoading && customers.isEmpty) {
      return const LoadingView(message: AppStrings.loadingCustomers);
    }

    // 2) الخطأ: رسالة عربية واضحة وزر إعادة المحاولة
    if (controller.error != null && customers.isEmpty) {
      return ErrorView(message: controller.error!, onRetry: controller.retry);
    }

    // 3) القائمة فارغة
    if (customers.isEmpty) {
      // بحث بلا نتائج: رسالة فقط، دون زر إضافة
      if (controller.query.trim().isNotEmpty) {
        return const EmptyView(
          icon: Icons.search_off,
          title: AppStrings.noSearchResultsTitle,
          message: AppStrings.noSearchResultsMessage,
        );
      }
      // لا يوجد عملاء أصلًا: رسالة وزر لإضافة أول عميل
      return EmptyView(
        icon: Icons.people_outline,
        title: AppStrings.noCustomersTitle,
        message: AppStrings.noCustomersMessage,
        actionLabel: AppStrings.addFirstCustomer,
        actionIcon: Icons.person_add,
        onAction: _showAddCustomerDialog,
      );
    }

    // إذا لم تمتلئ الشاشة بالعملاء المحمّلين (شاشة كبيرة مثلًا) فلن يحدث تمرير
    // يطلب المزيد، لذلك نتحقق بعد كل رسم ونكمل التحميل حتى تمتلئ أو تنتهي البيانات.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeLoadMore();
    });

    // صف إضافي في نهاية القائمة: مؤشر تحميل أو رسالة خطأ مع إعادة محاولة
    final showFooter = controller.isMoreLoading || controller.error != null;

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: customers.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        if (i >= customers.length) {
          return controller.isMoreLoading
              ? const ListFooterLoader()
              : ListFooterError(
                  message: controller.error!,
                  onRetry: controller.retry,
                );
        }
        return CustomerTile(
          item: customers[i],
          onTap: () => _openDetails(customers[i].customer),
        );
      },
    );
  }
}
