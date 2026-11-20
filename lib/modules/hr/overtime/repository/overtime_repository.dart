import '../../../../core/utils/palestine_time.dart';
import '../../../../data/api/erp_api_client.dart';
import '../../attendance/models/attendance_models.dart';
import '../../shared/repository/hr_employee_identity.dart';
import 'package:flutter/foundation.dart';
/// «عملي الإضافي»: Additional Salary (Overtime) وOvertime Slip إن كان مدعومًا.
/// (R6) الدوال منقولة حرفيًا من ErpEmployeeRepository (F6). يُبقي نتيجة فحص
/// Overtime Slip لبقية الجلسة، فهو كائن واحد دائم (InitialBinding).
class OvertimeRepository {
  OvertimeRepository(this._api, this._identity);

  final ErpApiClient _api;
  final HrEmployeeIdentity _identity;

  /// نتيجة فحص Overtime Slip (تُحفظ لبقية الجلسة: لا تتغير نسخة HRMS أثناءها)
  OvertimeSlipSupport? _overtimeSlipSupport;

  /// مبالغ العمل الإضافي المعتمدة (Additional Salary / Overtime) في الشهر، بالشيكل.
  Future<List<OvertimePayment>> fetchOvertime(int year, int month) async {
    final employee = await _identity.employeeId();
    final rows = await _api.getAll(
      'Additional Salary',
      fields: OvertimePayment.fields,
      filters: [
        ['employee', '=', employee],
        ['salary_component', '=', 'Overtime'],
        ['docstatus', '=', 1],
        ['payroll_date', '>=', PalestineTime.date(DateTime(year, month))],
        [
          'payroll_date',
          '<=',
          PalestineTime.date(DateTime(year, month + 1, 0)),
        ],
      ],
      orderBy: 'payroll_date asc',
    );
    return [for (final r in rows) OvertimePayment.fromJson(r)];
  }

  /// هل نسخة HRMS تدعم Overtime Slip؟ طلب قائمة بصف واحد: 404 (أو «DocType
  /// غير موجود») = غير مدعوم، 403 = موجود بلا صلاحية قراءة.
  Future<OvertimeSlipSupport> overtimeSlipSupport() async {
    final cached = _overtimeSlipSupport;
    if (cached != null) return cached;
    OvertimeSlipSupport result;
    try {
      await _api.getList('Overtime Slip', fields: ['name'], limitPageLength: 1);
      result = OvertimeSlipSupport.available;
    } on ErpApiException catch (e) {
      final detail = (e.detail ?? '').toLowerCase();
      if (e.type == ErpErrorType.notFound ||
          detail.contains('doesnotexist') ||
          detail.contains('not found')) {
        result = OvertimeSlipSupport.missing;
      } else if (e.type == ErpErrorType.forbidden) {
        result = OvertimeSlipSupport.noAccess;
      } else {
        rethrow; // خطأ شبكة أو خادم: لا نحفظ نتيجة خاطئة
      }
    }
    debugPrint('Overtime Slip support: $result');
    return _overtimeSlipSupport = result;
  }

  /// العمل الإضافي للشهر المختار: الساعات من Overtime Slip المعتمد إن كان مدعومًا،
  /// والمبلغ بالشيكل من Additional Salary بمكوّن Overtime. لا يحسب التطبيق شيئًا:
  /// يعرض total_overtime_duration ومدة كل بند ومبالغ Additional Salary كما هي.
  Future<OvertimeMonth> fetchOvertimeMonth(int year, int month) async {
    final from = PalestineTime.date(DateTime(year, month));
    final to = PalestineTime.date(DateTime(year, month + 1, 0));
    final results = await Future.wait([
      fetchOvertime(year, month),
      overtimeSlipSupport(),
    ]);
    final payments = results[0] as List<OvertimePayment>;
    final support = results[1] as OvertimeSlipSupport;

    if (support != OvertimeSlipSupport.available) {
      return OvertimeMonth(
        source: OvertimeSource.additionalSalary,
        slipSupport: support,
        totalSeconds: null,
        days: const [],
        slips: const [],
        payments: payments,
      );
    }

    final employee = await _identity.employeeId();
    final slips = await _api.getAll(
      'Overtime Slip',
      fields: ['name', 'start_date', 'end_date', 'total_overtime_duration'],
      filters: [
        ['employee', '=', employee],
        ['docstatus', '=', 1],
        ['start_date', '>=', from],
        ['start_date', '<=', to],
      ],
      orderBy: 'start_date asc',
    );

    var total = 0.0;
    final days = <OvertimeDay>[];
    for (final slip in slips) {
      total += _num(slip['total_overtime_duration']);
      try {
        final doc = await _api.getDoc('Overtime Slip', slip['name'].toString());
        // جدول البنود: أي جدول فرعي صفوفه فيها overtime_duration
        for (final value in doc.values) {
          if (value is! List) continue;
          for (final row in value) {
            if (row is! Map || !row.containsKey('overtime_duration')) continue;
            final date = DateTime.tryParse('${row['date']}');
            if (date == null) continue;
            days.add(
              OvertimeDay(
                date: DateTime(date.year, date.month, date.day),
                durationSeconds: _num(row['overtime_duration']),
                overtimeType: row['overtime_type']?.toString() ?? '',
              ),
            );
          }
        }
      } catch (e) {
        // البنود معلومة إضافية: الإجمالي من الكشف نفسه يكفي
        debugPrint('ErpEmployeeRepository overtime slip details failed: $e');
      }
    }
    days.sort((a, b) => a.date.compareTo(b.date));

    return OvertimeMonth(
      source: OvertimeSource.overtimeSlip,
      slipSupport: support,
      totalSeconds: total,
      days: days,
      slips: [for (final s in slips) s['name'].toString()],
      payments: payments,
    );
  }

  static double _num(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
}
