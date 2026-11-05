import 'package:flutter/foundation.dart';

import '../../core/utils/palestine_time.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/attendance_models.dart';
import '../models/employee_models.dart';
import '../models/leave_models.dart';

/// المستخدم الحالي غير مرتبط بسجل موظف نشط في ERPNext (Employee.user_id).
class EmployeeNotLinkedException implements Exception {
  const EmployeeNotLinkedException();
}

/// خدمات الموظف من ERPNext (HRMS) للموظف المرتبط بالمستخدم الحالي: بياناته
/// وورديته، البصمات، الحضور، طلبات الحضور، الإجازات، والعمل الإضافي.
/// كل التواريخ والأوقات بتوقيت فلسطين. التطبيق لا يرسل docstatus ولا يعتمد
/// شيئًا أبدًا: الموافقة من الموارد البشرية في ERPNext.
class ErpEmployeeRepository {
  ErpEmployeeRepository(this._api);

  final ErpApiClient _api;

  static const _leaveModule =
      'hrms.hr.doctype.leave_application.leave_application';

  // ───────────────────────── F1) أنا وورديتي ─────────────────────────

  /// صف Employee النشط للمستخدم الحالي (get_logged_user ← user_id).
  Future<Map<String, dynamic>> _employeeRow(List<String> fields) async {
    final user = (await _api.getMethod('frappe.auth.get_logged_user'))['message']
            ?.toString() ??
        '';
    if (user.isEmpty) throw const EmployeeNotLinkedException();

    final rows = await _api.getList(
      'Employee',
      fields: fields,
      filters: [
        ['user_id', '=', user],
        ['status', '=', 'Active'],
      ],
      limitPageLength: 1,
    );
    if (rows.isEmpty) throw const EmployeeNotLinkedException();
    return rows.first;
  }

  /// رقم الموظف (Employee.name) المستخدم في كل الطلبات
  Future<String> _employeeId() async =>
      (await _employeeRow(['name']))['name'].toString();

  /// الموظف مع ورديته اليوم.
  Future<EmployeeProfile> fetchProfile() async {
    final profile =
        EmployeeProfile.fromJson(await _employeeRow(EmployeeProfile.fields));
    EmployeeShift? shift;
    try {
      shift = await _shift(profile.id, profile.defaultShift);
    } catch (e) {
      // الوردية معلومة إضافية: فشلها لا يمنع عرض بقية البيانات
      debugPrint('ErpEmployeeRepository shift failed: $e');
    }
    return profile.withShift(shift);
  }

  /// وردية اليوم: تعيين الوردية الساري (بلا نهاية أو نهايته اليوم أو بعده)،
  /// وإلا الوردية الافتراضية للموظف. null إن لم توجد وردية.
  Future<EmployeeShift?> _shift(String employee, String defaultShift) async {
    final today = PalestineTime.date(PalestineTime.today());
    final rows = await _api.getList(
      'Shift Assignment',
      fields: ['shift_type', 'start_date', 'end_date'],
      filters: [
        ['employee', '=', employee],
        ['docstatus', '=', 1],
        ['status', '=', 'Active'],
        ['start_date', '<=', today],
      ],
      orFilters: [
        ['end_date', '>=', today],
        ['end_date', 'is', 'not set'],
      ],
      orderBy: 'start_date desc',
      limitPageLength: 1,
    );
    final name = rows.isNotEmpty
        ? rows.first['shift_type']?.toString() ?? ''
        : defaultShift;
    if (name.isEmpty) return null;
    return EmployeeShift.fromJson(await _api.getDoc('Shift Type', name));
  }

  /// صورة الموظف (قد تكون ملفًا خاصًا فتحتاج كوكي الجلسة).
  Future<Uint8List> fetchImage(String path) => _api.downloadFile(path);

  // ───────────────────────── F2) البصمة ─────────────────────────

  /// بصمات اليوم بالترتيب (الأقدم أولًا).
  Future<List<EmployeeCheckin>> fetchTodayPunches() async {
    final employee = await _employeeId();
    final today = PalestineTime.today();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final rows = await _api.getAll(
      'Employee Checkin',
      fields: EmployeeCheckin.fields,
      filters: [
        ['employee', '=', employee],
        ['time', '>=', '${PalestineTime.date(today)} 00:00:00'],
        ['time', '<', '${PalestineTime.date(tomorrow)} 00:00:00'],
      ],
      orderBy: 'time asc',
    );
    return [for (final r in rows) EmployeeCheckin.fromJson(r)];
  }

  /// يسجّل بصمة الآن بتوقيت فلسطين. لا موقع: التطبيق لا يطلب إذن الموقع.
  Future<EmployeeCheckin> punch({required bool isIn}) async {
    final employee = await _employeeId();
    final now = PalestineTime.now();
    final created = await _api.postDoc('Employee Checkin', {
      'employee': employee,
      'log_type': isIn ? 'IN' : 'OUT',
      'time': PalestineTime.format(now),
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Employee Checkin $name (${isIn ? 'IN' : 'OUT'})');
    return EmployeeCheckin(name: name, isIn: isIn, time: now);
  }

  // ───────────────────────── F3) حضوري ─────────────────────────

  /// سجلات الحضور المعتمدة لشهر [month] من [year]، بالترتيب. مدة التأخير والخروج
  /// المبكر تُحسب من وقتي وردية الموظف الحالية.
  Future<List<AttendanceRecord>> fetchAttendance(int year, int month) async {
    final emp = await _employeeRow(['name', 'default_shift']);
    final employee = emp['name'].toString();
    final rows = await _api.getAll(
      'Attendance',
      fields: AttendanceRecord.fields,
      filters: [
        ['employee', '=', employee],
        ['docstatus', '=', 1],
        ['attendance_date', '>=', PalestineTime.date(DateTime(year, month))],
        [
          'attendance_date',
          '<=',
          PalestineTime.date(DateTime(year, month + 1, 0)),
        ],
      ],
      orderBy: 'attendance_date asc',
    );

    EmployeeShift? shift;
    if (rows.isNotEmpty) {
      try {
        shift = await _shift(employee, emp['default_shift']?.toString() ?? '');
      } catch (e) {
        // بلا أوقات الوردية: تظهر علامة التأخير دون مدته
        debugPrint('ErpEmployeeRepository attendance shift failed: $e');
      }
    }
    return [
      for (final r in rows)
        AttendanceRecord.fromJson(
          r,
          shiftStart: shift?.startTime,
          shiftEnd: shift?.endTime,
        ),
    ];
  }

  // ───────────────────────── F4) نسيت البصمة ─────────────────────────

  /// يحفظ طلب حضور ليوم [date] (مسودة = قيد المراجعة).
  /// [reason]: On Duty أو Work From Home فقط.
  Future<String> submitAttendanceRequest({
    required DateTime date,
    required String reason,
    required String explanation,
  }) async {
    final emp = await _employeeRow(['name', 'company']);
    final day = PalestineTime.date(date);
    final created = await _api.postDoc('Attendance Request', {
      'employee': emp['name'],
      'company': _companyOf(emp),
      'from_date': day,
      'to_date': day,
      'reason': reason,
      'explanation': explanation.trim(),
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Attendance Request $name created');
    return name;
  }

  /// طلباتي، الأحدث أولًا.
  Future<List<AttendanceRequestRecord>> fetchAttendanceRequests() async {
    final employee = await _employeeId();
    final rows = await _api.getAll(
      'Attendance Request',
      fields: AttendanceRequestRecord.fields,
      filters: [
        ['employee', '=', employee],
      ],
      orderBy: 'creation desc',
    );
    return [for (final r in rows) AttendanceRequestRecord.fromJson(r)];
  }

  // ───────────────────────── F5) إجازاتي ─────────────────────────

  /// أرصدة اليوم (get_leave_details)، والأنواع بدون راتب من Leave Type.is_lwp
  /// ومن message.lwps معًا.
  Future<LeaveDetails> fetchLeaveDetails() async {
    final employee = await _employeeId();
    final results = await Future.wait([
      _api.getMethod('$_leaveModule.get_leave_details', {
        'employee': employee,
        'date': PalestineTime.date(PalestineTime.today()),
      }),
      _api.getAll('Leave Type', fields: ['name', 'is_lwp']),
    ]);
    final msg = (results[0] as Map<String, dynamic>)['message'];
    final details = msg is Map
        ? LeaveDetails.fromJson(Map<String, dynamic>.from(msg))
        : const LeaveDetails(balances: [], withoutPayTypes: []);
    final lwpTypes = [
      for (final t in results[1] as List<Map<String, dynamic>>)
        if ('${t['is_lwp']}' == '1') t['name'].toString(),
    ];
    return LeaveDetails(
      balances: details.balances,
      withoutPayTypes: {...details.withoutPayTypes, ...lwpTypes}.toList(),
    );
  }

  /// طلبات الإجازة، الأحدث أولًا.
  Future<List<LeaveRequest>> fetchLeaveRequests() async {
    final employee = await _employeeId();
    final rows = await _api.getAll(
      'Leave Application',
      fields: LeaveRequest.fields,
      filters: [
        ['employee', '=', employee],
      ],
      orderBy: 'creation desc',
    );
    return [for (final r in rows) LeaveRequest.fromJson(r)];
  }

  /// أيام الإجازة كما يحسبها ERPNext (العطل لا تُحسب).
  Future<double> leaveDays({
    required String leaveType,
    required DateTime from,
    required DateTime to,
  }) async {
    final employee = await _employeeId();
    final res = await _api.getMethod('$_leaveModule.get_number_of_leave_days', {
      'employee': employee,
      'leave_type': leaveType,
      'from_date': PalestineTime.date(from),
      'to_date': PalestineTime.date(to),
    });
    final v = res['message'];
    return v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  }

  /// يقدّم طلب إجازة بحالة Open (قيد المراجعة). إن لم يكفِ الرصيد يرفضه الخادم
  /// ويصل نص الخطأ في [ErpApiException.detail].
  Future<String> submitLeave({
    required String leaveType,
    required DateTime from,
    required DateTime to,
    required String reason,
  }) async {
    final emp = await _employeeRow(['name', 'company']);
    final created = await _api.postDoc('Leave Application', {
      'employee': emp['name'],
      'company': _companyOf(emp),
      'leave_type': leaveType,
      'from_date': PalestineTime.date(from),
      'to_date': PalestineTime.date(to),
      'posting_date': PalestineTime.date(PalestineTime.today()),
      'description': reason.trim(),
      'status': 'Open',
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Leave Application $name created');
    return name;
  }

  // ───────────────────────── F6) عملي الإضافي ─────────────────────────

  /// مبالغ العمل الإضافي المعتمدة (Additional Salary / Overtime) في الشهر، بالشيكل.
  Future<List<OvertimePayment>> fetchOvertime(int year, int month) async {
    final employee = await _employeeId();
    final rows = await _api.getAll(
      'Additional Salary',
      fields: OvertimePayment.fields,
      filters: [
        ['employee', '=', employee],
        ['salary_component', '=', 'Overtime'],
        ['docstatus', '=', 1],
        ['payroll_date', '>=', PalestineTime.date(DateTime(year, month))],
        ['payroll_date', '<=', PalestineTime.date(DateTime(year, month + 1, 0))],
      ],
      orderBy: 'payroll_date asc',
    );
    return [for (final r in rows) OvertimePayment.fromJson(r)];
  }

  static String _companyOf(Map<String, dynamic> emp) {
    final c = emp['company']?.toString() ?? '';
    return c.isNotEmpty ? c : ErpConfig.company;
  }
}
