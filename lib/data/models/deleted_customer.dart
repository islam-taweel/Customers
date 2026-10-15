import 'customer.dart';
import 'operation.dart';

/// نسخة من عميل محذوف وكل عملياته (بنفس الـ id)، تُحفظ مؤقتًا في الذاكرة
/// لإتاحة التراجع عن الحذف واستعادة كل شيء كما كان.
class DeletedCustomer {
  final Customer customer;
  final List<Operation> operations;

  const DeletedCustomer({required this.customer, required this.operations});
}