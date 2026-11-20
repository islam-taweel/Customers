import '../../../../data/api/erp_api_client.dart';
import '../../shared/repository/hr_employee_identity.dart';
import '../models/payslip_models.dart';

/// «كشوف رواتبي»: المعتمدة فقط (docstatus 1)، والكشف كاملًا للموظف الحالي.
/// القيم كما يحسبها ERPNext؛ التطبيق لا يعيد حساب الراتب.
/// (R6) الدوال منقولة حرفيًا من ErpEmployeeRepository.
class PayslipsRepository {
  PayslipsRepository(this._api, this._identity);

  final ErpApiClient _api;
  final HrEmployeeIdentity _identity;

  /// كشوف رواتب الموظف الحالي المعتمدة فقط (docstatus 1، لا مسودات)، الأحدث أولًا.
  Future<List<PayslipSummary>> fetchPayslips() async {
    final employee = await _identity.employeeId();
    final rows = await _api.getAll(
      'Salary Slip',
      fields: PayslipSummary.fields,
      filters: [
        ['employee', '=', employee],
        ['docstatus', '=', 1],
      ],
      orderBy: 'start_date desc',
    );
    return [for (final r in rows) PayslipSummary.fromJson(r)];
  }

  /// كشف راتب كاملًا. يُرفض إن لم يكن للموظف الحالي أو لم يكن معتمدًا
  /// (الصلاحية على الخادم هي الأساس، وهذا تحقق إضافي).
  Future<PayslipDetail> fetchPayslip(String name) async {
    final employee = await _identity.employeeId();
    final doc = await _api.getDoc('Salary Slip', name);
    if (doc['employee']?.toString() != employee ||
        '${doc['docstatus']}' != '1') {
      throw const ErpApiException(ErpErrorType.forbidden);
    }
    return PayslipDetail.fromJson(doc);
  }
}
