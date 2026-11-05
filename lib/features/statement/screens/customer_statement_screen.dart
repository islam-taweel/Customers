import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/statement_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/erp_customer.dart';
import '../../../data/models/statement_models.dart';
import '../../../data/repositories/erp_statement_repository.dart';
import 'voucher_details_screen.dart';

/// كشف حساب عميل من ERPNext (بالشيكل): الرصيد الافتتاحي (لفترة محددة)، ثم كل
/// حركة بمدينها ودائنها والرصيد الجاري بعدها، وفي الأعلى المجاميع والرصيد الختامي.
/// موجب = مستحق على العميل. الضغط على حركة يفتح مستندها.
class CustomerStatementScreen extends StatefulWidget {
  final ErpCustomer customer;

  const CustomerStatementScreen({super.key, required this.customer});

  static Route<void> route(ErpCustomer customer) => MaterialPageRoute<void>(
        builder: (_) => CustomerStatementScreen(customer: customer),
      );

  @override
  State<CustomerStatementScreen> createState() =>
      _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends State<CustomerStatementScreen> {
  DateTimeRange? _range;
  late Future<CustomerStatement> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ErpStatementRepository>().fetchStatement(
          widget.customer.id,
          from: _range?.start,
          to: _range?.end,
        );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _range = picked;
      _load();
    });
  }

  void _clearRange() => setState(() {
        _range = null;
        _load();
      });

  String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final range = _range;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customer.name),
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickRange,
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
                    onPressed: _clearRange,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<CustomerStatement>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return LoadingView(
                    message: StatementStrings.loadingStatement,
                  );
                }
                if (snapshot.hasError) {
                  final e = snapshot.error!;
                  return ErrorView(
                    message: e is ErpApiException &&
                            e.type == ErpErrorType.forbidden
                        ? StatementStrings.needsAccountsRole
                        : describeError(e, fallback: StatementStrings.loadFailed),
                    onRetry: () => setState(_load),
                  );
                }
                final s = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_load);
                    await _future.then((_) {}, onError: (_) {});
                  },
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
              },
            ),
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
