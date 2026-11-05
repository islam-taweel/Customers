String _s(Object? v) => v?.toString() ?? '';
double _n(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

/// رصيد نوع إجازة من get_leave_details (leave_allocation)
class LeaveBalance {
  final String leaveType;
  final double total;
  final double taken;
  final double pending;
  final double remaining;

  /// إجازة بدون راتب: لا رصيد مخصص لها
  final bool withoutPay;

  const LeaveBalance({
    required this.leaveType,
    required this.total,
    required this.taken,
    required this.pending,
    required this.remaining,
    this.withoutPay = false,
  });

  factory LeaveBalance.fromJson(String type, Map<String, dynamic> json) =>
      LeaveBalance(
        leaveType: type,
        total: _n(json['total_leaves']),
        taken: _n(json['leaves_taken']),
        pending: _n(json['leaves_pending_approval']),
        remaining: _n(json['remaining_leaves']),
      );
}

/// أرصدة الموظف وأنواع الإجازة المتاحة له
class LeaveDetails {
  final List<LeaveBalance> balances;

  /// أنواع الإجازة بدون راتب (lwps)
  final List<String> withoutPayTypes;

  const LeaveDetails({required this.balances, required this.withoutPayTypes});

  /// كل الأنواع التي يمكن الطلب منها: المخصصة ثم بدون راتب
  List<String> get types => [
        for (final b in balances) b.leaveType,
        for (final t in withoutPayTypes)
          if (!balances.any((b) => b.leaveType == t)) t,
      ];

  bool isWithoutPay(String type) => withoutPayTypes.contains(type);

  LeaveBalance? balanceOf(String type) {
    for (final b in balances) {
      if (b.leaveType == type) return b;
    }
    return null;
  }

  factory LeaveDetails.fromJson(Map<String, dynamic> json) {
    final lwps = [
      if (json['lwps'] is List)
        for (final t in json['lwps'] as List) _s(t),
    ];
    final alloc = json['leave_allocation'];
    final balances = <LeaveBalance>[
      if (alloc is Map)
        for (final e in alloc.entries)
          if (e.value is Map)
            LeaveBalance.fromJson(
              _s(e.key),
              Map<String, dynamic>.from(e.value as Map),
            ),
    ];
    return LeaveDetails(balances: balances, withoutPayTypes: lwps);
  }
}

/// Open = قيد المراجعة
enum LeaveRequestStatus { pending, approved, rejected, cancelled }

/// طلب إجازة (Leave Application)
class LeaveRequest {
  final String name;
  final String leaveType;
  final DateTime from;
  final DateTime to;
  final double days;
  final DateTime? postedOn;
  final String reason;
  final LeaveRequestStatus status;

  const LeaveRequest({
    required this.name,
    required this.leaveType,
    required this.from,
    required this.to,
    required this.days,
    required this.postedOn,
    required this.reason,
    required this.status,
  });

  static const fields = [
    'name',
    'leave_type',
    'from_date',
    'to_date',
    'total_leave_days',
    'posting_date',
    'description',
    'status',
  ];

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
        name: _s(json['name']),
        leaveType: _s(json['leave_type']),
        from: DateTime.tryParse(_s(json['from_date'])) ?? DateTime(0),
        to: DateTime.tryParse(_s(json['to_date'])) ?? DateTime(0),
        days: _n(json['total_leave_days']),
        postedOn: DateTime.tryParse(_s(json['posting_date'])),
        reason: _s(json['description']),
        status: switch (_s(json['status'])) {
          'Approved' => LeaveRequestStatus.approved,
          'Rejected' => LeaveRequestStatus.rejected,
          'Cancelled' => LeaveRequestStatus.cancelled,
          _ => LeaveRequestStatus.pending,
        },
      );
}
