String _s(Object? v) => v?.toString() ?? '';
double _n(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
DateTime? _d(Object? v) => DateTime.tryParse(_s(v));

/// كشف راتب معتمد (Salary Slip، docstatus 1) في القائمة
class PayslipSummary {
  final String name;
  final DateTime? postingDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final double grossPay;
  final double totalDeduction;
  final double netPay;
  final String currency;

  const PayslipSummary({
    required this.name,
    required this.postingDate,
    required this.startDate,
    required this.endDate,
    required this.grossPay,
    required this.totalDeduction,
    required this.netPay,
    required this.currency,
  });

  static const fields = [
    'name',
    'posting_date',
    'start_date',
    'end_date',
    'gross_pay',
    'total_deduction',
    'net_pay',
    'currency',
  ];

  factory PayslipSummary.fromJson(Map<String, dynamic> json) => PayslipSummary(
    name: _s(json['name']),
    postingDate: _d(json['posting_date']),
    startDate: _d(json['start_date']),
    endDate: _d(json['end_date']),
    grossPay: _n(json['gross_pay']),
    totalDeduction: _n(json['total_deduction']),
    netPay: _n(json['net_pay']),
    currency: _s(json['currency']),
  );
}

/// بند مستحق أو خصم (Salary Detail)
class SalaryLine {
  final String component;
  final String abbr;
  final double amount;

  const SalaryLine({
    required this.component,
    required this.abbr,
    required this.amount,
  });

  factory SalaryLine.fromJson(Map<String, dynamic> json) => SalaryLine(
    component: _s(json['salary_component']),
    abbr: _s(json['abbr']),
    amount: _n(json['amount']),
  );
}

/// كشف الراتب كاملًا: المستحقات والخصومات والملخص
class PayslipDetail {
  final String name;
  final String employee;
  final DateTime? postingDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String currency;
  final List<SalaryLine> earnings;
  final List<SalaryLine> deductions;
  final double grossPay;
  final double totalDeduction;
  final double netPay;
  final double paymentDays;
  final double workingDays;

  /// أيام الإجازة بدون راتب والغياب في الفترة (تُنقص أيام الدفع)
  final double leaveWithoutPay;
  final double absentDays;

  const PayslipDetail({
    required this.name,
    required this.employee,
    required this.postingDate,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.earnings,
    required this.deductions,
    required this.grossPay,
    required this.totalDeduction,
    required this.netPay,
    required this.paymentDays,
    required this.workingDays,
    required this.leaveWithoutPay,
    required this.absentDays,
  });

  factory PayslipDetail.fromJson(Map<String, dynamic> json) {
    List<SalaryLine> lines(Object? v) => [
      if (v is List)
        for (final r in v)
          if (r is Map) SalaryLine.fromJson(Map<String, dynamic>.from(r)),
    ];
    return PayslipDetail(
      name: _s(json['name']),
      employee: _s(json['employee']),
      postingDate: _d(json['posting_date']),
      startDate: _d(json['start_date']),
      endDate: _d(json['end_date']),
      currency: _s(json['currency']),
      earnings: lines(json['earnings']),
      deductions: lines(json['deductions']),
      grossPay: _n(json['gross_pay']),
      totalDeduction: _n(json['total_deduction']),
      netPay: _n(json['net_pay']),
      paymentDays: _n(json['payment_days']),
      workingDays: _n(json['total_working_days']),
      leaveWithoutPay: _n(json['leave_without_pay']),
      absentDays: _n(json['absent_days']),
    );
  }
}
