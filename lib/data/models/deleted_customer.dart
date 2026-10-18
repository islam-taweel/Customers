import 'customer.dart';
import 'invoice.dart';
import 'operation.dart';

/// نسخة من عميل محذوف وكل عملياته وفواتيره (بنفس الـ id)، تُحفظ مؤقتًا في الذاكرة
/// لإتاحة التراجع عن الحذف واستعادة كل شيء كما كان.
class DeletedCustomer {
  final Customer customer;
  final List<Operation> operations;
  final List<Invoice> invoices;

  const DeletedCustomer({
    required this.customer,
    required this.operations,
    this.invoices = const [],
  });
}
