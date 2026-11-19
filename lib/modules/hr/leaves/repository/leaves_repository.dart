import 'package:flutter/foundation.dart';

import '../../../../core/utils/palestine_time.dart';
import '../../../../data/api/erp_api_client.dart';
import '../../shared/repository/hr_employee_identity.dart';
import '../models/leave_models.dart';

/// «إجازاتي»: الأرصدة والأنواع بدون راتب، الطلبات، عدد الأيام من ERPNext،
/// وتقديم طلب (Open). (R5) الدوال منقولة حرفيًا من ErpEmployeeRepository (F5).
class LeavesRepository {
  LeavesRepository(this._api, this._identity);

  final ErpApiClient _api;
  final HrEmployeeIdentity _identity;

  static const _leaveModule =
      'hrms.hr.doctype.leave_application.leave_application';

  /// أرصدة اليوم (get_leave_details)، والأنواع بدون راتب من Leave Type.is_lwp
  /// ومن message.lwps معًا.
  Future<LeaveDetails> fetchLeaveDetails() async {
    final employee = await _identity.employeeId();
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
    final employee = await _identity.employeeId();
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
    final employee = await _identity.employeeId();
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
    final emp = await _identity.employeeRow(['name', 'company']);
    var approver = '';
    try {
      final res = await _api.getMethod('$_leaveModule.get_leave_approver', {
        'employee': emp['name'].toString(),
      });
      approver = res['message']?.toString() ?? '';
    } catch (e) {
      // بلا معتمِد محدد: يكمله الخادم من إعدادات الموظف أو يرفض برسالة واضحة
      debugPrint('ErpEmployeeRepository leave approver failed: $e');
    }
    final created = await _api.postDoc('Leave Application', {
      'employee': emp['name'],
      'company': HrEmployeeIdentity.companyOf(emp),
      if (approver.isNotEmpty) 'leave_approver': approver,
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
}
