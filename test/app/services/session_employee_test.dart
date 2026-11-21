import 'dart:convert';

import 'package:customer/app/services/session_service.dart';
import 'package:customer/core/constants/app_strings.dart';
import 'package:customer/data/api/erp_auth_service.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:customer/modules/hr/profile/controllers/profile_controller.dart';
import 'package:customer/modules/hr/profile/repository/profile_repository.dart';
import 'package:customer/modules/hr/shared/repository/hr_employee_identity.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../modules/hr/hr_fakes.dart';
import '../../modules/support/fakes.dart';

/// (R7) SessionService: نسخة واحدة تحمل الجلسة وهوية الموظف المسجّل، وتمسح
/// الهوية مع الخروج أو انتهاء الجلسة فلا تنتقل بين مستخدمين.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  Future<SessionService> signedIn() async {
    FlutterSecureStorage.setMockInitialValues({
      'erp_session_sid': 'abc',
      'erp_session_full_name': 'Ahmad',
    });
    final store = SessionStore();
    final auth = ErpAuthService(
      store,
      client: MockClient((_) async => http.Response(jsonEncode({}), 200)),
    );
    final s = SessionService(store, auth);
    await s.init();
    return s;
  }

  test('يحفظ الموظف مع جلسة قائمة، ويمسحه عند الخروج', () async {
    final s = await signedIn();
    s.rememberEmployee(id: 'HR-EMP-0007', name: 'Ahmad Saleh');
    expect(s.employeeId.value, 'HR-EMP-0007');
    expect(s.employeeName.value, 'Ahmad Saleh');

    await s.logout();
    expect(s.isAuthenticated.value, isFalse);
    expect(s.employeeId.value, isNull);
    expect(s.employeeName.value, isNull);
  });

  test('انتهاء الجلسة يمسح الموظف أيضًا، وبلا جلسة لا يُحفظ شيء', () async {
    final s = await signedIn();
    s.rememberEmployee(id: 'HR-EMP-0007', name: 'Ahmad');
    await s.store.clear();
    s.handleSessionExpired();
    expect(s.employeeId.value, isNull);

    s.rememberEmployee(id: 'HR-EMP-0001', name: 'X');
    expect(s.employeeId.value, isNull, reason: 'لا جلسة = لا هوية');
  });

  test(
    'ProfileController يحفظ هوية الموظف بعد التحميل (نفس SessionService)',
    () async {
      final s = await signedIn();
      final f = await fakeApi(hrReply);
      final c = ProfileController(
        ProfileRepository(f.api, HrEmployeeIdentity(f.api)),
        s,
      );
      c.onInit();
      await pumpEventQueue(times: 30);
      expect(s.employeeId.value, 'HR-EMP-0007');
      expect(s.employeeName.value, 'Ahmad Saleh');
    },
  );

  test('andJoiner: نفس الفاصل القديم في اللغتين', () {
    Get.locale = const Locale('ar');
    expect(AppStrings.andJoiner, ' و ');
    Get.locale = const Locale('en');
    expect(AppStrings.andJoiner, ' and ');
    Get.locale = const Locale('ar');
  });
}
