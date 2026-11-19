import 'dart:convert';

import 'package:customer/data/api/erp_api_client.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:customer/data/repositories/erp_cache_store.dart';
import 'package:customer/data/repositories/erp_lookup_repository.dart';
import 'package:customer/data/repositories/invoice_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// نسخة محلية في الذاكرة بدل sqflite (نفس واجهة ErpCacheStore)
class MemoryCache implements ErpCacheStore {
  final data = <String, ({String json, DateTime savedAt})>{};

  @override
  Future<({String json, DateTime savedAt})?> read(String key) async =>
      data[key];

  @override
  Future<void> write(String key, String json) async =>
      data[key] = (json: json, savedAt: DateTime(2026, 11, 1, 9));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLookup implements ErpLookupRepository {
  List<String> modes = ['Cash'];
  Object? failWith;
  int calls = 0;

  @override
  Future<List<String>> fetchModesOfPayment() async {
    calls++;
    if (failWith != null) throw failWith!;
    return modes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalInvoices implements InvoiceRepository {
  Set<String> billed = {};

  @override
  Future<Set<String>> billedSalesInvoiceNames() async => billed;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// طلب مسجَّل (المسار مفكوك الترميز + الجسم كـ JSON إن وُجد)
class Sent {
  final String method;
  final List<String> path;
  final Map<String, String> query;
  final Object? body;

  Sent(this.method, this.path, this.query, this.body);

  String get pathText => path.join('/');

  @override
  String toString() => '$method $pathText';
}

typedef Reply = Object? Function(Sent r);

/// ErpApiClient حقيقي فوق MockClient: [reply] يعيد Map/List (200) أو http.Response
/// أو يرمي. فحص الجلسة (get_logged_user) يرد بمستخدم حقيقي.
Future<({ErpApiClient api, List<Sent> sent})> fakeApi(Reply reply) async {
  FlutterSecureStorage.setMockInitialValues({
    'erp_session_sid': 'abc',
    'erp_session_full_name': 'Ahmad',
  });
  final store = SessionStore();
  await store.load();
  final sent = <Sent>[];
  final mock = MockClient((request) async {
    if (request.url.path.contains('frappe.auth.get_logged_user')) {
      return http.Response(jsonEncode({'message': 'ahmad@rtc.ps'}), 200);
    }
    Object? body;
    if (request.body.isNotEmpty) {
      try {
        body = jsonDecode(request.body);
      } catch (_) {
        body = request.body;
      }
    }
    final r = Sent(
      request.method,
      request.url.pathSegments,
      request.url.queryParameters,
      body,
    );
    sent.add(r);
    final out = reply(r);
    if (out is http.Response) return out;
    return http.Response(
      jsonEncode(out ?? {}),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  return (api: ErpApiClient(session: store, client: mock), sent: sent);
}

/// رد خطأ من ERPNext بنص الاستثناء (كما يرسله frappe)
http.Response erpError(int status, String message) => http.Response(
  jsonEncode({
    'exception': 'frappe.exceptions.ValidationError: $message',
    '_server_messages': jsonEncode([
      jsonEncode({'message': message}),
    ]),
  }),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// فاتورة مبيعات كما يرسلها ERPNext في القائمة
Map<String, dynamic> invoiceRow(
  String name, {
  int docstatus = 1,
  double total = 100,
  double outstanding = 100,
  String status = 'Unpaid',
  String postingDate = '2026-11-10',
}) => {
  'name': name,
  'customer': 'CUST-001',
  'customer_name': 'Ahmad',
  'posting_date': postingDate,
  'due_date': '2026-11-30',
  'grand_total': total,
  'rounded_total': total,
  'base_grand_total': total,
  'base_rounded_total': total,
  'disable_rounded_total': 0,
  'outstanding_amount': outstanding,
  'status': status,
  'currency': 'ILS',
  'party_account_currency': 'ILS',
  'docstatus': docstatus,
  'total_advance': 0,
  'write_off_amount': 0,
  'base_write_off_amount': 0,
};
