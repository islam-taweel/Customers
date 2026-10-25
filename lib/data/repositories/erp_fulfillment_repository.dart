import 'dart:math';
import 'dart:typed_data';

import '../../core/constants/app_strings.dart';
import '../api/erp_api_client.dart';

/// مرحلة طلبية في ERPNext: هل سُلِّمت بالكامل، وهل فُوتِرت بالكامل.
typedef OrderFulfillment = ({bool delivered, bool billed});

/// ما بعد اعتماد الطلبية في ERPNext: التسليم (Delivery Note) وقراءة حالتي
/// التسليم والفوترة من الطلبية (Sales Order).
class ErpFulfillmentRepository {
  ErpFulfillmentRepository(this._api);

  final ErpApiClient _api;

  static const _doctype = 'Sales Order';

  /// عدد الطلبيات في الطلب الواحد (حتى لا يطول عنوان الطلب)
  static const _chunk = 50;

  /// حالة التسليم والفوترة لكل طلبية، بحسب رقمها في ERPNext.
  /// الطلبية غير الموجودة في الرد (حُذفت مثلًا) لا تظهر في النتيجة.
  Future<Map<String, OrderFulfillment>> fetchStatuses(
    List<String> orderIds,
  ) async {
    final result = <String, OrderFulfillment>{};
    for (var i = 0; i < orderIds.length; i += _chunk) {
      final ids = orderIds.sublist(i, min(i + _chunk, orderIds.length));
      final rows = await _api.getList(
        _doctype,
        fields: ['name', 'per_delivered', 'per_billed'],
        filters: [
          ['name', 'in', ids],
        ],
        limitPageLength: ids.length,
      );
      for (final row in rows) {
        final name = row['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        result[name] = (
          delivered: _isComplete(row['per_delivered']),
          billed: _isComplete(row['per_billed']),
        );
      }
    }
    return result;
  }

  /// الطلبيات التي لها سند تسليم مسودة (غير معتمد) في ERPNext، من بين [orderIds].
  /// تُجلب خمس طلبيات في كل دفعة حتى لا يزدحم الخادم.
  Future<Set<String>> ordersWithDraftDelivery(List<String> orderIds) async {
    final found = <String>{};
    for (var i = 0; i < orderIds.length; i += 5) {
      final batch = orderIds.sublist(i, min(i + 5, orderIds.length));
      final results = await Future.wait([
        for (final id in batch) _hasDraftDelivery(id),
      ]);
      for (var j = 0; j < batch.length; j++) {
        if (results[j]) found.add(batch[j]);
      }
    }
    return found;
  }

  Future<bool> _hasDraftDelivery(String orderId) async {
    final rows = await _api.getList(
      'Delivery Note',
      fields: ['name'],
      filters: [
        ['Delivery Note Item', 'against_sales_order', '=', orderId],
        ['docstatus', '=', 0],
      ],
      limitPageLength: 1,
    );
    return rows.isNotEmpty;
  }

  static const _deliveryNoteToInvoiceMethod =
      'erpnext.stock.doctype.delivery_note.delivery_note.make_sales_invoice';

  /// يسلّم الطلبية: ينشئ منها سند تسليم **مسودة** ويعيد رقمه، ويبقى كذلك إلى أن
  /// يعتمده المسؤول في ERPNext. تُرمى [ErpApiException] إن رفض الخادم (مثل نقص المخزون).
  Future<String> deliverOrder(String orderId) async {
    // 1) سند تسليم جاهز من الطلبية (غير محفوظ بعد)
    final made = await _api.getMethod(
      'erpnext.selling.doctype.sales_order.sales_order.make_delivery_note',
      {'source_name': orderId},
    );
    final draft = _cleanDoc(made['message']);

    // 2) حفظه مسودة فقط
    final created = await _api.postDoc('Delivery Note', draft);
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    return name;
  }

  /// يفوتر الطلبية: ينشئ فاتورة مبيعات **مسودة** من سند التسليم المعتمد ويعيد رقمها،
  /// ويعتمدها المسؤول في ERPNext. [deliveryNote] إن كان التطبيق أنشأ السند، وإلا
  /// نبحث عن سند معتمد للطلبية. تُرمى [ErpApiException] إن رفض الخادم.
  Future<String> createInvoiceDraft({
    required String orderId,
    String? deliveryNote,
  }) async {
    var note = deliveryNote ?? '';
    if (note.isEmpty) note = await _findSubmittedDeliveryNote(orderId) ?? '';
    if (note.isEmpty) {
      throw ErpApiException(
        ErpErrorType.server,
        detail: AppStrings.billNoDeliveryNote,
      );
    }

    final made = await _api.getMethod(
      _deliveryNoteToInvoiceMethod,
      {'source_name': note},
    );
    final draft = _cleanDoc(made['message']);
    final created = await _api.postDoc('Sales Invoice', draft);
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    return name;
  }

  /// رقم سند تسليم معتمد للطلبية (null إن لم يوجد)
  Future<String?> _findSubmittedDeliveryNote(String orderId) async {
    final rows = await _api.getList(
      'Delivery Note',
      fields: ['name'],
      filters: [
        ['Delivery Note Item', 'against_sales_order', '=', orderId],
        ['docstatus', '=', 1],
      ],
      limitPageLength: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['name']?.toString();
  }

  /// docstatus لكل مستند موجود من [names] (الغائب = حُذف، أي رُفض في ERPNext).
  Future<Map<String, int>> existingDocs(String doctype, List<String> names) async {
    final result = <String, int>{};
    for (var i = 0; i < names.length; i += _chunk) {
      final batch = names.sublist(i, min(i + _chunk, names.length));
      final rows = await _api.getList(
        doctype,
        fields: ['name', 'docstatus'],
        filters: [
          ['name', 'in', batch],
        ],
        limitPageLength: batch.length,
      );
      for (final row in rows) {
        final name = row['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        result[name] = (row['docstatus'] as num?)?.toInt() ?? 0;
      }
    }
    return result;
  }

  /// المستند الجاهز من make_* يحمل أحيانًا مفاتيح تبدأ بـ __ يرفضها الحفظ: نحذفها
  /// (حتى داخل صفوف الجداول).
  static Map<String, dynamic> _cleanDoc(Object? message) {
    if (message is! Map) throw const ErpApiException(ErpErrorType.badResponse);
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

  /// ملف PDF لسند التسليم من ERPNext (للطباعة).
  Future<Uint8List> downloadDeliveryNotePdf(String deliveryNote) =>
      _api.downloadPdf('Delivery Note', deliveryNote);

  /// ملف PDF للطلبية من ERPNext (للطباعة).
  Future<Uint8List> downloadOrderPdf(String orderId) =>
      _api.downloadPdf(_doctype, orderId);

  /// النسبة تصل رقمًا أو نصًا؛ 100 = مكتمل (نسمح بفارق عشري صغير)
  static bool _isComplete(Object? percent) {
    final value = percent is num
        ? percent.toDouble()
        : double.tryParse(percent?.toString() ?? '') ?? 0;
    return value >= 99.99;
  }
}
