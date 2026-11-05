import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/statement_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/erp_customer.dart';
import '../../../data/repositories/erp_statement_repository.dart';
import 'customer_statement_screen.dart';

/// «كشف حساب العملاء»: كل أسماء العملاء مع البحث، والضغط على عميل يفتح كشف حسابه.
class CustomerStatementListScreen extends StatefulWidget {
  const CustomerStatementListScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
        builder: (_) => const CustomerStatementListScreen(),
      );

  @override
  State<CustomerStatementListScreen> createState() =>
      _CustomerStatementListScreenState();
}

class _CustomerStatementListScreenState
    extends State<CustomerStatementListScreen> {
  final _search = TextEditingController();
  late Future<List<ErpCustomer>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ErpStatementRepository>().fetchCustomers();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ErpCustomer> _filter(List<ErpCustomer> all) {
    final q = normalizeDigits(_query.trim()).toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final c in all)
        if (c.name.toLowerCase().contains(q) ||
            c.id.toLowerCase().contains(q) ||
            c.phone.contains(q))
          c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(StatementStrings.section)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: StatementStrings.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
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
          ),
          Expanded(
            child: FutureBuilder<List<ErpCustomer>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return LoadingView(
                    message: StatementStrings.loadingCustomers,
                  );
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
                final list = _filter(snapshot.data ?? const []);
                if (list.isEmpty) {
                  return EmptyView(
                    icon: _query.isEmpty
                        ? Icons.people_outline
                        : Icons.search_off,
                    title: StatementStrings.noCustomers,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_load);
                    await _future.then((_) {}, onError: (_) {});
                  },
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
                        onTap: () => Navigator.of(context).push(
                          CustomerStatementScreen.route(c),
                        ),
                      );
                    },
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
