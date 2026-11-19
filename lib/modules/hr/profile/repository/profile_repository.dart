import 'package:flutter/foundation.dart';

import '../../../../data/api/erp_api_client.dart';
import '../../shared/models/employee_models.dart';
import '../../shared/repository/hr_employee_identity.dart';

/// «حسابي»: بيانات الموظف المرتبط بالمستخدم الحالي ووردية اليوم وصورته.
/// (R5) الدوال منقولة حرفيًا من ErpEmployeeRepository (F1).
class ProfileRepository {
  ProfileRepository(this._api, this._identity);

  final ErpApiClient _api;
  final HrEmployeeIdentity _identity;

  /// الموظف مع ورديته اليوم.
  Future<EmployeeProfile> fetchProfile() async {
    final profile = EmployeeProfile.fromJson(
      await _identity.employeeRow(EmployeeProfile.fields),
    );
    EmployeeShift? shift;
    try {
      shift = await _identity.shift(profile.id, profile.defaultShift);
    } catch (e) {
      // الوردية معلومة إضافية: فشلها لا يمنع عرض بقية البيانات
      debugPrint('ErpEmployeeRepository shift failed: $e');
    }
    return profile.withShift(shift);
  }

  /// صورة الموظف (قد تكون ملفًا خاصًا فتحتاج كوكي الجلسة).
  Future<Uint8List> fetchImage(String path) => _api.downloadFile(path);
}
