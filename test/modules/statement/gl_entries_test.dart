import 'package:customer/core/constants/app_strings.dart';
import 'package:customer/core/constants/statement_strings.dart';
import 'package:customer/data/models/erp_customer.dart';
import 'package:customer/data/repositories/erp_customer_repository.dart';
import 'package:customer/modules/statement/controllers/customer_statement_controller.dart';
import 'package:customer/modules/statement/controllers/gl_entries_controller.dart';
import 'package:customer/modules/statement/repository/erp_ledger_repository.dart';
import 'package:customer/modules/statement/repository/erp_statement_repository.dart';
import 'package:customer/modules/statement/views/customer_statement_view.dart';
import 'package:customer/modules/statement/views/gl_entries_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../support/fakes.dart';

Map<String, dynamic> ple(String type, String no, double amount) => {
  'posting_date': '2026-11-10',
  'voucher_type': type,
  'voucher_no': no,
  'amount_in_account_currency': amount,
  'account_currency': 'ILS',
};

/// R4 — القيود المحاسبية (GL Entries) وحالات كشف الحساب في الواجهة.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('ErpLedgerRepository (نفس الطلبات)', () {
    test('فاتورة مسودة: طلب واحد ولا قيود تُطلب', () async {
      final f = await fakeApi(
        (_) => {
          'data': [
            {'name': 'SINV-9', 'docstatus': 0},
          ],
        },
      );
      final ledger = await ErpLedgerRepository(f.api).forInvoice('SINV-9');
      expect(f.sent.single.pathText, 'api/resource/Sales Invoice');
      expect(ledger.lines, isEmpty);
      expect(ledger.drafts.single.name, 'SINV-9');
    });

    test(
      'فاتورة معتمدة: Payment Ledger Entry، السطور الصفرية تُحذف، والتوازن',
      () async {
        final f = await fakeApi((r) {
          if (r.pathText == 'api/resource/Sales Invoice') {
            return {
              'data': [
                {'name': 'SINV-1', 'docstatus': 1},
              ],
            };
          }
          return {
            'data': [
              ple('Sales Invoice', 'SINV-1', 300),
              ple('Payment Entry', 'PE-1', -120),
              ple('Journal Entry', 'JV-0', 0),
              ple('Payment Entry', 'PE-2', -80.5),
            ],
          };
        });
        final ledger = await ErpLedgerRepository(f.api).forInvoice('SINV-1');

        final r = f.sent[1];
        expect(r.pathText, 'api/resource/Payment Ledger Entry');
        expect(
          r.query['filters'],
          '[["against_voucher_type","=","Sales Invoice"],'
          '["against_voucher_no","=","SINV-1"],["delinked","=",0]]',
        );
        expect(r.query['order_by'], 'creation asc');
        expect(ledger.lines.map((l) => l.voucherNo), [
          'SINV-1',
          'PE-1',
          'PE-2',
        ]);
        expect(ledger.lines.first.debit, 300);
        expect(ledger.lines[1].credit, 120);
        expect(ledger.totalDebit, 300);
        expect(ledger.totalCredit, 200.5);
        expect(ledger.difference, closeTo(99.5, 1e-9));
        expect(ledger.isBalanced, isFalse);
        expect(ledger.currency, 'ILS');
      },
    );

    test(
      'تعذّر دفتر الدفعات (403) ← احتياط GL Entry؛ والشبكة لا تُحتاط',
      () async {
        var offlineOnPle = false;
        final f = await fakeApi((r) {
          if (r.pathText == 'api/resource/Sales Invoice') {
            return {
              'data': [
                {'name': 'SINV-1', 'docstatus': 1},
              ],
            };
          }
          if (r.pathText == 'api/resource/Payment Ledger Entry') {
            if (offlineOnPle) throw http.ClientException('offline');
            return http.Response('{}', 403);
          }
          return {
            'data': [
              {
                'posting_date': '2026-11-10',
                'voucher_type': 'Sales Invoice',
                'voucher_no': 'SINV-1',
                'debit_in_account_currency': 100,
                'credit_in_account_currency': 0,
                'account_currency': 'ILS',
              },
              {
                'posting_date': '2026-11-11',
                'voucher_type': 'Payment Entry',
                'voucher_no': 'PE-1',
                'debit_in_account_currency': 0,
                'credit_in_account_currency': 100,
                'account_currency': 'ILS',
              },
            ],
          };
        });
        final repo = ErpLedgerRepository(f.api);
        final ledger = await repo.forInvoice('SINV-1');
        expect(f.sent.last.pathText, 'api/resource/GL Entry');
        expect(ledger.isBalanced, isTrue);

        offlineOnPle = true;
        await expectLater(repo.forInvoice('SINV-1'), throwsA(isA<Object>()));
      },
    );

    test(
      'طلبية: الفواتير المكررة (join الأصناف) مرة واحدة، والمسودات منفصلة',
      () async {
        final f = await fakeApi((r) {
          if (r.pathText == 'api/resource/Sales Invoice') {
            return {
              'data': [
                {'name': 'SINV-1', 'docstatus': 1},
                {'name': 'SINV-1', 'docstatus': 1},
                {'name': 'SINV-2', 'docstatus': 0},
              ],
            };
          }
          return {
            'data': [ple('Sales Invoice', 'SINV-1', 50)],
          };
        });
        final ledger = await ErpLedgerRepository(f.api).forOrder('SO-1');
        expect(
          f.sent
              .where((s) => s.pathText == 'api/resource/Payment Ledger Entry')
              .length,
          1,
        );
        expect(ledger.lines.length, 1);
        expect(ledger.drafts.map((d) => d.name), ['SINV-2']);
      },
    );
  });

  group('GlEntriesController', () {
    test('طلب واحد، والمسودة ← رسالة «بانتظار الاعتماد»', () async {
      var calls = 0;
      final f = await fakeApi((_) {
        calls++;
        return {
          'data': [
            {'name': 'SINV-9', 'docstatus': 0},
          ],
        };
      });
      final c = Get.put(
        GlEntriesController(
          ErpLedgerRepository(f.api),
          (l) => l.forInvoice('SINV-9'),
        ),
      );
      await pumpEventQueue();
      expect(calls, 1);
      expect(c.isLoading.value, isFalse);
      expect(c.emptyMessage, AppStrings.glDraftsPending('SINV-9'));
    });

    test('انقطاع الشبكة: رسالة خطأ، وإعادة المحاولة تنجح', () async {
      var offline = true;
      final f = await fakeApi((_) {
        if (offline) throw http.ClientException('offline');
        return {'data': []};
      });
      final c = Get.put(
        GlEntriesController(
          ErpLedgerRepository(f.api),
          (l) => l.forOrder('SO-1'),
        ),
      );
      await pumpEventQueue();
      expect(c.errorMessage, isNotNull);
      expect(c.ledger.value, isNull);

      offline = false;
      await c.load();
      expect(c.errorMessage, isNull);
      expect(c.emptyMessage, AppStrings.glEntriesEmptyMessage);
    });
  });

  group('الشاشات (Widget)', () {
    late GlobalKey<NavigatorState> nav;
    setUp(() => nav = GlobalKey<NavigatorState>());

    Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
      GetMaterialApp(navigatorKey: nav, home: const Scaffold()),
    );

    testWidgets(
      'GlEntriesScreen.forInvoice: الجدول والمجاميع، والمتحكم يُحذف مع المسار',
      (tester) async {
        await tester.runAsync(() async {
          final f = await fakeApi((r) {
            if (r.pathText == 'api/resource/Sales Invoice') {
              return {
                'data': [
                  {'name': 'SINV-1', 'docstatus': 1},
                ],
              };
            }
            return {
              'data': [
                ple('Sales Invoice', 'SINV-1', 300),
                ple('Payment Entry', 'PE-1', -300),
              ],
            };
          });
          Get.put(ErpLedgerRepository(f.api), permanent: true);
        });
        await pumpApp(tester);
        nav.currentState!.push(GlEntriesScreen.forInvoice('SINV-1'));
        await tester.pump();
        // أول إطار للمسار يُبنى خارج الشاشة (قياس Hero)
        expect(
          find.text(AppStrings.glEntriesLoading, skipOffstage: false),
          findsOneWidget,
        );
        await tester.runAsync(() => pumpEventQueue(times: 30));
        await tester.pumpAndSettle();

        expect(find.textContaining('PE-1'), findsOneWidget);
        expect(find.text(AppStrings.glBalanced), findsOneWidget);
        expect(
          Get.isRegistered<GlEntriesController>(tag: 'gl:SINV-1#1'),
          isTrue,
        );

        nav.currentState!.pop();
        await tester.pumpAndSettle();
        expect(
          Get.isRegistered<GlEntriesController>(tag: 'gl:SINV-1#1'),
          isFalse,
        );
        expect(Get.isRegistered<ErpLedgerRepository>(), isTrue);
      },
    );

    testWidgets('كشف الحساب: Empty ثم Error (دون انهيار) ثم إعادة المحاولة', (
      tester,
    ) async {
      var offline = false;
      await tester.runAsync(() async {
        final f = await fakeApi((r) {
          if (offline) throw http.ClientException('offline');
          return {'data': []};
        });
        Get.put(
          ErpStatementRepository(f.api, ErpCustomerRepository(f.api)),
          permanent: true,
        );
      });
      const customer = ErpCustomer(id: 'CUST-001', name: 'Ahmad', phone: '');
      await pumpApp(tester);
      nav.currentState!.push(CustomerStatementScreen.route(customer));
      await tester.runAsync(() => pumpEventQueue(times: 30));
      await tester.pumpAndSettle();
      expect(find.text(StatementStrings.noEntries), findsOneWidget);
      expect(find.text(StatementStrings.allPeriods), findsOneWidget);

      offline = true;
      final c = Get.find<CustomerStatementController>(
        tag: tester
            .widget<CustomerStatementScreen>(
              find.byType(CustomerStatementScreen),
            )
            .tag,
      );
      await tester.runAsync(c.load);
      await tester.pumpAndSettle();
      expect(find.text(StatementStrings.noEntries), findsNothing);
      expect(find.text(AppStrings.retry), findsOneWidget);

      offline = false;
      await tester.tap(find.text(AppStrings.retry));
      await tester.runAsync(() => pumpEventQueue(times: 30));
      await tester.pumpAndSettle();
      expect(find.text(StatementStrings.noEntries), findsOneWidget);
    });
  });
}
