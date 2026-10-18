/// فاتورة واحدة محفوظة في قاعدة البيانات.
/// اسم العميل ورقمه نسخة ثابتة (snapshot) لحظة الإنشاء،
/// فلا تتغير الفاتورة إن عُدّل العميل بعد ذلك.
class Invoice {
  final int? id;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final double amount;
  final DateTime createdAt;

  const Invoice({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.createdAt,
  });

  /// رقم الفاتورة مشتق من الـ id المتسلسل، مثال: INV-00012
  String get number => 'INV-${(id ?? 0).toString().padLeft(5, '0')}';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Invoice copyWith({int? id}) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      amount: amount,
      createdAt: createdAt,
    );
  }
}
