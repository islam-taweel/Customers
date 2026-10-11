import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/customer_with_balance.dart';
import '../utils/formatters.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _db = DatabaseHelper.instance;
  final _searchController = TextEditingController();

  List<CustomerWithBalance> _all = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final data = await _db.getCustomersWithBalances();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  /// إجمالي الديون المستحقة (مجموع الأرصدة الموجبة لكل العملاء)
  double get _totalDebts => _all
      .where((c) => c.balance > 0)
      .fold(0.0, (sum, c) => sum + c.balance);

  List<CustomerWithBalance> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((c) => c.customer.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _showAddCustomerDialog() async {
    final customer = await showDialog<Customer>(
      context: context,
      builder: (_) => const _AddCustomerDialog(),
    );
    if (customer == null) return;

    await _db.insertCustomer(customer);
    await _loadCustomers(); // تحديث فوري للقائمة والإجمالي
  }

  Future<void> _openDetails(Customer customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailsScreen(customer: customer),
      ),
    );
    // عند العودة: تحديث الأرصدة والإجمالي بعد أي عملية جديدة
    await _loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('العملاء')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        tooltip: 'إضافة عميل',
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          _TotalDebtsCard(total: _totalDebts),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'ابحث باسم العميل...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : customers.isEmpty
                    ? Center(
                        child: Text(
                          _all.isEmpty
                              ? 'لا يوجد عملاء بعد.\nاضغط + لإضافة عميل.'
                              : 'لا توجد نتائج مطابقة',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: customers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _CustomerTile(
                          item: customers[i],
                          onTap: () => _openDetails(customers[i].customer),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── بطاقة الإجمالي ─────────────────────────

class _TotalDebtsCard extends StatelessWidget {
  final double total;
  const _TotalDebtsCard({required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(16),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: scheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'إجمالي الديون',
                style: TextStyle(
                  fontSize: 16,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            Text(
              formatAmount(total),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── عنصر العميل ─────────────────────────

class _CustomerTile extends StatelessWidget {
  final CustomerWithBalance item;
  final VoidCallback onTap;
  const _CustomerTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final balance = item.balance;
    final Color color;
    final String label;

    if (balance > 0) {
      color = Colors.red.shade700;
      label = 'مستحق';
    } else if (balance < 0) {
      color = Colors.green.shade700;
      label = 'له رصيد';
    } else {
      color = Colors.grey;
      label = 'مسدد';
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(
          item.customer.name.isNotEmpty ? item.customer.name[0] : '؟',
        ),
      ),
      title: Text(item.customer.name),
      subtitle: Text(item.customer.phone),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatAmount(balance.abs()),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

// ───────────────────────── نافذة إضافة عميل ─────────────────────────

class _AddCustomerDialog extends StatefulWidget {
  const _AddCustomerDialog();

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Customer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة عميل جديد'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'الاسم'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الرجاء إدخال الاسم' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'الرجاء إدخال رقم الهاتف'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}