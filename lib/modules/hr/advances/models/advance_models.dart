String _s(Object? v) => v?.toString() ?? '';
double _n(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

/// حالة السلفة كما يعرضها التطبيق (من docstatus و Employee Advance.status)
enum AdvanceStatus {
  /// مسودة: قُدّمت وتنتظر موافقة الموارد البشرية
  pending,

  /// معتمدة ولم تُدفع بعد
  unpaid,
  paid,
  claimed,
  returned,
  partlyClaimedAndReturned,
  cancelled,
}

/// سلفة موظف (Employee Advance)
class EmployeeAdvance {
  /// رقم السلفة (مثل HR-EAD-2026-00001)
  final String name;
  final DateTime? postingDate;
  final String purpose;
  final String currency;

  /// المبلغ الأصلي المطلوب
  final double advanceAmount;

  /// ما دُفع للموظف
  final double paidAmount;

  /// ما استُخدم (سُوّي بمطالبات مصاريف)
  final double claimedAmount;

  /// ما أعاده الموظف
  final double returnAmount;

  /// pending_amount كما يحسبه ERPNext
  final double pendingAmount;
  final AdvanceStatus status;

  const EmployeeAdvance({
    required this.name,
    required this.postingDate,
    required this.purpose,
    required this.currency,
    required this.advanceAmount,
    required this.paidAmount,
    required this.claimedAmount,
    required this.returnAmount,
    required this.pendingAmount,
    required this.status,
  });

  /// المتبقي مع الموظف = المدفوع − المستخدم − المسترجع (لا يقل عن صفر)
  double get remainingAmount {
    final r = paidAmount - claimedAmount - returnAmount;
    return r > 0.005 ? r : 0;
  }

  static const fields = [
    'name',
    'posting_date',
    'purpose',
    'currency',
    'advance_amount',
    'paid_amount',
    'claimed_amount',
    'return_amount',
    'pending_amount',
    'status',
    'docstatus',
  ];

  factory EmployeeAdvance.fromJson(Map<String, dynamic> json) {
    final docstatus = _n(json['docstatus']).toInt();
    final status = docstatus == 0
        ? AdvanceStatus.pending
        : docstatus == 2
        ? AdvanceStatus.cancelled
        : switch (_s(json['status'])) {
            'Paid' => AdvanceStatus.paid,
            'Claimed' => AdvanceStatus.claimed,
            'Returned' => AdvanceStatus.returned,
            'Partly Claimed and Returned' =>
              AdvanceStatus.partlyClaimedAndReturned,
            'Cancelled' => AdvanceStatus.cancelled,
            _ => AdvanceStatus.unpaid,
          };
    return EmployeeAdvance(
      name: _s(json['name']),
      postingDate: DateTime.tryParse(_s(json['posting_date'])),
      purpose: _s(json['purpose']),
      currency: _s(json['currency']),
      advanceAmount: _n(json['advance_amount']),
      paidAmount: _n(json['paid_amount']),
      claimedAmount: _n(json['claimed_amount']),
      returnAmount: _n(json['return_amount']),
      pendingAmount: _n(json['pending_amount']),
      status: status,
    );
  }
}
