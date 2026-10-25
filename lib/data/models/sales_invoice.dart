/// تحويل آمن لقيمة JSON إلى رقم (ERPNext يرسل الأرقام num، وأحيانًا null)
double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _toText(Object? value) => value?.toString() ?? '';

/// تبويبات قسم «الفواتير»: تُحسب من مبالغ الفاتورة في ERPNext (لا من نص الحالة)
/// لأن حالة Overdue تغطي المدفوعة جزئيًا المتأخرة أيضًا.
enum InvoiceBucket { draft, unpaid, partlyPaid, paid, other }

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

  /// عملة الفاتورة (فارغة = الشيكل أو نسخة محفوظة قديمة بلا عملة)
  final String currency;

  /// true = فاتورة طلبية محفوظة على الهاتف (وليست من ERPNext)
  final bool isLocal;

  /// 0 = مسودة، 1 = معتمدة في ERPNext
  final int docstatus;

  const SalesInvoice({
    required this.name,
    required this.customer,
    required this.customerName,
    required this.postingDate,
    required this.dueDate,
    required this.grandTotal,
    required this.outstandingAmount,
    required this.status,
    this.currency = '',
    this.isLocal = false,
    this.docstatus = 1,
  });

  /// أي تبويب في قسم «الفواتير» تنتمي إليه (المرتجعات وإشعارات الدائن خارج التبويبات)
  InvoiceBucket get bucket {
    if (docstatus == 0) return InvoiceBucket.draft;
    if (docstatus != 1 || isLocal) return InvoiceBucket.other;
    if (status == 'Return' ||
        status == 'Credit Note Issued' ||
        status == 'Cancelled') {
      return InvoiceBucket.other;
    }
    if (grandTotal <= 0) return InvoiceBucket.other;
    if (outstandingAmount <= 0.005) return InvoiceBucket.paid;
    if (outstandingAmount < grandTotal - 0.005) return InvoiceBucket.partlyPaid;
    return InvoiceBucket.unpaid;
  }

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
      currency: _toText(json['currency']),
      docstatus: json['docstatus'] is num
          ? (json['docstatus'] as num).toInt()
          : int.tryParse('${json['docstatus']}') ?? 1,
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
