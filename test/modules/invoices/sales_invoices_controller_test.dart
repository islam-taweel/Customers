import 'dart:convert';

import 'package:customer/core/constants/app_strings.dart';
import 'package:customer/core/utils/formatters.dart';
import 'package:customer/data/models/sales_invoice.dart';
import 'package:customer/modules/collections/controllers/invoice_collections_controller.dart';
import 'package:customer/modules/collections/repository/invoice_collections_repository.dart';
import 'package:customer/modules/invoices/controllers/sales_invoices_controller.dart';
import 'package:customer/modules/invoices/repository/sales_invoices_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../support/fakes.dart';

/// R3 — قائمة الفواتير (غير المدفوعة وبقية التبويبات): نفس الطلب، نفس التصنيف،
/// والنسخة المحلية عند انقطاع الاتصال.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  late MemoryCache cache;
  late FakeLocalInvoices local;
  late bool offline;

  final rows = [
    invoiceRow('SINV-1', outstanding: 100, postingDate: '2026-11-01'),
    invoiceRow('SINV-2', outstanding: 40, postingDate: '2026-11-03'),
    invoiceRow(
      'SINV-3',
      outstanding: 0,
      status: 'Paid',
      postingDate: '2026-11-02',
    ),
    invoiceRow('SINV-4', docstatus: 0, status: 'Draft'),
    invoiceRow('SINV-5', docstatus: 0, status: 'Draft'),
  ];

  setUp(() {
    cache = MemoryCache();
    local = FakeLocalInvoices();
    offline = false;
  });

  Future<({SalesInvoicesController c, List<Sent> sent})> open() async {
    final f = await fakeApi((r) {
      if (offline) throw http.ClientException('offline');
      if (r.pathText == 'api/resource/Payment Entry') return {'data': []};
      return {'data': rows};
    });
    final collections = Get.put(
      InvoiceCollectionsController(
        ErpInvoiceCollectionsRepository(f.api, cache, FakeLookup()),
      ),
    );
    final c = Get.put(
      SalesInvoicesController(
        ErpSalesInvoicesRepository(f.api, cache),
        local,
        collections,
      ),
    );
    await pumpEventQueue();
    return (c: c, sent: f.sent);
  }

  test('طلب واحد عند الفتح، بنفس الحقول والفلتر، ثم الحفظ محليًا', () async {
    final o = await open();
    final invoiceRequests = o.sent.where(
      (s) => s.pathText == 'api/resource/Sales Invoice',
    );
    expect(invoiceRequests.length, 1, reason: 'لا طلبات مكررة');
    final r = invoiceRequests.single;
    expect(r.query['filters'], '[["docstatus","in",[0,1]]]');
    expect(jsonDecode(r.query['fields']!), contains('outstanding_amount'));
    expect(cache.data.containsKey('sales_invoices:all'), isTrue);
    expect(o.c.loaded.value, isTrue);
    expect(o.c.error.value, isNull);
  });

  test('التبويبات: غير مدفوعة / جزئيًا / مدفوعة / مسودة (والمفوترة من التطبيق ← غير مدفوعة)', () async {
    local.billed = {'SINV-5'};
    final c = (await open()).c;

    expect(c.byBucket(InvoiceBucket.unpaid).map((i) => i.name), [
      'SINV-5',
      'SINV-1',
    ]);
    expect(c.byBucket(InvoiceBucket.partlyPaid).single.name, 'SINV-2');
    expect(c.byBucket(InvoiceBucket.paid).single.name, 'SINV-3');
    expect(c.byBucket(InvoiceBucket.draft).single.name, 'SINV-4');
  });

  test('دون اتصال مع نسخة محفوظة: تُعرض مع تنبيه، بلا خطأ', () async {
    await open();
    Get.reset();
    offline = true;
    final c = (await open()).c;

    expect(c.loaded.value, isTrue);
    expect(c.byBucket(InvoiceBucket.unpaid).length, 1);
    expect(c.error.value, isNull);
    expect(
      c.notice.value,
      AppStrings.offlineNotice(formatDateTime(DateTime(2026, 11, 1, 9))),
    );
  });

  test('دون اتصال ولا نسخة: رسالة «لا توجد بيانات محفوظة»', () async {
    offline = true;
    final c = (await open()).c;
    expect(c.error.value, AppStrings.offlineNoCache);
    expect(c.loaded.value, isTrue);
    expect(c.refreshing.value, isFalse);
  });

  test('reload أثناء reload لا يرسل طلبًا ثانيًا', () async {
    final o = await open();
    o.sent.clear();
    final a = o.c.reload();
    final b = o.c.reload();
    await Future.wait([a, b]);
    expect(
      o.sent.where((s) => s.pathText == 'api/resource/Sales Invoice').length,
      1,
    );
  });
}
