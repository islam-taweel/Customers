/// وحدة بيع للمنتج (Piece، Box…): من جدول UOM Conversion Detail في Item.
/// [factor] = كم وحدة مخزون في هذه الوحدة (الكرتونة = 12 قطعة مثلًا).
class SaleUnit {
  final String uom;
  final double factor;

  /// الوحدة لا تقبل كسورًا (UOM.must_be_whole_number)
  final bool wholeNumber;

  const SaleUnit({
    required this.uom,
    required this.factor,
    this.wholeNumber = false,
  });
}

/// بند في فاتورة البيع الجديدة
class SaleLine {
  final String itemCode;
  final String itemName;
  final SaleUnit unit;
  final double qty;

  /// سعر الوحدة التقديري من قائمة الأسعار (null = لا سعر معروف). السعر النهائي
  /// يحدده ERPNext عند الحفظ.
  final double? price;

  const SaleLine({
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.qty,
    this.price,
  });

  /// الكمية بوحدة المخزون (ما يُخصم من الفان)
  double get stockQty => qty * unit.factor;

  double? get amount => price == null ? null : price! * qty;

  SaleLine copyWith({double? qty, double? price}) => SaleLine(
    itemCode: itemCode,
    itemName: itemName,
    unit: unit,
    qty: qty ?? this.qty,
    price: price ?? this.price,
  );
}

/// الفاتورة بعد الحفظ كما ردّ بها ERPNext
class CreatedSale {
  final String name;
  final double grandTotal;
  final String currency;

  const CreatedSale({
    required this.name,
    required this.grandTotal,
    required this.currency,
  });
}

double _n(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
String _s(Object? v) => v?.toString() ?? '';

/// فاتورة مبيعات معتمدة من الفان (يمكن الإرجاع منها)
class VanInvoice {
  final String name;
  final String customer;
  final String customerName;
  final DateTime? postingDate;
  final double grandTotal;
  final double outstanding;
  final String currency;
  final String status;

  const VanInvoice({
    required this.name,
    required this.customer,
    required this.customerName,
    required this.postingDate,
    required this.grandTotal,
    required this.outstanding,
    required this.currency,
    required this.status,
  });

  static const fields = [
    'name',
    'customer',
    'customer_name',
    'posting_date',
    'grand_total',
    'rounded_total',
    'outstanding_amount',
    'currency',
    'status',
  ];

  factory VanInvoice.fromJson(Map<String, dynamic> json) {
    final rounded = _n(json['rounded_total']);
    final customer = _s(json['customer']);
    final name = _s(json['customer_name']);
    return VanInvoice(
      name: _s(json['name']),
      customer: customer,
      customerName: name.isEmpty ? customer : name,
      postingDate: DateTime.tryParse(_s(json['posting_date'])),
      grandTotal: rounded != 0 ? rounded : _n(json['grand_total']),
      outstanding: _n(json['outstanding_amount']),
      currency: _s(json['currency']),
      status: _s(json['status']),
    );
  }
}

/// بند في مستند الإرجاع كما حسبه ERPNext (الكمية والمبلغ سالبان)
class ReturnLine {
  final String itemName;
  final double qty;
  final String uom;
  final double rate;
  final double amount;

  const ReturnLine({
    required this.itemName,
    required this.qty,
    required this.uom,
    required this.rate,
    required this.amount,
  });
}

/// مستند الإرجاع (Sales Invoice، is_return) بعد حفظه مسودة: القيم من ERPNext
class VanReturnResult {
  final String name;
  final String returnAgainst;
  final double netTotal;
  final double taxes;
  final double grandTotal;
  final String currency;
  final List<ReturnLine> lines;

  const VanReturnResult({
    required this.name,
    required this.returnAgainst,
    required this.netTotal,
    required this.taxes,
    required this.grandTotal,
    required this.currency,
    required this.lines,
  });

  factory VanReturnResult.fromDoc(Map<String, dynamic> doc) {
    final rounded = _n(doc['rounded_total']);
    final items = doc['items'];
    return VanReturnResult(
      name: _s(doc['name']),
      returnAgainst: _s(doc['return_against']),
      netTotal: _n(doc['net_total']),
      taxes: _n(doc['total_taxes_and_charges']),
      grandTotal: rounded != 0 ? rounded : _n(doc['grand_total']),
      currency: _s(doc['currency']),
      lines: [
        if (items is List)
          for (final r in items)
            if (r is Map)
              ReturnLine(
                itemName: _s(r['item_name']).isEmpty
                    ? _s(r['item_code'])
                    : _s(r['item_name']),
                qty: _n(r['qty']),
                uom: _s(r['uom']),
                rate: _n(r['rate']),
                amount: _n(r['amount']),
              ),
      ],
    );
  }
}

/// من أين جاء الحد الائتماني
enum CreditLimitSource { customer, customerGroup, none }

/// رصيد العميل وحده الائتماني (بعملة الشركة)
class CustomerCredit {
  final String customerId;
  final String customerName;
  final String customerGroup;
  final String phone;

  /// Credit Limit للشركة (0 = لا حد)
  final double creditLimit;
  final CreditLimitSource limitSource;

  /// تخطي فحص الحد عند أمر البيع (bypass_credit_limit_check)
  final bool bypassAtSalesOrder;

  /// الرصيد الحالي المستحق على العميل (get_balance_on، موجب = مدين)
  final double balance;
  final String currency;

  const CustomerCredit({
    required this.customerId,
    required this.customerName,
    required this.customerGroup,
    required this.phone,
    required this.creditLimit,
    required this.limitSource,
    required this.bypassAtSalesOrder,
    required this.balance,
    required this.currency,
  });

  bool get hasLimit => creditLimit > 0;

  /// المتبقي من الحد = الحد − الرصيد (قد يكون سالبًا إن تجاوزه)
  double get available => creditLimit - balance;

  /// هل يتجاوز الحد بعد إضافة [amount]
  bool exceedsWith(double amount) =>
      hasLimit && balance + amount > creditLimit + 0.005;
}

/// فاتورة (أو مرتجع) من الفان في يوم: للملخص اليومي، بعملة الشركة
class DaySale {
  final String name;
  final String customerName;
  final double total;
  final bool isReturn;

  /// 0 مسودة، 1 معتمدة
  final int docstatus;
  final String status;

  const DaySale({
    required this.name,
    required this.customerName,
    required this.total,
    required this.isReturn,
    required this.docstatus,
    required this.status,
  });

  bool get isDraft => docstatus == 0;

  static const fields = [
    'name',
    'customer',
    'customer_name',
    'base_grand_total',
    'base_rounded_total',
    'is_return',
    'docstatus',
    'status',
  ];

  factory DaySale.fromJson(Map<String, dynamic> json) {
    final rounded = _n(json['base_rounded_total']);
    final name = _s(json['customer_name']);
    return DaySale(
      name: _s(json['name']),
      customerName: name.isEmpty ? _s(json['customer']) : name,
      total: rounded != 0 ? rounded : _n(json['base_grand_total']),
      isReturn: '${json['is_return']}' == '1',
      docstatus: _n(json['docstatus']).toInt(),
      status: _s(json['status']),
    );
  }
}

/// بند في طلب التزويد (Material Request) كما حفظه ERPNext
class RequestLine {
  final String itemCode;
  final String itemName;
  final double qty;
  final String uom;

  const RequestLine({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.uom,
  });
}

/// طلب تزويد مخزون الفان بعد حفظه (Material Request / Material Transfer)
class ReplenishmentRequest {
  final String name;
  final String status;
  final DateTime? transactionDate;
  final DateTime? scheduleDate;
  final String fromWarehouse;
  final String toWarehouse;
  final List<RequestLine> lines;

  const ReplenishmentRequest({
    required this.name,
    required this.status,
    required this.transactionDate,
    required this.scheduleDate,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.lines,
  });

  factory ReplenishmentRequest.fromDoc(Map<String, dynamic> doc) {
    final items = doc['items'];
    return ReplenishmentRequest(
      name: _s(doc['name']),
      status: _s(doc['status']),
      transactionDate: DateTime.tryParse(_s(doc['transaction_date'])),
      scheduleDate: DateTime.tryParse(_s(doc['schedule_date'])),
      fromWarehouse: _s(doc['set_from_warehouse']),
      toWarehouse: _s(doc['set_warehouse']),
      lines: [
        if (items is List)
          for (final r in items)
            if (r is Map)
              RequestLine(
                itemCode: _s(r['item_code']),
                itemName: _s(r['item_name']).isEmpty
                    ? _s(r['item_code'])
                    : _s(r['item_name']),
                qty: _n(r['qty']),
                uom: _s(r['uom']),
              ),
      ],
    );
  }
}
