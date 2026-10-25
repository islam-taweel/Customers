import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/purchase_models.dart';
import 'erp_cache_store.dart';
import 'erp_lookup_repository.dart';
import 'erp_sales_invoices_repository.dart' show PendingPayment;

/// كل ما يخص المشتريات في ERPNext: أوامر الشراء ← الاستلامات ← الفواتير ← الدفعات.
///
/// القراءة مباشرة من ERPNext. الكتابة تنتهي دائمًا **مسودة** (استلام، فاتورة، دفعة)
/// ويعتمدها المسؤول في ERPNext؛ أمر الشراء وحده يُعتمد من التطبيق.
class ErpPurchasesRepository {
  ErpPurchasesRepository(this._api, this._cache, this._lookup);

  final ErpApiClient _api;
  final ErpCacheStore _cache;
  final ErpLookupRepository _lookup;

  static const buyingPriceList = 'Standard Buying';

  static const _pendingKey = 'purchase_invoices:pending_payments';

  static const _orderMethodReceipt =
      'erpnext.buying.doctype.purchase_order.purchase_order.make_purchase_receipt';
  static const _receiptMethodInvoice =
      'erpnext.stock.doctype.purchase_receipt.purchase_receipt.make_purchase_invoice';
  static const _paymentEntryMethod =
      'erpnext.accounts.doctype.payment_entry.payment_entry.get_payment_entry';

  /// حقل أمر الشراء داخل جدول بنود المستند (صيغة Frappe لحقول الجداول الفرعية)
  static const _receiptPoField = '`tabPurchase Receipt Item`.purchase_order';
  static const _invoicePoField = '`tabPurchase Invoice Item`.purchase_order';

  // ───────────────────────── القراءة ─────────────────────────

  /// أوامر الشراء (مسودة ومعتمدة) مع حالة الاستلام المرتبط بكل منها.
  Future<List<PurchaseOrder>> fetchOrders() async {
    final rows = await _api.getAll(
      'Purchase Order',
      fields: [
        'name',
        'supplier',
        'supplier_name',
        'transaction_date',
        'schedule_date',
        'grand_total',
        'total_qty',
        'currency',
        'docstatus',
        'status',
        'per_received',
        'per_billed',
      ],
      filters: [
        ['docstatus', 'in', [0, 1]],
        ['status', 'not in', ['Closed', 'Cancelled']],
      ],
    );
    final links = await _receiptLinksByOrder();
    final orders = [
      for (final r in rows) PurchaseOrder.fromJson(r),
    ];
    orders.sort(_newestFirst((o) => o.transactionDate, (o) => o.name));
    return [
      for (final o in orders) o.withReceipt(links[o.name] ?? ReceiptLink.none),
    ];
  }

  /// لكل أمر شراء: هل له استلام مسودة (أو معتمد) في ERPNext.
  Future<Map<String, ReceiptLink>> _receiptLinksByOrder() async {
    final rows = await _api.getAll(
      'Purchase Receipt',
      fields: ['name', 'docstatus', _receiptPoField],
      filters: [
        ['docstatus', 'in', [0, 1]],
      ],
    );
    final result = <String, ReceiptLink>{};
    for (final r in rows) {
      final po = (r['purchase_order'] ?? '').toString();
      if (po.isEmpty) continue;
      final doc = (r['docstatus'] as num?)?.toInt() ?? 0;
      final link = doc == 0 ? ReceiptLink.draft : ReceiptLink.submitted;
      // الاستلام المسودة أهم: يعني أن هناك ما ينتظر الاعتماد
      if (result[po] != ReceiptLink.draft) result[po] = link;
    }
    return result;
  }

  Future<List<PurchaseReceipt>> fetchReceipts() async {
    final rows = await _api.getAll(
      'Purchase Receipt',
      fields: [
        'name',
        'supplier',
        'supplier_name',
        'posting_date',
        'grand_total',
        'total_qty',
        'currency',
        'docstatus',
        'status',
        'per_billed',
        _receiptPoField,
      ],
      filters: [
        ['docstatus', 'in', [0, 1]],
      ],
    );
    // الاستلام ذو البنود المتعددة يتكرر صفه بعدد بنوده: نكتفي بصف واحد
    final byName = <String, PurchaseReceipt>{};
    for (final r in rows) {
      final doc = PurchaseReceipt.fromJson(r);
      final old = byName[doc.name];
      if (old == null || (old.purchaseOrder.isEmpty && doc.purchaseOrder.isNotEmpty)) {
        byName[doc.name] = doc;
      }
    }
    final list = byName.values.toList()
      ..sort(_newestFirst((r) => r.postingDate, (r) => r.name));
    return list;
  }

  Future<List<PurchaseInvoice>> fetchInvoices() async {
    final rows = await _api.getAll(
      'Purchase Invoice',
      fields: [
        'name',
        'supplier',
        'supplier_name',
        'posting_date',
        'due_date',
        'grand_total',
        'rounded_total',
        'outstanding_amount',
        'total_qty',
        'status',
        'currency',
        'docstatus',
        _invoicePoField,
      ],
      filters: [
        ['docstatus', 'in', [0, 1]],
      ],
    );
    final byName = <String, PurchaseInvoice>{};
    for (final r in rows) {
      final doc = PurchaseInvoice.fromJson(r);
      final old = byName[doc.name];
      if (old == null || (old.purchaseOrder.isEmpty && doc.purchaseOrder.isNotEmpty)) {
        byName[doc.name] = doc;
      }
    }
    final list = byName.values.toList()
      ..sort(_newestFirst((i) => i.postingDate, (i) => i.name));
    return list;
  }

  Comparator<T> _newestFirst<T>(
    String Function(T) date,
    String Function(T) name,
  ) =>
      (a, b) {
        final byDate = date(b).compareTo(date(a));
        return byDate != 0 ? byDate : name(b).compareTo(name(a));
      };

  /// تفاصيل مستند واحد (أصناف وضريبة ومجموع).
  Future<PurchaseDocDetail> fetchDetail(String doctype, String name) async {
    final doc = await _api.getDoc(doctype, name);
    return PurchaseDocDetail.fromJson(doc);
  }

  /// يحفظ كميات بنود مستند **مسودة** (PUT) دون لمس السعر. كل صف يحمل name، وكل
  /// الصفوف المطلوب بقاؤها تُرسل (الناقص يُحذف). يعيد المستند كما حسبه ERPNext
  /// (المبالغ والضريبة والإجمالي منه لا من حسابنا).
  Future<PurchaseDocDetail> updateItems(
    String doctype,
    String name,
    List<PurchaseLineEdit> edits,
  ) async {
    final saved = await _api.putDoc(doctype, name, {
      'items': [for (final e in edits) e.toJson()],
    });
    return PurchaseDocDetail.fromJson(saved);
  }

  Future<Uint8List> downloadPdf(String doctype, String name) =>
      _api.downloadPdf(doctype, name);

  Future<List<String>> fetchModesOfPayment() => _lookup.fetchModesOfPayment();

  // ───────────────────────── أمر شراء جديد ─────────────────────────

  Future<List<ErpSupplier>> searchSuppliers(String query) async {
    final q = query.trim();
    final rows = await _api.getList(
      'Supplier',
      fields: ['name', 'supplier_name'],
      filters: [
        ['disabled', '=', 0],
        if (q.isNotEmpty) ['supplier_name', 'like', '%$q%'],
      ],
      limitPageLength: 30,
    );
    return [
      for (final r in rows)
        ErpSupplier(
          id: r['name'].toString(),
          name: (r['supplier_name'] ?? r['name']).toString(),
        ),
    ];
  }

  Future<List<PurchasableItem>> searchItems(String query) async {
    final q = query.trim();
    final rows = await _api.getList(
      'Item',
      fields: ['item_code', 'item_name', 'stock_uom'],
      filters: [
        ['disabled', '=', 0],
        ['is_purchase_item', '=', 1],
        if (q.isNotEmpty) ['item_name', 'like', '%$q%'],
      ],
      limitPageLength: 30,
    );
    return [
      for (final r in rows)
        PurchasableItem(
          code: r['item_code'].toString(),
          name: (r['item_name'] ?? r['item_code']).toString(),
          uom: (r['stock_uom'] ?? '').toString(),
          rate: 0,
        ),
    ];
  }

  /// سعر الشراء من قائمة «Standard Buying». null = لا يوجد سعر، فيكتبه المستخدم.
  Future<double?> fetchBuyingRate(String itemCode) async {
    final rows = await _api.getList(
      'Item Price',
      fields: ['price_list_rate'],
      filters: [
        ['item_code', '=', itemCode],
        ['price_list', '=', buyingPriceList],
        ['buying', '=', 1],
      ],
      limitPageLength: 1,
    );
    if (rows.isEmpty) return null;
    final v = rows.first['price_list_rate'];
    final rate = v is num ? v.toDouble() : double.tryParse('$v');
    return (rate == null || rate <= 0) ? null : rate;
  }

  /// ينشئ أمر شراء **مسودة** ويعيد رقمه. الضريبة الافتراضية للشركة (إن وُجدت)
  /// تُضاف تلقائيًا، فيصير 300 + 16% = 348 مثلًا.
  Future<String> createOrder({
    required ErpSupplier supplier,
    required List<NewPurchaseLine> lines,
    required DateTime scheduleDate,
  }) async {
    final body = <String, dynamic>{
      'supplier': supplier.id,
      'company': ErpConfig.company,
      'transaction_date': _date(DateTime.now()),
      'schedule_date': _date(scheduleDate),
      'buying_price_list': buyingPriceList,
      'price_list_currency': ErpConfig.priceListCurrency,
      'plc_conversion_rate': 1,
      'items': [
        for (final l in lines)
          {
            'item_code': l.item.code,
            'qty': l.qty,
            'rate': l.rate,
            'schedule_date': _date(scheduleDate),
            'warehouse': ErpConfig.warehouse,
          },
      ],
    };
    await _applyDefaultTaxes(body);
    final created = await _api.postDoc('Purchase Order', body);
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    return name;
  }

  /// قالب ضريبة المشتريات (16%): يُرسل اسمه فقط في taxes_and_charges فيملأ ERPNext
  /// الصفوف. نختار القالب الافتراضي للشركة، وإلا الذي اسمه فيه 16، وإلا الأول.
  /// فشل الجلب لا يوقف إنشاء الأمر (يُحفظ دون ضريبة).
  Future<void> _applyDefaultTaxes(Map<String, dynamic> body) async {
    try {
      final rows = await _api.getList(
        'Purchase Taxes and Charges Template',
        fields: ['name', 'is_default', 'company'],
        limitPageLength: 50,
      );
      if (rows.isEmpty) return;
      Map<String, dynamic>? pick;
      for (final r in rows) {
        final sameCompany = (r['company'] ?? ErpConfig.company) == ErpConfig.company;
        if (sameCompany && r['is_default'] == 1) pick = r;
      }
      pick ??= rows.firstWhere(
        (r) => r['name'].toString().contains('16'),
        orElse: () => rows.first,
      );
      body['taxes_and_charges'] = pick['name'];
    } catch (e) {
      debugPrint('ErpPurchasesRepository._applyDefaultTaxes failed: $e');
    }
  }

  /// يحذف أمر شراء مسودة (404 = محذوف أصلًا فنعدّه ناجحًا).
  Future<void> deleteOrder(String name) async {
    try {
      await _api.deleteDoc('Purchase Order', name);
    } on ErpApiException catch (e) {
      if (e.type != ErpErrorType.notFound) rethrow;
    }
  }

  /// يعتمد أمر الشراء (docstatus 0 ← 1). هذا الاعتماد الوحيد الذي يتم من التطبيق.
  Future<void> submitOrder(String name) async {
    await _api.putDoc('Purchase Order', name, {'docstatus': 1});
  }

  // ───────────────────────── الاستلام والفوترة (مسودات) ─────────────────────────

  /// ينشئ استلامًا **مسودة** من أمر شراء معتمد ويعيد رقمه.
  Future<String> createReceiptDraft(String orderName) async {
    final made = await _api.getMethod(_orderMethodReceipt, {
      'source_name': orderName,
    });
    final created = await _api.postDoc('Purchase Receipt', _cleanDoc(made['message']));
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    return name;
  }

  /// ينشئ فاتورة مشتريات **مسودة** من استلام معتمد ويعيد رقمها.
  Future<String> createInvoiceDraft(String receiptName) async {
    final made = await _api.getMethod(_receiptMethodInvoice, {
      'source_name': receiptName,
    });
    final created = await _api.postDoc('Purchase Invoice', _cleanDoc(made['message']));
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    return name;
  }

  /// رقم استلام معتمد لأمر الشراء (null إن لم يوجد) — لزر «فوترة» في أمر الشراء.
  Future<String?> findSubmittedReceipt(String orderName) async {
    final rows = await _api.getList(
      'Purchase Receipt',
      fields: ['name'],
      filters: [
        ['Purchase Receipt Item', 'purchase_order', '=', orderName],
        ['docstatus', '=', 1],
        ['per_billed', '<', 100],
      ],
      limitPageLength: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['name']?.toString();
  }

  // ───────────────────────── الدفع للمورد ─────────────────────────

  Future<List<PendingPayment>> readPending() async {
    final entry = await _cache.read(_pendingKey);
    if (entry == null) return [];
    try {
      final list = jsonDecode(entry.json) as List;
      return [
        for (final r in list)
          PendingPayment.fromJson(Map<String, dynamic>.from(r as Map)),
      ];
    } catch (e) {
      debugPrint('الدفعات المعلّقة المحفوظة تالفة: $e');
      return [];
    }
  }

  Future<void> _writePending(List<PendingPayment> list) =>
      _cache.write(_pendingKey, jsonEncode([for (final p in list) p.toJson()]));

  /// يحذف من المعلّقة كل دفعة لم تعد مسودة في ERPNext (اعتُمدت أو أُلغيت أو حُذفت).
  Future<List<PendingPayment>> reconcilePending() async {
    final pending = await readPending();
    if (pending.isEmpty) return pending;
    final rows = await _api.getAll(
      'Payment Entry',
      fields: ['name', 'docstatus'],
      filters: [
        ['name', 'in', [for (final p in pending) p.entry]],
      ],
    );
    final stillDraft = <String>{
      for (final r in rows)
        if ((r['docstatus'] as num?)?.toInt() == 0) r['name'].toString(),
    };
    final kept = [
      for (final p in pending)
        if (stillDraft.contains(p.entry)) p,
    ];
    if (kept.length != pending.length) await _writePending(kept);
    return kept;
  }

  /// يحفظ دفعة للمورد (Payment Entry من نوع Pay) **مسودة** مربوطة بالفاتورة.
  /// المبلغ أكبر من صفر وليس أكثر من المستحق؛ أقل من المستحق = دفعة جزئية.
  Future<PendingPayment> savePayment({
    required PurchaseInvoice invoice,
    required double amount,
    required String modeOfPayment,
    String? note,
    String? referenceNo,
    DateTime? referenceDate,
  }) async {
    final made = await _api.getMethod(_paymentEntryMethod, {
      'dt': 'Purchase Invoice',
      'dn': invoice.name,
      'party_amount': amount.toStringAsFixed(2),
    });
    final message = made['message'];
    if (message is! Map) throw const ErpApiException(ErpErrorType.badResponse);
    final entry = _cleanMap(message);

    // حساب الدفع (طالع منا) = الحساب الافتراضي لطريقة الدفع في الشركة الحالية
    final mode = await _api.getDoc('Mode of Payment', modeOfPayment);
    final paidFrom = _defaultAccount(mode['accounts']);
    if (paidFrom.isEmpty) {
      throw ErpApiException(
        ErpErrorType.server,
        detail: AppStrings.paymentNoAccountForMode(modeOfPayment),
      );
    }
    entry['payment_type'] = 'Pay';
    entry['mode_of_payment'] = modeOfPayment;
    entry['paid_from'] = paidFrom;
    final cleanNote = note?.trim() ?? '';
    if (cleanNote.isNotEmpty) entry['remarks'] = cleanNote;
    // غير النقدي: رقم المرجع وتاريخه مطلوبان (شيك أو مرجع تحويل)
    final ref = referenceNo?.trim() ?? '';
    if (ref.isNotEmpty) entry['reference_no'] = ref;
    if (referenceDate != null) entry['reference_date'] = _date(referenceDate);

    final created = await _api.postDoc('Payment Entry', entry);
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);

    final payment = PendingPayment(
      invoice: invoice.name,
      entry: name,
      amount: amount,
      currency: invoice.currency.isEmpty
          ? ErpConfig.priceListCurrency
          : invoice.currency,
    );
    await _writePending([...await readPending(), payment]);
    return payment;
  }

  String _defaultAccount(Object? accounts) {
    if (accounts is! List) return '';
    for (final row in accounts) {
      if (row is Map && row['company']?.toString() == ErpConfig.company) {
        return row['default_account']?.toString() ?? '';
      }
    }
    return '';
  }

  // ───────────────────────── أدوات ─────────────────────────

  static Map<String, dynamic> _cleanDoc(Object? message) {
    if (message is! Map) throw const ErpApiException(ErpErrorType.badResponse);
    return _cleanMap(message);
  }

  /// يحذف مفاتيح __ (حتى داخل صفوف الجداول) فلا يرفضها الحفظ
  static Map<String, dynamic> _cleanMap(Map message) {
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

  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
