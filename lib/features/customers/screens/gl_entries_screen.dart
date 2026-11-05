import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/gl_entry.dart';
import '../../../data/repositories/erp_ledger_repository.dart';

/// رقم بفواصل الآلاف وخانتين عشريتين، بلا رمز عملة (العملة في رأس العمود)
String _num(double v) {
  final parts = v.abs().toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '-' : ''}$intPart.${parts[1]}';
}

/// القيود المحاسبية للفاتورة على حساب العميل: جدول (البيان، مدين، دائن).
/// المدين = قيمة الفاتورة، والدائن = كل ما سُدد منها (دفعات، رصيد سابق، إشعار دائن).
/// لم يُدفع شيء أو دُفع جزء: غير متوازنة والفرق هو المتبقي. دُفعت كاملة: متوازنة.
class GlEntriesScreen extends StatefulWidget {
  final String title;
  final Future<CustomerLedger> Function(ErpLedgerRepository ledger) load;

  const GlEntriesScreen({super.key, required this.title, required this.load});

  /// فاتورة مبيعات واحدة
  static Route<void> forInvoice(String invoice) {
    return MaterialPageRoute<void>(
      builder: (_) => GlEntriesScreen(
        title: invoice,
        load: (ledger) => ledger.forInvoice(invoice),
      ),
    );
  }

  /// كل فواتير طلبية (لا قيود على العميل قبل فوترتها)
  static Route<void> forOrder(String orderId) {
    return MaterialPageRoute<void>(
      builder: (_) => GlEntriesScreen(
        title: orderId,
        load: (ledger) => ledger.forOrder(orderId),
      ),
    );
  }

  @override
  State<GlEntriesScreen> createState() => _GlEntriesScreenState();
}

class _GlEntriesScreenState extends State<GlEntriesScreen> {
  late Future<CustomerLedger> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load(context.read<ErpLedgerRepository>());
  }

  void _retry() => setState(() {
        _future = widget.load(context.read<ErpLedgerRepository>());
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.glEntriesTitle),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.bodySmall,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
      body: FutureBuilder<CustomerLedger>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return LoadingView(message: AppStrings.glEntriesLoading);
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: describeError(
                snapshot.error!,
                fallback: AppStrings.glEntriesLoadFailed,
              ),
              onRetry: _retry,
            );
          }
          final ledger = snapshot.data!;

          // مسودة فقط (أو لا شيء بعد): لا قيود قبل الاعتماد
          if (ledger.lines.isEmpty) {
            return EmptyView(
              icon: Icons.account_balance_outlined,
              title: AppStrings.glEntriesEmptyTitle,
              message: ledger.drafts.isNotEmpty
                  ? AppStrings.glDraftsPending(
                      ledger.drafts.map((d) => d.name).join('، '),
                    )
                  : AppStrings.glEntriesEmptyMessage,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _retry();
              await _future.then((_) {}, onError: (_) {});
            },
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              children: [
                _LedgerTable(ledger: ledger),
                const SizedBox(height: 16),
                _Totals(ledger: ledger),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LedgerTable extends StatelessWidget {
  final CustomerLedger ledger;

  const _LedgerTable({required this.ledger});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.onSurfaceVariant,
    );
    final symbol = formatAmount(0, currency: displayCurrency(ledger.currency))
        .split(' ')
        .last;
    const pad = EdgeInsets.symmetric(vertical: 10, horizontal: 8);

    Widget amount(double v) => Text(
          v == 0 ? '—' : _num(v),
          textAlign: TextAlign.end,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: v == 0 ? scheme.onSurfaceVariant : null,
            fontWeight: v == 0 ? null : FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1.2),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(AppStrings.glDescription, style: headerStyle),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  '${AppStrings.glDebit} ($symbol)',
                  style: headerStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  '${AppStrings.glCredit} ($symbol)',
                  style: headerStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          for (final l in ledger.lines)
            TableRow(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              children: [
                Padding(
                  padding: pad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.voucherTypeLabel(l.voucherType),
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${l.voucherNo}  ${l.postingDate}',
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(padding: pad, child: amount(l.debit)),
                Padding(padding: pad, child: amount(l.credit)),
              ],
            ),
        ],
      ),
    );
  }
}

/// مجموع المدين والدائن والتحقق من التوازن: متوازنة = الفاتورة مسددة بالكامل.
class _Totals extends StatelessWidget {
  final CustomerLedger ledger;

  const _Totals({required this.ledger});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currency = displayCurrency(ledger.currency);
    final balanced = ledger.isBalanced;
    final diff = ledger.difference;
    final color = balanced ? AppColors.payment : scheme.error;

    Widget line(String label, double value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
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
                formatAmount(value, currency: currency),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );

    final message = balanced
        ? AppStrings.glBalanced
        : diff > 0
            ? AppStrings.glUnbalanced(formatAmount(diff, currency: currency))
            : AppStrings.glOverpaid(formatAmount(-diff, currency: currency));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(AppStrings.glTotalDebit, ledger.totalDebit),
          line(AppStrings.glTotalCredit, ledger.totalCredit),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                balanced
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
