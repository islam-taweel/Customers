import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/constants/returns_strings.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/return_models.dart';
import 'erp_cache_store.dart';
import 'erp_lookup_repository.dart';

/// نتيجة قراءة مع وقت حفظ النسخة المحلية إن كانت منها.
class CachedResult<T> {
  final T data;

  /// null = جاءت للتو من ERPNext، وإلا وقت حفظ النسخة المحلية
  final DateTime? savedAt;

  const CachedResult(this.data, {this.savedAt});
}

/// قسم «مردود المبيعات» في ERPNext:
/// 1) العملاء وفواتيرهم المعتمدة، 2) أصناف الفاتورة وما بقي قابلًا للإرجاع،
/// 3) إشعار دائن مسودة، 4) إرجاع البضاعة للمخزون (Delivery Note مسودة)،
/// 5) رد المال بعد الاعتماد (Payment Entry مسودة)، 6) المرتجعات بانتظار الاعتماد.
class ErpSalesReturnsRepository {
  ErpSalesReturnsRepository(this._api, this._cache, this._lookup);

  final ErpApiClient _api;
  final ErpCacheStore _cache;
  final ErpLookupRepository _lookup;

  static const _customersKey = 'sales_returns:customers';

  static const _invoiceReturnMethod =
      'erpnext.accounts.doctype.sales_invoice.sales_invoice.make_sales_return';
  static const _deliveryReturnMethod =
      'erpnext.stock.doctype.delivery_note.delivery_note.make_sales_return';
  static const _paymentEntryMethod =
      'erpnext.accounts.doctype.payment_entry.payment_entry.get_payment_entry';

  // ───────────────────────── 1) العملاء والفواتير ─────────────────────────

  Future<CachedResult<List<ReturnCustomer>>> fetchCustomers() async {
    try {
      final rows = await _api.getAll(
        'Sales Invoice',
        fields: ['customer', 'customer_name', 'posting_date'],
        filters: [
          ['docstatus', '=', 1],
          ['is_return', '=', 0],
        ],
      );
      await _cache.write(_customersKey, jsonEncode(rows));
      return CachedResult(ReturnCustomer.fromInvoiceRows(rows));
    } on ErpApiException catch (e) {
      final cached = await _readCached(_customersKey);
      if (cached == null || e.type == ErpErrorType.sessionExpired) rethrow;
      return CachedResult(
        ReturnCustomer.fromInvoiceRows(cached.rows),
        savedAt: cached.savedAt,
      );
    }
  }

  /// فواتير العميل المعتمدة (غير المرتجعات)، الأحدث أولًا. لا تصفية على الحالة:
  /// المرتجعة جزئيًا («Credit Note Issued») يبقى فيها ما يُرجع.
  Future<List<ReturnInvoice>> fetchInvoices(String customer) async {
    final rows = await _api.getAll(
      'Sales Invoice',
      fields: [
        'name',
        'posting_date',
        'currency',
        'grand_total',
        'outstanding_amount',
        'status',
      ],
      filters: [
        ['customer', '=', customer],
        ['docstatus', '=', 1],
        ['is_return', '=', 0],
      ],
    );
    return [for (final r in rows) ReturnInvoice.fromJson(r)]
      ..sort((a, b) {
        final byDate = b.postingDate.compareTo(a.postingDate);
        return byDate != 0 ? byDate : b.name.compareTo(a.name);
      });
  }

  // ───────────────────────── 2) أصناف الفاتورة ─────────────────────────

  /// بنود الفاتورة مع ما أُرجع من كل صف في المرتجعات المعتمدة السابقة.
  Future<List<ReturnableItem>> fetchReturnableItems(String invoice) async {
    final doc = await _api.getDoc('Sales Invoice', invoice);
    final rows = _rows(doc['items']);

    // المرتجعات المعتمدة السابقة: كميتها سالبة، تُطابق بـ sales_invoice_item
    final returns = await _api.getAll(
      'Sales Invoice',
      fields: ['name'],
      filters: [
        ['return_against', '=', invoice],
        ['is_return', '=', 1],
        ['docstatus', '=', 1],
      ],
    );
    final returned = <String, double>{};
    for (final r in returns) {
      final ret = await _api.getDoc('Sales Invoice', r['name'].toString());
      for (final row in _rows(ret['items'])) {
        final original = row['sales_invoice_item']?.toString() ?? '';
        if (original.isEmpty) continue;
        final qty = (row['qty'] as num?)?.toDouble() ?? 0;
        returned[original] = (returned[original] ?? 0) + qty.abs();
      }
    }

    final wholeUoms = await _wholeNumberUoms({
      for (final row in rows) row['uom']?.toString() ?? '',
    }..remove(''));

    return [
      for (final row in rows)
        ReturnableItem.fromJson(
          row,
          returnedQty: returned[row['name']?.toString()] ?? 0,
          wholeNumber: wholeUoms.contains(row['uom']?.toString()),
        ),
    ];
  }

  /// الوحدات التي لا تقبل كسورًا من بين [uoms].
  Future<Set<String>> _wholeNumberUoms(Set<String> uoms) async {
    if (uoms.isEmpty) return {};
    final rows = await _api.getAll(
      'UOM',
      fields: ['name', 'must_be_whole_number'],
      filters: [
        ['name', 'in', uoms.toList()],
      ],
    );
    return {
      for (final r in rows)
        if ((r['must_be_whole_number'] as num?)?.toInt() == 1)
          r['name'].toString(),
    };
  }

  // ───────────────────── 3) و 4) إنشاء المرتجع (مسودات) ─────────────────────

  /// [quantities]: رقم صف الفاتورة → الكمية المرجعة (موجبة).
  /// يحفظ إشعار الدائن مسودة، ثم إرجاع البضاعة لكل إذن تسليم. يرمي
  /// [ErpApiException] إن فشل إشعار الدائن؛ فشل إذن تسليم يُعاد في [CreatedReturn.stockErrors].
  Future<CreatedReturn> createReturn({
    required String invoice,
    required List<ReturnableItem> items,
    required Map<String, double> quantities,
    String? reason,
  }) async {
    final chosen = {
      for (final e in quantities.entries)
        if (e.value > 0) e.key: e.value,
    };
    if (chosen.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);

    // 3) إشعار الدائن: نبقي الصفوف المرجعة فقط بكمية سالبة
    final creditNote = await _makeReturn(_invoiceReturnMethod, invoice);
    creditNote['items'] = [
      for (final row in _rows(creditNote['items']))
        if (chosen.containsKey(row['sales_invoice_item']?.toString()))
          {...row, 'qty': -chosen[row['sales_invoice_item'].toString()]!},
    ];
    final cleanReason = reason?.trim() ?? '';
    if (cleanReason.isNotEmpty) creditNote['remarks'] = cleanReason;

    final created = await _api.postDoc('Sales Invoice', creditNote);
    final creditNoteName = created['name']?.toString() ?? '';
    if (creditNoteName.isEmpty) {
      throw const ErpApiException(ErpErrorType.badResponse);
    }

    // 4) إرجاع البضاعة: لكل إذن تسليم، الكميات مطابقة لإشعار الدائن (عبر dn_detail)
    final byDelivery = <String, Map<String, double>>{};
    for (final item in items) {
      final qty = chosen[item.rowName];
      if (qty == null || item.deliveryNote.isEmpty || item.dnDetail.isEmpty) {
        continue;
      }
      final rows = byDelivery[item.deliveryNote] ??= {};
      rows[item.dnDetail] = (rows[item.dnDetail] ?? 0) + qty;
    }

    final stockReturns = <String>[];
    final stockErrors = <String, String>{};
    for (final entry in byDelivery.entries) {
      try {
        final dn = await _makeReturn(_deliveryReturnMethod, entry.key);
        dn['items'] = [
          for (final row in _rows(dn['items']))
            if (entry.value.containsKey(row['dn_detail']?.toString()))
              {...row, 'qty': -entry.value[row['dn_detail'].toString()]!},
        ];
        final saved = await _api.postDoc('Delivery Note', dn);
        stockReturns.add(saved['name']?.toString() ?? '');
      } catch (e) {
        debugPrint('إرجاع البضاعة من ${entry.key} فشل: $e');
        stockErrors[entry.key] = e is ErpApiException
            ? (e.detail ?? e.type.name)
            : e.toString();
      }
    }

    return CreatedReturn(
      creditNote: creditNoteName,
      stockReturns: stockReturns,
      stockErrors: stockErrors,
    );
  }

  /// مستند مرتجع جاهز من ERPNext (كل الأصناف بكميتها الأصلية سالبة)، بلا مفاتيح __.
  Future<Map<String, dynamic>> _makeReturn(String method, String source) async {
    final made = await _api.getMethod(method, {'source_name': source});
    final message = made['message'];
    if (message is! Map) throw const ErpApiException(ErpErrorType.badResponse);
    return _cleanDoc(message);
  }

  // ───────────────────── 6) المرتجعات بانتظار الاعتماد ─────────────────────

  Future<List<PendingReturn>> fetchPending() async {
    final credit = await _api.getAll(
      PendingReturn.creditNote,
      fields: [
        'name',
        'customer',
        'customer_name',
        'return_against',
        'grand_total',
        'currency',
        'remarks',
      ],
      filters: [
        ['is_return', '=', 1],
        ['docstatus', '=', 0],
      ],
    );
    final stock = await _api.getAll(
      PendingReturn.stockReturn,
      fields: [
        'name',
        'customer',
        'customer_name',
        'return_against',
        'grand_total',
        'currency',
      ],
      filters: [
        ['is_return', '=', 1],
        ['docstatus', '=', 0],
      ],
    );
    return [
      for (final r in credit) PendingReturn.fromJson(PendingReturn.creditNote, r),
      for (final r in stock) PendingReturn.fromJson(PendingReturn.stockReturn, r),
    ];
  }

  Future<void> approve(PendingReturn r) =>
      _api.putDoc(r.doctype, r.name, {'docstatus': 1});

  Future<void> reject(PendingReturn r) => _api.deleteDoc(r.doctype, r.name);

  // ───────────────────── 5) رد المال بعد اعتماد إشعار الدائن ─────────────────────

  /// ما يمكن رده من إشعار دائن معتمد، وصافي ما على العميل. إن كان العميل ما زال
  /// مدينًا فإشعار الدائن يُنقص دينه ولا يُرد مال.
  Future<RefundCheck> checkRefund(PendingReturn creditNote) async {
    final doc = await _api.getDoc('Sales Invoice', creditNote.name);
    final outstanding = (doc['outstanding_amount'] as num?)?.toDouble() ?? 0;

    final rows = await _api.getAll(
      'Sales Invoice',
      fields: ['outstanding_amount'],
      filters: [
        ['customer', '=', creditNote.customer],
        ['docstatus', '=', 1],
      ],
    );
    var customerOutstanding = 0.0;
    for (final r in rows) {
      customerOutstanding += (r['outstanding_amount'] as num?)?.toDouble() ?? 0;
    }

    return RefundCheck(
      refundable: outstanding < 0 ? -outstanding : 0,
      customerOutstanding: customerOutstanding,
      currency: doc['currency']?.toString() ?? creditNote.currency,
    );
  }

  Future<List<String>> fetchModesOfPayment() => _lookup.fetchModesOfPayment();

  /// يحفظ دفعة رد (Pay) مسودة على إشعار الدائن. يعيد رقمها.
  Future<String> saveRefund({
    required String creditNote,
    required String modeOfPayment,
    String? referenceNo,
    DateTime? referenceDate,
  }) async {
    final made = await _api.getMethod(_paymentEntryMethod, {
      'dt': 'Sales Invoice',
      'dn': creditNote,
    });
    final message = made['message'];
    if (message is! Map) throw const ErpApiException(ErpErrorType.badResponse);
    final entry = _cleanDoc(message);
    if (entry['payment_type']?.toString() != 'Pay') {
      throw ErpApiException(
        ErpErrorType.server,
        detail: ReturnsStrings.refundNotPay,
      );
    }

    final mode = await _api.getDoc('Mode of Payment', modeOfPayment);
    final paidFrom = _defaultAccount(mode['accounts']);
    if (paidFrom.isEmpty) {
      throw ErpApiException(
        ErpErrorType.server,
        detail: ReturnsStrings.refundNoAccount(modeOfPayment),
      );
    }
    entry['mode_of_payment'] = modeOfPayment;
    entry['paid_from'] = paidFrom;
    final refNo = referenceNo?.trim() ?? '';
    if (refNo.isNotEmpty) entry['reference_no'] = refNo;
    if (referenceDate != null) entry['reference_date'] = _date(referenceDate);

    final created = await _api.postDoc('Payment Entry', entry);
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    return name;
  }

  // ───────────────────────── أدوات ─────────────────────────

  /// حساب طريقة الدفع الافتراضي للشركة الحالية (فارغ إن لم يوجد)
  String _defaultAccount(Object? accounts) {
    if (accounts is! List) return '';
    for (final row in accounts) {
      if (row is Map && row['company']?.toString() == ErpConfig.company) {
        return row['default_account']?.toString() ?? '';
      }
    }
    return '';
  }

  static List<Map<String, dynamic>> _rows(Object? value) => [
        if (value is List)
          for (final r in value) Map<String, dynamic>.from(r as Map),
      ];

  /// يحذف مفاتيح __ (حتى داخل صفوف الجداول) فلا يرفضها الحفظ
  static Map<String, dynamic> _cleanDoc(Map message) {
    Object? clean(Object? v) {
      if (v is Map) {
        return {
          for (final e in v.entries)
            if (!e.key.toString().startsWith('__')) e.key.toString(): clean(e.value),
        };
      }
      if (v is List) return [for (final x in v) clean(x)];
      return v;
    }

    return Map<String, dynamic>.from(clean(message)! as Map);
  }

  /// YYYY-MM-DD كما يطلبها ERPNext
  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<({List<Map<String, dynamic>> rows, DateTime savedAt})?> _readCached(
    String key,
  ) async {
    final entry = await _cache.read(key);
    if (entry == null) return null;
    try {
      final list = jsonDecode(entry.json) as List;
      return (
        rows: [for (final r in list) Map<String, dynamic>.from(r as Map)],
        savedAt: entry.savedAt,
      );
    } catch (e) {
      debugPrint('نسخة مردود المبيعات المحفوظة تالفة ($key): $e');
      return null;
    }
  }
}
