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

  Operation({
    this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    this.note,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'amount': amount,
      'type': type.value,
      'note': note,
      'date': date.toIso8601String(),
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
    );
  }

  Operation copyWith({
    int? id,
    int? customerId,
    double? amount,
    OperationType? type,
    String? note,
    DateTime? date,
  }) {
    return Operation(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  @override
  String toString() =>
      'Operation(id: $id, customerId: $customerId, amount: $amount, type: ${type.value}, date: $date)';
}