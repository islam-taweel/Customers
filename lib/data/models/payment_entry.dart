/// تحويل آمن لقيمة JSON إلى رقم (ERPNext يرسل الأرقام num، وأحيانًا null)
double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _toText(Object? value) => value?.toString() ?? '';

/// دفعة عميل (Payment Entry من نوع Receive) كما تظهر في تبويبي «مسودة» و«معتمدة».
class PaymentEntrySummary {
  final String name;
  final String postingDate;

  /// 0 = مسودة، 1 = معتمدة
  final int docstatus;

  /// المبلغ المستلم بعملة الدفعة (حساب القبض)
  final double receivedAmount;
  final String receivedCurrency;

  /// ما يقابله بعملة حساب العميل (يُخصم من دينه)
  final double paidAmount;
  final String accountCurrency;

  final String modeOfPayment;
  final String remarks;

  const PaymentEntrySummary({
    required this.name,
    required this.postingDate,
    required this.docstatus,
    required this.receivedAmount,
    required this.receivedCurrency,
    required this.paidAmount,
    required this.accountCurrency,
    required this.modeOfPayment,
    required this.remarks,
  });

  bool get isDraft => docstatus == 0;

  static const fields = [
    'name',
    'posting_date',
    'docstatus',
    'received_amount',
    'paid_to_account_currency',
    'paid_amount',
    'paid_from_account_currency',
    'mode_of_payment',
    'remarks',
  ];

  factory PaymentEntrySummary.fromJson(Map<String, dynamic> json) =>
      PaymentEntrySummary(
        name: _toText(json['name']),
        postingDate: _toText(json['posting_date']),
        docstatus: (json['docstatus'] as num?)?.toInt() ?? 0,
        receivedAmount: _toDouble(json['received_amount']),
        receivedCurrency: _toText(json['paid_to_account_currency']),
        paidAmount: _toDouble(json['paid_amount']),
        accountCurrency: _toText(json['paid_from_account_currency']),
        modeOfPayment: _toText(json['mode_of_payment']),
        remarks: _toText(json['remarks']),
      );
}
