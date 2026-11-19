import 'package:customer/core/constants/ess_strings.dart';
import 'package:customer/core/utils/palestine_time.dart';
import 'package:customer/modules/hr/attendance/controllers/attendance_controller.dart';
import 'package:customer/modules/hr/attendance/controllers/correction_controller.dart';
import 'package:customer/modules/hr/attendance/models/attendance_models.dart';
import 'package:customer/modules/hr/attendance/repository/attendance_repository.dart';
import 'package:customer/modules/hr/leaves/controllers/leaves_controller.dart';
import 'package:customer/modules/hr/leaves/repository/leaves_repository.dart';
import 'package:customer/modules/hr/profile/controllers/profile_controller.dart';
import 'package:customer/modules/hr/profile/repository/profile_repository.dart';
import 'package:customer/modules/hr/shared/repository/hr_employee_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../support/fakes.dart';
import 'hr_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(PalestineTime.init);
  tearDown(Get.reset);

  group('Profile', () {
    Object? erp(Sent r) => hrReply(
      r,
      extra: (r) {
        if (r.pathText == 'api/resource/Employee') {
          return {
            'data': [
              {
                'name': 'HR-EMP-0007',
                'image': '/private/files/ahmad.jpg',
                'department': 'Sales - RTC',
                'designation': 'Sales Rep',
                'company_email': 'ahmad@rtc.ps',
                'cell_number': '0599000000',
                'default_shift': 'Morning',
              },
            ],
          };
        }
        if (r.pathText == 'api/resource/Shift Assignment') return {'data': []};
        if (r.path.contains('files')) return {'ok': 1};
        return null;
      },
    );

    test('البيانات والوردية ثم الصورة، بنفس الترتيب والحقول', () async {
      final f = await fakeApi(erp);
      final c = Get.put(
        ProfileController(ProfileRepository(f.api, HrEmployeeIdentity(f.api))),
      );
      await pumpEventQueue(times: 30);

      expect(c.status.isSuccess, isTrue);
      final p = c.state!;
      expect(p.name, 'Ahmad Saleh');
      expect(p.id, 'HR-EMP-0007');
      expect(p.department, 'Sales - RTC');
      expect(p.designation, 'Sales Rep');
      expect(p.email, 'ahmad@rtc.ps');
      expect(p.phone, '0599000000');
      expect(p.shift!.name, 'Morning');
      expect(p.shift!.startTime, '8:00:00');
      expect(f.sent.map((s) => s.pathText).toList(), [
        'api/method/hrms.api.get_current_employee_info',
        'api/resource/Employee',
        'api/resource/Shift Assignment',
        'api/resource/Shift Type/Morning',
        'private/files/ahmad.jpg',
      ]);
      expect(c.image.value, isNotNull);
    });

    test(
      'غير مرتبط بموظف ← خطأ notLinked؛ والشبكة ← رسالة دون انهيار',
      () async {
        var f = await fakeApi((r) => hrReply(r, linked: false));
        var c = Get.put(
          ProfileController(
            ProfileRepository(f.api, HrEmployeeIdentity(f.api)),
          ),
        );
        await pumpEventQueue();
        expect(c.status.isError, isTrue);
        expect(c.status.errorMessage, EssStrings.notLinked);

        Get.reset();
        f = await fakeApi((_) => throw http.ClientException('offline'));
        c = Get.put(
          ProfileController(
            ProfileRepository(f.api, HrEmployeeIdentity(f.api)),
          ),
        );
        await pumpEventQueue();
        expect(c.status.isError, isTrue);
      },
    );
  });

  group('Attendance', () {
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
        if (r.pathText == 'api/resource/Attendance' &&
            r.query['filters']!.contains('2026-11-01')) {
          return {
            'data': [
              {
                'attendance_date': '2026-11-02',
                'status': 'Present',
                'working_hours': 8,
                'late_entry': 1,
                'early_exit': 0,
                'in_time': '2026-11-02 08:17:00',
                'out_time': '2026-11-02 16:05:00',
              },
              {'attendance_date': '2026-11-03', 'status': 'Absent'},
              {
                'attendance_date': '2026-11-04',
                'status': 'On Leave',
                'leave_type': 'Annual Leave',
              },
            ],
          };
        }
        return null;
      },
    );

    Future<({AttendanceController c, List<Sent> sent})> open() async {
      final f = await fakeApi(erp);
      final c = Get.put(
        AttendanceController(
          AttendanceRepository(f.api, HrEmployeeIdentity(f.api)),
          clock: () => DateTime(2026, 11, 19),
        ),
      );
      await pumpEventQueue(times: 30);
      return (c: c, sent: f.sent);
    }

    String? monthFilter(List<Sent> sent) => sent
        .lastWhere((s) => s.pathText == 'api/resource/Attendance')
        .query['filters'];

    test(
      'الشهر الحالي: فلتر أول الشهر وآخره، والتأخير بمدته، والغياب والإجازة',
      () async {
        final o = await open();
        expect(
          monthFilter(o.sent),
          contains('["attendance_date",">=","2026-11-01"]'),
        );
        expect(
          monthFilter(o.sent),
          contains('["attendance_date","<=","2026-11-30"]'),
        );
        expect(o.c.status.isSuccess, isTrue);
        final late = o.c.state!.first;
        expect(late.lateEntry, isTrue);
        expect(late.lateMinutes, 17, reason: 'من وقت الوردية 8:00');
        expect(o.c.state![1].status, AttendanceStatus.absent);
        expect(o.c.state![2].status, AttendanceStatus.onLeave);
        final s = o.c.summary;
        expect(s.absentDays, 1);
        expect(s.lateDays, 1);
      },
    );

    test('شهر سابق ولاحق (عبر السنة)، ونفس الشهر لا يعيد الطلب', () async {
      final o = await open();
      o.c.setPeriod(2026, 10);
      await pumpEventQueue(times: 30);
      expect(
        monthFilter(o.sent),
        contains('["attendance_date",">=","2026-10-01"]'),
      );
      expect(
        monthFilter(o.sent),
        contains('["attendance_date","<=","2026-10-31"]'),
      );
      expect(o.c.status.isEmpty, isTrue, reason: 'لا سجلات ← Empty');

      o.c.setPeriod(2027, 2);
      await pumpEventQueue(times: 30);
      expect(
        monthFilter(o.sent),
        contains('["attendance_date","<=","2027-02-28"]'),
      );

      final before = o.sent.length;
      o.c.setPeriod(2027, 2);
      await pumpEventQueue();
      expect(o.sent.length, before);
    });

    test(
      'طلب حضور (نسيت البصمة): مسودة بنفس الحقول، ولا طلبين لنفس اليوم',
      () async {
        final f = await fakeApi(
          (r) => hrReply(
            r,
            extra: (r) {
              if (r.method == 'POST') {
                return {
                  'data': {'name': 'HR-ARQ-1'},
                };
              }
              if (r.pathText == 'api/resource/Attendance Request' &&
                  r.method == 'GET') {
                return {
                  'data': [
                    {
                      'name': 'HR-ARQ-0',
                      'from_date': '2026-11-10',
                      'to_date': '2026-11-10',
                      'docstatus': 0,
                    },
                  ],
                };
              }
              return null;
            },
          ),
        );
        final c = Get.put(
          CorrectionController(
            AttendanceRepository(f.api, HrEmployeeIdentity(f.api)),
          ),
        );
        await pumpEventQueue(times: 20);

        expect(
          await c.submit(
            date: DateTime(2026, 11, 10),
            type: CorrectionType.forgotCheckIn,
            correctTime: '08:00',
            reason: 'On Duty',
            userReason: 'x',
          ),
          EssStrings.pendingSameDay,
        );
        expect(f.sent.where((s) => s.method == 'POST'), isEmpty);

        expect(
          await c.submit(
            date: DateTime(2026, 11, 11),
            type: CorrectionType.forgotCheckOut,
            correctTime: '16:00',
            reason: 'On Duty',
            userReason: ' نسيت ',
          ),
          isNull,
        );
        final body = f.sent.singleWhere((s) => s.method == 'POST').body! as Map;
        expect(body['employee'], 'HR-EMP-0007');
        expect(body['from_date'], '2026-11-11');
        expect(body['to_date'], '2026-11-11');
        expect(body['reason'], 'On Duty');
        expect(body.containsKey('docstatus'), isFalse);
      },
    );
  });

  group('Leaves', () {
    Object? erp(Sent r) => hrReply(
      r,
      extra: (r) {
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
        if (r.pathText == 'api/resource/Leave Type') {
          return {
            'data': [
              {'name': 'Annual Leave', 'is_lwp': 0},
              {'name': 'Unpaid Personal', 'is_lwp': 1},
            ],
          };
        }
        if (r.pathText.endsWith('get_number_of_leave_days')) {
          return {'message': r.query['to_date'] == '2026-12-07' ? 5 : 2};
        }
        if (r.pathText.endsWith('get_leave_approver')) {
          return {'message': 'manager@rtc.ps'};
        }
        if (r.method == 'POST') {
          return {
            'data': {'name': 'HR-LAP-1'},
          };
        }
        return null;
      },
    );

    Future<({LeavesController c, List<Sent> sent})> open() async {
      final f = await fakeApi(erp);
      final c = Get.put(
        LeavesController(LeavesRepository(f.api, HrEmployeeIdentity(f.api))),
      );
      await pumpEventQueue(times: 30);
      return (c: c, sent: f.sent);
    }

    test(
      'الرصيد والأنواع بدون راتب (من lwps ومن Leave Type.is_lwp معًا)',
      () async {
        final c = (await open()).c;
        expect(c.details.balanceOf('Annual Leave')!.remaining, 3);
        expect(c.details.isWithoutPay('Leave Without Pay'), isTrue);
        expect(c.details.isWithoutPay('Unpaid Personal'), isTrue);
        expect(c.details.isWithoutPay('Annual Leave'), isFalse);
      },
    );

    test('تحذير LWP عند اختيار نوع بدون راتب فقط', () async {
      final c = (await open()).c;
      c.setType('Annual Leave');
      expect(c.isWithoutPay, isFalse);
      c.setType('Leave Without Pay');
      expect(c.isWithoutPay, isTrue);
    });

    test('أيام ERPNext تتجاوز الرصيد ← رسالة الرصيد ولا POST', () async {
      final o = await open();
      final c = o.c;
      c.setType('Annual Leave');
      c.setFrom(DateTime(2026, 12, 1));
      c.setTo(DateTime(2026, 12, 7));
      c.reason = 'سفر';
      await pumpEventQueue(times: 20);
      expect(c.days, 5);
      expect(c.daysFromErp, isTrue);
      expect(
        await c.submit(),
        EssStrings.exceedsBalance(EssStrings.daysValue(3)),
      );
      expect(o.sent.where((s) => s.method == 'POST'), isEmpty);
    });

    test('تقديم طلب: Open مع المعتمِد، بنفس الحقول، ثم إعادة التحميل وتفريغ النموذج', () async {
      final o = await open();
      final c = o.c;
      c.setType('Annual Leave');
      c.setFrom(DateTime(2026, 12, 1));
      c.setTo(DateTime(2026, 12, 2));
      c.reason = ' سفر ';
      await pumpEventQueue(times: 20);
      expect(await c.submit(), isNull);

      final body = o.sent.singleWhere((s) => s.method == 'POST').body! as Map;
      expect(body['employee'], 'HR-EMP-0007');
      expect(body['leave_type'], 'Annual Leave');
      expect(body['from_date'], '2026-12-01');
      expect(body['to_date'], '2026-12-02');
      expect(body['leave_approver'], 'manager@rtc.ps');
      expect(body['description'], 'سفر');
      expect(body['status'], 'Open');
      expect(body.containsKey('docstatus'), isFalse);
      expect(c.type, isNull);
      expect(c.reason, '');
    });

    test('رفض الخادم لعدم كفاية الرصيد ← رسالة عربية واضحة', () async {
      final f = await fakeApi(
        (r) => r.method == 'POST'
            ? erpError(417, 'Insufficient leave balance for Annual Leave')
            : erp(r),
      );
      final c = Get.put(
        LeavesController(LeavesRepository(f.api, HrEmployeeIdentity(f.api))),
      );
      await pumpEventQueue(times: 30);
      c.setType('Leave Without Pay');
      c.setFrom(DateTime(2026, 12, 1));
      c.reason = 'x';
      await pumpEventQueue(times: 20);
      expect(await c.submit(), EssStrings.insufficientBalance);
    });

    test('انقطاع الشبكة عند الفتح: رسالة خطأ دون انهيار', () async {
      final f = await fakeApi((_) => throw http.ClientException('offline'));
      final c = Get.put(
        LeavesController(LeavesRepository(f.api, HrEmployeeIdentity(f.api))),
      );
      await pumpEventQueue();
      expect(c.errorMessage, isNotNull);
      expect(c.loading, isFalse);
    });
  });
}
