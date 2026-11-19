import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../data/api/erp_api_client.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../data/repositories/erp_cache_store.dart';
import '../models/sales_invoices_result.dart';

/// فواتير المبيعات (قسم «الفواتير») من ERPNext.
///
/// القراءة: كل رد ناجح يُحفظ محليًا فتظهر النسخة المحفوظة دون إنترنت.
/// (R3) الدفع على الفاتورة انتقل كما هو إلى ErpInvoiceCollectionsRepository.
class ErpSalesInvoicesRepository {
  ErpSalesInvoicesRepository(this._api, this._cache);

  final ErpApiClient _api;
  final ErpCacheStore _cache;

  static const _listKey = 'sales_invoices:all';

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
    // قيمة الفاتورة والمسدد من رصيد سابق (InvoiceSettlement.fields)
    'party_account_currency',
    'rounded_total',
    'base_grand_total',
    'base_rounded_total',
    'disable_rounded_total',
    'total_advance',
    'write_off_amount',
    'base_write_off_amount',
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
    return [for (final row in rows) SalesInvoice.fromJson(row)]..sort((a, b) {
      final byDate = b.postingDate.compareTo(a.postingDate);
      return byDate != 0 ? byDate : b.name.compareTo(a.name);
    });
  }

  /// ملف PDF للفاتورة من ERPNext للطباعة.
  Future<Uint8List> downloadInvoicePdf(String name) =>
      _api.downloadPdf('Sales Invoice', name);
}
