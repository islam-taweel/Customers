import 'package:flutter/foundation.dart';

import '../../../../core/utils/palestine_time.dart';
import '../../../../data/api/erp_api_client.dart';
import '../../shared/models/employee_models.dart';
import '../../shared/repository/hr_employee_identity.dart';

/// البصمة (Employee Checkin) بتوقيت فلسطين.
/// (R5) الدوال منقولة حرفيًا من ErpEmployeeRepository (F2). الفرق الوحيد:
/// مصدر «الآن» قابل للحقن للاختبار، وافتراضيًا PalestineTime.now كما كان.
class PunchRepository {
  PunchRepository(this._api, this._identity, {DateTime Function()? now})
    : _now = now ?? PalestineTime.now;

  final ErpApiClient _api;
  final HrEmployeeIdentity _identity;

  /// وقت فلسطين الحالي (قيم «جدار»)
  final DateTime Function() _now;

  /// بصمات اليوم بالترتيب (الأقدم أولًا).
  Future<List<EmployeeCheckin>> fetchTodayPunches() async {
    final employee = await _identity.employeeId();
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
    final employee = await _identity.employeeId();
    final now = _now();
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
}
