import 'package:flutter/foundation.dart';

import '../api/erp_api_client.dart';
import '../../core/constants/app_strings.dart';
import '../api/erp_config.dart';
import '../models/order_models.dart';
import '../models/pending_order.dart';
import '../models/sync_models.dart';
import 'catalog_store.dart';

/// كل ما يخص طلبيات العملاء في ERPNext: مجموعات الأصناف، الأصناف، السعر والمخزون،
/// وإنشاء الطلبية (Sales Order). العملاء يأتون من [ErpCustomerRepository].
///
/// العمل دون إنترنت: كل ما يُجلب من ERPNext يُحفظ في [CatalogStore]، وعند تعذّر
/// الوصول للخادم تُقرأ النسخة المحلية. والمزامنة الكاملة من الإعدادات تجلب
/// الكتالوج كله دفعة واحدة ([syncCatalog]).
class ErpOrderRepository {
  ErpOrderRepository(this._api, this._catalog);

  final ErpApiClient _api;
  final CatalogStore _catalog;

  /// الخادم أولًا ثم النسخة المحلية عند انقطاع الاتصال فقط.
  /// أثناء انقطاع معروف (فشل حديث) نقرأ المحلي مباشرة دون انتظار المهلة.
  Future<T> _remoteOrLocal<T>({
    required Future<T> Function() remote,
    required Future<T?> Function() local,
  }) async {
    if (_api.recentlyUnreachable) {
      final cached = await _safeLocal(local);
      if (cached != null) return cached;
    }
    try {
      return await remote();
    } on ErpApiException catch (e) {
      if (e.type == ErpErrorType.network) {
        final cached = await _safeLocal(local);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  Future<T?> _safeLocal<T>(Future<T?> Function() local) async {
    try {
      return await local();
    } catch (e) {
      debugPrint('ErpOrderRepository: local read failed: $e');
      return null;
    }
  }

  /// حفظ نسخة محلية بعد جلب ناجح؛ فشلها لا يوقف التطبيق.
  Future<void> _save(Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      debugPrint('ErpOrderRepository: local save failed: $e');
    }
  }

  // ───────────────────────── المجموعات ─────────────────────────

  /// المجموعات النهائية فقط (is_group = 0). الشجرة بمستوى واحد.
  Future<List<String>> fetchItemGroups() {
    return _remoteOrLocal<List<String>>(
      remote: () async {
        final groups = await _fetchGroupsRemote();
        if (groups.isNotEmpty) await _save(() => _catalog.saveGroups(groups));
        return groups;
      },
      local: _catalog.readGroups,
    );
  }

  Future<List<String>> _fetchGroupsRemote() async {
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

  // ───────────────────────── الأصناف ─────────────────────────

  /// أصناف المجموعة المفعّلة والقابلة للبيع.
  Future<List<ErpItem>> fetchItems(String group) {
    return _remoteOrLocal<List<ErpItem>>(
      remote: () async {
        final rows = await _api.getAll(
          'Item',
          fields: ['item_code', 'item_name', 'stock_uom'],
          filters: [
            ['item_group', '=', group],
            ['disabled', '=', 0],
            ['is_sales_item', '=', 1],
          ],
        );
        final items = _parseItems(rows);
        await _save(() => _catalog.saveItemsForGroup(group, items));
        return items;
      },
      local: () => _catalog.readItems(group),
    );
  }

  List<ErpItem> _parseItems(List<Map<String, dynamic>> rows) {
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

  // ───────────────────────── السعر والمخزون ─────────────────────────

  /// السعر والمخزون معًا (طلبان متوازيان) عند الضغط على صنف.
  Future<ItemPricing> fetchPricing(String itemCode) {
    return _remoteOrLocal<ItemPricing>(
      remote: () async {
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
        final rate =
            priceRows.isEmpty ? null : _num(priceRows.first['price_list_rate']);

        // قائمة فارغة = لا مخزون (0)
        var available = 0.0;
        for (final row in results[1]) {
          available += _num(row['actual_qty']) - _num(row['reserved_qty']);
        }
        if (available < 0) available = 0;

        final pricing = ItemPricing(rate: rate, available: available);
        await _save(() => _catalog.savePricing(itemCode, pricing));
        return pricing;
      },
      local: () => _catalog.readPricing(itemCode),
    );
  }

  // ───────────────────────── المزامنة الكاملة ─────────────────────────

  /// يجلب الكتالوج كله (المجموعات، الأصناف، الأسعار، المخزون) بـ 4 طلبات
  /// مقسّمة على صفحات، ويحفظه محليًا ليعمل إنشاء الطلبيات دون إنترنت.
  /// يرمي [ErpApiException] عند الفشل، وتبقى النسخة المحلية القديمة كما هي.
  Future<({int groups, int items})> syncCatalog({
    void Function(double progress, SyncStep step)? onProgress,
  }) async {
    onProgress?.call(0.02, SyncStep.groups);
    final groups = await _fetchGroupsRemote();

    onProgress?.call(0.15, SyncStep.items);
    final itemRows = await _api.getAll(
      'Item',
      fields: ['item_code', 'item_name', 'stock_uom', 'item_group'],
      filters: [
        ['disabled', '=', 0],
        ['is_sales_item', '=', 1],
      ],
    );

    onProgress?.call(0.5, SyncStep.prices);
    final priceRows = await _api.getAll(
      'Item Price',
      fields: ['item_code', 'price_list_rate'],
      filters: [
        ['price_list', '=', ErpConfig.sellingPriceList],
        ['selling', '=', 1],
      ],
    );

    onProgress?.call(0.75, SyncStep.stock);
    final binRows = await _api.getAll(
      'Bin',
      fields: ['item_code', 'actual_qty', 'reserved_qty'],
      filters: [
        ['warehouse', '=', ErpConfig.warehouse],
      ],
    );

    onProgress?.call(0.92, SyncStep.saving);

    // الأصناف حسب مجموعتها
    final byGroup = <String, List<ErpItem>>{};
    var itemCount = 0;
    for (final row in itemRows) {
      final group = row['item_group']?.toString() ?? '';
      final parsed = _parseItems([row]);
      if (group.isEmpty || parsed.isEmpty) continue;
      byGroup.putIfAbsent(group, () => []).add(parsed.first);
      itemCount++;
    }

    // أول سعر لكل صنف (كما يفعل الجلب الفردي)
    final rateByCode = <String, double>{};
    for (final row in priceRows) {
      final code = row['item_code']?.toString() ?? '';
      if (code.isEmpty) continue;
      rateByCode.putIfAbsent(code, () => _num(row['price_list_rate']));
    }

    // المتاح = actual_qty - reserved_qty مجموعًا على الصفوف
    final availableByCode = <String, double>{};
    for (final row in binRows) {
      final code = row['item_code']?.toString() ?? '';
      if (code.isEmpty) continue;
      availableByCode[code] = (availableByCode[code] ?? 0) +
          _num(row['actual_qty']) -
          _num(row['reserved_qty']);
    }

    final pricing = <String, ItemPricing>{};
    for (final items in byGroup.values) {
      for (final item in items) {
        final available = availableByCode[item.code] ?? 0;
        pricing[item.code] = ItemPricing(
          rate: rateByCode[item.code],
          available: available < 0 ? 0 : available,
        );
      }
    }

    // حماية: رد فارغ لا يمحو النسخة المحلية الموجودة
    if (groups.isNotEmpty) await _catalog.saveGroups(groups);
    if (itemCount > 0) {
      await _catalog.saveAllItems(byGroup);
      await _catalog.saveAllPricing(pricing);
    }

    return (groups: groups.length, items: itemCount);
  }

  // ───────────────────────── إنشاء الطلبية ─────────────────────────

  /// سعر تحويل عملة الطلبية إلى عملة الشركة (ILS): كم شيكلًا تساوي وحدة واحدة منها.
  /// يُجلب وقت الطلب من ERPNext ولا يُخمَّن: إن لم يوجد سعر (0 أو خطأ) يُرمى خطأ
  /// بنصٍّ واضح فيُمنع الإجراء.
  Future<double> conversionRate(String currency) async {
    if (currency.isEmpty || currency == ErpConfig.priceListCurrency) return 1;
    final res = await _api.getMethod('erpnext.setup.utils.get_exchange_rate', {
      'from_currency': currency,
      'to_currency': ErpConfig.priceListCurrency,
      'transaction_date': _date(DateTime.now()),
    });
    final raw = res['message'];
    final rate = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    if (rate <= 0) {
      throw ErpApiException(
        ErpErrorType.server,
        detail: AppStrings.exchangeRateMissing(
          currency,
          ErpConfig.priceListCurrency,
        ),
      );
    }
    return rate;
  }

  /// ينشئ الطلبية (تُحفظ كمسودة Draft) ويعيد رقمها. أسعار [lines] بعملة
  /// الطلبية [currency]، و[conversionRate] سعر تحويلها إلى الشيكل.
  Future<CreatedOrder> createOrder({
    required String customerId,
    required DateTime deliveryDate,
    required List<CartLine> lines,
    String currency = ErpConfig.priceListCurrency,
    double conversionRate = 1,
    String notes = '',
  }) {
    return _createOrder(
      customerId: customerId,
      currency: currency,
      conversionRate: conversionRate,
      notes: notes,
      transactionDate: _date(DateTime.now()),
      deliveryDate: _date(deliveryDate),
      lines: [
        for (final l in lines) (code: l.item.code, qty: l.qty, rate: l.rate),
      ],
    );
  }

  /// يرفع طلبية محفوظة محليًا (أُنشئت دون اتصال) بتاريخها الأصلي.
  Future<CreatedOrder> createOrderFromPending(PendingOrder order) {
    return _createOrder(
      customerId: order.customerErpId,
      currency: ErpConfig.priceListCurrency,
      conversionRate: 1,
      notes: order.notes ?? '',
      transactionDate: order.transactionDate,
      deliveryDate: order.deliveryDate,
      lines: [
        for (final l in order.lines) (code: l.code, qty: l.qty, rate: l.rate),
      ],
    );
  }

  Future<CreatedOrder> _createOrder({
    required String customerId,
    required String currency,
    required double conversionRate,
    required String transactionDate,
    required String deliveryDate,
    required List<({String code, double qty, double rate})> lines,
    String notes = '',
  }) async {
    final body = {
      'customer': customerId,
      'company': ErpConfig.company,
      'transaction_date': transactionDate,
      'delivery_date': deliveryDate,
      // عملة الطلبية وسعر تحويلها إلى الشيكل (1 للشيكل). السعر غير مقرّب
      'currency': currency,
      'conversion_rate': conversionRate,
      'selling_price_list': ErpConfig.sellingPriceList,
      'price_list_currency': ErpConfig.priceListCurrency,
      'plc_conversion_rate': ErpConfig.priceListConversionRate,
      // ملاحظات الطلبية (إن كُتبت)
      if (notes.trim().isNotEmpty) ErpConfig.orderNotesField: notes.trim(),
      'items': [
        for (final line in lines)
          {
            'item_code': line.code,
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
      total: lines.fold<double>(0, (sum, l) => sum + l.qty * l.rate),
      itemCount: lines.length,
      currency: currency == ErpConfig.priceListCurrency ? null : currency,
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
