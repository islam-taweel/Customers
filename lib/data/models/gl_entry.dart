/// تحويل آمن لقيمة JSON إلى رقم (ERPNext يرسل الأرقام num، وأحيانًا null)
double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _toText(Object? value) => value?.toString() ?? '';

/// سطر في حساب العميل لفاتورة واحدة: الفاتورة نفسها (مدين) أو ما سدّد منها (دائن):
/// دفعة، رصيد سابق خُصص لها، إشعار دائن، قيد يومية.
class CustomerLedgerLine {
  final String postingDate;
  final String voucherType;
  final String voucherNo;

  /// بعملة حساب العميل
  final double debit;
  final double credit;
  final String currency;

  const CustomerLedgerLine({
    required this.postingDate,
    required this.voucherType,
    required this.voucherNo,
    required this.debit,
    required this.credit,
    required this.currency,
  });

  /// من Payment Ledger Entry: المبلغ الموجب على العميل (مدين)، والسالب سداد (دائن)
  factory CustomerLedgerLine.fromPaymentLedger(Map<String, dynamic> json) {
    final amount = _toDouble(json['amount_in_account_currency']);
    return CustomerLedgerLine(
      postingDate: _toText(json['posting_date']),
      voucherType: _toText(json['voucher_type']),
      voucherNo: _toText(json['voucher_no']),
      debit: amount > 0 ? amount : 0,
      credit: amount < 0 ? -amount : 0,
      currency: _toText(json['account_currency']),
    );
  }

  /// من GL Entry (سطر حساب العميل) عند تعذّر دفتر الدفعات
  factory CustomerLedgerLine.fromGl(Map<String, dynamic> json) =>
      CustomerLedgerLine(
        postingDate: _toText(json['posting_date']),
        voucherType: _toText(json['voucher_type']),
        voucherNo: _toText(json['voucher_no']),
        debit: _toDouble(json['debit_in_account_currency']),
        credit: _toDouble(json['credit_in_account_currency']),
        currency: _toText(json['account_currency']),
      );
}

/// حساب العميل لفاتورة (أو لفواتير طلبية): مجموع المدين = قيمة الفواتير، ومجموع
/// الدائن = المسدد منها. متوازنة = مسددة بالكامل؛ وإلا الفرق هو المتبقي على العميل.
class CustomerLedger {
  final List<CustomerLedgerLine> lines;

  /// مستندات مرتبطة ما زالت مسودة: لا قيود لها قبل اعتمادها
  final List<({String doctype, String name})> drafts;

  const CustomerLedger({required this.lines, required this.drafts});

  double get totalDebit => lines.fold(0.0, (s, l) => s + l.debit);
  double get totalCredit => lines.fold(0.0, (s, l) => s + l.credit);

  /// موجب = متبقٍ على العميل، سالب = دفع أكثر (رصيد له)
  double get difference => totalDebit - totalCredit;
  bool get isBalanced => difference.abs() < 0.005;

  /// عملة حساب العميل (كل السطور على حسابه نفسه)
  String get currency => lines.isEmpty ? '' : lines.first.currency;
}
