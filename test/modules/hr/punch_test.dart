import 'package:customer/core/constants/ess_strings.dart';
import 'package:customer/core/utils/palestine_time.dart';
import 'package:customer/modules/hr/punch/controllers/punch_controller.dart';
import 'package:customer/modules/hr/punch/repository/punch_repository.dart';
import 'package:customer/modules/hr/shared/repository/hr_employee_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

import '../support/fakes.dart';
import 'hr_fakes.dart';

/// R5 — البصمة: نفس الطلبات، ووقت فلسطين يُرسل كما هو (بلا UTC ولا إزاحة).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(PalestineTime.init);
  tearDown(Get.reset);

  /// ساعة ثابتة: 2026-07-15 07:58:09 بتوقيت فلسطين (صيفًا UTC+3)
  final fixed = DateTime(2026, 7, 15, 7, 58, 9);

  group('توقيت فلسطين (Asia/Gaza)', () {
    test('صيفًا UTC+3 وشتاءً UTC+2 من قاعدة المناطق (لا إضافة يدوية)', () {
      final gaza = tz.getLocation('Asia/Gaza');
      final summer = tz.TZDateTime.from(
        DateTime.utc(2026, 7, 15, 4, 58, 9),
        gaza,
      );
      final winter = tz.TZDateTime.from(
        DateTime.utc(2026, 1, 15, 5, 58, 9),
        gaza,
      );
      expect(summer.timeZoneOffset, const Duration(hours: 3));
      expect(winter.timeZoneOffset, const Duration(hours: 2));
      expect('${summer.hour}:${summer.minute}', '7:58');
      expect('${winter.hour}:${winter.minute}', '7:58');
    });

    test('PalestineTime.now يطابق الوقت الحالي في Asia/Gaza (لا وقت الجهاز ولا UTC)', () {
      final gaza = tz.TZDateTime.now(tz.getLocation('Asia/Gaza'));
      final now = PalestineTime.now();
      final wall = DateTime(
        gaza.year,
        gaza.month,
        gaza.day,
        gaza.hour,
        gaza.minute,
        gaza.second,
      );
      expect(now.difference(wall).inSeconds.abs(), lessThanOrEqualTo(2));
      expect(now.isUtc, isFalse);
    });

    test('الصيغة المرسلة YYYY-MM-DD HH:MM:SS بلا Z ولا إزاحة', () {
      expect(
        PalestineTime.format(DateTime(2026, 3, 5, 7, 4, 9)),
        '2026-03-05 07:04:09',
      );
    });
  });

  group('PunchRepository (طلبات حقيقية فوق MockClient)', () {
    test(
      'Punch In: POST Employee Checkin بنفس الحقول ووقت فلسطين حرفيًا',
      () async {
        final f = await fakeApi(
          (r) => hrReply(
            r,
            extra: (r) => r.method == 'POST'
                ? {
                    'data': {'name': 'EMP-CKIN-001'},
                  }
                : null,
          ),
        );
        final repo = PunchRepository(
          f.api,
          HrEmployeeIdentity(f.api),
          now: () => fixed,
        );
        final p = await repo.punch(isIn: true);

        final post = f.sent.singleWhere((s) => s.method == 'POST');
        expect(post.pathText, 'api/resource/Employee Checkin');
        expect(post.body, {
          'employee': 'HR-EMP-0007',
          'log_type': 'IN',
          'time': '2026-07-15 07:58:09',
        });
        expect(p.isIn, isTrue);
        expect(p.time, fixed, reason: 'الوقت المعروض هو نفس المرسل');
      },
    );

    test('Punch Out: log_type OUT', () async {
      final f = await fakeApi(
        (r) => hrReply(
          r,
          extra: (r) => r.method == 'POST'
              ? {
                  'data': {'name': 'EMP-CKIN-002'},
                }
              : null,
        ),
      );
      final repo = PunchRepository(
        f.api,
        HrEmployeeIdentity(f.api),
        now: () => fixed,
      );
      await repo.punch(isIn: false);
      expect((f.sent.last.body! as Map)['log_type'], 'OUT');
    });

    test(
      'بصمات اليوم: فلتر اليوم بتوقيت فلسطين والترتيب الأقدم أولًا',
      () async {
        final f = await fakeApi(hrReply);
        final repo = PunchRepository(f.api, HrEmployeeIdentity(f.api));
        await repo.fetchTodayPunches();
        final r = f.sent.last;
        final today = PalestineTime.today();
        final tomorrow = DateTime(today.year, today.month, today.day + 1);
        expect(r.pathText, 'api/resource/Employee Checkin');
        expect(
          r.query['filters'],
          contains('["time",">=","${PalestineTime.date(today)} 00:00:00"]'),
        );
        expect(
          r.query['filters'],
          contains('["time","<","${PalestineTime.date(tomorrow)} 00:00:00"]'),
        );
        expect(r.query['order_by'], 'time asc');
      },
    );

    test(
      'مستخدم غير مرتبط بموظف ← EmployeeNotLinkedException ولا POST',
      () async {
        final f = await fakeApi((r) => hrReply(r, linked: false));
        final repo = PunchRepository(f.api, HrEmployeeIdentity(f.api));
        await expectLater(
          repo.punch(isIn: true),
          throwsA(isA<EmployeeNotLinkedException>()),
        );
        expect(f.sent.where((s) => s.method == 'POST'), isEmpty);
      },
    );
  });

  group('CheckinController', () {
    Future<({CheckinController c, List<Sent> sent})> open(
      Object? Function(Sent r)? extra,
    ) async {
      final f = await fakeApi((r) => hrReply(r, extra: extra));
      final c = Get.put(
        CheckinController(
          PunchRepository(f.api, HrEmployeeIdentity(f.api), now: () => fixed),
          clock: () => fixed,
        ),
      );
      await pumpEventQueue();
      return (c: c, sent: f.sent);
    }

    test(
      'حالة الدوام: لا بصمة ← حضور متاح؛ بعد IN ← انصراف؛ بعد OUT ← انتهى',
      () async {
        final o = await open(
          (r) => r.method == 'POST'
              ? {
                  'data': {'name': 'CK-${r.body}'},
                }
              : null,
        );
        final c = o.c;
        expect(c.status, CheckinStatus.notCheckedIn);
        expect(c.canCheckIn, isTrue);
        expect(c.canCheckOut, isFalse);

        expect(await c.punch(isIn: true), isNull);
        expect(c.status, CheckinStatus.onDuty);
        expect(c.checkInAt, fixed);
        expect(c.canCheckIn, isFalse);
        expect(c.canCheckOut, isTrue);
        expect(await c.punch(isIn: true), isNull, reason: 'حضور مكرر يُتجاهل');
        expect(o.sent.where((s) => s.method == 'POST').length, 1);

        expect(await c.punch(isIn: false), isNull);
        expect(c.status, CheckinStatus.finished);
        expect(c.checkOutAt, fixed);
        expect(c.log.first.isIn, isFalse, reason: 'الأحدث أولًا للعرض');
      },
    );

    test('مدة العمل: مجموع IN←OUT والفترة المفتوحة حتى الآن', () async {
      final o = await open(
        (r) => r.pathText == 'api/resource/Employee Checkin'
            ? {
                'data': [
                  {
                    'name': 'A',
                    'log_type': 'IN',
                    'time': '2026-07-15 08:00:00',
                  },
                  {
                    'name': 'B',
                    'log_type': 'OUT',
                    'time': '2026-07-15 12:00:00',
                  },
                  {
                    'name': 'C',
                    'log_type': 'IN',
                    'time': '2026-07-15 13:00:00',
                  },
                ],
              }
            : null,
      );
      expect(
        o.c.worked(DateTime(2026, 7, 15, 14, 30)),
        const Duration(hours: 5, minutes: 30),
      );
      expect(o.c.status, CheckinStatus.onDuty);
    });

    test(
      'رفض ERPNext: الرسالة العامة + نص الخادم؛ والشبكة: رسالة دون انهيار',
      () async {
        final o = await open(
          (r) =>
              r.method == 'POST' ? erpError(417, 'Shift not assigned') : null,
        );
        final error = await o.c.punch(isIn: true);
        expect(error, '${EssStrings.punchFailed}\nShift not assigned');
        expect(o.c.punching, isFalse);
        expect(o.c.status, CheckinStatus.notCheckedIn);

        Get.reset();
        final f = await fakeApi((_) => throw http.ClientException('offline'));
        final c = Get.put(
          CheckinController(PunchRepository(f.api, HrEmployeeIdentity(f.api))),
        );
        await pumpEventQueue();
        expect(c.errorMessage, isNotNull);
        expect(c.loading, isFalse);
      },
    );

    test('غير مرتبط بموظف ← رسالة notLinked', () async {
      final f = await fakeApi((r) => hrReply(r, linked: false));
      final c = Get.put(
        CheckinController(PunchRepository(f.api, HrEmployeeIdentity(f.api))),
      );
      await pumpEventQueue();
      expect(c.errorMessage, EssStrings.notLinked);
    });

    test('الساعة تتحدث كل ثانية وتتوقف عند إغلاق المتحكم', () async {
      var t = fixed;
      final f = await fakeApi(hrReply);
      final c = Get.put(
        CheckinController(
          PunchRepository(f.api, HrEmployeeIdentity(f.api)),
          clock: () => t,
        ),
      );
      t = fixed.add(const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(c.now.value, t);
      Get.delete<CheckinController>();
      t = fixed.add(const Duration(minutes: 1));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(c.now.value, isNot(t));
    });
  });
}
