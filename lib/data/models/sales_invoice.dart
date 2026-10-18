/// تحويل آمن لقيمة JSON إلى رقم (ERPNext يرسل الأرقام num، وأحيانًا null)
double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _toText(Object? value) => value?.toString() ?? '';

/// فاتورة مبيعات كما تظهر في قائمة فواتير العميل.
class SalesInvoice {
  final String name;
  final String customer;
  final String customerName;

  /// تاريخ الفاتورة بصيغة yyyy-MM-dd (نص، يُرتَّب أبجديًا كالتاريخ)
  final String postingDate;
  final String? dueDate;
  final double grandTotal;

  /// المتبقي على الفاتورة. سالب في فاتورة المرتجع.
  final double outstandingAmount;
  final String status;

  const SalesInvoice({
    required this.name,
    required this.customer,
    required this.customerName,
    required this.postingDate,
    required this.dueDate,
    required this.grandTotal,
    required this.outstandingAmount,
    required this.status,
  });

  factory SalesInvoice.fromJson(Map<String, dynamic> json) {
    return SalesInvoice(
      name: _toText(json['name']),
      customer: _toText(json['customer']),
      customerName: _toText(json['customer_name']),
      postingDate: _toText(json['posting_date']),
      dueDate: json['due_date']?.toString(),
      grandTotal: _toDouble(json['grand_total']),
      outstandingAmount: _toDouble(json['outstanding_amount']),
      status: _toText(json['status']),
    );
  }
}

/// بند (صنف) داخل فاتورة.
class InvoiceItem {
  final String itemName;
  final double qty;
  final double rate;
  final double amount;

  const InvoiceItem({
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      itemName: _toText(json['item_name']),
      qty: _toDouble(json['qty']),
      rate: _toDouble(json['rate']),
      amount: _toDouble(json['amount']),
    );
  }
}

/// تفاصيل فاتورة واحدة (عند الضغط عليها): الحقول العامة وقائمة الأصناف.
class SalesInvoiceDetail {
  final String name;
  final String customerName;
  final String postingDate;
  final String? dueDate;
  final double grandTotal;
  final double totalTaxesAndCharges;
  final double outstandingAmount;
  final String status;
  final String currency;
  final List<InvoiceItem> items;

  const SalesInvoiceDetail({
    required this.name,
    required this.customerName,
    required this.postingDate,
    required this.dueDate,
    required this.grandTotal,
    required this.totalTaxesAndCharges,
    required this.outstandingAmount,
    required this.status,
    required this.currency,
    required this.items,
  });

  factory SalesInvoiceDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return SalesInvoiceDetail(
      name: _toText(json['name']),
      customerName: _toText(json['customer_name']),
      postingDate: _toText(json['posting_date']),
      dueDate: json['due_date']?.toString(),
      grandTotal: _toDouble(json['grand_total']),
      totalTaxesAndCharges: _toDouble(json['total_taxes_and_charges']),
      outstandingAmount: _toDouble(json['outstanding_amount']),
      status: _toText(json['status']),
      currency: _toText(json['currency']),
      items: [
        if (rawItems is List)
          for (final item in rawItems)
            InvoiceItem.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }
}
