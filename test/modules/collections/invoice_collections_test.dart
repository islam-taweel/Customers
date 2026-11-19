import 'package:customer/core/constants/app_strings.dart';
import 'package:customer/data/api/erp_api_client.dart';
import 'package:customer/data/models/sales_invoice.dart';
import 'package:customer/modules/collections/controllers/invoice_collections_controller.dart';
import 'package:customer/modules/collections/controllers/payment_sheet_controller.dart';
import 'package:customer/modules/collections/models/collection_models.dart';
import 'package:customer/modules/collections/repository/invoice_collections_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../support/fakes.dart';

/// R3 — تحصيل فاتورة (مسودة Payment Entry): نفس الطلبات والبيانات المرسلة إلى
/// ERPNext، نفس رسائل الخطأ، ونفس قواعد التحقق في نافذة الدفع.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  final invoice = SalesInvoice.fromJson(
    invoiceRow('ACC-SINV-2026-00010', total: 250, outstanding: 250),
  );

  /// ERPNext: get_payment_entry ← Mode of Payment ← حفظ المسودة
  Object? erp(Sent r) {
    if (r.pathText.endsWith('get_payment_entry')) {
      return {
        'message': {
          'doctype': 'Payment Entry',
          'payment_type': 'Receive',
          'party': 'CUST-001',
          'paid_amount': 120.0,
          '__islocal': 1,
          'references': [
            {
              'reference_name': 'ACC-SINV-2026-00010',
              'allocated_amount': 120.0,
              '__unsaved': 1,
            },
          ],
        },
      };
    }
    if (r.pathText.startsWith('api/resource/Mode of Payment/')) {
      return {
        'data': {
          'name': r.path.last,
          'accounts': [
            {'company': 'Other Co', 'default_account': 'Wrong - X'},
            {'company': 'Ramallah Tools Co.', 'default_account': 'Bank - RTC'},
          ],
        },
      };
    }
    if (r.method == 'POST' && r.pathText == 'api/resource/Payment Entry') {
      return {
        'data': {'name': 'ACC-PAY-2026-00077'},
      };
    }
    return {'data': []};
  }

  group('InvoiceCollectionsController.pay (مع repository حقيقي)', () {
    test(
      'مسودة تحصيل: نفس الطلبات والحقول، وتُحفظ معلّقة على الفاتورة',
      () async {
        final f = await fakeApi(erp);
        final cache = MemoryCache();
        final repo = ErpInvoiceCollectionsRepository(
          f.api,
          cache,
          FakeLookup(),
        );
        final c = Get.put(InvoiceCollectionsController(repo));

        final error = await c.pay(
          invoice,
          amount: 120,
          modeOfPayment: 'Cheque',
          note: '  دفعة أولى ',
          details: PaymentDetails(
            referenceNo: ' CHQ-55 ',
            referenceDate: DateTime(2026, 11, 18),
            extra: const {
              'custom_cheque_bank': 'Bank of Palestine',
              'custom_drawer_name': ' ',
            },
          ),
        );

        expect(error, isNull);
        expect(f.sent.map((s) => '$s'), [
          'GET api/method/erpnext.accounts.doctype.payment_entry.payment_entry.get_payment_entry',
          'GET api/resource/Mode of Payment/Cheque',
          'POST api/resource/Payment Entry',
        ]);
        expect(f.sent[0].query, {
          'dt': 'Sales Invoice',
          'dn': 'ACC-SINV-2026-00010',
          'party_amount': '120.00',
        });

        final body = f.sent[2].body! as Map<String, dynamic>;
        // مفاتيح __ محذوفة (حتى داخل الجداول)، والباقي كما أرسله ERPNext
        expect(body.containsKey('__islocal'), isFalse);
        expect((body['references'] as List).single, {
          'reference_name': 'ACC-SINV-2026-00010',
          'allocated_amount': 120.0,
        });
        expect(body['paid_amount'], 120.0);
        expect(body['mode_of_payment'], 'Cheque');
        expect(body['paid_to'], 'Bank - RTC', reason: 'حساب الشركة الحالية');
        expect(body['remarks'], 'دفعة أولى');
        expect(body['reference_no'], 'CHQ-55');
        expect(body['reference_date'], '2026-11-18');
        expect(body['custom_cheque_bank'], 'Bank of Palestine');
        expect(body.containsKey('custom_drawer_name'), isFalse);
        expect(body.containsKey('docstatus'), isFalse, reason: 'مسودة فقط');

        // معلّقة على الفاتورة، ومحفوظة محليًا بنفس المفتاح القديم
        expect(c.pendingAmount('ACC-SINV-2026-00010'), 120);
        expect(cache.data.keys, ['sales_invoices:pending_payments']);
        final saved = await repo.readPending();
        expect(saved.single.entry, 'ACC-PAY-2026-00077');
        expect(saved.single.currency, 'ILS');
      },
    );

    test('انقطاع الشبكة ← «يحتاج اتصالًا» ولا شيء معلّق', () async {
      final f = await fakeApi((_) => throw http.ClientException('offline'));
      final repo = ErpInvoiceCollectionsRepository(
        f.api,
        MemoryCache(),
        FakeLookup(),
      );
      final c = Get.put(InvoiceCollectionsController(repo));

      final error = await c.pay(invoice, amount: 10, modeOfPayment: 'Cash');
      expect(error, AppStrings.draftNeedsConnection);
      expect(c.pending, isEmpty);
    });

    test('رفض ERPNext (417) ← الرسالة العامة + نص ERPNext', () async {
      final f = await fakeApi((r) {
        if (r.method == 'POST') {
          return erpError(
            417,
            'Paid Amount cannot be greater than outstanding',
          );
        }
        return erp(r);
      });
      final repo = ErpInvoiceCollectionsRepository(
        f.api,
        MemoryCache(),
        FakeLookup(),
      );
      final c = Get.put(InvoiceCollectionsController(repo));

      final error = await c.pay(invoice, amount: 10, modeOfPayment: 'Cheque');
      expect(error, startsWith('${AppStrings.paymentSaveFailed}\n'));
      expect(error, contains('Paid Amount cannot be greater'));
      expect(c.pending, isEmpty);
    });

    test('طريقة دفع بلا حساب للشركة ← خطأ واضح ولا يُرسل الحفظ', () async {
      final f = await fakeApi((r) {
        if (r.pathText.endsWith('Mode of Payment/Cash')) {
          return {
            'data': {'name': 'Cash', 'accounts': []},
          };
        }
        return erp(r);
      });
      final repo = ErpInvoiceCollectionsRepository(
        f.api,
        MemoryCache(),
        FakeLookup(),
      );
      final c = Get.put(InvoiceCollectionsController(repo));

      final error = await c.pay(invoice, amount: 10, modeOfPayment: 'Cash');
      expect(error, contains(AppStrings.paymentNoAccountForMode('Cash')));
      expect(f.sent.where((s) => s.method == 'POST'), isEmpty);
    });

    test(
      'reconcile: يُبقي ما زال مسودة فقط، وفشل الاتصال لا يمسح شيئًا',
      () async {
        var offline = false;
        final f = await fakeApi((r) {
          if (offline) throw http.ClientException('offline');
          return {
            'data': [
              {'name': 'PE-1', 'docstatus': 0},
              {'name': 'PE-2', 'docstatus': 1},
            ],
          };
        });
        final cache = MemoryCache();
        final repo = ErpInvoiceCollectionsRepository(
          f.api,
          cache,
          FakeLookup(),
        );
        cache.write(
          'sales_invoices:pending_payments',
          '[{"invoice":"A","entry":"PE-1","amount":5,"currency":"ILS"},'
              '{"invoice":"A","entry":"PE-2","amount":7,"currency":"ILS"}]',
        );
        final c = Get.put(InvoiceCollectionsController(repo));
        await c.loadPending();
        expect(c.pendingAmount('A'), 12);

        offline = true;
        await c.reconcile();
        expect(c.pendingAmount('A'), 12);

        offline = false;
        await c.reconcile();
        expect(c.pending.map((p) => p.entry), ['PE-1']);
        expect(f.sent.last.query['filters'], '[["name","in",["PE-1","PE-2"]]]');
      },
    );
  });

  group('PaymentSheetController (قواعد التحقق كما كانت)', () {
    late FakeLookup lookup;
    late List<Sent> sent;

    Future<PaymentSheetController> sheet() async {
      final f = await fakeApi(erp);
      sent = f.sent;
      final repo = ErpInvoiceCollectionsRepository(
        f.api,
        MemoryCache(),
        lookup,
      );
      final collections = Get.put(InvoiceCollectionsController(repo));
      final c = Get.put(PaymentSheetController(invoice, collections));
      await pumpEventQueue();
      return c;
    }

    setUp(() => lookup = FakeLookup());

    test(
      'طريقة واحدة تُختار تلقائيًا، وفشل التحميل يظهر مع إعادة المحاولة',
      () async {
        var c = await sheet();
        expect(c.mode.value, 'Cash');
        expect(lookup.calls, 1, reason: 'طلب واحد فقط عند الفتح');
        Get.reset();

        lookup = FakeLookup()
          ..failWith = const ErpApiException(ErpErrorType.network);
        c = await sheet();
        expect(c.modesFailed.value, isTrue);
        expect(c.modesLoading.value, isFalse);
        lookup.failWith = null;
        await c.loadModes();
        expect(c.modesFailed.value, isFalse);
      },
    );

    test('تحذيرات المبلغ: فارغ، نص، صفر، أكثر من المستحق', () async {
      final c = await sheet();
      expect(c.amountWarning, isNull);
      c.amountText.value = 'abc';
      expect(c.amountWarning, AppStrings.payAmountRequired);
      c.amountText.value = '0';
      expect(c.amountWarning, AppStrings.payAmountPositive);
      c.amountText.value = '250.01';
      expect(c.amountWarning, AppStrings.payAmountExceeds(c.dueText));
      c.amountText.value = '250.004';
      expect(c.amountWarning, isNull, reason: 'هامش 0.005 كما كان');
      // أرقام عربية
      c.amountText.value = '١٢٠';
      expect(c.amount, 120);
      expect(c.canSave, isTrue);
    });

    test(
      'الشيك يحتاج رقمًا وتاريخًا وبنكًا وساحبًا؛ البطاقة 4 أرقام ونوعًا',
      () async {
        lookup.modes = ['Cash', 'Cheque', 'Credit Card', 'Bank Transfer'];
        final c = await sheet();
        c.amountText.value = '100';
        expect(c.canSave, isFalse, reason: 'لم تُختر طريقة');

        c.selectMode('Cheque');
        expect(c.kind, PaymentModeKind.cheque);
        expect(c.canSave, isFalse);
        c.referenceNo.value = '55';
        c.referenceDate.value = DateTime(2026, 11, 18);
        c.chequeBank.value = 'BOP';
        expect(c.canSave, isFalse);
        c.drawerName.value = 'Sami';
        expect(c.canSave, isTrue);

        c.selectMode('Credit Card');
        expect(c.kind, PaymentModeKind.card);
        c.cardLast4.value = '12';
        expect(c.last4Valid, isFalse);
        c.cardLast4.value = '١٢٣٤';
        c.cardBrand.value = 'Visa';
        expect(c.canSave, isTrue);
        expect(c.details().extra, {
          'custom_card_last4': '1234',
          'custom_card_brand': 'Visa',
        });

        c.selectMode('Bank Transfer');
        expect(c.kind, PaymentModeKind.transfer);
        expect(paymentModeKindOf('Wire'), PaymentModeKind.other);
        expect(paymentModeKindOf('cash'), PaymentModeKind.cash);
      },
    );

    test('الحفظ: النجاح يُبقي «جارٍ» حتى الإغلاق، والفشل يعرض السبب', () async {
      final c = await sheet();
      c.amountText.value = '50';
      c.note.value = '  ';
      expect(await c.save(), isTrue);
      expect(c.saving.value, isTrue);
      final post = sent.singleWhere((s) => s.method == 'POST');
      expect(
        (post.body! as Map).containsKey('remarks'),
        isFalse,
        reason: 'ملاحظة فارغة لا تُرسل',
      );
    });

    test(
      'فشل الحفظ: يعود الزر ويظهر السبب، ولا حفظ مكرر أثناء «جارٍ»',
      () async {
        final f = await fakeApi((r) {
          if (r.method == 'POST') return erpError(417, 'Account is frozen');
          return erp(r);
        });
        final repo = ErpInvoiceCollectionsRepository(
          f.api,
          MemoryCache(),
          lookup,
        );
        final collections = Get.put(InvoiceCollectionsController(repo));
        final c = Get.put(PaymentSheetController(invoice, collections));
        await pumpEventQueue();
        c.amountText.value = '50';

        final first = c.save();
        expect(c.canSave, isFalse, reason: 'معطّل أثناء الحفظ');
        expect(await c.save(), isFalse);
        expect(await first, isFalse);
        expect(c.saving.value, isFalse);
        expect(c.saveError.value, contains('Account is frozen'));
        expect(f.sent.where((s) => s.method == 'POST').length, 1);
      },
    );
  });
}
