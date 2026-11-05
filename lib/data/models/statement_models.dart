/// تحويل آمن لقيمة JSON إلى رقم (ERPNext يرسل الأرقام num، وأحيانًا null)
double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _toText(Object? value) => value?.toString() ?? '';

/// حركة في كشف حساب العميل (سطر GL Entry على حسابه) مع الرصيد الجاري بعدها.
/// المبالغ بعملة الشركة (الشيكل).
class StatementLine {
  final String postingDate;

  /// Sales Invoice (والمرتجع أيضًا، ويظهر دائنًا) أو Payment Entry أو Journal Entry
  final String voucherType;
  final String voucherNo;
  final double debit;
  final double credit;
  final String remarks;

  /// الرصيد بعد هذه الحركة: موجب = مستحق على العميل
  final double balance;

  const StatementLine({
    required this.postingDate,
    required this.voucherType,
    required this.voucherNo,
    required this.debit,
    required this.credit,
    required this.remarks,
    required this.balance,
  });

  static const fields = [
    'posting_date',
    'voucher_type',
    'voucher_no',
    'debit',
    'credit',
    'remarks',
  ];

  factory StatementLine.fromJson(Map<String, dynamic> json, double balance) =>
      StatementLine(
        postingDate: _toText(json['posting_date']),
        voucherType: _toText(json['voucher_type']),
        voucherNo: _toText(json['voucher_no']),
        debit: _toDouble(json['debit']),
        credit: _toDouble(json['credit']),
        remarks: _toText(json['remarks']),
        balance: balance,
      );
}

/// كشف حساب عميل لفترة (أو لكل الفترات): الرصيد الافتتاحي ثم الحركات بالترتيب.
class CustomerStatement {
  /// 0 دون فترة محددة، وإلا رصيد العميل في اليوم السابق لبدايتها
  final double opening;
  final List<StatementLine> lines;
  final DateTime? from;
  final DateTime? to;

  const CustomerStatement({
    required this.opening,
    required this.lines,
    this.from,
    this.to,
  });

  double get totalDebit => lines.fold(0.0, (s, l) => s + l.debit);
  double get totalCredit => lines.fold(0.0, (s, l) => s + l.credit);

  /// آخر رصيد جارٍ (أو الافتتاحي إن لم توجد حركات)
  double get closing => lines.isEmpty ? opening : lines.last.balance;
}
