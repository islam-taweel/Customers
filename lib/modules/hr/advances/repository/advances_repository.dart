import 'package:flutter/foundation.dart';

import '../../../../core/utils/palestine_time.dart';
import '../../../../data/api/erp_api_client.dart';
import '../../../../data/api/erp_config.dart';
import '../../shared/repository/hr_employee_identity.dart';
import '../models/advance_models.dart';

/// «سلفي»: سلف الموظف الحالي، وطلب سلفة مسودة (لا docstatus).
/// (R6) الدوال منقولة حرفيًا من ErpEmployeeRepository.
class AdvancesRepository {
  AdvancesRepository(this._api, this._identity);

  final ErpApiClient _api;
  final HrEmployeeIdentity _identity;

  /// سلف الموظف الحالي فقط، الأحدث أولًا.
  Future<List<EmployeeAdvance>> fetchAdvances() async {
    final employee = await _identity.employeeId();
    final rows = await _api.getAll(
      'Employee Advance',
      fields: EmployeeAdvance.fields,
      filters: [
        ['employee', '=', employee],
      ],
      orderBy: 'creation desc',
    );
    return [for (final r in rows) EmployeeAdvance.fromJson(r)];
  }

  /// يقدّم طلب سلفة مسودة (قيد المراجعة) بالشيكل على حساب سلف الموظفين.
  /// لا docstatus: الموافقة والدفع من الموارد البشرية في ERPNext.
  Future<String> submitAdvance({
    required double amount,
    required String purpose,
  }) async {
    final emp = await _identity.employeeRow(['name', 'company']);
    final company = HrEmployeeIdentity.companyOf(emp);
    final created = await _api.postDoc('Employee Advance', {
      'employee': emp['name'],
      'company': company,
      'posting_date': PalestineTime.date(PalestineTime.today()),
      'advance_amount': amount,
      'purpose': purpose.trim(),
      'currency': ErpConfig.companyCurrency,
      'exchange_rate': 1,
      'advance_account': ErpConfig.employeeAdvanceAccount,
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Employee Advance $name created');
    return name;
  }
}
