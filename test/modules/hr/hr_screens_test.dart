import 'package:customer/app/routes/app_pages.dart';
import 'package:customer/app/routes/app_routes.dart';
import 'package:customer/app/services/session_service.dart';
import 'package:customer/core/constants/ess_strings.dart';
import 'package:customer/core/constants/visit_strings.dart';
import 'package:customer/core/utils/palestine_time.dart';
import 'package:customer/data/api/erp_auth_service.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:customer/features/auth/controllers/auth_controller.dart';
import 'package:customer/modules/hr/attendance/controllers/attendance_controller.dart';
import 'package:customer/modules/hr/attendance/repository/attendance_repository.dart';
import 'package:customer/modules/hr/home/controllers/hr_access_controller.dart';
import 'package:customer/modules/hr/leaves/controllers/leaves_controller.dart';
import 'package:customer/modules/hr/leaves/repository/leaves_repository.dart';
import 'package:customer/modules/hr/profile/repository/profile_repository.dart';
import 'package:customer/modules/hr/punch/controllers/punch_controller.dart';
import 'package:customer/modules/hr/punch/repository/punch_repository.dart';
import 'package:customer/modules/hr/shared/hr_approver_access.dart';
import 'package:customer/modules/hr/shared/hr_repositories.dart';
import 'package:customer/modules/hr/team/repository/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';
import 'hr_fakes.dart';

/// R5/R6 — الشاشات عبر المسارات الحقيقية (AppPages + Bindings + Middleware):
/// المدخل ← Get.toNamed(service.routeName) ← الشاشة؛ المتحكم يُنشأ مرة ويُحذف
/// عند الرجوع؛ الـ repository الدائم يبقى.
void main() {
  late List<Sent> sent;
  late AuthController auth;

  setUpAll(PalestineTime.init);

  /// أدوار المستخدم في ERPNext لهذا الاختبار (افتراضيًا: ليس معتمِدًا)
  var roles = <String>['Employee'];
  tearDown(() {
    Get.reset();
    roles = ['Employee'];
  });

  Object? erp(Sent r) => hrReply(
    r,
    extra: (r) {
      if (r.pathText.endsWith('get_current_user_info')) {
        return {
          'message': {'name': 'manager@rtc.ps', 'roles': roles},
        };
      }
      if (r.pathText == 'api/resource/Salary Slip') {
        return {
          'data': [
            {
              'name': 'SAL-11',
              'start_date': '2026-10-01',
              'end_date': '2026-10-31',
              'gross_pay': 3250.5,
              'total_deduction': 120,
              'net_pay': 3130.5,
              'currency': 'ILS',
            },
          ],
        };
      }
      if (r.pathText == 'api/resource/Salary Slip/SAL-11') {
        return {
          'data': {
            'name': 'SAL-11',
            'employee': 'HR-EMP-0007',
            'docstatus': 1,
            'currency': 'ILS',
            'start_date': '2026-10-01',
            'end_date': '2026-10-31',
            'earnings': [
              {'salary_component': 'Basic', 'amount': 3250.5},
            ],
            'deductions': [
              {'salary_component': 'Income Tax', 'amount': 120},
            ],
            'gross_pay': 3250.5,
            'total_deduction': 120,
            'net_pay': 3130.5,
          },
        };
      }
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
      // R6: مدخل HR (HrHomeBinding) وManagerMiddleware يحتاجان هذين
      Get.put(hr.team, permanent: true);
      Get.put(hr.payslips, permanent: true);
      Get.put(HrApproverAccess(session), permanent: true);
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
    expect(Get.isRegistered<TeamRepository>(), isTrue);
  });

  testWidgets('فريقي: غير المعتمِد لا يدخل المسار حتى بالاسم', (tester) async {
    await pumpHr(tester);
    // المستخدم في هذا الاختبار ليس Leave/Expense Approver
    expect(Get.find<HrApproverAccess>().canSeeTeam, isFalse);

    Get.toNamed(Routes.hrTeam);
    await settle(tester);

    expect(
      Get.currentRoute,
      Routes.hr,
      reason: 'ManagerMiddleware يعيده إلى المدخل',
    );
    expect(find.text(EssStrings.teamNoAccess), findsNothing);
  });
  testWidgets(
    'فريقي: المعتمِد يرى البطاقة ويدخل المسار، والخروج يمسح الصلاحية',
    (tester) async {
      roles = ['Leave Approver'];
      await pumpHr(tester);
      expect(Get.find<HrApproverAccess>().canSeeTeam, isTrue);
      // openService يفشل إن لم تكن البطاقة موجودة (تظهر للمعتمِد فقط)
      await openService(tester, EssStrings.team);
      await settle(tester);
      expect(Get.currentRoute, Routes.hrTeam);
      expect(find.text(EssStrings.teamNoAccess), findsNothing);
      expect(
        sent
            .where((s) => s.pathText == 'api/resource/Leave Application')
            .length,
        1,
      );

      // الخروج: تُمسح الصلاحية المخزّنة فلا تنتقل إلى مستخدم آخر
      await tester.runAsync(() => Get.find<SessionService>().logout());
      await settle(tester);
      expect(Get.find<HrApproverAccess>().canSeeTeam, isFalse);
    },
  );

  testWidgets(
    'كشوف رواتبي: القائمة ← التفاصيل بـ Get.toNamed(arguments)، وصافي ERPNext',
    (tester) async {
      await pumpHr(tester);
      await openService(tester, EssStrings.payslips);
      await settle(tester);
      expect(Get.currentRoute, Routes.hrPayslips);

      await tester.tap(find.textContaining('3,130.50').first);
      await settle(tester);
      expect(Get.currentRoute, Routes.hrPayslipDetail);
      expect(find.textContaining('3,130.50'), findsWidgets);
      // المكوّن المعروف (ضريبة) يظهر بتسميته العربية؛ نتحقق من مبلغه كما من ERPNext
      // القيم كما من ERPNext (لا إعادة حساب): المستحقات، الخصم، الصافي
      expect(find.text('3,250.50 ₪', skipOffstage: false), findsWidgets);
      expect(find.text('ضريبة الدخل', skipOffstage: false), findsOneWidget);
      expect(find.text('120 ₪', skipOffstage: false), findsWidgets);
      expect(find.text('3,130.50 ₪', skipOffstage: false), findsWidgets);
    },
  );
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
  // الشبكة تُبنى عند ظهورها فقط (Sliver): نمرّر حتى تُبنى البطاقة
  await tester.scrollUntilVisible(
    find.text(title),
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(title));
  await tester.pump();
  await tester.tap(find.text(title));
}
