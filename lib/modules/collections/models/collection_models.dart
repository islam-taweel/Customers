/// تفاصيل الدفعة غير النقدية. لا يُرسل ولا يُحفظ رقم البطاقة كاملًا ولا تاريخ
/// انتهائها ولا CVV: آخر 4 أرقام فقط (في [extra] باسم custom_card_last4).
class PaymentDetails {
  /// رقم الشيك، أو رمز الموافقة، أو مرجع التحويل
  final String? referenceNo;

  /// تاريخ الشيك أو العملية أو التحويل
  final DateTime? referenceDate;

  /// حقول إضافية بحسب طريقة الدفع (custom_cheque_bank، custom_card_last4...)
  final Map<String, String> extra;

  const PaymentDetails({
    this.referenceNo,
    this.referenceDate,
    this.extra = const {},
  });
}

/// دفعة حُفظت مسودة في ERPNext وتنتظر اعتمادها هناك. الفاتورة لا يتغير مستحقها
/// ولا حالتها إلا بعد الاعتماد، فنتذكرها محليًا لنعرضها على الفاتورة.
class PendingPayment {
  final String invoice;
  final String entry;
  final double amount;
  final String currency;

  const PendingPayment({
    required this.invoice,
    required this.entry,
    required this.amount,
    required this.currency,
  });

  Map<String, dynamic> toJson() => {
    'invoice': invoice,
    'entry': entry,
    'amount': amount,
    'currency': currency,
  };

  factory PendingPayment.fromJson(Map<String, dynamic> json) => PendingPayment(
    invoice: json['invoice']?.toString() ?? '',
    entry: json['entry']?.toString() ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    currency: json['currency']?.toString() ?? '',
  );
}
