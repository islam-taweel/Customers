import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/statement_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/repositories/erp_statement_repository.dart';

double _n(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
String _s(Object? v) => v?.toString() ?? '';
List<Map<String, dynamic>> _rows(Object? v) => [
      if (v is List)
        for (final r in v)
          if (r is Map) Map<String, dynamic>.from(r),
    ];

/// تفاصيل مستند من ERPNext كما هو (`GET /api/resource/<doctype>/<name>`):
/// فاتورة مبيعات (أو مرتجع)، دفعة، قيد يومية. تُفتح من كشف الحساب ومن زر
/// «تفاصيل الدفعة»؛ الفاتورة المخصص لها في الدفعة تُفتح بالضغط عليها.
class VoucherDetailsScreen extends StatefulWidget {
  final String doctype;
  final String name;

  const VoucherDetailsScreen({
    super.key,
    required this.doctype,
    required this.name,
  });

  static Route<void> route(String doctype, String name) =>
      MaterialPageRoute<void>(
        builder: (_) => VoucherDetailsScreen(doctype: doctype, name: name),
      );

  @override
  State<VoucherDetailsScreen> createState() => _VoucherDetailsScreenState();
}

class _VoucherDetailsScreenState extends State<VoucherDetailsScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context
        .read<ErpStatementRepository>()
        .fetchVoucher(widget.doctype, widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(StatementStrings.voucherType(widget.doctype)),
            Text(
              widget.name,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return LoadingView(message: StatementStrings.loadingDocument);
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: describeError(
                snapshot.error!,
                fallback: StatementStrings.loadFailed,
              ),
              onRetry: () => setState(_load),
            );
          }
          final doc = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: [
              _Header(doc: doc, doctype: widget.doctype),
              const SizedBox(height: 16),
              ...switch (widget.doctype) {
                'Sales Invoice' => _invoiceBody(context, doc),
                'Payment Entry' => _paymentBody(context, doc),
                'Journal Entry' => _journalBody(context, doc),
                _ => const <Widget>[],
              },
              if (_s(doc['remarks']).trim().isNotEmpty ||
                  _s(doc['user_remark']).trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _Section(
                  title: StatementStrings.remarks,
                  children: [
                    Text(
                      _s(doc['user_remark']).trim().isNotEmpty
                          ? _s(doc['user_remark']).trim()
                          : _s(doc['remarks']).trim(),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ───────── فاتورة مبيعات / مرتجع ─────────
  List<Widget> _invoiceBody(BuildContext context, Map<String, dynamic> doc) {
    final currency = displayCurrency(_s(doc['currency']));
    final rounded = _n(doc['rounded_total']);
    final total = rounded != 0 ? rounded : _n(doc['grand_total']);
    final isReturn = _n(doc['is_return']) == 1;
    return [
      _Section(
        title: StatementStrings.items,
        children: [
          for (final r in _rows(doc['items']))
            _KeyValue(
              label: '${_s(r['item_name'])}  ×${_plain(_n(r['qty']))}',
              value: formatSignedAmount(_n(r['amount']), currency: currency),
            ),
        ],
      ),
      const SizedBox(height: 16),
      _Section(
        children: [
          if (isReturn && _s(doc['return_against']).isNotEmpty)
            _KeyValue(
              label: StatementStrings.returnAgainst,
              value: _s(doc['return_against']),
              onTap: () => _open('Sales Invoice', _s(doc['return_against'])),
            ),
          _KeyValue(
            label: isReturn
                ? StatementStrings.creditNote
                : StatementStrings.invoiceTotal,
            value: formatSignedAmount(total, currency: currency),
            strong: true,
          ),
          if (_n(doc['docstatus']) == 1)
            _KeyValue(
              label: StatementStrings.outstanding,
              value: formatSignedAmount(
                _n(doc['outstanding_amount']),
                currency: currency,
              ),
              strong: true,
            ),
        ],
      ),
    ];
  }

  // ───────── دفعة ─────────
  List<Widget> _paymentBody(BuildContext context, Map<String, dynamic> doc) {
    final receivedCur = _s(doc['paid_to_account_currency']);
    final accountCur = _s(doc['paid_from_account_currency']);
    final refs = _rows(doc['references']);
    final unallocated = _n(doc['unallocated_amount']);
    return [
      _Section(
        children: [
          _KeyValue(
            label: StatementStrings.modeOfPayment,
            value: _s(doc['mode_of_payment']),
          ),
          _KeyValue(
            label: StatementStrings.received,
            value: formatAmount(
              _n(doc['received_amount']),
              currency: displayCurrency(receivedCur),
            ),
            strong: true,
          ),
          if (accountCur.isNotEmpty && accountCur != receivedCur)
            _KeyValue(
              label: StatementStrings.creditedToCustomer,
              value: formatAmount(
                _n(doc['paid_amount']),
                currency: displayCurrency(accountCur),
              ),
            ),
          _KeyValue(label: StatementStrings.paidTo, value: _s(doc['paid_to'])),
          if (_s(doc['reference_no']).isNotEmpty)
            _KeyValue(
              label: StatementStrings.referenceNo,
              value: _s(doc['reference_no']),
            ),
          if (_s(doc['reference_date']).isNotEmpty)
            _KeyValue(
              label: StatementStrings.referenceDate,
              value: _s(doc['reference_date']),
            ),
        ],
      ),
      const SizedBox(height: 16),
      _Section(
        title: StatementStrings.allocations,
        children: [
          if (refs.isEmpty) Text(StatementStrings.notAllocated),
          for (final r in refs)
            _KeyValue(
              label: _s(r['reference_name']),
              value: formatAmount(
                _n(r['allocated_amount']),
                currency: displayCurrency(accountCur),
              ),
              onTap: () => _open(
                _s(r['reference_doctype']),
                _s(r['reference_name']),
              ),
            ),
          if (unallocated > 0.005)
            _KeyValue(
              label: StatementStrings.unallocated,
              value: formatAmount(
                unallocated,
                currency: displayCurrency(accountCur),
              ),
            ),
        ],
      ),
    ];
  }

  // ───────── قيد يومية ─────────
  List<Widget> _journalBody(BuildContext context, Map<String, dynamic> doc) {
    return [
      _Section(
        title: StatementStrings.accounts,
        children: [
          for (final r in _rows(doc['accounts']))
            _KeyValue(
              label: [
                _s(r['account']),
                if (_s(r['party']).isNotEmpty) _s(r['party']),
              ].join('\n'),
              value: _n(r['debit_in_account_currency']) > 0
                  ? '${StatementStrings.debit} ${formatAmount(_n(r['debit_in_account_currency']), currency: displayCurrency(_s(r['account_currency'])))}'
                  : '${StatementStrings.credit} ${formatAmount(_n(r['credit_in_account_currency']), currency: displayCurrency(_s(r['account_currency'])))}',
            ),
        ],
      ),
    ];
  }

  void _open(String doctype, String name) {
    if (doctype.isEmpty || name.isEmpty) return;
    Navigator.of(context).push(VoucherDetailsScreen.route(doctype, name));
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

/// الرقم والتاريخ والحالة والعميل
class _Header extends StatelessWidget {
  final Map<String, dynamic> doc;
  final String doctype;

  const _Header({required this.doc, required this.doctype});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final docstatus = _n(doc['docstatus']).toInt();
    final (label, color) = switch (docstatus) {
      0 => (StatementStrings.draft, scheme.tertiary),
      2 => (StatementStrings.cancelled, scheme.error),
      _ => (StatementStrings.submitted, scheme.primary),
    };
    final party = _s(doc['customer_name']).isNotEmpty
        ? _s(doc['customer_name'])
        : _s(doc['party_name']).isNotEmpty
            ? _s(doc['party_name'])
            : _s(doc['customer']).isNotEmpty
                ? _s(doc['customer'])
                : _s(doc['party']);
    return _Section(
      children: [
        _KeyValue(label: StatementStrings.number, value: _s(doc['name'])),
        _KeyValue(
          label: StatementStrings.date,
          value: _s(doc['posting_date']),
        ),
        if (party.isNotEmpty)
          _KeyValue(label: StatementStrings.party, value: party),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(StatementStrings.status)),
              Chip(
                label: Text(label, style: TextStyle(color: color)),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _Section({required this.children, this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final VoidCallback? onTap;

  const _KeyValue({
    required this.label,
    required this.value,
    this.strong = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onTap != null ? scheme.primary : scheme.onSurfaceVariant,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
