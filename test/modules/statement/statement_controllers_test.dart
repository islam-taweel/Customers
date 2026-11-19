import 'dart:async';
import 'dart:convert';

import 'package:customer/core/constants/statement_strings.dart';
import 'package:customer/data/api/erp_api_client.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:customer/data/models/erp_customer.dart';
import 'package:customer/data/repositories/erp_customer_repository.dart';
import 'package:customer/modules/statement/controllers/customer_statement_controller.dart';
import 'package:customer/modules/statement/controllers/statement_customers_controller.dart';
import 'package:customer/modules/statement/controllers/voucher_details_controller.dart';
import 'package:customer/modules/statement/models/statement_models.dart';
import 'package:customer/modules/statement/repository/erp_statement_repository.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// بديل للـ repository يعدّ الاستدعاءات ويتحكم بتوقيت الرد
class FakeStatementRepo implements ErpStatementRepository {
  int customerCalls = 0;
  Object? failWith;
  List<ErpCustomer> customers = const [];
  final pending = <Completer<CustomerStatement>>[];

  @override
  Future<List<ErpCustomer>> fetchCustomers() async {
    customerCalls++;
    final e = failWith;
    if (e != null) throw e;
    return customers;
  }

  @override
  Future<CustomerStatement> fetchStatement(
    String customerId, {
    DateTime? from,
    DateTime? to,
  }) {
    final c = Completer<CustomerStatement>();
    pending.add(c);
    return c.future;
  }

  @override
  Future<Map<String, dynamic>> fetchVoucher(
    String doctype,
    String name,
  ) async => {'name': name};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  const ahmad = ErpCustomer(id: 'CUST-001', name: 'Ahmad', phone: '0599123456');
  const sami = ErpCustomer(id: 'CUST-002', name: 'Sami', phone: '');

  group('StatementCustomersController', () {
    test('يحمّل مرة واحدة عند الإنشاء، ويفلتر بالاسم والرقم والهاتف', () async {
      final repo = FakeStatementRepo()..customers = [ahmad, sami];
      final c = Get.put(StatementCustomersController(repo));
      await pumpEventQueue();

      expect(repo.customerCalls, 1);
      expect(c.isLoading.value, isFalse);
      expect(c.visible, [ahmad, sami]);

      c.setQuery('sam');
      expect(c.visible, [sami]);
      c.setQuery('cust-001');
      expect(c.visible, [ahmad]);
      // أرقام عربية تُطبَّع كما في الشاشة القديمة
      c.setQuery('٠٥٩٩');
      expect(c.visible, [ahmad]);

      c.clearQuery();
      expect(c.query.value, '');
      expect(c.search.text, '');
      expect(c.visible.length, 2);
    });

    test('الخطأ يظهر رسالة، وإعادة المحاولة تنجح', () async {
      final repo = FakeStatementRepo()
        ..failWith = const ErpApiException(ErpErrorType.network);
      final c = Get.put(StatementCustomersController(repo));
      await pumpEventQueue();
      expect(c.errorMessage, isNotNull);

      repo
        ..failWith = null
        ..customers = [ahmad];
      await c.load();
      expect(c.errorMessage, isNull);
      expect(c.visible, [ahmad]);
      expect(repo.customerCalls, 2);
    });
  });

  test('CustomerStatementController يهمل رد الطلب الأقدم', () async {
    final repo = FakeStatementRepo();
    final c = Get.put(CustomerStatementController(repo, ahmad));
    c.setRange(
      DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
    );
    expect(repo.pending.length, 2);

    final newer = CustomerStatement(
      opening: 5,
      lines: const [],
      from: DateTime(2026),
    );
    repo.pending[1].complete(newer);
    await pumpEventQueue();
    repo.pending[0].complete(const CustomerStatement(opening: 0, lines: []));
    await pumpEventQueue();

    expect(identical(c.statement.value, newer), isTrue);
    expect(c.isLoading.value, isFalse);
  });

  group('مع ErpApiClient حقيقي (نفس الطلبات القديمة بالضبط)', () {
    late List<http.Request> requests;
    late int status;
    late ErpStatementRepository repo;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({
        'erp_session_sid': 'abc',
        'erp_session_full_name': 'Ahmad',
      });
      final store = SessionStore();
      await store.load();
      requests = [];
      status = 200;
      final mock = MockClient((r) async {
        if (r.url.path.contains('frappe.auth.get_logged_user')) {
          return http.Response(jsonEncode({'message': 'ahmad@rtc.ps'}), 200);
        }
        requests.add(r);
        if (status != 200) return http.Response('{}', status);
        if (r.url.path.contains('get_balance_on')) {
          return http.Response(jsonEncode({'message': 100}), 200);
        }
        if (r.url.pathSegments.last == 'GL Entry') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'posting_date': '2026-01-05',
                  'voucher_type': 'Sales Invoice',
                  'voucher_no': 'SINV-1',
                  'debit': 50,
                  'credit': 0,
                },
                {
                  'posting_date': '2026-01-09',
                  'voucher_type': 'Payment Entry',
                  'voucher_no': 'PE-1',
                  'debit': 0,
                  'credit': 30,
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'data': {'name': 'SINV-1', 'docstatus': 1},
          }),
          200,
        );
      });
      final api = ErpApiClient(session: store, client: mock);
      repo = ErpStatementRepository(api, ErpCustomerRepository(api));
    });

    test('بلا فترة: طلب GL Entry واحد ولا رصيد افتتاحي', () async {
      final c = Get.put(CustomerStatementController(repo, ahmad));
      await pumpEventQueue();

      expect(requests.length, 1);
      expect(requests.single.url.pathSegments, ['api', 'resource', 'GL Entry']);
      expect(
        requests.single.url.queryParameters['filters'],
        contains('CUST-001'),
      );
      final s = c.statement.value!;
      expect(s.opening, 0);
      expect(s.lines.map((l) => l.balance), [50, 20]);
    });

    test('مع فترة: نفس فلاتر التاريخ + get_balance_on لليوم السابق', () async {
      final c = Get.put(CustomerStatementController(repo, ahmad));
      await pumpEventQueue();
      requests.clear();

      await c.setRange(
        DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
      );

      expect(requests.length, 2);
      final filters = requests[0].url.queryParameters['filters']!;
      expect(filters, contains('["posting_date",">=","2026-01-01"]'));
      expect(filters, contains('["posting_date","<=","2026-01-31"]'));
      expect(
        requests[1].url.path,
        '/api/method/erpnext.accounts.utils.get_balance_on',
      );
      expect(requests[1].url.queryParameters['date'], '2025-12-31');
      expect(c.statement.value!.lines.map((l) => l.balance), [150, 120]);

      requests.clear();
      await c.clearRange();
      expect(requests.length, 1, reason: 'مسح الفترة ← طلب GL Entry فقط');
      expect(c.range.value, isNull);
    });

    test('403 لمستخدم حقيقي ← رسالة «يحتاج دور محاسبة»', () async {
      status = 403;
      final c = Get.put(CustomerStatementController(repo, ahmad));
      await pumpEventQueue();
      expect(c.errorMessage, StatementStrings.needsAccountsRole);
    });

    test(
      'VoucherDetailsController: GET /api/resource/<doctype>/<name>',
      () async {
        final c = Get.put(
          VoucherDetailsController(
            repo,
            doctype: 'Sales Invoice',
            name: 'SINV-1',
          ),
        );
        await pumpEventQueue();
        expect(requests.single.url.pathSegments, [
          'api',
          'resource',
          'Sales Invoice',
          'SINV-1',
        ]);
        expect(c.doc.value!['name'], 'SINV-1');
        expect(c.errorMessage, isNull);
      },
    );
  });
}
