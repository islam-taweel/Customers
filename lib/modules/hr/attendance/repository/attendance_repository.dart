import 'package:flutter/foundation.dart';

import '../../../../core/utils/palestine_time.dart';
import '../../../../data/api/erp_api_client.dart';
import '../../shared/models/employee_models.dart';
import '../../shared/repository/hr_employee_identity.dart';
import '../models/attendance_models.dart';

/// «حضوري» و«نسيت البصمة»: سجلات Attendance المعتمدة وطلبات Attendance Request.
/// (R5) الدوال منقولة حرفيًا من ErpEmployeeRepository (F3، F4).
class AttendanceRepository {
  AttendanceRepository(this._api, this._identity);

  final ErpApiClient _api;
  final HrEmployeeIdentity _identity;

  /// سجلات الحضور المعتمدة لشهر [month] من [year]، بالترتيب. مدة التأخير والخروج
  /// المبكر تُحسب من وقتي وردية الموظف الحالية.
  Future<List<AttendanceRecord>> fetchAttendance(int year, int month) async {
    final emp = await _identity.employeeRow(['name', 'default_shift']);
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
        shift = await _identity.shift(
          employee,
          emp['default_shift']?.toString() ?? '',
        );
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

  /// يحفظ طلب حضور ليوم [date] (مسودة = قيد المراجعة).
  /// [reason]: On Duty أو Work From Home فقط.
  Future<String> submitAttendanceRequest({
    required DateTime date,
    required String reason,
    required String explanation,
  }) async {
    final emp = await _identity.employeeRow(['name', 'company']);
    final day = PalestineTime.date(date);
    final created = await _api.postDoc('Attendance Request', {
      'employee': emp['name'],
      'company': HrEmployeeIdentity.companyOf(emp),
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
    final employee = await _identity.employeeId();
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
}
