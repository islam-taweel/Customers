import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/operation.dart';
import '../utils/formatters.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final _db = DatabaseHelper.instance;

  double _balance = 0;
  List<Operation> _operations = [];
  bool _loading = true;

  int get _customerId => widget.customer.id!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _db.getCustomerBalance(_customerId),
      _db.getOperationsByCustomer(_customerId),
    ]);
    if (!mounted) return;
    setState(() {
      _balance = results[0] as double;
      _operations = results[1] as List<Operation>;
      _loading = false;
    });
  }

  Future<void> _addOperation(OperationType type) async {
    final result = await showDialog<_OperationInput>(
      context: context,
      builder: (_) => _OperationDialog(type: type),
    );
    if (result == null) return;

    await _db.insertOperation(
      Operation(
        customerId: _customerId,
        amount: result.amount,
        type: type,
        note: result.note,
        date: DateTime.now(), // وقت الجهاز الحالي تلقائيًا
      ),
    );
    await _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          type == OperationType.debt ? 'تمت إضافة الدين' : 'تمت إضافة الدفعة',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _BalanceCard(customer: widget.customer, balance: _balance),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _addOperation(OperationType.debt),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة دين'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _addOperation(OperationType.payment),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('إضافة دفعة'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'سجل العمليات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _operations.isEmpty
                      ? const Center(child: Text('لا توجد عمليات بعد'))
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _operations.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) =>
                              _OperationTile(operation: _operations[i]),
                        ),
                ),
              ],
            ),
    );
  }
}

// ───────────────────────── بطاقة الرصيد ─────────────────────────

class _BalanceCard extends StatelessWidget {
  final Customer customer;
  final double balance;
  const _BalanceCard({required this.customer, required this.balance});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (balance > 0) {
      color = Colors.red.shade700;
      label = 'الرصيد المستحق على العميل';
    } else if (balance < 0) {
      color = Colors.green.shade700;
      label = 'للعميل رصيد عندك';
    } else {
      color = Colors.grey.shade700;
      label = 'الحساب مسدد';
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                formatAmount(balance.abs()),
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customer.phone,
                style: Theme.of(context).textTheme.bodyMedium,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── عنصر العملية ─────────────────────────

class _OperationTile extends StatelessWidget {
  final Operation operation;
  const _OperationTile({required this.operation});

  @override
  Widget build(BuildContext context) {
    final isDebt = operation.type == OperationType.debt;
    final color = isDebt ? Colors.red.shade700 : Colors.green.shade700;
    final hasNote = operation.note != null && operation.note!.trim().isNotEmpty;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(
          isDebt ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
        ),
      ),
      title: Text(
        isDebt ? 'دين' : 'دفعة',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasNote) Text(operation.note!.trim()),
          Text(
            formatDateTime(operation.date),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      isThreeLine: hasNote,
      trailing: Text(
        '${isDebt ? '+' : '-'} ${formatAmount(operation.amount)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

// ───────────────────────── نافذة إضافة دين / دفعة ─────────────────────────

class _OperationInput {
  final double amount;
  final String? note;
  const _OperationInput(this.amount, this.note);
}

class _OperationDialog extends StatefulWidget {
  final OperationType type;
  const _OperationDialog({required this.type});

  @override
  State<_OperationDialog> createState() => _OperationDialogState();
}

class _OperationDialogState extends State<_OperationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final note = _noteController.text.trim();
    Navigator.pop(
      context,
      _OperationInput(
        parseAmount(_amountController.text)!,
        note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDebt = widget.type == OperationType.debt;

    return AlertDialog(
      title: Text(isDebt ? 'إضافة دين' : 'إضافة دفعة'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                suffixText: '₪',
              ),
              validator: (v) {
                final value = parseAmount(v ?? '');
                if (value == null) return 'الرجاء إدخال مبلغ صحيح';
                if (value <= 0) return 'يجب أن يكون المبلغ أكبر من صفر';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor:
                isDebt ? Colors.red.shade700 : Colors.green.shade700,
          ),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}