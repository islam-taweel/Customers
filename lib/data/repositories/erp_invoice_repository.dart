import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../core/utils/formatters.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/customer.dart';
import '../models/sales_invoice.dart';
import '../models/sync_models.dart';
import 'erp_cache_store.dart';

/// دليل عملاء ERPNext: يربط رقم الهاتف أو الاسم برقم العميل في ERPNext.
class _Directory {
  final Map<String, String> idByPhoneKey;
  final Map<String, String> idByName;
  final DateTime loadedAt;

  const _Directory({
    required this.idByPhoneKey,
    required this.idByName,
    required this.loadedAt,
  });
}

/// فواتير عميل. [matched] = false إن لم يوجد له عميل مطابق في ERPNext.
/// [savedAt] = null إذا جاءت للتو من ERPNext، وإلا هو وقت حفظ النسخة المحلية.
class InvoicesResult {
  final bool matched;
  final List<SalesInvoice> invoices;
  final DateTime? savedAt;

  const InvoicesResult({
    required this.matched,
    required this.invoices,
    this.savedAt,
  });
}

/// تفاصيل فاتورة، مع وقت حفظها إن كانت من النسخة المحلية (null = من ERPNext الآن).
class InvoiceDetailResult {
  final SalesInvoiceDetail detail;
  final DateTime? savedAt;

  const InvoiceDetailResult({required this.detail, this.savedAt});
}

/// الوسيط بين التطبيق وفواتير ERPNext **فقط**. العملاء والديون والدفعات تبقى في
/// قاعدة البيانات المحلية ولا تمر من هنا.
///
/// العمل دون إنترنت: كل رد ناجح يُحفظ في قاعدة البيانات المحلية ([ErpCacheStore])،
/// ويوفّر المستودع دالتين لكل شيء: `readCached…` تقرأ المحفوظ فورًا، و`fetch…` تجلب من
/// ERPNext (وتحفظ). فتعرض الواجهة المحفوظ أولًا ثم تحدّثه إن توفر الاتصال.
///
/// لمعرفة فواتير عميل محلي نطابقه مع عميل ERPNext: أولًا بالهاتف (آخر 9 أرقام، فتتطابق
/// 0599123456 و +970599123456)، وإن لم يوجد فبالاسم. ثم نجلب فواتيره المعتمدة.
class ErpInvoiceRepository {
  ErpInvoiceRepository(this._api, this._cache);

  final ErpApiClient _api;
  final ErpCacheStore _cache;

  static const Duration _directoryTtl = Duration(minutes: 5);
  static const Duration _invoicesTtl = Duration(seconds: 60);

  /// عدد أحدث الفواتير التي نجلب تفاصيلها مسبقًا في الخلفية لتتوفر دون إنترنت
  static const int _prefetchCount = 10;

  static const List<String> _invoiceFields = [
    'name',
    'customer',
    'customer_name',
    'posting_date',
    'due_date',
    'grand_total',
    'outstanding_amount',
    'status',
  ];

  _Directory? _directory;
  Future<_Directory>? _directoryInFlight;
  final Map<String, ({DateTime at, InvoicesResult result})> _memoryCache = {};

  // ───────────────────────── قائمة الفواتير ─────────────────────────

  String _invoicesKey(Customer customer) => _invoicesKeyForId(customer.id);

  String _invoicesKeyForId(int? localCustomerId) => 'invoices:$localCustomerId';

  /// المحفوظ محليًا من آخر مرة نجح فيها الجلب (null إن لم يُحفظ شيء بعد).
  Future<InvoicesResult?> readCachedInvoices(Customer customer) async {
    final entry = await _cache.read(_invoicesKey(customer));
    if (entry == null) return null;

    try {
      final decoded = jsonDecode(entry.json) as Map<String, dynamic>;
      final rows = decoded['rows'] as List;
      return InvoicesResult(
        matched: decoded['matched'] == true,
        invoices: _parseInvoices([
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
  Future<InvoicesResult> fetchInvoices(Customer customer) async {
    final directory = await _ensureDirectory();

    final phoneKey = _phoneKey(customer.phone);
    final erpId = (phoneKey == null ? null : directory.idByPhoneKey[phoneKey]) ??
        directory.idByName[_nameKey(customer.name)];

    final key = _invoicesKey(customer);

    if (erpId == null) {
      await _cache.write(key, jsonEncode({'matched': false, 'rows': <Object>[]}));
      return const InvoicesResult(matched: false, invoices: []);
    }

    final cached = _memoryCache[erpId];
    if (cached != null && DateTime.now().difference(cached.at) < _invoicesTtl) {
      return cached.result;
    }

    final rows = await _api.getAll(
      'Sales Invoice',
      fields: _invoiceFields,
      filters: [
        ['docstatus', '=', 1],
        ['customer', '=', erpId],
      ],
    );

    await _cache.write(key, jsonEncode({'matched': true, 'rows': rows}));

    final result = InvoicesResult(matched: true, invoices: _parseInvoices(rows));
    _memoryCache[erpId] = (at: DateTime.now(), result: result);

    // نجلب تفاصيل أحدث الفواتير في الخلفية لتفتح دون إنترنت لاحقًا
    unawaited(_prefetchDetails(result.invoices));
    return result;
  }

  List<SalesInvoice> _parseInvoices(List<Map<String, dynamic>> rows) {
    return [for (final row in rows) SalesInvoice.fromJson(row)]
      ..sort((a, b) {
        final byDate = b.postingDate.compareTo(a.postingDate);
        return byDate != 0 ? byDate : b.name.compareTo(a.name);
      });
  }

  // ───────────────────────── ملف PDF من الخادم ─────────────────────────

  /// ملف PDF للمستند من ERPNext (download_pdf). [doctype] هو Sales Invoice لفواتير
  /// ERPNext، وSales Order للطلبيات المعتمدة من التطبيق.
  Future<Uint8List> downloadPdf(String doctype, String name) =>
      _api.downloadPdf(doctype, name);

  // ───────────────────────── مزامنة كل الفواتير ─────────────────────────

  /// عدد أحدث الفواتير التي تُجلب تفاصيلها (بأصنافها) أثناء المزامنة الكاملة
  static const int _syncDetailCount = 40;

  /// يجلب فواتير كل العملاء المرتبطين بـ ERPNext بطلب مقسّم على صفحات واحد،
  /// ويحفظ قائمة كل عميل محليًا (نفس مفاتيح الجلب الفردي)، ثم تفاصيل أحدث الفواتير.
  /// الارتباط بـ erpId (دقيق) وليس بالهاتف أو الاسم.
  Future<({int customers, int invoices})> syncAll(
    List<({int id, String erpId})> links, {
    void Function(double progress, SyncStep step)? onProgress,
  }) async {
    onProgress?.call(0.05, SyncStep.invoicesList);
    final rows = await _api.getAll(
      'Sales Invoice',
      fields: _invoiceFields,
      filters: [
        ['docstatus', '=', 1],
      ],
    );

    final byCustomer = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final id = row['customer']?.toString() ?? '';
      if (id.isEmpty) continue;
      byCustomer.putIfAbsent(id, () => []).add(row);
    }

    onProgress?.call(0.35, SyncStep.saving);
    await _cache.writeAll({
      for (final link in links)
        _invoicesKeyForId(link.id): jsonEncode({
          'matched': true,
          'rows': byCustomer[link.erpId] ?? const <Object>[],
        }),
    });
    _memoryCache.clear();

    // تفاصيل أحدث الفواتير لتُفتح دون إنترنت. فشلها لا يُفشل المزامنة
    // (قوائم الفواتير حُفظت أصلًا)، فنتوقف عند أول خطأ.
    final linked = {for (final l in links) l.erpId};
    final recent = _parseInvoices([
      for (final row in rows)
        if (linked.contains(row['customer']?.toString())) row,
    ]).take(_syncDetailCount).toList();

    for (var i = 0; i < recent.length; i++) {
      onProgress?.call(0.4 + 0.6 * (i / recent.length), SyncStep.invoiceDetails);
      try {
        if (await _cache.read(_detailKey(recent[i].name)) != null) continue;
        await fetchInvoiceDetail(recent[i].name);
      } catch (e) {
        debugPrint('تعذّر جلب تفاصيل ${recent[i].name} أثناء المزامنة: $e');
        break;
      }
    }

    final total = links.fold<int>(
      0,
      (sum, l) => sum + (byCustomer[l.erpId]?.length ?? 0),
    );
    return (customers: links.length, invoices: total);
  }

  // ───────────────────────── تفاصيل فاتورة ─────────────────────────

  String _detailKey(String invoiceName) => 'invoice:$invoiceName';

  Future<InvoiceDetailResult?> readCachedInvoiceDetail(String invoiceName) async {
    final entry = await _cache.read(_detailKey(invoiceName));
    if (entry == null) return null;

    try {
      final json = Map<String, dynamic>.from(jsonDecode(entry.json) as Map);
      return InvoiceDetailResult(
        detail: SalesInvoiceDetail.fromJson(json),
        savedAt: entry.savedAt,
      );
    } catch (e) {
      debugPrint('نسخة تفاصيل الفاتورة المحفوظة تالفة: $e');
      return null;
    }
  }

  /// تفاصيل فاتورة كاملة (بأصنافها) من ERPNext ثم حفظها محليًا.
  /// الاسم يُمرَّر كما جاء من القائمة (قد ينتهي بـ -1 أو -2).
  Future<InvoiceDetailResult> fetchInvoiceDetail(String invoiceName) async {
    final json = await _api.getDoc('Sales Invoice', invoiceName);
    await _cache.write(_detailKey(invoiceName), jsonEncode(json));
    return InvoiceDetailResult(detail: SalesInvoiceDetail.fromJson(json));
  }

  /// يجلب تفاصيل أحدث الفواتير التي لم تُحفظ بعد. يتوقف عند أول فشل (غالبًا انقطاع)،
  /// ولا يُظهر أي خطأ للمستخدم لأنه عمل خلفي.
  Future<void> _prefetchDetails(List<SalesInvoice> invoices) async {
    for (final invoice in invoices.take(_prefetchCount)) {
      try {
        if (await _cache.read(_detailKey(invoice.name)) != null) continue;
        await fetchInvoiceDetail(invoice.name);
      } catch (e) {
        debugPrint('تعذّر جلب تفاصيل ${invoice.name} مسبقًا: $e');
        return;
      }
    }
  }

  // ───────────────────────── دليل العملاء ─────────────────────────

  Future<_Directory> _ensureDirectory() async {
    final current = _directory;
    if (current != null &&
        DateTime.now().difference(current.loadedAt) < _directoryTtl) {
      return current;
    }

    final running = _directoryInFlight;
    if (running != null) return running;

    final future = _fetchDirectory();
    _directoryInFlight = future;
    try {
      final fresh = await future;
      _directory = fresh;
      return fresh;
    } finally {
      if (identical(_directoryInFlight, future)) _directoryInFlight = null;
    }
  }

  Future<_Directory> _fetchDirectory() async {
    final results = await Future.wait<List<Map<String, dynamic>>>([
      _api.getAll('Customer', fields: ['name', 'customer_name']),
      _fetchContactRows(),
    ]);
    final customerRows = results[0];
    final contactRows = results[1];

    final idByName = <String, String>{};
    for (final row in customerRows) {
      final id = row['name']?.toString() ?? '';
      final name = row['customer_name']?.toString() ?? '';
      if (id.isEmpty || name.isEmpty) continue;
      idByName.putIfAbsent(_nameKey(name), () => id);
    }

    // link_name = رقم العميل في ERPNext. نفهرس phone و mobile_no معًا.
    final idByPhoneKey = <String, String>{};
    for (final row in contactRows) {
      final id = row['link_name']?.toString() ?? '';
      if (id.isEmpty) continue;
      for (final raw in [row['phone'], row['mobile_no']]) {
        final key = _phoneKey(raw?.toString() ?? '');
        if (key != null) idByPhoneKey.putIfAbsent(key, () => id);
      }
    }

    return _Directory(
      idByPhoneKey: idByPhoneKey,
      idByName: idByName,
      loadedAt: DateTime.now(),
    );
  }

  /// فشل جلب الهواتف بسبب خطأ من الخادم (مثل صيغة حقل الجدول الفرعي) لا يمنع المطابقة
  /// بالاسم، فنكمل بلا هواتف. أخطاء المفاتيح والاتصال تُرمى كما هي.
  Future<List<Map<String, dynamic>>> _fetchContactRows() async {
    try {
      return await _api.getAll(
        'Contact',
        fields: [
          'name',
          'first_name',
          'phone',
          'mobile_no',
          ErpConfig.contactLinkField,
        ],
        filters: [
          ['Dynamic Link', 'link_doctype', '=', 'Customer'],
        ],
      );
    } on ErpApiException catch (e) {
      if (e.type == ErpErrorType.server || e.type == ErpErrorType.badResponse) {
        debugPrint('تعذّر جلب أرقام الهواتف، سنطابق بالاسم فقط: $e');
        return const [];
      }
      rethrow;
    }
  }

  /// آخر 9 أرقام من الهاتف، فتتطابق الصيغ المحلية والدولية (null إن قصر الرقم).
  String? _phoneKey(String raw) {
    final digits = normalizeDigits(raw).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) return null;
    return digits.substring(digits.length - 9);
  }

  /// الاسم بلا فروق في حالة الأحرف أو المسافات الزائدة
  String _nameKey(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
