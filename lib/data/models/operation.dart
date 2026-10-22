/// نوع العملية: دين (على العميل) أو دفعة (من العميل)
enum OperationType {
  debt,
  payment;

  /// القيمة التي تُخزَّن في قاعدة البيانات
  String get value => name;

  static OperationType fromString(String value) {
    return OperationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('نوع عملية غير معروف: $value'),
    );
  }
}

class Operation {
  final int? id;
  final int customerId;
  final double amount;
  final OperationType type;
  final String? note;
  final DateTime date;

  /// رمز العملة (USD, ILS...) كما في ERPNext. null للعمليات القديمة قبل إضافة العملات.
  final String? currency;

  /// طريقة الدفع (Mode of Payment) للدفعات فقط.
  final String? modeOfPayment;

  /// رقم مستند Payment Entry في ERPNext إن سُجّلت الدفعة هناك.
  final String? paymentEntry;

  /// دفعة بعملة تختلف عن عملة حساب العميل: مبلغها بعد التحويل (بسعر صرف ERPNext)
  /// وعملته. هذا ما يُخصم من رصيد العميل، أما [amount] فهو ما دفعه فعلًا.
  /// null = لا تحويل (نفس عملة الحساب، أو عملية قديمة).
  final double? settledAmount;
  final String? settledCurrency;

  bool get isConverted =>
      settledAmount != null && (settledCurrency ?? '').isNotEmpty;

  /// سعر الصرف المستخدم (عملة الحساب لكل وحدة من عملة الدفعة)
  double? get exchangeRate =>
      isConverted && amount > 0 ? settledAmount! / amount : null;

  Operation({
    this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    this.note,
    DateTime? date,
    this.currency,
    this.modeOfPayment,
    this.paymentEntry,
    this.settledAmount,
    this.settledCurrency,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'amount': amount,
      'type': type.value,
      'note': note,
      'date': date.toIso8601String(),
      'currency': currency,
      'modeOfPayment': modeOfPayment,
      'paymentEntry': paymentEntry,
      'settledAmount': settledAmount,
      'settledCurrency': settledCurrency,
    };
  }

  factory Operation.fromMap(Map<String, dynamic> map) {
    return Operation(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      amount: (map['amount'] as num).toDouble(),
      type: OperationType.fromString(map['type'] as String),
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      currency: map['currency'] as String?,
      modeOfPayment: map['modeOfPayment'] as String?,
      paymentEntry: map['paymentEntry'] as String?,
      settledAmount: (map['settledAmount'] as num?)?.toDouble(),
      settledCurrency: map['settledCurrency'] as String?,
    );
  }

  Operation copyWith({
    int? id,
    int? customerId,
    double? amount,
    OperationType? type,
    String? note,
    DateTime? date,
    String? currency,
    String? modeOfPayment,
    String? paymentEntry,
    double? settledAmount,
    String? settledCurrency,
  }) {
    return Operation(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      modeOfPayment: modeOfPayment ?? this.modeOfPayment,
      paymentEntry: paymentEntry ?? this.paymentEntry,
      settledAmount: settledAmount ?? this.settledAmount,
      settledCurrency: settledCurrency ?? this.settledCurrency,
    );
  }

  @override
  String toString() =>
      'Operation(id: $id, customerId: $customerId, amount: $amount, type: ${type.value}, date: $date)';
}