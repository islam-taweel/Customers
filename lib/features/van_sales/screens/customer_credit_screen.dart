import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/van_sale_models.dart';
import '../../../data/repositories/erp_van_sales_repository.dart';
import '../controllers/customer_credit_controller.dart';
import '../widgets/credit_summary.dart';
import '../widgets/customer_picker_sheet.dart';

/// رصيد العميل: اختيار العميل، ثم معلوماته وحده الائتماني (Credit Limit)
/// ورصيده الحالي والمتاح من الحد، كلها من ERPNext.
class CustomerCreditScreen extends StatefulWidget {
  const CustomerCreditScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const CustomerCreditScreen());

  @override
  State<CustomerCreditScreen> createState() => _CustomerCreditScreenState();
}

class _CustomerCreditScreenState extends State<CustomerCreditScreen> {
  late final CustomerCreditController _c;

  @override
  void initState() {
    super.initState();
    // متحكم مستقل للشاشة: يُنشأ عند فتحها ويُحذف عند إغلاقها
    _c = Get.put(
      CustomerCreditController(context.read<ErpVanSalesRepository>()),
    );
  }

  @override
  void dispose() {
    Get.delete<CustomerCreditController>();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await CustomerPickerSheet.show(
      context,
      customers: _c.customers,
      loading: _c.customersLoading,
      error: _c.customersError,
      filter: _c.filterCustomers,
      onRetry: _c.loadCustomers,
      selectedId: _c.customer.value?.id,
    );
    if (picked != null) await _c.select(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(VanStrings.creditTitle)),
      body: Obx(() {
        final customer = _c.customer.value;
        final credit = _c.credit.value;
        final error = _c.creditError.value;

        Widget content;
        if (customer == null) {
          content = Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyView(
              icon: Icons.account_balance_wallet_outlined,
              title: VanStrings.chooseCustomerHint,
            ),
          );
        } else if (_c.creditLoading.value && credit == null) {
          content = SizedBox(
            height: 240,
            child: LoadingView(message: VanStrings.loadingCredit),
          );
        } else if (error != null && credit == null) {
          content = SizedBox(
            height: 300,
            child: ErrorView(
              message: describeError(error, fallback: VanStrings.creditFailed),
              onRetry: _c.loadCredit,
            ),
          );
        } else if (credit != null) {
          content = _CreditDetails(credit: credit);
        } else {
          content = const SizedBox.shrink();
        }

        return RefreshIndicator(
          onRefresh: _c.loadCredit,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              InkWell(
                onTap: _pick,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: VanStrings.customer,
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    customer?.name ?? VanStrings.chooseCustomer,
                    style: customer == null
                        ? TextStyle(color: scheme.onSurfaceVariant)
                        : const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        );
      }),
    );
  }
}

/// معلومات العميل ثم ملخص الحد والرصيد
class _CreditDetails extends StatelessWidget {
  final CustomerCredit credit;

  const _CreditDetails({required this.credit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = credit;

    Widget info(
      IconData icon,
      String label,
      String value, {
      bool ltr = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.end,
              textDirection: ltr && value.isNotEmpty ? TextDirection.ltr : null,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    final source = switch (c.limitSource) {
      CreditLimitSource.customer => VanStrings.limitFromCustomer,
      CreditLimitSource.customerGroup => VanStrings.limitFromGroup(
        c.customerGroup,
      ),
      CreditLimitSource.none => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // معلومات العميل
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
                child: Text(
                  c.customerName.isEmpty
                      ? '?'
                      : c.customerName.characters.first,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 22,
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
                      c.customerName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      c.customerId,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              children: [
                info(
                  Icons.badge_outlined,
                  VanStrings.customerId,
                  c.customerId,
                  ltr: true,
                ),
                info(
                  Icons.groups_outlined,
                  VanStrings.customerGroup,
                  c.customerGroup,
                ),
                info(
                  Icons.phone_outlined,
                  VanStrings.phone,
                  c.phone,
                  ltr: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // الحد والرصيد
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CreditSummary(credit: c),
                if (source != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    source,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          VanStrings.creditNote,
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
        ),
      ],
    );
  }
}
