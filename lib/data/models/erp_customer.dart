/// عميل كما يأتي من ERPNext: رقمه في ERPNext، واسمه، وهاتفه (فارغ إن لم يُسجَّل له هاتف)،
/// وعملة حسابه (default_currency؛ فارغة = عملة الشركة الافتراضية).
class ErpCustomer {
  final String id;
  final String name;
  final String phone;

  /// عملة حساب العميل في ERPNext (ILS, USD…). فارغة = عملة الشركة (ILS).
  final String currency;

  const ErpCustomer({
    required this.id,
    required this.name,
    required this.phone,
    this.currency = '',
  });

  @override
  String toString() =>
      'ErpCustomer(id: $id, name: $name, phone: $phone, currency: $currency)';
}
