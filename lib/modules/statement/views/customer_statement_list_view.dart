import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/statement_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../bindings/statement_bindings.dart';
import '../controllers/statement_customers_controller.dart';
import 'customer_statement_view.dart';

/// «كشف حساب العملاء»: كل أسماء العملاء مع البحث، والضغط على عميل يفتح كشف حسابه.
/// الحالة كلها في [StatementCustomersController]؛ الشاشة تعرض فقط.
class CustomerStatementListScreen
    extends GetView<StatementCustomersController> {
  const CustomerStatementListScreen({super.key});

  /// نفس الواجهة القديمة (القائمة الجانبية تستدعيها)، لكن بمسار GetX يربط
  /// المتحكم بعمر الشاشة. Transition.native = نفس انتقال MaterialPageRoute.
  static Route<void> route() => GetPageRoute<void>(
    settings: const RouteSettings(name: '/statement'),
    page: () => const CustomerStatementListScreen(),
    binding: StatementCustomersBinding(),
    transition: Transition.native,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = controller;

    return Scaffold(
      appBar: AppBar(title: Text(StatementStrings.section)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Obx(
              () => TextField(
                controller: c.search,
                onChanged: c.setQuery,
                decoration: InputDecoration(
                  hintText: StatementStrings.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: c.query.value.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: c.clearQuery,
                        ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return LoadingView(message: StatementStrings.loadingCustomers);
              }
              final message = c.errorMessage;
              if (message != null) {
                return ErrorView(message: message, onRetry: c.load);
              }
              final list = c.visible;
              if (list.isEmpty) {
                return EmptyView(
                  icon: c.query.value.isEmpty
                      ? Icons.people_outline
                      : Icons.search_off,
                  title: StatementStrings.noCustomers,
                );
              }
              return RefreshIndicator(
                onRefresh: c.load,
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          c.name.isEmpty ? '?' : c.name.characters.first,
                        ),
                      ),
                      title: Text(c.name),
                      subtitle: Text(
                        c.phone.isEmpty ? c.id : '${c.id}  •  ${c.phone}',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context)
                              .push(CustomerStatementScreen.route(c)),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
