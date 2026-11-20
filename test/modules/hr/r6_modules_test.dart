import 'dart:typed_data';

import 'package:customer/core/constants/ess_strings.dart';
import 'package:customer/core/utils/palestine_time.dart';
import 'package:customer/data/api/erp_api_client.dart';
import 'package:customer/data/api/erp_config.dart';
import 'package:customer/modules/hr/advances/controllers/advances_controller.dart';
import 'package:customer/modules/hr/advances/repository/advances_repository.dart';
import 'package:customer/modules/hr/expenses/controllers/expenses_controller.dart';
import 'package:customer/modules/hr/expenses/models/expense_models.dart';
import 'package:customer/modules/hr/expenses/repository/expenses_repository.dart';
import 'package:customer/modules/hr/payslips/repository/payslips_repository.dart';
import 'package:customer/modules/hr/shared/repository/hr_employee_identity.dart';
import 'package:customer/modules/hr/team/repository/team_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../support/fakes.dart';
import 'hr_fakes.dart';

/// R6 — السلف، المصاريف (والإيصال)، كشوف الرواتب، فريقي: نفس الطلبات والحقول.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(PalestineTime.init);
  tearDown(Get.reset);

  group('Advances', () {
    test('القائمة للموظف الحالي فقط، والطلب مسودة بنفس الحقول', () async {
      final f = await fakeApi(
        (r) => hrReply(
          r,
          extra: (r) => r.method == 'POST'
              ? {
                  'data': {'name': 'HR-EAD-1'},
                }
              : null,
        ),
      );
      final c = Get.put(
        AdvancesController(
          AdvancesRepository(f.api, HrEmployeeIdentity(f.api)),
        ),
      );
      await pumpEventQueue(times: 20);
      final list = f.sent.firstWhere(
        (s) => s.pathText == 'api/resource/Employee Advance',
      );
      expect(list.query['filters'], '[["employee","=","HR-EMP-0007"]]');

      expect(await c.submit(amount: 0, purpose: 'x'), EssStrings.amountInvalid);
      expect(
        await c.submit(amount: 300, purpose: ' '),
        EssStrings.requiredField,
      );
      expect(f.sent.where((s) => s.method == 'POST'), isEmpty);

      expect(await c.submit(amount: 300, purpose: ' سفر '), isNull);
      final body = f.sent.singleWhere((s) => s.method == 'POST').body! as Map;
      expect(body['employee'], 'HR-EMP-0007');
      expect(body['advance_amount'], 300);
      expect(body['purpose'], 'سفر');
      expect(body['currency'], ErpConfig.companyCurrency);
      expect(body['advance_account'], ErpConfig.employeeAdvanceAccount);
      expect(body.containsKey('docstatus'), isFalse);
    });

    test(
      'رفض الخادم ← الرسالة + نص ERPNext؛ الشبكة عند الفتح ← رسالة',
      () async {
        final f = await fakeApi(
          (r) => r.method == 'POST'
              ? erpError(417, 'Advance exceeds limit')
              : hrReply(r),
        );
        final c = Get.put(
          AdvancesController(
            AdvancesRepository(f.api, HrEmployeeIdentity(f.api)),
          ),
        );
        await pumpEventQueue(times: 20);
        final error = await c.submit(amount: 50, purpose: 'x');
        expect(error, contains('Advance exceeds limit'));

        Get.reset();
        final off = await fakeApi((_) => throw http.ClientException('offline'));
        final c2 = Get.put(
          AdvancesController(
            AdvancesRepository(off.api, HrEmployeeIdentity(off.api)),
          ),
        );
        await pumpEventQueue(times: 20);
        expect(c2.errorMessage, isNotNull);
      },
    );
  });

  group('Expenses', () {
    Object? erp(Sent r, {bool uploadFails = false}) => hrReply(
      r,
      extra: (r) {
        if (r.pathText == 'api/resource/Expense Claim Type') {
          return {
            'data': [
              {'name': 'Travel'},
              {'name': 'Food'},
            ],
          };
        }
        if (r.pathText == 'api/method/upload_file') {
          if (uploadFails) return http.Response('{}', 413);
          return {
            'message': {'file_url': '/private/files/receipt.jpg'},
          };
        }
        if (r.method == 'POST') {
          return {
            'data': {'name': 'HR-EXP-1'},
          };
        }
        return null;
      },
    );

    Future<({ExpensesController c, List<Sent> sent})> open({
      bool uploadFails = false,
    }) async {
      final f = await fakeApi((r) => erp(r, uploadFails: uploadFails));
      final c = Get.put(
        ExpensesController(
          ExpensesRepository(f.api, HrEmployeeIdentity(f.api)),
        ),
      );
      await pumpEventQueue(times: 30);
      return (c: c, sent: f.sent);
    }

    test(
      'الأنواع من ERPNext، والمطالبة مسودة ثم رفع الإيصال مرفقًا بها',
      () async {
        final o = await open();
        expect(o.c.types[ExpenseKind.transport], 'Travel');
        expect(o.c.types[ExpenseKind.meals], 'Food');

        final r = await o.c.submit(
          kind: ExpenseKind.transport,
          amount: 25,
          date: DateTime(2026, 11, 18),
          description: ' تاكسي ',
          receipt: Uint8List.fromList([1, 2, 3]),
          receiptName: 'IMG_1.jpg',
        );
        expect(r.error, isNull);
        expect(r.warning, isNull);

        final post = o.sent.firstWhere(
          (s) =>
              s.method == 'POST' && s.pathText == 'api/resource/Expense Claim',
        );
        final line = ((post.body! as Map)['expenses'] as List).single as Map;
        expect(line['expense_type'], 'Travel');
        expect(line['amount'], 25);
        expect(line['sanctioned_amount'], 25);
        expect(line['description'], 'تاكسي');
        expect(line['expense_date'], '2026-11-18');
        expect((post.body! as Map).containsKey('docstatus'), isFalse);

        final upload = o.sent.singleWhere(
          (s) => s.pathText == 'api/method/upload_file',
        );
        final multipart = upload.body.toString();
        expect(multipart, contains('name="doctype"'));
        expect(multipart, contains('Expense Claim'));
        expect(multipart, contains('HR-EXP-1'));
        expect(multipart, contains('filename="IMG_1.jpg"'));
        expect(multipart, contains('name="is_private"'));
      },
    );

    test('فشل رفع الإيصال: المطالبة محفوظة، وتحذير بدل خطأ', () async {
      final o = await open(uploadFails: true);
      final r = await o.c.submit(
        kind: ExpenseKind.meals,
        amount: 10,
        date: DateTime(2026, 11, 18),
        description: 'غداء',
        receipt: Uint8List.fromList([9]),
      );
      expect(r.error, isNull);
      expect(r.warning, isNotNull);
      expect(
        o.sent
            .where(
              (s) =>
                  s.pathText == 'api/resource/Expense Claim' &&
                  s.method == 'POST',
            )
            .length,
        1,
        reason: 'لا تُعاد المطالبة ولا تُحذف',
      );
    });

    test('التحقق: مبلغ صفر أو تاريخ مستقبلي ← لا طلب', () async {
      final o = await open();
      final future = PalestineTime.today().add(const Duration(days: 2));
      expect(
        (await o.c.submit(
          kind: ExpenseKind.meals,
          amount: 0,
          date: DateTime(2026, 11, 1),
          description: 'x',
        )).error,
        EssStrings.amountInvalid,
      );
      expect(
        (await o.c.submit(
          kind: ExpenseKind.meals,
          amount: 5,
          date: future,
          description: 'x',
        )).error,
        EssStrings.futureDate,
      );
      expect(o.sent.where((s) => s.method == 'POST'), isEmpty);
    });
  });

  group('Payslips', () {
    final slip = {
      'name': 'Sal Slip/HR-EMP-0007/00011',
      'employee': 'HR-EMP-0007',
      'docstatus': 1,
      'currency': 'ILS',
      'earnings': [
        {'salary_component': 'Basic', 'abbr': 'B', 'amount': 3000},
        {'salary_component': 'Overtime', 'abbr': 'OT', 'amount': 250.5},
      ],
      'deductions': [
        {'salary_component': 'Income Tax', 'abbr': 'IT', 'amount': 120},
      ],
      'gross_pay': 3250.5,
      'total_deduction': 120,
      'net_pay': 3130.5,
    };

    test('القائمة: المعتمدة فقط للموظف الحالي', () async {
      final f = await fakeApi(hrReply);
      await PayslipsRepository(
        f.api,
        HrEmployeeIdentity(f.api),
      ).fetchPayslips();
      final r = f.sent.last;
      expect(r.pathText, 'api/resource/Salary Slip');
      expect(
        r.query['filters'],
        '[["employee","=","HR-EMP-0007"],["docstatus","=",1]]',
      );
      expect(r.query['order_by'], 'start_date desc');
    });

    test(
      'Earnings وDeductions وNet Pay كما من ERPNext (لا إعادة حساب)',
      () async {
        final f = await fakeApi(
          (r) => hrReply(
            r,
            extra: (r) =>
                r.path.contains('Salary Slip') ? {'data': slip} : null,
          ),
        );
        final d = await PayslipsRepository(
          f.api,
          HrEmployeeIdentity(f.api),
        ).fetchPayslip(slip['name']! as String);
        expect(d.earnings.map((l) => l.amount), [3000, 250.5]);
        expect(d.deductions.single.component, 'Income Tax');
        expect(d.grossPay, 3250.5);
        expect(d.totalDeduction, 120);
        expect(d.netPay, 3130.5);
      },
    );

    test('كشف لموظف آخر أو مسودة ← مرفوض (forbidden)', () async {
      for (final bad in [
        {...slip, 'employee': 'HR-EMP-9999'},
        {...slip, 'docstatus': 0},
      ]) {
        final f = await fakeApi(
          (r) => hrReply(
            r,
            extra: (r) => r.path.contains('Salary Slip') ? {'data': bad} : null,
          ),
        );
        await expectLater(
          PayslipsRepository(
            f.api,
            HrEmployeeIdentity(f.api),
          ).fetchPayslip('x'),
          throwsA(
            isA<ErpApiException>().having(
              (e) => e.type,
              'type',
              ErpErrorType.forbidden,
            ),
          ),
        );
      }
    });
  });

  group('Team', () {
    Future<({TeamRepository t, List<Sent> sent})> team(
      List<String> roles,
    ) async {
      final f = await fakeApi(
        (r) => hrReply(
          r,
          extra: (r) => r.pathText.endsWith('get_current_user_info')
              ? {
                  'message': {'name': 'manager@rtc.ps', 'roles': roles},
                }
              : null,
        ),
      );
      final id = HrEmployeeIdentity(f.api);
      return (
        t: TeamRepository(f.api, id, ExpensesRepository(f.api, id)),
        sent: f.sent,
      );
    }

    test('الصلاحية من أدوار ERPNext', () async {
      expect((await (await team(['Employee'])).t.fetchApproverAccess()), (
        leaves: false,
        expenses: false,
      ));
      expect((await (await team(['Leave Approver'])).t.fetchApproverAccess()), (
        leaves: true,
        expenses: false,
      ));
      expect(
        (await (await team(['Expense Approver'])).t.fetchApproverAccess()),
        (leaves: false, expenses: true),
      );
    });

    test('طلبات الفريق: فقط التي المستخدم معتمِدها (leave_approver / expense_approver)', () async {
      final o = await team(['Leave Approver', 'Expense Approver']);
      await o.t.fetchTeamLeaves();
      await o.t.fetchTeamExpenses();
      final leaves = o.sent.firstWhere(
        (s) => s.pathText == 'api/resource/Leave Application',
      );
      expect(
        leaves.query['filters'],
        contains('["leave_approver","=","manager@rtc.ps"]'),
      );
      expect(leaves.query['filters'], contains('["status","=","Open"]'));
      final exp = o.sent.firstWhere(
        (s) => s.pathText == 'api/resource/Expense Claim',
      );
      expect(
        exp.query['filters'],
        contains('["expense_approver","=","manager@rtc.ps"]'),
      );
    });
  });
}
