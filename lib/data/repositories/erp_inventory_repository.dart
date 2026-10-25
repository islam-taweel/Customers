import 'package:flutter/foundation.dart';

import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/inventory_models.dart';

/// الجرد في ERPNext: البحث عن الصنف بالباركود، ثم تعديل كميته (تسوية مخزون).
/// السعر لا يُقرأ ولا يُعدَّل هنا.
class ErpInventoryRepository {
  ErpInventoryRepository(this._api);

  final ErpApiClient _api;

  /// الغرض الافتراضي لقائمة الجرد (للتحميل الأول يُستخدم 'Opening Stock').
  static const purposeReconciliation = 'Stock Reconciliation';
  static const purposeOpening = 'Opening Stock';

  // ───────────────────────── البحث ─────────────────────────

  /// الصنف صاحب هذا الباركود (جدول Item Barcode)، وإن لم يوجد فرمز الصنف نفسه.
  /// null = لا يوجد صنف.
  Future<InventoryItem?> findByBarcode(String code) async {
    final barcode = code.trim();
    if (barcode.isEmpty) return null;

    var rows = await _api.getList(
      'Item',
      fields: [
        'name',
        'item_code',
        'item_name',
        'stock_uom',
        'has_serial_no',
        'has_batch_no',
      ],
      filters: [
        ['disabled', '=', 0],
        ['Item Barcode', 'barcode', '=', barcode],
      ],
      limitPageLength: 1,
    );
    if (rows.isEmpty) {
      rows = await _api.getList(
        'Item',
        fields: [
        'name',
        'item_code',
        'item_name',
        'stock_uom',
        'has_serial_no',
        'has_batch_no',
      ],
        filters: [
          ['disabled', '=', 0],
          ['item_code', '=', barcode],
        ],
        limitPageLength: 1,
      );
    }
    if (rows.isEmpty) return null;
    return _load(rows.first);
  }

  Future<InventoryItem> _load(Map<String, dynamic> item) async {
    final code = (item['item_code'] ?? item['name']).toString();
    final bins = await _api.getList(
      'Bin',
      fields: ['actual_qty', 'valuation_rate'],
      filters: [
        ['item_code', '=', code],
        ['warehouse', '=', ErpConfig.warehouse],
      ],
      limitPageLength: 1,
    );

    return InventoryItem.fromRows(
      item: item,
      bin: bins.isEmpty ? null : bins.first,
      warehouse: ErpConfig.warehouse,
    );
  }

  // ───────────────────────── الإرسال ─────────────────────────

  /// يرسل **كل** القائمة في استدعاء واحد كتسوية مخزون **مسودة** (docstatus 0).
  /// لا يُرسل docstatus=1 أبدًا: الاعتماد النهائي خطوة المسؤول في ERPNext.
  /// يعيد رقم المستند (data.name).
  Future<String> submitList({
    required List<CountLine> lines,
    required String purpose,
  }) async {
    final created = await _api.postDoc('Stock Reconciliation', {
      'purpose': purpose,
      'company': ErpConfig.company,
      'posting_date': _date(DateTime.now()),
      'set_warehouse': ErpConfig.warehouse,
      if (ErpConfig.differenceAccount.isNotEmpty)
        'expense_account': ErpConfig.differenceAccount,
      'items': [for (final l in lines) l.toRow(ErpConfig.warehouse)],
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Stock Reconciliation $name created (${lines.length} rows)');
    return name;
  }

  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
