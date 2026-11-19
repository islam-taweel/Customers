import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../data/repositories/erp_cache_store.dart';
import '../../../data/repositories/erp_lookup_repository.dart';
import '../models/collection_models.dart';

/// تحصيل فاتورة مبيعات: ينشئ Payment Entry **مسودة** مربوطة بالفاتورة
/// (get_payment_entry) ويتذكرها محليًا حتى تُعتمد في ERPNext. حالة الفاتورة
/// ومستحقها يتغيران من ERPNext وحده بعد أن يعتمد المسؤول الدفعة.
///
/// (R3) نُقل كما هو من ErpSalesInvoicesRepository: نفس الطلبات والمفتاح المحلي.
class ErpInvoiceCollectionsRepository {
  ErpInvoiceCollectionsRepository(this._api, this._cache, this._lookup);

  final ErpApiClient _api;
  final ErpCacheStore _cache;
  final ErpLookupRepository _lookup;

  static const _pendingKey = 'sales_invoices:pending_payments';

  /// طرق الدفع المفعّلة في ERPNext (مع نسخة محلية عند انقطاع الاتصال).
  Future<List<String>> fetchModesOfPayment() => _lookup.fetchModesOfPayment();

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
            if (!e.key.toString().startsWith('__'))
              e.key.toString(): clean(e.value),
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
