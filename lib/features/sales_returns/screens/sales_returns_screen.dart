import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/returns_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/return_models.dart';
import '../controllers/sales_returns_controller.dart';
import 'pending_returns_screen.dart';
import 'return_invoices_screen.dart';

/// قسم «مردود المبيعات»: اختيار عميل لديه فواتير سابقة ← فاتورته ← كميات الإرجاع.
/// زر في الشريط العلوي يفتح المرتجعات بانتظار الاعتماد.
class SalesReturnsScreen extends StatefulWidget {
  const SalesReturnsScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<SalesReturnsController>(
        create: (ctx) => ctx.read<SalesReturnsControllerFactory>().create(),
        child: const SalesReturnsScreen(),
      ),
    );
  }

  @override
  State<SalesReturnsScreen> createState() => _SalesReturnsScreenState();
}

class _SalesReturnsScreenState extends State<SalesReturnsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(ReturnCustomer customer) {
    Navigator.of(context).push(ReturnInvoicesScreen.route(context, customer));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SalesReturnsController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(ReturnsStrings.section),
        actions: [
          IconButton(
            tooltip: ReturnsStrings.pendingTitle,
            icon: const Icon(Icons.pending_actions_outlined),
            onPressed: () => Navigator.of(context)
                .push(PendingReturnsScreen.route(context)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ReturnsStrings.chooseCustomer,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ReturnsStrings.chooseCustomerHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (c.savedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ReturnsStrings.savedAt(formatDateTime(c.savedAt!)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: c.setQuery,
                  decoration: InputDecoration(
                    hintText: ReturnsStrings.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: c.query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              c.setQuery('');
                            },
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
              ],
            ),
          ),
          Expanded(child: _body(c)),
        ],
      ),
    );
  }

  Widget _body(SalesReturnsController c) {
    if (c.loading && !c.hasAny) {
      return LoadingView(message: ReturnsStrings.loadingCustomers);
    }
    if (c.error != null && !c.hasAny) {
      return ErrorView(message: c.error!, onRetry: c.load);
    }
    final list = c.customers;
    if (list.isEmpty) {
      return EmptyView(
        icon: c.query.trim().isEmpty ? Icons.people_outline : Icons.search_off,
        title: ReturnsStrings.noCustomers,
      );
    }

    return RefreshIndicator(
      onRefresh: c.load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final customer = list[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  customer.name.isEmpty ? '?' : customer.name.characters.first,
                ),
              ),
              title: Text(customer.name),
              subtitle: Text(
                '${ReturnsStrings.invoicesCount(customer.invoiceCount)}'
                '  •  ${ReturnsStrings.lastInvoice(customer.lastDate)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(customer),
            ),
          );
        },
      ),
    );
  }
}
