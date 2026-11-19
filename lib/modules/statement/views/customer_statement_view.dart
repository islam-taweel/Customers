import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/statement_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/erp_customer.dart';
import '../bindings/statement_bindings.dart';
import '../controllers/customer_statement_controller.dart';
import '../models/statement_models.dart';
import 'voucher_details_view.dart';

/// كشف حساب عميل من ERPNext (بالشيكل): الرصيد الافتتاحي (لفترة محددة)، ثم كل
/// حركة بمدينها ودائنها والرصيد الجاري بعدها، وفي الأعلى المجاميع والرصيد الختامي.
/// موجب = مستحق على العميل. الضغط على حركة يفتح مستندها.
class CustomerStatementScreen extends StatelessWidget {
  final ErpCustomer customer;

  /// وسم متحكم هذا المسار في GetX
  final String tag;

  const CustomerStatementScreen({
    super.key,
    required this.customer,
    required this.tag,
  });

  static Route<void> route(ErpCustomer customer) {
    final tag = nextStatementTag('statement:${customer.id}');
    return GetPageRoute<void>(
      settings: const RouteSettings(name: '/statement/customer'),
      page: () => CustomerStatementScreen(customer: customer, tag: tag),
      binding: CustomerStatementBinding(customer, tag: tag),
      transition: Transition.native,
    );
  }

  /// منتقي التاريخ يحتاج BuildContext فيبقى هنا؛ المتحكم يستلم الفترة فقط
  Future<void> _pickRange(
    BuildContext context,
    CustomerStatementController c,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          c.range.value ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (picked == null || !context.mounted) return;
    await c.setRange(picked);
  }

  String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CustomerStatementController>(tag: tag);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.name),
            Text(
              StatementStrings.section,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // الفترة: كل الفترات (افتراضيًا) أو من/إلى
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Obx(() {
              final range = c.range.value;
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickRange(context, c),
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(
                        range == null
                            ? StatementStrings.allPeriods
                            : '${_day(range.start)}  →  ${_day(range.end)}',
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                  if (range != null)
                    IconButton(
                      tooltip: StatementStrings.clearRange,
                      onPressed: c.clearRange,
                      icon: const Icon(Icons.close),
                    ),
                ],
              );
            }),
          ),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return LoadingView(message: StatementStrings.loadingStatement);
              }
              final message = c.errorMessage;
              if (message != null) {
                return ErrorView(message: message, onRetry: c.load);
              }
              final s = c.statement.value!;
              return RefreshIndicator(
                onRefresh: c.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _Summary(statement: s),
                    const SizedBox(height: 12),
                    if (s.lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text(StatementStrings.noEntries)),
                      )
                    else
                      for (final line in s.lines)
                        _LineTile(
                          line: line,
                          onTap: () => Navigator.of(context).push(
                            VoucherDetailsScreen.route(
                              line.voucherType,
                              line.voucherNo,
                            ),
                          ),
                        ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// الافتتاحي (لفترة) ومجموع المدين والدائن والرصيد الختامي
class _Summary extends StatelessWidget {
  final CustomerStatement statement;

  const _Summary({required this.statement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final closing = statement.closing;
    final state = closing > 0.005
        ? StatementStrings.owesUs
        : closing < -0.005
        ? StatementStrings.inCredit
        : StatementStrings.settled;

    Widget line(String label, double v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            formatSignedAmount(v),
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (statement.from != null)
            line(StatementStrings.openingBalance, statement.opening),
          line(StatementStrings.totalDebit, statement.totalDebit),
          line(StatementStrings.totalCredit, statement.totalCredit),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StatementStrings.closingBalance,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      state,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.forBalance(closing),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatSignedAmount(closing),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.forBalance(closing),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// حركة واحدة: نوع المستند ورقمه وتاريخه، المدين أو الدائن، والرصيد بعدها
class _LineTile extends StatelessWidget {
  final StatementLine line;
  final VoidCallback onTap;

  const _LineTile({required this.line, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDebit = line.debit > 0.005;
    final amount = isDebit ? line.debit : line.credit;
    // المرتجع فاتورة مبيعات أيضًا لكنه يظهر دائنًا
    final label = line.voucherType == 'Sales Invoice' && !isDebit
        ? StatementStrings.creditNote
        : StatementStrings.voucherType(line.voucherType);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${line.voucherNo}  •  ${line.postingDate}',
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDebit ? StatementStrings.debit : StatementStrings.credit}  ${formatAmount(amount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDebit ? AppColors.debt : AppColors.payment,
                    ),
                  ),
                  Text(
                    '${StatementStrings.balance}: ${formatSignedAmount(line.balance)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
