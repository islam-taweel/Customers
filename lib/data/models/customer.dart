/// قيمة داخلية للتمييز بين «لم تُمرَّر» و«null» في copyWith
const Object _unset = Object();

class Customer {
  final int? id;
  final String name;
  final String phone;

  /// عملة حساب العميل (ILS, USD…): الدفعات بأي عملة أخرى تُحوَّل إليها بسعر
  /// صرف ERPNext. null = غير محددة، فتُؤخذ عملة حسابه في ERPNext أو عملة الشركة.
  final String? accountCurrency;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    this.accountCurrency,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'accountCurrency': accountCurrency,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    final currency = map['accountCurrency'] as String?;
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      accountCurrency: (currency == null || currency.isEmpty) ? null : currency,
    );
  }

  /// [accountCurrency] يقبل null صراحةً (= إلغاء التحديد)، وعدم تمريره يُبقي القيمة.
  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    Object? accountCurrency = _unset,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      accountCurrency: identical(accountCurrency, _unset)
          ? this.accountCurrency
          : accountCurrency as String?,
    );
  }

  @override
  String toString() =>
      'Customer(id: $id, name: $name, phone: $phone, accountCurrency: $accountCurrency)';
}
