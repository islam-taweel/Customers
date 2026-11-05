import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/returns_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/return_models.dart';
import '../controllers/sales_returns_controller.dart';
import 'return_items_screen.dart';

/// فواتير العميل المعتمدة، الأحدث أولًا. الضغط على فاتورة يفتح أصنافها للإرجاع.
class ReturnInvoicesScreen extends StatelessWidget {
  const ReturnInvoicesScreen({super.key});

  static Route<void> route(BuildContext context, ReturnCustomer customer) {
    final factory = context.read<SalesReturnsControllerFactory>();
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<ReturnInvoicesController>(
        create: (_) => factory.createInvoices(customer),
        child: const ReturnInvoicesScreen(),
      ),
    );
  }

  Future<void> _open(BuildContext context, ReturnInvoice invoice) async {
    final controller = context.read<ReturnInvoicesController>();
    final created = await Navigator.of(context)
        .push<bool>(ReturnItemsScreen.route(context, invoice));
    // بعد حفظ مرتجع تتغير حالة الفاتورة
    if (created == true) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReturnInvoicesController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.customer.name),
            Text(ReturnsStrings.chooseInvoice, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: _body(context, c),
    );
  }

  Widget _body(BuildContext context, ReturnInvoicesController c) {
    if (c.loading && c.invoices.isEmpty) {
      return LoadingView(message: ReturnsStrings.loadingInvoices);
    }
    if (c.error != null && c.invoices.isEmpty) {
      return ErrorView(message: c.error!, onRetry: c.load);
    }
    if (c.invoices.isEmpty) {
      return EmptyView(
        icon: Icons.receipt_long_outlined,
        title: ReturnsStrings.noInvoices,
      );
    }

    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: c.load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: c.invoices.length,
        itemBuilder: (_, i) {
          final inv = c.invoices[i];
          final currency = displayCurrency(inv.currency);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                inv.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.postingDate),
                  Text(ReturnsStrings.total(
                    formatAmount(inv.grandTotal, currency: currency),
                  )),
                  if (inv.outstandingAmount.abs() > 0.005)
                    Text(ReturnsStrings.outstanding(
                      formatAmount(inv.outstandingAmount, currency: currency),
                    )),
                ],
              ),
              trailing: Chip(
                label: Text(inv.status, style: theme.textTheme.labelSmall),
                visualDensity: VisualDensity.compact,
              ),
              onTap: () => _open(context, inv),
            ),
          );
        },
      ),
    );
  }
}
