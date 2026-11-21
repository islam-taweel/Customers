import 'dart:async';

import 'package:customer/data/api/erp_api_client.dart';
import 'package:customer/data/models/erp_customer.dart';
import 'package:customer/modules/hr/advances/controllers/advances_controller.dart';
import 'package:customer/modules/hr/advances/models/advance_models.dart';
import 'package:customer/modules/hr/advances/repository/advances_repository.dart';
import 'package:customer/modules/statement/controllers/customer_statement_controller.dart';
import 'package:customer/modules/statement/controllers/gl_entries_controller.dart';
import 'package:customer/modules/statement/controllers/statement_customers_controller.dart';
import 'package:customer/modules/statement/models/gl_entry.dart';
import 'package:customer/modules/statement/models/statement_models.dart';
import 'package:customer/modules/statement/repository/erp_ledger_repository.dart';
import 'package:customer/modules/statement/repository/erp_statement_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _StatementRepo implements ErpStatementRepository {
  Completer<List<ErpCustomer>> next = Completer();

  Completer<CustomerStatement> statement = Completer();

  @override
  Future<List<ErpCustomer>> fetchCustomers() => next.future;

  @override
  Future<CustomerStatement> fetchStatement(
    String customerId, {
    DateTime? from,
    DateTime? to,
  }) => statement.future;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _LedgerRepo implements ErpLedgerRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _AdvancesRepo implements AdvancesRepository {
  Completer<List<EmployeeAdvance>> next = Completer();

  @override
  Future<List<EmployeeAdvance>> fetchAdvances() => next.future;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// (R7) حالات StateMixin لشاشات القوائم والبيانات: loading/error/empty/success
/// بنفس شروط العرض السابقة.
void main() {
  tearDown(Get.reset);

  group('مجموعة A: البيانات تحل محل الشاشة', () {
    test('العملاء: loading ← success، وقائمة فارغة ← empty، والخطأ ← error برسالته', () async {
      final repo = _StatementRepo();
      final c = Get.put(StatementCustomersController(repo));
      expect(c.status.isLoading, isTrue);

      repo.next.complete(const [
        ErpCustomer(id: 'C1', name: 'Ahmad', phone: ''),
      ]);
      await pumpEventQueue();
      expect(c.status.isSuccess, isTrue);
      expect(c.state!.single.id, 'C1');

      repo.next = Completer()..complete(const []);
      await c.load();
      expect(c.status.isEmpty, isTrue);

      repo.next = Completer()
        ..completeError(const ErpApiException(ErpErrorType.network));
      await c.load();
      expect(c.status.isError, isTrue);
      expect(c.status.errorMessage, c.errorMessage);
      expect(c.isLoading.value, isFalse, reason: 'الحقول القديمة كما هي');
    });

    test(
      'القيود: لا سطور (مسودة) ← empty مع بقاء الدفتر لرسالة المسودات',
      () async {
        final c = Get.put(
          GlEntriesController(
            _LedgerRepo(),
            (_) async => const CustomerLedger(
              lines: [],
              drafts: [(doctype: 'Sales Invoice', name: 'SINV-9')],
            ),
          ),
        );
        await pumpEventQueue();
        expect(c.status.isEmpty, isTrue);
        expect(c.state!.drafts.single.name, 'SINV-9');
      },
    );

    test(
      'كشف الحساب بلا حركات ← empty والملخص متاح (state)، وبحركات ← success',
      () async {
        final repo = _StatementRepo();
        final c = Get.put(
          CustomerStatementController(
            repo,
            const ErpCustomer(id: 'C1', name: 'Ahmad', phone: ''),
          ),
        );
        repo.statement.complete(
          const CustomerStatement(opening: 50, lines: []),
        );
        await pumpEventQueue();
        expect(c.status.isEmpty, isTrue);
        expect(c.state!.closing, 50, reason: 'onEmpty يعرض الملخص و«لا حركات»');

        repo.statement = Completer()
          ..complete(
            CustomerStatement.fromGlRows([
              {'posting_date': '2026-01-05', 'debit': 10, 'credit': 0},
            ], opening: 0),
          );
        await c.load();
        expect(c.status.isSuccess, isTrue);
      },
    );
  });

  group('مجموعة B: القائمة تبقى ظاهرة أثناء إعادة التحميل', () {
    EmployeeAdvance adv() =>
        EmployeeAdvance.fromJson({'name': 'ADV-1', 'advance_amount': 100});

    test('أول تحميل ← loading؛ بيانات ← success؛ إعادة تحميل مع بيانات ← تبقى success', () async {
      final repo = _AdvancesRepo();
      final c = Get.put(AdvancesController(repo));
      expect(c.status.isLoading, isTrue, reason: 'تحميل والقائمة فارغة');

      repo.next.complete([adv()]);
      await pumpEventQueue();
      expect(c.status.isSuccess, isTrue);

      repo.next = Completer();
      final reload = c.load();
      await pumpEventQueue();
      expect(c.loading.value, isTrue);
      expect(
        c.status.isSuccess,
        isTrue,
        reason: 'شريط التقدم فقط، لا LoadingView',
      );

      repo.next.completeError(const ErpApiException(ErpErrorType.network));
      await reload;
      await pumpEventQueue();
      expect(
        c.status.isSuccess,
        isTrue,
        reason: 'خطأ مع بيانات قديمة ← تبقى القائمة',
      );
    });

    test('خطأ والقائمة فارغة ← error؛ نجاح فارغ ← empty', () async {
      final repo = _AdvancesRepo();
      final c = Get.put(AdvancesController(repo));
      repo.next.completeError(const ErpApiException(ErpErrorType.network));
      await pumpEventQueue();
      expect(c.status.isError, isTrue);
      expect(c.status.errorMessage, c.errorMessage);

      repo.next = Completer()..complete(const []);
      await c.load();
      await pumpEventQueue();
      expect(c.status.isEmpty, isTrue);
    });
  });
}
