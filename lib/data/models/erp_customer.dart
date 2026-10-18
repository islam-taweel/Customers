/// عميل كما يأتي من ERPNext: رقمه في ERPNext، واسمه، وهاتفه (فارغ إن لم يُسجَّل له هاتف).
class ErpCustomer {
  final String id;
  final String name;
  final String phone;

  const ErpCustomer({
    required this.id,
    required this.name,
    required this.phone,
  });

  @override
  String toString() => 'ErpCustomer(id: $id, name: $name, phone: $phone)';
}
