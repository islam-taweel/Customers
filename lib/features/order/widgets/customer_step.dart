import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/erp_customer.dart';
import '../controllers/order_controller.dart';

/// حالة عملة الطلبية وسعر صرفها بعد اختيار العميل: جارٍ الجلب، أو فشل (يمنع المتابعة)،
/// أو السعر المستخدم. لا تظهر لعملاء الشيكل.
class _RateStatus extends StatelessWidget {
  const _RateStatus();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OrderController>();
    final scheme = Theme.of(context).colorScheme;
    final currency = c.orderCurrency;
    if (c.customer == null || currency == null) return const SizedBox.shrink();

    Widget body;
    Color background;
    if (c.rateLoading) {
      background = scheme.surfaceContainerHighest;
      body = Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(AppStrings.orderRateLoading)),
        ],
      );
    } else if (c.rateError != null) {
      background = scheme.errorContainer;
      body = Row(
        children: [
          Expanded(
            child: Text(
              c.rateError!,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          TextButton(onPressed: c.retryRate, child: Text(AppStrings.retry)),
        ],
      );
    } else {
      background = scheme.secondaryContainer;
      body = Text(
        AppStrings.orderCurrencyInfo(currency, c.conversionRate),
        style: TextStyle(color: scheme.onSecondaryContainer),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: body,
    );
  }
}

/// الخطوة 1: اختيار عميل واحد من عملاء ERPNext.
class CustomerStep extends StatefulWidget {
  const CustomerStep({super.key});

  @override
  State<CustomerStep> createState() => _CustomerStepState();
}

class _CustomerStepState extends State<CustomerStep> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: context.read<OrderController>().query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OrderController>();
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.chooseCustomer,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.chooseCustomerHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              const _RateStatus(),
              TextField(
                controller: _search,
                onChanged: c.setQuery,
                decoration: InputDecoration(
                  hintText: AppStrings.searchHint,
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
        Expanded(child: _body(context, c)),
      ],
    );
  }

  Widget _body(BuildContext context, OrderController c) {
    if (c.customersLoading && !c.hasAnyCustomer) {
      return LoadingView(message: AppStrings.loadingCustomers);
    }
    if (c.customersError != null && !c.hasAnyCustomer) {
      return ErrorView(message: c.customersError!, onRetry: c.loadCustomers);
    }

    final list = c.customers;
    if (list.isEmpty) {
      return c.query.trim().isNotEmpty
          ? EmptyView(
              icon: Icons.search_off,
              title: AppStrings.noSearchResultsTitle,
              message: AppStrings.noSearchResultsMessage,
            )
          : EmptyView(
              icon: Icons.people_outline,
              title: AppStrings.orderCustomersEmpty,
            );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final customer = list[i];
        return _CustomerCard(
          customer: customer,
          selected: c.customer?.id == customer.id,
          onTap: () => c.selectCustomer(customer),
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final ErpCustomer customer;
  final bool selected;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final initial = customer.name.isNotEmpty
        ? customer.name[0]
        : AppStrings.unknownInitial;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.55)
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius + 4),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius + 4),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        selected ? scheme.primary : scheme.secondaryContainer,
                    foregroundColor: selected
                        ? scheme.onPrimary
                        : scheme.onSecondaryContainer,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              customer.phone.isEmpty
                                  ? Icons.tag
                                  : Icons.phone_outlined,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                customer.phone.isEmpty
                                    ? customer.id
                                    : customer.phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey('on'),
                            color: scheme.primary,
                            size: 28,
                          )
                        : Icon(
                            Icons.radio_button_unchecked,
                            key: const ValueKey('off'),
                            color: scheme.outline,
                            size: 28,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
