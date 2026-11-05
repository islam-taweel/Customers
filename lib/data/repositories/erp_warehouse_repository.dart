import 'package:flutter/foundation.dart';

import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/warehouse_models.dart';

/// المستودعات في ERPNext: قائمة المستودعات، أرصدة الأصناف في كل مستودع (Bin)،
/// ونقل الأصناف بينها (Stock Entry / Material Transfer) يُحفظ مسودة ثم يُعتمد أو يُرفض.
class ErpWarehouseRepository {
  ErpWarehouseRepository(this._api);

  final ErpApiClient _api;

  static const _transfer = 'Material Transfer';

  /// حد آمن لطول رابط فلتر `in`
  static const _chunk = 100;

  // ───────────────────────── 1) المستودعات ─────────────────────────

  Future<List<Warehouse>> fetchWarehouses() async {
    final rows = await _api.getAll(
      'Warehouse',
      fields: ['name', 'warehouse_name', 'parent_warehouse', 'company'],
      filters: [
        ['is_group', '=', 0],
        ['disabled', '=', 0],
        ['company', '=', ErpConfig.company],
      ],
      orderBy: 'warehouse_name asc',
    );
    return [for (final r in rows) Warehouse.fromJson(r)];
  }

  // ───────────────────────── 2) أصناف المستودع ─────────────────────────

  /// أرصدة الأصناف الموجودة فعليًا (actual_qty > 0) في [warehouse]، مع أسمائها
  /// من Item ووحداتها التي لا تقبل كسورًا من UOM.
  Future<List<WarehouseStock>> fetchStock(String warehouse) async {
    final bins = await _api.getAll(
      'Bin',
      fields: [
        'item_code',
        'warehouse',
        'actual_qty',
        'reserved_qty',
        'projected_qty',
        'stock_uom',
      ],
      filters: [
        ['warehouse', '=', warehouse],
        ['actual_qty', '>', 0],
      ],
      orderBy: 'item_code asc',
    );
    if (bins.isEmpty) return const [];

    final codes = {for (final b in bins) b['item_code']?.toString() ?? ''}
      ..remove('');
    final items = <String, Map<String, dynamic>>{};
    for (final part in _chunks(codes.toList())) {
      final rows = await _api.getAll(
        'Item',
        fields: ['item_code', 'item_name', 'item_group'],
        filters: [
          ['item_code', 'in', part],
        ],
      );
      for (final r in rows) {
        items[r['item_code'].toString()] = r;
      }
    }

    final whole = await _wholeNumberUoms({
      for (final b in bins) b['stock_uom']?.toString() ?? '',
    }..remove(''));

    return [
      for (final b in bins)
        WarehouseStock.fromBin(
          b,
          item: items[b['item_code']?.toString()],
          wholeNumber: whole.contains(b['stock_uom']?.toString()),
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

  // ───────────────────────── 3) النقل (مسودة) ─────────────────────────

  /// ينشئ قيد نقل **مسودة**: لا يتحرك المخزون قبل الاعتماد.
  /// [quantities]: رمز الصنف → الكمية. يعيد رقم القيد (data.name).
  Future<String> createTransfer({
    required String from,
    required String to,
    required Map<String, double> quantities,
    String remarks = '',
  }) async {
    final created = await _api.postDoc('Stock Entry', {
      'stock_entry_type': _transfer,
      'purpose': _transfer,
      'company': ErpConfig.company,
      'posting_date': _date(DateTime.now()),
      'from_warehouse': from,
      'to_warehouse': to,
      if (remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
      'items': [
        for (final e in quantities.entries)
          {
            'item_code': e.key,
            'qty': e.value,
            's_warehouse': from,
            't_warehouse': to,
          },
      ],
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Stock Entry $name created (${quantities.length} rows)');
    return name;
  }

  // ───────────────────────── 4) الاعتماد ─────────────────────────

  /// قيود النقل المسودة التي تنتظر الاعتماد (الأحدث أولًا).
  Future<List<StockTransfer>> fetchPending() async {
    final rows = await _api.getAll(
      'Stock Entry',
      fields: [
        'name',
        'posting_date',
        'from_warehouse',
        'to_warehouse',
        'remarks',
      ],
      filters: [
        ['stock_entry_type', '=', _transfer],
        ['docstatus', '=', 0],
        ['company', '=', ErpConfig.company],
      ],
      orderBy: 'creation desc',
    );
    return [for (final r in rows) StockTransfer.fromJson(r)];
  }

  /// القيد كاملًا بأصنافه.
  Future<StockTransfer> fetchTransfer(String name) async =>
      StockTransfer.fromJson(await _api.getDoc('Stock Entry', name));

  /// الاعتماد: الآن فقط يتحرك المخزون.
  Future<void> approve(String name) =>
      _api.putDoc('Stock Entry', name, {'docstatus': 1});

  /// رفض المسودة = حذفها.
  Future<void> reject(String name) => _api.deleteDoc('Stock Entry', name);

  static Iterable<List<String>> _chunks(List<String> all) sync* {
    for (var i = 0; i < all.length; i += _chunk) {
      yield all.sublist(i, i + _chunk > all.length ? all.length : i + _chunk);
    }
  }

  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
