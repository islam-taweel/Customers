import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/order_models.dart';

/// كل ما يخص طلبيات العملاء في ERPNext: مجموعات الأصناف، الأصناف، السعر والمخزون،
/// وإنشاء الطلبية (Sales Order). العملاء يأتون من [ErpCustomerRepository].
class ErpOrderRepository {
  ErpOrderRepository(this._api);

  final ErpApiClient _api;

  /// المجموعات النهائية فقط (is_group = 0). الشجرة بمستوى واحد.
  Future<List<String>> fetchItemGroups() async {
    final rows = await _api.getList(
      'Item Group',
      fields: ['name'],
      filters: [
        ['is_group', '=', 0],
      ],
      limitPageLength: 100,
    );
    return [
      for (final row in rows)
        if ((row['name']?.toString() ?? '').isNotEmpty) row['name'].toString(),
    ];
  }

  /// أصناف المجموعة المفعّلة والقابلة للبيع.
  Future<List<ErpItem>> fetchItems(String group) async {
    final rows = await _api.getAll(
      'Item',
      fields: ['item_code', 'item_name', 'stock_uom'],
      filters: [
        ['item_group', '=', group],
        ['disabled', '=', 0],
        ['is_sales_item', '=', 1],
      ],
    );

    final items = <ErpItem>[];
    for (final row in rows) {
      final code = row['item_code']?.toString() ?? '';
      if (code.isEmpty) continue;
      final name = (row['item_name']?.toString() ?? '').trim();
      items.add(
        ErpItem(
          code: code,
          name: name.isEmpty ? code : name,
          uom: row['stock_uom']?.toString() ?? '',
        ),
      );
    }
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  /// السعر والمخزون معًا (طلبان متوازيان) عند الضغط على صنف.
  Future<ItemPricing> fetchPricing(String itemCode) async {
    final results = await Future.wait<List<Map<String, dynamic>>>([
      _api.getList(
        'Item Price',
        fields: ['price_list_rate'],
        filters: [
          ['item_code', '=', itemCode],
          ['price_list', '=', ErpConfig.sellingPriceList],
          ['selling', '=', 1],
        ],
      ),
      _api.getList(
        'Bin',
        fields: ['actual_qty', 'reserved_qty'],
        filters: [
          ['item_code', '=', itemCode],
          ['warehouse', '=', ErpConfig.warehouse],
        ],
      ),
    ]);

    // قائمة فارغة = لا يوجد سعر. لا نستخدم standard_rate (قيمته 0).
    final priceRows = results[0];
    final rate = priceRows.isEmpty ? null : _num(priceRows.first['price_list_rate']);

    // قائمة فارغة = لا مخزون (0)
    var available = 0.0;
    for (final row in results[1]) {
      available += _num(row['actual_qty']) - _num(row['reserved_qty']);
    }
    if (available < 0) available = 0;

    return ItemPricing(rate: rate, available: available);
  }

  /// ينشئ الطلبية (تُحفظ كمسودة Draft) ويعيد رقمها.
  Future<CreatedOrder> createOrder({
    required String customerId,
    required DateTime deliveryDate,
    required List<CartLine> lines,
  }) async {
    final body = {
      'customer': customerId,
      'company': ErpConfig.company,
      'transaction_date': _date(DateTime.now()),
      'delivery_date': _date(deliveryDate),
      'selling_price_list': ErpConfig.sellingPriceList,
      'price_list_currency': ErpConfig.priceListCurrency,
      'plc_conversion_rate': ErpConfig.priceListConversionRate,
      'items': [
        for (final line in lines)
          {
            'item_code': line.item.code,
            'qty': line.qty,
            'rate': line.rate,
            'warehouse': ErpConfig.warehouse,
          },
      ],
    };

    final data = await _api.postDoc('Sales Order', body);
    final id = data['name']?.toString() ?? '';
    if (id.isEmpty) {
      throw const ErpApiException(ErpErrorType.badResponse);
    }
    return CreatedOrder(
      id: id,
      total: lines.fold<double>(0, (sum, l) => sum + l.total),
      itemCount: lines.length,
    );
  }

  /// YYYY-MM-DD كما يطلبها ERPNext
  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// القيم قد تصل رقمًا أو نصًا أو null
  static double _num(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
