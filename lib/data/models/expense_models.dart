String _s(Object? v) => v?.toString() ?? '';
double _n(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

/// نوع المصروف في التطبيق، يقابله Expense Claim Type في ERPNext
enum ExpenseKind {
  transport,
  meals;

  /// يطابق اسم نوع المصروف في ERPNext (الأسماء تختلف بين المواقع)
  bool matches(String erpName) {
    final n = erpName.toLowerCase();
    return switch (this) {
      transport =>
        n.contains('travel') ||
            n.contains('transport') ||
            n.contains('مواصلات'),
      meals => n.contains('food') || n.contains('meal') || n.contains('وجب'),
    };
  }
}

/// حالة طلب المصروف حسب ERPNext:
/// مسودة (docstatus 0)، موافق عليه (approval_status Approved ولم يُعتمد بعد)،
/// مُقدَّم (docstatus 1)، مدفوع (status Paid)، مرفوض، ملغى.
enum ExpenseStatus { draft, approved, submitted, paid, rejected, cancelled }

/// طلب مصروف (Expense Claim) مع نوع وتاريخ أول بند فيه
class ExpenseClaimSummary {
  /// رقم الطلب (مثل HR-EXP-2026-00001)
  final String name;
  final DateTime? postingDate;
  final double amount;
  final String currency;
  final ExpenseStatus status;

  /// من جدول البنود (Expense Claim Detail)؛ فارغ إن تعذّرت قراءته
  final String expenseType;
  final DateTime? expenseDate;
  final String description;

  const ExpenseClaimSummary({
    required this.name,
    required this.postingDate,
    required this.amount,
    required this.currency,
    required this.status,
    this.expenseType = '',
    this.expenseDate,
    this.description = '',
  });

  static const fields = [
    'name',
    'posting_date',
    'total_claimed_amount',
    'total_sanctioned_amount',
    'grand_total',
    'status',
    'approval_status',
    'docstatus',
  ];

  factory ExpenseClaimSummary.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? detail,
  }) {
    final docstatus = _n(json['docstatus']).toInt();
    final approval = _s(json['approval_status']);
    final status = _s(json['status']);
    final ExpenseStatus s;
    if (docstatus == 2 || status == 'Cancelled') {
      s = ExpenseStatus.cancelled;
    } else if (approval == 'Rejected' || status == 'Rejected') {
      s = ExpenseStatus.rejected;
    } else if (status == 'Paid') {
      s = ExpenseStatus.paid;
    } else if (docstatus == 1) {
      s = ExpenseStatus.submitted;
    } else if (approval == 'Approved') {
      s = ExpenseStatus.approved;
    } else {
      s = ExpenseStatus.draft;
    }
    return ExpenseClaimSummary(
      name: _s(json['name']),
      postingDate: DateTime.tryParse(_s(json['posting_date'])),
      amount: _n(json['total_claimed_amount']),
      // Expense Claim لا حقل عملة فيه: عملة الشركة
      currency: 'ILS',
      status: s,
      expenseType: _s(detail?['expense_type']),
      expenseDate: DateTime.tryParse(_s(detail?['expense_date'])),
      description: _s(detail?['description']),
    );
  }
}

/// سلفة مدفوعة فيها مبلغ لم يُستخدم بعد، يمكن ربط المصروف بها
class OpenAdvance {
  final String name;
  final DateTime? postingDate;
  final String purpose;
  final double paidAmount;

  /// غير المستخدم = المدفوع − المستخدم − المسترجع
  final double unclaimedAmount;
  final String advanceAccount;

  const OpenAdvance({
    required this.name,
    required this.postingDate,
    required this.purpose,
    required this.paidAmount,
    required this.unclaimedAmount,
    required this.advanceAccount,
  });

  static const fields = [
    'name',
    'posting_date',
    'purpose',
    'paid_amount',
    'claimed_amount',
    'return_amount',
    'advance_account',
  ];

  factory OpenAdvance.fromJson(Map<String, dynamic> json) {
    final paid = _n(json['paid_amount']);
    final unclaimed =
        paid - _n(json['claimed_amount']) - _n(json['return_amount']);
    return OpenAdvance(
      name: _s(json['name']),
      postingDate: DateTime.tryParse(_s(json['posting_date'])),
      purpose: _s(json['purpose']),
      paidAmount: paid,
      unclaimedAmount: unclaimed > 0 ? unclaimed : 0,
      advanceAccount: _s(json['advance_account']),
    );
  }
}
