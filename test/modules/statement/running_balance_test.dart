import 'dart:math';

import 'package:customer/data/repositories/erp_customer_repository.dart';
import 'package:customer/modules/statement/models/statement_models.dart';
import 'package:customer/modules/statement/repository/erp_statement_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

/// صف GL Entry كما يرسله ERPNext لحقول StatementLine.fields
Map<String, dynamic> gl(
  String date,
  String type,
  String no, {
  Object? debit = 0,
  Object? credit = 0,
}) => {
  'posting_date': date,
  'voucher_type': type,
  'voucher_no': no,
  'debit': debit,
  'credit': credit,
  'remarks': '',
};

/// الحلقة القديمة من ErpStatementRepository.fetchStatement (قبل R4) حرفيًا،
/// مرجعًا للمقارنة: يجب أن يطابقها الحساب الجديد رقمًا برقم.
CustomerStatement legacy(List<Map<String, dynamic>> rows, double opening) {
  double toNum(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  var balance = opening;
  final lines = <StatementLine>[];
  for (final r in rows) {
    balance += toNum(r['debit']) - toNum(r['credit']);
    lines.add(StatementLine.fromJson(r, balance));
  }
  return CustomerStatement(opening: opening, lines: lines);
}

/// R4 — الرصيد الجاري: الافتتاحي + مجموع (مدين − دائن) سطرًا بسطر بترتيب ERPNext.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerStatement.fromGlRows', () {
    test('رصيد افتتاحي + حركات مدينة ودائنة معًا', () {
      final s = CustomerStatement.fromGlRows([
        gl('2026-01-05', 'Sales Invoice', 'SINV-1', debit: 500),
        gl('2026-01-07', 'Payment Entry', 'PE-1', credit: 200),
        gl('2026-01-09', 'Sales Invoice', 'SINV-2', debit: 150.5),
        gl('2026-01-12', 'Sales Invoice', 'SINV-R1', credit: 50.25),
      ], opening: 1000);

      expect(s.lines.map((l) => l.balance), [1500, 1300, 1450.5, 1400.25]);
      expect(s.totalDebit, 650.5);
      expect(s.totalCredit, 250.25);
      expect(s.closing, 1400.25);
      expect(s.closing, s.opening + s.totalDebit - s.totalCredit);
    });

    test('حركات مدينة فقط', () {
      final s = CustomerStatement.fromGlRows([
        gl('2026-02-01', 'Sales Invoice', 'A', debit: 10),
        gl('2026-02-02', 'Sales Invoice', 'B', debit: 20),
      ], opening: 0);
      expect(s.lines.map((l) => l.balance), [10, 30]);
      expect(s.totalCredit, 0);
      expect(s.closing, 30);
    });

    test('حركات دائنة فقط (رصيد للعميل = سالب)', () {
      final s = CustomerStatement.fromGlRows([
        gl('2026-02-01', 'Payment Entry', 'PE-1', credit: 70),
        gl('2026-02-03', 'Journal Entry', 'JV-1', credit: 30),
      ], opening: 40);
      expect(s.lines.map((l) => l.balance), [-30, -60]);
      expect(s.totalDebit, 0);
      expect(s.closing, -60);
    });

    test('لا حركات: الختامي = الافتتاحي، والمجاميع صفر', () {
      final withOpening = CustomerStatement.fromGlRows(const [], opening: 250);
      expect(withOpening.lines, isEmpty);
      expect(withOpening.closing, 250);
      expect(withOpening.totalDebit, 0);
      expect(withOpening.totalCredit, 0);
      expect(CustomerStatement.fromGlRows(const [], opening: 0).closing, 0);
    });

    test(
      'تواريخ مختلفة: الترتيب كما جاء من ERPNext، لا يُعاد ترتيبه في التطبيق',
      () {
        // ERPNext يرتّب posting_date ثم creation؛ قيدان بنفس اليوم يبقيان بترتيبهما
        final s = CustomerStatement.fromGlRows([
          gl('2026-03-01', 'Sales Invoice', 'S-1', debit: 100),
          gl('2026-03-01', 'Payment Entry', 'P-1', credit: 100),
          gl('2026-03-04', 'Sales Invoice', 'S-2', debit: 40),
          gl('2026-03-10', 'Payment Entry', 'P-2', credit: 15),
        ], opening: 0);
        expect(s.lines.map((l) => l.voucherNo), ['S-1', 'P-1', 'S-2', 'P-2']);
        expect(s.lines.map((l) => l.postingDate), [
          '2026-03-01',
          '2026-03-01',
          '2026-03-04',
          '2026-03-10',
        ]);
        expect(s.lines.map((l) => l.balance), [100, 0, 40, 25]);
      },
    );

    test('قيم ERPNext نصية أو فارغة تُقرأ كما كانت (null = 0)', () {
      final s = CustomerStatement.fromGlRows([
        gl('2026-04-01', 'Sales Invoice', 'S', debit: '120.75', credit: null),
        gl('2026-04-02', 'Payment Entry', 'P', debit: null, credit: '20.75'),
      ], opening: 0);
      expect(s.lines.first.debit, 120.75);
      expect(s.lines.first.credit, 0);
      expect(s.lines.map((l) => l.balance), [120.75, 100]);
    });

    test('مطابق للحساب القديم رقمًا برقم (300 صف عشوائي، 20 مجموعة)', () {
      final rnd = Random(2026);
      for (var round = 0; round < 20; round++) {
        final opening = (rnd.nextInt(200000) - 100000) / 100;
        final rows = [
          for (var i = 0; i < 300; i++)
            gl(
              '2026-${(i % 12 + 1).toString().padLeft(2, '0')}-01',
              rnd.nextBool() ? 'Sales Invoice' : 'Payment Entry',
              'V-$i',
              debit: rnd.nextBool() ? rnd.nextInt(1000000) / 100 : 0,
              credit: rnd.nextBool() ? rnd.nextInt(1000000) / 100 : 0,
            ),
        ];
        final now = CustomerStatement.fromGlRows(rows, opening: opening);
        final old = legacy(rows, opening);
        expect(now.lines.length, old.lines.length);
        for (var i = 0; i < rows.length; i++) {
          expect(now.lines[i].balance, old.lines[i].balance);
        }
        expect(now.closing, old.closing);
      }
    });
  });

  group('fetchStatement: الافتتاحي والفلاتر من ERPNext (repository حقيقي)', () {
    test(
      'مع فترة: get_balance_on لليوم السابق للبداية، وفلاتر التاريخ والترتيب',
      () async {
        final f = await fakeApi((r) {
          if (r.pathText.endsWith('get_balance_on')) return {'message': 1000};
          return {
            'data': [
              gl('2026-01-05', 'Sales Invoice', 'SINV-1', debit: 500),
              gl('2026-01-07', 'Payment Entry', 'PE-1', credit: 200),
            ],
          };
        });
        final repo = ErpStatementRepository(
          f.api,
          ErpCustomerRepository(f.api),
        );

        final s = await repo.fetchStatement(
          'CUST-001',
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 1, 31),
        );

        final list = f.sent.first;
        expect(list.pathText, 'api/resource/GL Entry');
        expect(list.query['order_by'], 'posting_date asc, creation asc');
        expect(
          list.query['filters'],
          '[["party_type","=","Customer"],["party","=","CUST-001"],'
          '["company","=","Ramallah Tools Co."],["is_cancelled","=",0],'
          '["posting_date",">=","2026-01-01"],["posting_date","<=","2026-01-31"]]',
        );
        final balance = f.sent[1];
        expect(balance.query, {
          'party_type': 'Customer',
          'party': 'CUST-001',
          'company': 'Ramallah Tools Co.',
          'date': '2025-12-31',
        });
        expect(s.opening, 1000);
        expect(s.lines.map((l) => l.balance), [1500, 1300]);
        expect(s.closing, 1300);
      },
    );

    test('كل الفترات: لا طلب رصيد افتتاحي، والافتتاحي 0', () async {
      final f = await fakeApi(
        (_) => {
          'data': [gl('2026-01-05', 'Sales Invoice', 'SINV-1', debit: 80)],
        },
      );
      final repo = ErpStatementRepository(f.api, ErpCustomerRepository(f.api));
      final s = await repo.fetchStatement('CUST-001');
      expect(f.sent.length, 1);
      expect(s.opening, 0);
      expect(s.closing, 80);
    });

    test('كل الصفحات تُجلب (100 صف لكل طلب) والرصيد يستمر عبرها', () async {
      final f = await fakeApi((r) {
        final start = int.parse(r.query['limit_start'] ?? '0');
        final count = start == 0 ? 100 : 30;
        return {
          'data': [
            for (var i = 0; i < count; i++)
              gl('2026-01-01', 'Sales Invoice', 'S-${start + i}', debit: 1),
          ],
        };
      });
      final repo = ErpStatementRepository(f.api, ErpCustomerRepository(f.api));
      final s = await repo.fetchStatement('CUST-001');
      expect(f.sent.length, 2);
      expect(s.lines.length, 130);
      expect(s.closing, 130);
    });
  });
}
