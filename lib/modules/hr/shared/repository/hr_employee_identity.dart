import '../../../../core/utils/palestine_time.dart';
import '../../../../data/api/erp_api_client.dart';
import '../../../../data/api/erp_config.dart';
import '../models/employee_models.dart';

/// المستخدم الحالي غير مرتبط بسجل موظف نشط في ERPNext (Employee.user_id).
class EmployeeNotLinkedException implements Exception {
  const EmployeeNotLinkedException();
}

/// هوية الموظف المرتبط بالمستخدم الحالي، مشتركة بين كل وحدات HR.
///
/// (R5) نُقلت كما هي من ErpEmployeeRepository (_currentEmployee، _employeeRow،
/// _employeeId، _shift، _userInfo، _loggedUser، _companyOf). بلا حالة: كل
/// استدعاء يطلب من الخادم كما كان، فلا يتغير شيء إن تبدّل المستخدم.
class HrEmployeeIdentity {
  HrEmployeeIdentity(this._api);

  final ErpApiClient _api;

  /// الموظف المرتبط بالمستخدم الحالي (hrms.api.get_current_employee_info).
  /// ردّ فارغ = المستخدم غير مرتبط بموظف.
  Future<Map<String, dynamic>> currentEmployee() async {
    final msg = (await _api.getMethod(
      'hrms.api.get_current_employee_info',
    ))['message'];
    if (msg is! Map || '${msg['name'] ?? ''}'.isEmpty) {
      throw const EmployeeNotLinkedException();
    }
    return Map<String, dynamic>.from(msg);
  }

  /// الموظف الحالي مع [fields]: ما لا يرد في get_current_employee_info (مثل
  /// default_shift أو expense_approver) يُقرأ من Employee بنفس الرقم.
  Future<Map<String, dynamic>> employeeRow(List<String> fields) async {
    final me = await currentEmployee();
    final missing = [
      for (final f in fields)
        if (!me.containsKey(f)) f,
    ];
    if (missing.isEmpty) return me;
    final rows = await _api.getList(
      'Employee',
      fields: ['name', ...missing],
      filters: [
        ['name', '=', me['name']],
      ],
      limitPageLength: 1,
    );
    return rows.isEmpty ? me : {...me, ...rows.first};
  }

  /// رقم الموظف (Employee.name) المستخدم في كل الطلبات
  Future<String> employeeId() async =>
      (await currentEmployee())['name'].toString();

  /// وردية اليوم: تعيين الوردية الساري (بلا نهاية أو نهايته اليوم أو بعده)،
  /// وإلا الوردية الافتراضية للموظف. null إن لم توجد وردية.
  Future<EmployeeShift?> shift(String employee, String defaultShift) async {
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

  /// المستخدم الحالي (name = رقم المستخدم) وأدواره (hrms.api.get_current_user_info)
  Future<Map<String, dynamic>> userInfo() async {
    final msg = (await _api.getMethod(
      'hrms.api.get_current_user_info',
    ))['message'];
    return msg is Map ? Map<String, dynamic>.from(msg) : const {};
  }

  Future<String> loggedUser() async =>
      (await userInfo())['name']?.toString() ?? '';

  static String companyOf(Map<String, dynamic> emp) {
    final c = emp['company']?.toString() ?? '';
    return c.isNotEmpty ? c : ErpConfig.company;
  }
}
