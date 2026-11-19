import 'package:flutter/foundation.dart';

import '../../core/utils/palestine_time.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/erp_customer.dart';
import '../models/return_models.dart';
import '../models/van_sale_models.dart';
import 'erp_customer_repository.dart';
import 'erp_sales_returns_repository.dart';

/// مبيعات الفان في ERPNext: العملاء، وحدات بيع المنتج وسعرها التقديري،
/// فاتورة مبيعات مسودة تُخرج البضاعة من مستودع الفان (Update Stock)، الإرجاع
/// من فواتير الفان المعتمدة، ورصيد العميل وحده الائتماني.
class ErpVanSalesRepository {
  ErpVanSalesRepository(this._api, this._customers, this._returns);

  final ErpApiClient _api;
  final ErpCustomerRepository _customers;

  /// إنشاء المرتجع وما بقي قابلًا للإرجاع: نفس منطق قسم «مردود المبيعات»
  final ErpSalesReturnsRepository _returns;

  /// العملاء (أو النسخة المحلية دون اتصال)، مرتبون بالاسم.
  Future<List<ErpCustomer>> fetchCustomers() async {
    final list = await _customers.fetchCustomersOrLocal();
    return [...list]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// وحدات بيع المنتج: وحدة المخزون أولًا (معامل 1)، ثم وحدات جدول uoms
  /// (مثل Box) بمعامل تحويلها، مع الوحدات التي لا تقبل كسورًا.
  Future<List<SaleUnit>> fetchUnits(String itemCode) async {
    final item = await _api.getDoc('Item', itemCode);
    final stockUom = item['stock_uom']?.toString() ?? '';
    final factors = <String, double>{if (stockUom.isNotEmpty) stockUom: 1};
    final rows = item['uoms'];
    if (rows is List) {
      for (final r in rows) {
        if (r is! Map) continue;
        final uom = r['uom']?.toString() ?? '';
        final f = _num(r['conversion_factor']);
        if (uom.isNotEmpty && f > 0) factors.putIfAbsent(uom, () => f);
      }
    }

    var whole = <String>{};
    try {
      final uoms = await _api.getAll(
        'UOM',
        fields: ['name', 'must_be_whole_number'],
        filters: [
          ['name', 'in', factors.keys.toList()],
        ],
      );
      whole = {
        for (final u in uoms)
          if ('${u['must_be_whole_number']}' == '1') u['name'].toString(),
      };
    } catch (e) {
      debugPrint('ErpVanSalesRepository UOM whole numbers failed: $e');
    }

    return [
      for (final e in factors.entries)
        SaleUnit(
          uom: e.key,
          factor: e.value,
          wholeNumber: whole.contains(e.key),
        ),
    ];
  }

  /// سعر تقديري للوحدة من قائمة أسعار البيع: سعر هذه الوحدة إن وُجد، وإلا سعر
  /// وحدة المخزون × المعامل. null = لا سعر. للعرض فقط: ERPNext يحسب السعر النهائي.
  Future<double?> estimatePrice(
    String itemCode,
    SaleUnit unit, {
    required String stockUom,
  }) async {
    final rows = await _api.getList(
      'Item Price',
      fields: ['price_list_rate', 'uom'],
      filters: [
        ['item_code', '=', itemCode],
        ['price_list', '=', ErpConfig.sellingPriceList],
        ['selling', '=', 1],
      ],
    );
    if (rows.isEmpty) return null;
    for (final r in rows) {
      if (r['uom']?.toString() == unit.uom) return _num(r['price_list_rate']);
    }
    for (final r in rows) {
      final uom = r['uom']?.toString() ?? '';
      // سعر وحدة المخزون (أو بلا وحدة) × المعامل
      if (uom.isEmpty || uom == stockUom) {
        return _num(r['price_list_rate']) * unit.factor;
      }
    }
    return null;
  }

  /// ينشئ فاتورة مبيعات **مسودة** (docstatus 0) تُخرج البضاعة من مستودع الفان
  /// عند اعتمادها (update_stock = 1). لا يُرسل rate: ERPNext يحسب السعر من قائمة
  /// الأسعار بعملة العميل.
  Future<CreatedSale> createDraftInvoice({
    required String customerId,
    required List<SaleLine> lines,
  }) async {
    final today = PalestineTime.date(PalestineTime.today());
    final data = await _api.postDoc('Sales Invoice', {
      'customer': customerId,
      'company': ErpConfig.company,
      'posting_date': today,
      'due_date': today,
      'selling_price_list': ErpConfig.sellingPriceList,
      'update_stock': 1,
      'set_warehouse': ErpConfig.vanWarehouse,
      // ضريبة القيمة المضافة 16% مشمولة في السعر
      'taxes_and_charges': ErpConfig.salesTaxTemplate,
      'docstatus': 0,
      'items': [
        for (final l in lines)
          {
            'item_code': l.itemCode,
            'qty': l.qty,
            'uom': l.unit.uom,
            'conversion_factor': l.unit.factor,
            'warehouse': ErpConfig.vanWarehouse,
          },
      ],
    });
    final name = data['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Sales Invoice $name (draft, update stock) created');
    final rounded = _num(data['rounded_total']);
    return CreatedSale(
      name: name,
      grandTotal: rounded != 0 ? rounded : _num(data['grand_total']),
      currency: data['currency']?.toString() ?? '',
    );
  }

  // ───────────────────────── الإرجاع ─────────────────────────

  /// فواتير الفان المعتمدة (Submitted، غير المرتجعات)، الأحدث أولًا: التي
  /// أخرجت البضاعة بنفسها (update_stock) من مستودع الفان.
  Future<List<VanInvoice>> fetchSubmittedInvoices() async {
    final rows = await _api.getAll(
      'Sales Invoice',
      fields: VanInvoice.fields,
      filters: [
        ['docstatus', '=', 1],
        ['is_return', '=', 0],
        ['update_stock', '=', 1],
        ['set_warehouse', '=', ErpConfig.vanWarehouse],
        ['company', '=', ErpConfig.company],
      ],
      orderBy: 'posting_date desc, creation desc',
    );
    return [for (final r in rows) VanInvoice.fromJson(r)];
  }

  /// بنود الفاتورة مع ما بقي قابلًا للإرجاع (الكمية − ما أُرجع في مرتجعات معتمدة).
  Future<List<ReturnableItem>> fetchReturnableItems(String invoice) =>
      _returns.fetchReturnableItems(invoice);

  /// ينشئ Sales Invoice من نوع Return مرتبطة بالفاتورة الأصلية (make_sales_return)
  /// ويحفظها **مسودة**؛ تُعيد البضاعة إلى مستودع الفان عند اعتمادها. يعيد
  /// المستند كما حسبه ERPNext (القيم والإجمالي).
  Future<VanReturnResult> createReturn({
    required String invoice,
    required List<ReturnableItem> items,
    required Map<String, double> quantities,
  }) async {
    final created = await _returns.createReturn(
      invoice: invoice,
      items: items,
      quantities: quantities,
    );
    return VanReturnResult.fromDoc(
      await _api.getDoc('Sales Invoice', created.creditNote),
    );
  }

  // ───────────────────────── رصيد العميل ─────────────────────────

  static const _customerModule = 'erpnext.selling.doctype.customer.customer';

  /// الحد الائتماني (get_credit_limit: من العميل، وإلا من مجموعته أو الشركة)
  /// والرصيد المستحق (get_customer_outstanding) كما يحسبهما ERPNext لفحص الحد،
  /// مع بيانات العميل.
  Future<CustomerCredit> fetchCredit(String customerId) async {
    final args = {'customer': customerId, 'company': ErpConfig.company};
    final results = await Future.wait([
      _api.getDoc('Customer', customerId),
      _api.postMethod('$_customerModule.get_customer_outstanding', args),
      _api.postMethod('$_customerModule.get_credit_limit', args),
    ]);
    final customer = results[0];
    final balance = _num(results[1]['message']);
    final limit = _num(results[2]['message']);
    final own = _limitFor(customer['credit_limits']);

    final name = customer['customer_name']?.toString() ?? '';
    return CustomerCredit(
      customerId: customerId,
      customerName: name.isEmpty ? customerId : name,
      customerGroup: customer['customer_group']?.toString() ?? '',
      phone: customer['mobile_no']?.toString() ?? '',
      creditLimit: limit > 0 ? limit : 0,
      limitSource: limit <= 0
          ? CreditLimitSource.none
          : own != null
          ? CreditLimitSource.customer
          : CreditLimitSource.customerGroup,
      bypassAtSalesOrder: own?.bypass ?? false,
      balance: balance,
      currency: ErpConfig.companyCurrency,
    );
  }

  /// صف الشركة في جدول credit_limits (Customer Credit Limit)، null إن لم يوجد
  static ({double limit, bool bypass})? _limitFor(Object? rows) {
    if (rows is! List) return null;
    for (final r in rows) {
      if (r is! Map || r['company']?.toString() != ErpConfig.company) continue;
      final limit = _num(r['credit_limit']);
      if (limit <= 0) return null;
      return (limit: limit, bypass: '${r['bypass_credit_limit_check']}' == '1');
    }
    return null;
  }

  // ───────────────────────── نهاية اليوم ─────────────────────────

  /// فواتير الفان ومرتجعاته في يوم [day] (مسودة ومعتمدة، غير الملغاة).
  Future<List<DaySale>> fetchDaySales(DateTime day) async {
    final rows = await _api.getAll(
      'Sales Invoice',
      fields: DaySale.fields,
      filters: [
        ['posting_date', '=', PalestineTime.date(day)],
        ['set_warehouse', '=', ErpConfig.vanWarehouse],
        ['company', '=', ErpConfig.company],
        ['docstatus', '!=', 2],
      ],
      orderBy: 'creation asc',
    );
    return [for (final r in rows) DaySale.fromJson(r)];
  }

  /// تسوية مخزون الفان مسودة (Stock Reconciliation): لكل منتج الكمية الفعلية
  /// بعد الجرد. لا يتغير المخزون إلا بعد اعتمادها. يعيد رقم المستند.
  Future<String> createReconciliation(Map<String, double> counted) async {
    final created = await _api.postDoc('Stock Reconciliation', {
      'purpose': 'Stock Reconciliation',
      'company': ErpConfig.company,
      'posting_date': PalestineTime.date(PalestineTime.today()),
      'set_warehouse': ErpConfig.vanWarehouse,
      if (ErpConfig.differenceAccount.isNotEmpty)
        'expense_account': ErpConfig.differenceAccount,
      'items': [
        for (final e in counted.entries)
          {
            'item_code': e.key,
            'warehouse': ErpConfig.vanWarehouse,
            'qty': e.value,
          },
      ],
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Stock Reconciliation $name (van) created');
    return name;
  }

  // ───────────────────────── طلب تزويد الفان ─────────────────────────

  /// طلب مواد مسودة من نوع Material Transfer: من المستودع الرئيسي إلى الفان.
  /// [quantities]: رمز المنتج → الكمية بوحدة المخزون. يعيد الطلب كما حفظه ERPNext.
  Future<ReplenishmentRequest> createReplenishment({
    required Map<String, ({double qty, String uom})> quantities,
  }) async {
    final today = PalestineTime.today();
    // المطلوب بحلول الغد (schedule_date حقل إلزامي)
    final needBy = PalestineTime.date(
      DateTime(today.year, today.month, today.day + 1),
    );
    final created = await _api.postDoc('Material Request', {
      'material_request_type': 'Material Transfer',
      'company': ErpConfig.company,
      'transaction_date': PalestineTime.date(today),
      'schedule_date': needBy,
      'set_from_warehouse': ErpConfig.mainStore,
      'set_warehouse': ErpConfig.vanWarehouse,
      'items': [
        for (final e in quantities.entries)
          {
            'item_code': e.key,
            'qty': e.value.qty,
            if (e.value.uom.isNotEmpty) 'uom': e.value.uom,
            'schedule_date': needBy,
            'from_warehouse': ErpConfig.mainStore,
            'warehouse': ErpConfig.vanWarehouse,
          },
      ],
    });
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    debugPrint('Material Request $name (van replenishment) created');
    return ReplenishmentRequest.fromDoc(
      await _api.getDoc('Material Request', name),
    );
  }

  static double _num(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
}
