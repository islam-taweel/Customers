import 'package:customer/core/constants/app_strings.dart';
import 'package:customer/modules/collections/controllers/customer_collections_controller.dart';
import 'package:customer/modules/collections/repository/erp_payment_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../support/fakes.dart';

class FakeHost implements CustomerCollectionsHost {
  String? id = 'CUST-001';
  final recorded = <Map<String, dynamic>>[];
  final listeners = <VoidCallback>[];

  @override
  Future<String?> erpId() async => id;

  @override
  Future<void> recordApprovedPayment(Map<String, dynamic> doc) async =>
      recorded.add(doc);

  @override
  void addDraftSavedListener(VoidCallback l) => listeners.add(l);

  @override
  void removeDraftSavedListener(VoidCallback l) => listeners.remove(l);
}

Map<String, dynamic> pe(String name, int docstatus, double amount) => {
  'name': name,
  'posting_date': '2026-11-18',
  'docstatus': docstatus,
  'received_amount': amount,
  'paid_to_account_currency': 'ILS',
  'paid_amount': amount,
  'paid_from_account_currency': 'ILS',
  'mode_of_payment': 'Cash',
  'remarks': '',
};

/// R3 — مسودات تحصيل العميل: العرض، الاعتماد، الحذف (نفس طلبات ERPNext ورسائلها)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  late FakeHost host;
  setUp(() => host = FakeHost());

  test('عميل محلي: لا طلب لـ ERPNext ولا تبويبات', () async {
    final f = await fakeApi((_) => {'data': []});
    host.id = null;
    final c = Get.put(
      CustomerCollectionsController(ErpPaymentRepository(f.api), host),
    );
    await pumpEventQueue();
    expect(c.isErpCustomer.value, isFalse);
    expect(f.sent, isEmpty);
  });

  test('التحميل: طلب واحد بنفس الفلاتر، والتقسيم مسودة/معتمدة', () async {
    final f = await fakeApi(
      (_) => {
        'data': [pe('PE-3', 0, 40), pe('PE-2', 1, 100), pe('PE-1', 0, 5)],
      },
    );
    final c = Get.put(
      CustomerCollectionsController(ErpPaymentRepository(f.api), host),
    );
    await pumpEventQueue();

    expect(f.sent.length, 1);
    final r = f.sent.single;
    expect(r.pathText, 'api/resource/Payment Entry');
    expect(
      r.query['filters'],
      '[["party_type","=","Customer"],["party","=","CUST-001"],'
      '["payment_type","=","Receive"],["docstatus","in",[0,1]]]',
    );
    expect(r.query['order_by'], 'posting_date desc, creation desc');
    expect(c.isErpCustomer.value, isTrue);
    expect(c.drafts.map((p) => p.name), ['PE-3', 'PE-1']);
    expect(c.approved.single.receivedAmount, 100);
  });

  test(
    'حفظ مسودة من «إضافة دفعة» يعيد التحميل، وبعد الإغلاق لا يستمع',
    () async {
      final f = await fakeApi((_) => {'data': []});
      final c = Get.put(
        CustomerCollectionsController(ErpPaymentRepository(f.api), host),
      );
      await pumpEventQueue();
      expect(host.listeners.length, 1);

      for (final l in [...host.listeners]) {
        l();
      }
      await pumpEventQueue();
      expect(f.sent.length, 2);

      Get.delete<CustomerCollectionsController>();
      expect(host.listeners, isEmpty);
      expect(c.isClosed, isTrue);
    },
  );

  test(
    'حذف مسودة: DELETE واحد ثم إعادة تحميل؛ المحذوفة أصلًا (404) نجاح',
    () async {
      var deleted = false;
      final f = await fakeApi((r) {
        if (r.method == 'DELETE') {
          if (deleted) return http.Response('{}', 404);
          deleted = true;
          return {'message': 'ok'};
        }
        return {
          'data': [if (!deleted) pe('PE-9', 0, 30)],
        };
      });
      final c = Get.put(
        CustomerCollectionsController(ErpPaymentRepository(f.api), host),
      );
      await pumpEventQueue();
      final draft = c.drafts.single;

      expect(await c.cancel(draft), isNull);
      expect(f.sent.map((s) => '$s'), [
        'GET api/resource/Payment Entry',
        'DELETE api/resource/Payment Entry/PE-9',
        'GET api/resource/Payment Entry',
      ]);
      expect(c.drafts, isEmpty);
      expect(await c.cancel(draft), isNull, reason: '404 = محذوفة');
    },
  );

  test(
    'اعتماد: GET المستند ← frappe.client.submit به، ثم السجل المحلي',
    () async {
      final f = await fakeApi((r) {
        if (r.method == 'GET' &&
            r.pathText == 'api/resource/Payment Entry/PE-5') {
          return {
            'data': {...pe('PE-5', 0, 75), 'modified': '2026-11-18 10:00:00'},
          };
        }
        if (r.pathText == 'api/method/frappe.client.submit') {
          final doc = (r.body! as Map)['doc'] as Map;
          return {
            'message': {...doc, 'docstatus': 1},
          };
        }
        return {
          'data': [pe('PE-5', 0, 75)],
        };
      });
      final c = Get.put(
        CustomerCollectionsController(ErpPaymentRepository(f.api), host),
      );
      await pumpEventQueue();

      final error = await c.approve(c.drafts.single);
      expect(error, isNull);
      final submit = f.sent.singleWhere((s) => s.pathText.endsWith('submit'));
      expect((submit.body! as Map)['doc']['modified'], '2026-11-18 10:00:00');
      expect(host.recorded.single['name'], 'PE-5');
      expect(host.recorded.single['docstatus'], 1);
      expect(f.sent.last.pathText, 'api/resource/Payment Entry');
    },
  );

  test('رفض الاعتماد: الرسالة العامة + نص ERPNext، ولا تسجيل محلي', () async {
    final f = await fakeApi((r) {
      if (r.pathText.endsWith('submit')) {
        return erpError(417, 'Allocated amount cannot be greater');
      }
      if (r.pathText == 'api/resource/Payment Entry/PE-5') {
        return {'data': pe('PE-5', 0, 75)};
      }
      return {
        'data': [pe('PE-5', 0, 75)],
      };
    });
    final c = Get.put(
      CustomerCollectionsController(ErpPaymentRepository(f.api), host),
    );
    await pumpEventQueue();

    final error = await c.approve(c.drafts.single);
    expect(
      error,
      '${AppStrings.paymentApproveFailed}\nAllocated amount cannot be greater',
    );
    expect(host.recorded, isEmpty);
    expect(c.busy, isEmpty);
  });

  test('ضغطتان متتاليتان على نفس المسودة ← طلب واحد', () async {
    final f = await fakeApi((r) {
      if (r.method == 'DELETE') return {'message': 'ok'};
      return {
        'data': [pe('PE-7', 0, 10)],
      };
    });
    final c = Get.put(
      CustomerCollectionsController(ErpPaymentRepository(f.api), host),
    );
    await pumpEventQueue();
    final p = c.drafts.single;

    final first = c.cancel(p);
    expect(c.isBusy(p), isTrue);
    expect(await c.cancel(p), isNull);
    await first;
    expect(f.sent.where((s) => s.method == 'DELETE').length, 1);
  });

  test('انقطاع الشبكة عند التحميل: رسالة خطأ دون انهيار', () async {
    final f = await fakeApi((_) => throw http.ClientException('offline'));
    final c = Get.put(
      CustomerCollectionsController(ErpPaymentRepository(f.api), host),
    );
    await pumpEventQueue();
    expect(c.error.value, isNotNull);
    expect(c.loading.value, isFalse);
    expect(c.payments, isEmpty);
  });
}
