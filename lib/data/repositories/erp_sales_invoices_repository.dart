import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/sales_invoice.dart';
import 'erp_cache_store.dart';
import 'erp_lookup_repository.dart';

/// فواتير المبيعات لكل العملاء، مع وقت حفظ النسخة المحلية إن كانت منها.
class SalesInvoicesResult {
  final List<SalesInvoice> invoices;

  /// null = جاءت للتو من ERPNext، وإلا وقت حفظ النسخة المحلية
  final DateTime? savedAt;

  const SalesInvoicesResult({required this.invoices, this.savedAt});
}

/// تفاصيل الدفعة غير النقدية. لا يُرسل ولا يُحفظ رقم البطاقة كاملًا ولا تاريخ
/// انتهائها ولا CVV: آخر 4 أرقام فقط (في [extra] باسم custom_card_last4).
class PaymentDetails {
  /// رقم الشيك، أو رمز الموافقة، أو مرجع التحويل
  final String? referenceNo;

  /// تاريخ الشيك أو العملية أو التحويل
  final DateTime? referenceDate;

  /// حقول إضافية بحسب طريقة الدفع (custom_cheque_bank، custom_card_last4...)
  final Map<String, String> extra;

  const PaymentDetails({
    this.referenceNo,
    this.referenceDate,
    this.extra = const {},
  });
}

/// دفعة حُفظت مسودة في ERPNext وتنتظر اعتمادها هناك. الفاتورة لا يتغير مستحقها
/// ولا حالتها إلا بعد الاعتماد، فنتذكرها محليًا لنعرضها على الفاتورة.
class PendingPayment {
  final String invoice;
  final String entry;
  final double amount;
  final String currency;

  const PendingPayment({
    required this.invoice,
    required this.entry,
    required this.amount,
    required this.currency,
  });

  Map<String, dynamic> toJson() => {
        'invoice': invoice,
        'entry': entry,
        'amount': amount,
        'currency': currency,
      };

  factory PendingPayment.fromJson(Map<String, dynamic> json) => PendingPayment(
        invoice: json['invoice']?.toString() ?? '',
        entry: json['entry']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: json['currency']?.toString() ?? '',
      );
}

/// فواتير المبيعات (قسم «الفواتير») ودفعاتها في ERPNext.
///
/// القراءة: كل رد ناجح يُحفظ محليًا فتظهر النسخة المحفوظة دون إنترنت.
/// الدفع: ينشئ Payment Entry **مسودة** مربوطة بالفاتورة (get_payment_entry)؛
/// حالة الفاتورة ومستحقها يتغيران من ERPNext وحده بعد أن يعتمد المسؤول الدفعة.
class ErpSalesInvoicesRepository {
  ErpSalesInvoicesRepository(
    this._api,
    this._cache,
    this._lookup,
  );

  final ErpApiClient _api;
  final ErpCacheStore _cache;
  final ErpLookupRepository _lookup;

  static const _listKey = 'sales_invoices:all';
  static const _pendingKey = 'sales_invoices:pending_payments';

  static const List<String> _fields = [
    'name',
    'customer',
    'customer_name',
    'posting_date',
    'due_date',
    'grand_total',
    'outstanding_amount',
    'status',
    'currency',
    'docstatus',
  ];

  /// المحفوظ محليًا من آخر جلب ناجح (null إن لم يُحفظ شيء بعد).
  Future<SalesInvoicesResult?> readCached() async {
    final entry = await _cache.read(_listKey);
    if (entry == null) return null;
    try {
      final rows = jsonDecode(entry.json) as List;
      return SalesInvoicesResult(
        invoices: _parse([
          for (final r in rows) Map<String, dynamic>.from(r as Map),
        ]),
        savedAt: entry.savedAt,
      );
    } catch (e) {
      debugPrint('نسخة الفواتير المحفوظة تالفة: $e');
      return null;
    }
  }

  /// الجلب من ERPNext (يرمي [ErpApiException] عند الفشل) ثم الحفظ محليًا.
  Future<SalesInvoicesResult> fetchAll() async {
    final rows = await _api.getAll(
      'Sales Invoice',
      fields: _fields,
      filters: [
        [
          'docstatus',
          'in',
          [0, 1],
        ],
      ],
    );
    await _cache.write(_listKey, jsonEncode(rows));
    return SalesInvoicesResult(invoices: _parse(rows));
  }

  List<SalesInvoice> _parse(List<Map<String, dynamic>> rows) {
    return [for (final row in rows) SalesInvoice.fromJson(row)]
      ..sort((a, b) {
        final byDate = b.postingDate.compareTo(a.postingDate);
        return byDate != 0 ? byDate : b.name.compareTo(a.name);
      });
  }

  /// طرق الدفع المفعّلة في ERPNext (مع نسخة محلية عند انقطاع الاتصال).
  Future<List<String>> fetchModesOfPayment() => _lookup.fetchModesOfPayment();

  /// ملف PDF للفاتورة من ERPNext للطباعة.
  Future<Uint8List> downloadInvoicePdf(String name) =>
      _api.downloadPdf('Sales Invoice', name);

  // ───────────────────────── الدفعات بانتظار الاعتماد ─────────────────────────

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

  /// يحذف من المعلّقة كل دفعة لم تعد مسودة في ERPNext (اعتُمدت فانعكست على الفاتورة،
  /// أو أُلغيت/حُذفت). يرمي عند فشل الاتصال فتبقى القائمة المحلية كما هي.
  Future<List<PendingPayment>> reconcilePending() async {
    final pending = await readPending();
    if (pending.isEmpty) return pending;

    final rows = await _api.getAll(
      'Payment Entry',
      fields: ['name', 'docstatus'],
      filters: [
        [
          'name',
          'in',
          [for (final p in pending) p.entry],
        ],
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

  static const _paymentEntryMethod =
      'erpnext.accounts.doctype.payment_entry.payment_entry.get_payment_entry';

  /// يحفظ دفعة على فاتورة (Payment Entry مسودة) ويتذكرها. يرمي [ErpApiException].
  /// المبلغ يجب أن يكون أكبر من صفر وليس أكثر من مستحق الفاتورة. العملة من الفاتورة.
  Future<PendingPayment> savePayment({
    required SalesInvoice invoice,
    required double amount,
    required String modeOfPayment,
    String? note,
    PaymentDetails details = const PaymentDetails(),
  }) async {
    // 1) دفعة جاهزة مع تخصيص المبلغ على الفاتورة (غير محفوظة بعد)
    final made = await _api.getMethod(_paymentEntryMethod, {
      'dt': 'Sales Invoice',
      'dn': invoice.name,
      'party_amount': amount.toStringAsFixed(2),
    });
    final message = made['message'];
    if (message is! Map) throw const ErpApiException(ErpErrorType.badResponse);
    final entry = _cleanDoc(message);

    // 2) حساب القبض الافتراضي لطريقة الدفع في الشركة الحالية
    final mode = await _api.getDoc('Mode of Payment', modeOfPayment);
    final paidTo = _defaultAccount(mode['accounts']);
    if (paidTo.isEmpty) {
      throw ErpApiException(
        ErpErrorType.server,
        detail: AppStrings.paymentNoAccountForMode(modeOfPayment),
      );
    }

    entry['mode_of_payment'] = modeOfPayment;
    entry['paid_to'] = paidTo;
    final cleanNote = note?.trim() ?? '';
    if (cleanNote.isNotEmpty) entry['remarks'] = cleanNote;
    final refNo = details.referenceNo?.trim() ?? '';
    if (refNo.isNotEmpty) entry['reference_no'] = refNo;
    if (details.referenceDate != null) {
      entry['reference_date'] = _date(details.referenceDate!);
    }
    details.extra.forEach((key, value) {
      if (value.trim().isNotEmpty) entry[key] = value.trim();
    });

    // 3) حفظها مسودة فقط: يعتمدها المسؤول في ERPNext
    final created = await _api.postDoc('Payment Entry', entry);
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);

    final currency = invoice.currency.isEmpty
        ? ErpConfig.priceListCurrency
        : invoice.currency;
    final payment = PendingPayment(
      invoice: invoice.name,
      entry: name,
      amount: amount,
      currency: currency,
    );
    final pending = await readPending();
    await _writePending([...pending, payment]);
    return payment;
  }

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
}
