import 'package:customer/app/routes/app_pages.dart';
import 'package:customer/app/routes/app_routes.dart';
import 'package:customer/app/services/session_service.dart';
import 'package:customer/core/constants/ess_strings.dart';
import 'package:customer/core/constants/visit_strings.dart';
import 'package:customer/core/utils/palestine_time.dart';
import 'package:customer/data/api/erp_auth_service.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:customer/data/repositories/erp_employee_repository.dart';
import 'package:customer/features/auth/controllers/auth_controller.dart';
import 'package:customer/modules/hr/attendance/controllers/attendance_controller.dart';
import 'package:customer/modules/hr/attendance/repository/attendance_repository.dart';
import 'package:customer/modules/hr/home/controllers/hr_access_controller.dart';
import 'package:customer/modules/hr/leaves/controllers/leaves_controller.dart';
import 'package:customer/modules/hr/leaves/repository/leaves_repository.dart';
import 'package:customer/modules/hr/profile/repository/profile_repository.dart';
import 'package:customer/modules/hr/punch/controllers/punch_controller.dart';
import 'package:customer/modules/hr/punch/repository/punch_repository.dart';
import 'package:customer/modules/hr/shared/hr_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';
import 'hr_fakes.dart';

/// R5 — الشاشات عبر المسارات الحقيقية (AppPages + Bindings + AuthMiddleware):
/// المدخل ← Get.toNamed(service.routeName) ← الشاشة؛ المتحكم يُنشأ مرة ويُحذف
/// عند الرجوع؛ الـ repository الدائم يبقى.
void main() {
  late List<Sent> sent;
  late AuthController auth;

  setUpAll(PalestineTime.init);
  tearDown(Get.reset);

  Object? erp(Sent r) => hrReply(
    r,
    extra: (r) {
      if (r.pathText == 'api/resource/Employee') {
        return {
          'data': [
            {'name': 'HR-EMP-0007', 'default_shift': 'Morning'},
          ],
        };
      }
      if (r.pathText == 'api/resource/Attendance') {
        return {
          'data': [
            {
              'attendance_date': '2026-11-02',
              'status': 'Present',
              'late_entry': 1,
              'in_time': '2026-11-02 08:17:00',
            },
          ],
        };
      }
      if (r.pathText.endsWith('get_leave_details')) {
        return {
          'message': {
            'leave_allocation': {
              'Annual Leave': {'remaining_leaves': 3, 'total_leaves': 14},
            },
            'lwps': ['Leave Without Pay'],
          },
        };
      }
      return null;
    },
  );

  Future<void> pumpHr(WidgetTester tester) async {
    await tester.runAsync(() async {
      final f = await fakeApi(erp);
      sent = f.sent;
      final store = SessionStore();
      final session = SessionService(store, ErpAuthService(store));
      await session.init();
      Get.put(session, permanent: true);
      auth = AuthController(session);
      final hr = HrRepositories(f.api);
      Get.put(hr.profile, permanent: true);
      Get.put(hr.punch, permanent: true);
      Get.put(hr.attendance, permanent: true);
      Get.put(hr.leaves, permanent: true);
      Get.put(hr.legacy, permanent: true);
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: GetMaterialApp(
          getPages: AppPages.pages,
          initialRoute: Routes.hr,
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('المدخل ← البصمة: المتحكم مع المسار، ويُحذف عند الرجوع', (
    tester,
  ) async {
    await pumpHr(tester);
    expect(Get.isRegistered<HrAccessController>(), isTrue);
    expect(find.text(EssStrings.team), findsNothing, reason: 'غير معتمِد');

    await openService(tester, EssStrings.checkin);
    await settle(tester);
    expect(Get.currentRoute, Routes.hrPunch);
    expect(Get.isRegistered<CheckinController>(), isTrue);
    expect(find.text(EssStrings.statusNotCheckedIn), findsOneWidget);
    expect(
      sent.where((s) => s.pathText == 'api/resource/Employee Checkin').length,
      1,
      reason: 'لا طلبات مكررة مع إعادة البناء (الساعة كل ثانية)',
    );

    Get.back();
    await settle(tester);
    expect(Get.isRegistered<CheckinController>(), isFalse);
    expect(Get.isRegistered<PunchRepository>(), isTrue);
  });

  testWidgets(
    'حضوري: الشهر الحالي، علامة التأخير، والانتقال لشهر سابق ثم لاحق',
    (tester) async {
      await pumpHr(tester);
      await openService(tester, EssStrings.attendance);
      await settle(tester);
      expect(find.text(EssStrings.lateBy(17)), findsOneWidget);
      final c = Get.find<AttendanceController>();
      final month = c.month.value;

      await tester.tap(find.byTooltip(VisitStrings.previousMonth));
      await settle(tester);
      expect(c.month.value, month == 1 ? 12 : month - 1);
      await tester.tap(find.byTooltip(VisitStrings.nextMonth));
      await settle(tester);
      expect(c.month.value, month);
      expect(
        sent.where((s) => s.pathText == 'api/resource/Attendance').length,
        3,
      );

      Get.back();
      await settle(tester);
      expect(Get.isRegistered<AttendanceController>(), isFalse);
      expect(Get.isRegistered<AttendanceRepository>(), isTrue);
    },
  );

  testWidgets('إجازاتي: الرصيد، وتحذير LWP عند اختيار نوع بدون راتب', (
    tester,
  ) async {
    await pumpHr(tester);
    await openService(tester, EssStrings.leaves);
    await settle(tester);
    expect(find.textContaining('Annual Leave'), findsWidgets);
    expect(find.text(EssStrings.salaryWarningLwp), findsNothing);

    Get.find<LeavesController>().setType('Leave Without Pay');
    await settle(tester);
    await tester.ensureVisible(
      find.text(EssStrings.salaryWarningLwp, skipOffstage: false),
    );
    await tester.pump();
    expect(find.text(EssStrings.salaryWarningLwp), findsOneWidget);

    Get.back();
    await settle(tester);
    expect(Get.isRegistered<LeavesController>(), isFalse);
    expect(Get.isRegistered<LeavesRepository>(), isTrue);
  });

  testWidgets('حسابي: يفتح ويعرض الاسم، والـ repositories الدائمة باقية', (
    tester,
  ) async {
    await pumpHr(tester);
    await openService(tester, EssStrings.profile);
    await settle(tester);
    expect(find.text('Ahmad Saleh'), findsOneWidget);
    expect(Get.isRegistered<ProfileRepository>(), isTrue);
    expect(Get.isRegistered<ErpEmployeeRepository>(), isTrue);
  });
}

/// الطلبات تمر عبر MockClient (مستقبلات حقيقية)، فتحتاج runAsync ثم إطارات
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// البطاقة قد تكون خارج الشاشة (شبكة البطاقات تتمرر)
Future<void> openService(WidgetTester tester, String title) async {
  await tester.ensureVisible(find.text(title));
  await tester.pump();
  await tester.tap(find.text(title));
}
