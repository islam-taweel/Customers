import 'package:flutter/material.dart';

import '../../../core/constants/van_strings.dart';
import '../../../data/api/erp_config.dart';
import 'customer_credit_screen.dart';
import 'end_of_day_screen.dart';
import 'new_sale_screen.dart';
import 'replenishment_screen.dart';
import 'van_return_screen.dart';
import 'van_stock_screen.dart';

/// قسم «مبيعات الفان»: فاتورة بيع جديدة، إرجاع منتجات، رصيد العميل، مخزون الفان،
/// طلب تزويد الفان، ونهاية اليوم.
class VanSalesScreen extends StatelessWidget {
  const VanSalesScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const VanSalesScreen());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget card({
      required IconData icon,
      required String title,
      required String description,
      required Color color,
      required Route<void> Function() route,
    }) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(route()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(VanStrings.section),
            Text(
              ErpConfig.vanWarehouse,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          card(
            icon: Icons.point_of_sale_outlined,
            title: VanStrings.newSale,
            description: VanStrings.newSaleDesc,
            color: scheme.primary,
            route: NewSaleScreen.route,
          ),
          card(
            icon: Icons.assignment_return_outlined,
            title: VanStrings.returnTitle,
            description: VanStrings.returnDesc,
            color: scheme.error,
            route: VanReturnScreen.route,
          ),
          card(
            icon: Icons.account_balance_wallet_outlined,
            title: VanStrings.creditTitle,
            description: VanStrings.creditDesc,
            color: scheme.secondary,
            route: CustomerCreditScreen.route,
          ),
          card(
            icon: Icons.local_shipping_outlined,
            title: VanStrings.stockTitle,
            description: VanStrings.stockDesc,
            color: scheme.tertiary,
            route: VanStockScreen.route,
          ),
          card(
            icon: Icons.add_shopping_cart_outlined,
            title: VanStrings.refillTitle,
            description: VanStrings.refillDesc,
            color: scheme.primary,
            route: ReplenishmentScreen.route,
          ),
          card(
            icon: Icons.nightlight_outlined,
            title: VanStrings.eodTitle,
            description: VanStrings.eodDesc,
            color: scheme.tertiary,
            route: EndOfDayScreen.route,
          ),
        ],
      ),
    );
  }
}
