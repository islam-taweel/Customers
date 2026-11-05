String _s(Object? v) => v?.toString() ?? '';
double _n(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

/// حالة يوم الحضور في ERPNext (Attendance.status)
enum AttendanceStatus {
  present,
  absent,
  halfDay,
  onLeave,

  /// العمل من المنزل يُحسب حضورًا في الملخص
  workFromHome;

  static AttendanceStatus parse(String raw) => switch (raw) {
        'Absent' => absent,
        'Half Day' => halfDay,
        'On Leave' => onLeave,
        'Work From Home' => workFromHome,
        _ => present,
      };
}

/// سجل حضور يوم واحد (Attendance معتمد). اليوم الذي لا سجل له لم يُعالَج
/// حضوره بعد، ولا يُعرض غيابًا.
class AttendanceRecord {
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? inTime;
  final DateTime? outTime;
  final double workingHours;
  final bool lateEntry;
  final bool earlyExit;
  final String leaveType;

  /// دقائق التأخير / الخروج المبكر محسوبة من وقتي الوردية (null إن تعذّر)
  final int? lateMinutes;
  final int? earlyMinutes;

  const AttendanceRecord({
    required this.date,
    required this.status,
    required this.inTime,
    required this.outTime,
    required this.workingHours,
    required this.lateEntry,
    required this.earlyExit,
    required this.leaveType,
    this.lateMinutes,
    this.earlyMinutes,
  });

  static const fields = [
    'attendance_date',
    'status',
    'working_hours',
    'late_entry',
    'early_exit',
    'leave_type',
    'in_time',
    'out_time',
  ];

  /// [shiftStart]/[shiftEnd]: «H:MM:SS» من وردية الموظف لحساب مدة التأخير والخروج المبكر.
  factory AttendanceRecord.fromJson(
    Map<String, dynamic> json, {
    String? shiftStart,
    String? shiftEnd,
  }) {
    final date = DateTime.tryParse(_s(json['attendance_date'])) ?? DateTime(0);
    final inTime = DateTime.tryParse(_s(json['in_time']));
    final outTime = DateTime.tryParse(_s(json['out_time']));
    final late = '${json['late_entry']}' == '1';
    final early = '${json['early_exit']}' == '1';

    int? diff(DateTime? a, DateTime? b) {
      if (a == null || b == null) return null;
      final m = a.difference(b).inMinutes;
      return m > 0 ? m : null;
    }

    final start = _at(date, shiftStart);
    final end = _at(date, shiftEnd);
    // وردية ليلية: نهايتها في اليوم التالي
    final realEnd = (start != null && end != null && !end.isAfter(start))
        ? end.add(const Duration(days: 1))
        : end;

    return AttendanceRecord(
      date: DateTime(date.year, date.month, date.day),
      status: AttendanceStatus.parse(_s(json['status'])),
      inTime: inTime,
      outTime: outTime,
      workingHours: _n(json['working_hours']),
      lateEntry: late,
      earlyExit: early,
      leaveType: _s(json['leave_type']),
      lateMinutes: late ? diff(inTime, start) : null,
      earlyMinutes: early ? diff(realEnd, outTime) : null,
    );
  }

  static DateTime? _at(DateTime day, String? hhmmss) {
    if (hhmmss == null || hhmmss.isEmpty) return null;
    final p = hhmmss.split(':');
    final h = int.tryParse(p.first);
    final m = p.length > 1 ? int.tryParse(p[1]) : 0;
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }
}

/// ملخص الشهر
class AttendanceSummary {
  /// نصف اليوم يُحسب نصف يوم حضور
  final double presentDays;
  final int absentDays;
  final int lateDays;
  final double workingHours;

  const AttendanceSummary({
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.workingHours,
  });

  factory AttendanceSummary.of(List<AttendanceRecord> records) {
    var present = 0.0;
    var absent = 0;
    var late = 0;
    var hours = 0.0;
    for (final r in records) {
      switch (r.status) {
        case AttendanceStatus.present:
        case AttendanceStatus.workFromHome:
          present += 1;
        case AttendanceStatus.halfDay:
          present += 0.5;
        case AttendanceStatus.absent:
          absent += 1;
        case AttendanceStatus.onLeave:
          break;
      }
      if (r.lateEntry) late += 1;
      hours += r.workingHours;
    }
    return AttendanceSummary(
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      workingHours: hours,
    );
  }
}

/// طلب حضور (Attendance Request) لمن نسي البصمة. لا حقل حالة: docstatus
/// 0 = قيد المراجعة (مسودة)، 1 = موافق عليه، 2 = مرفوض.
class AttendanceRequestRecord {
  final String name;
  final DateTime fromDate;
  final DateTime toDate;

  /// On Duty أو Work From Home
  final String reason;
  final String explanation;
  final int docstatus;

  const AttendanceRequestRecord({
    required this.name,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.explanation,
    required this.docstatus,
  });

  static const fields = [
    'name',
    'from_date',
    'to_date',
    'reason',
    'explanation',
    'docstatus',
  ];

  factory AttendanceRequestRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRequestRecord(
        name: _s(json['name']),
        fromDate: DateTime.tryParse(_s(json['from_date'])) ?? DateTime(0),
        toDate: DateTime.tryParse(_s(json['to_date'])) ?? DateTime(0),
        reason: _s(json['reason']),
        explanation: _s(json['explanation']),
        docstatus: _n(json['docstatus']).toInt(),
      );
}

/// مبلغ عمل إضافي (Additional Salary بمكوّن Overtime معتمد). يحفظ المبلغ فقط
/// لا الساعات.
class OvertimePayment {
  final String name;
  final DateTime payrollDate;
  final double amount;

  const OvertimePayment({
    required this.name,
    required this.payrollDate,
    required this.amount,
  });

  static const fields = ['name', 'amount', 'payroll_date'];

  factory OvertimePayment.fromJson(Map<String, dynamic> json) {
    final d = DateTime.tryParse(_s(json['payroll_date'])) ?? DateTime(0);
    return OvertimePayment(
      name: _s(json['name']),
      payrollDate: DateTime(d.year, d.month, d.day),
      amount: _n(json['amount']),
    );
  }
}
