/// تحويل آمن لقيمة JSON إلى رقم (ERPNext يرسل الأرقام num، وأحيانًا null)
double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _toText(Object? value) => value?.toString() ?? '';

/// عميل لديه فواتير مبيعات معتمدة سابقة (لاختياره في «مردود المبيعات»).
class ReturnCustomer {
  final String id;
  final String name;
  final int invoiceCount;

  /// تاريخ آخر فاتورة yyyy-MM-dd
  final String lastDate;

  const ReturnCustomer({
    required this.id,
    required this.name,
    required this.invoiceCount,
    required this.lastDate,
  });

  /// يجمع صفوف الفواتير (customer, customer_name, posting_date) لكل عميل،
  /// الأحدث فاتورةً أولًا.
  static List<ReturnCustomer> fromInvoiceRows(List<Map<String, dynamic>> rows) {
    final byId = <String, ReturnCustomer>{};
    for (final row in rows) {
      final id = _toText(row['customer']);
      if (id.isEmpty) continue;
      final date = _toText(row['posting_date']);
      final old = byId[id];
      byId[id] = ReturnCustomer(
        id: id,
        name: _toText(row['customer_name']).isEmpty
            ? id
            : _toText(row['customer_name']),
        invoiceCount: (old?.invoiceCount ?? 0) + 1,
        lastDate: old == null || date.compareTo(old.lastDate) > 0
            ? date
            : old.lastDate,
      );
    }
    return byId.values.toList()
      ..sort((a, b) => b.lastDate.compareTo(a.lastDate));
  }
}

/// فاتورة مبيعات معتمدة للعميل يمكن الإرجاع منها. الحالة للعرض فقط:
/// المرتجعة جزئيًا تظهر «Credit Note Issued» ويبقى فيها ما يُرجع.
class ReturnInvoice {
  final String name;
  final String postingDate;
  final String currency;
  final double grandTotal;
  final double outstandingAmount;
  final String status;

  const ReturnInvoice({
    required this.name,
    required this.postingDate,
    required this.currency,
    required this.grandTotal,
    required this.outstandingAmount,
    required this.status,
  });

  factory ReturnInvoice.fromJson(Map<String, dynamic> json) => ReturnInvoice(
        name: _toText(json['name']),
        postingDate: _toText(json['posting_date']),
        currency: _toText(json['currency']),
        grandTotal: _toDouble(json['grand_total']),
        outstandingAmount: _toDouble(json['outstanding_amount']),
        status: _toText(json['status']),
      );
}

/// بند في الفاتورة الأصلية مع ما أُرجع منه سابقًا (مرتجعات معتمدة).
class ReturnableItem {
  /// رقم الصف في الفاتورة (يطابق sales_invoice_item في المرتجع)
  final String rowName;
  final String itemCode;
  final String itemName;
  final double qty;
  final String uom;
  final double rate;
  final double amount;

  /// إذن التسليم الذي خرجت منه البضاعة (فارغ إن حدّثت الفاتورة المخزون بنفسها)
  final String deliveryNote;
  final String dnDetail;

  /// موجب: مجموع ما أُرجع من هذا الصف في مرتجعات معتمدة سابقة
  final double returnedQty;

  /// الوحدة لا تقبل كسورًا (UOM.must_be_whole_number)
  final bool wholeNumber;

  const ReturnableItem({
    required this.rowName,
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.uom,
    required this.rate,
    required this.amount,
    required this.deliveryNote,
    required this.dnDetail,
    required this.returnedQty,
    required this.wholeNumber,
  });

  double get returnable {
    final left = qty - returnedQty;
    return left > 0.0001 ? left : 0;
  }

  factory ReturnableItem.fromJson(
    Map<String, dynamic> json, {
    required double returnedQty,
    required bool wholeNumber,
  }) =>
      ReturnableItem(
        rowName: _toText(json['name']),
        itemCode: _toText(json['item_code']),
        itemName: _toText(json['item_name']).isEmpty
            ? _toText(json['item_code'])
            : _toText(json['item_name']),
        qty: _toDouble(json['qty']),
        uom: _toText(json['uom']),
        rate: _toDouble(json['rate']),
        amount: _toDouble(json['amount']),
        deliveryNote: _toText(json['delivery_note']),
        dnDetail: _toText(json['dn_detail']),
        returnedQty: returnedQty,
        wholeNumber: wholeNumber,
      );
}

/// مرتجع محفوظ مسودة بانتظار الاعتماد: إشعار دائن (Sales Invoice) أو
/// إرجاع بضاعة للمخزون (Delivery Note).
class PendingReturn {
  static const creditNote = 'Sales Invoice';
  static const stockReturn = 'Delivery Note';

  final String doctype;
  final String name;
  final String customer;
  final String customerName;
  final String returnAgainst;

  /// سالب كما في ERPNext
  final double grandTotal;
  final String currency;
  final String remarks;

  const PendingReturn({
    required this.doctype,
    required this.name,
    required this.customer,
    required this.customerName,
    required this.returnAgainst,
    required this.grandTotal,
    required this.currency,
    required this.remarks,
  });

  bool get isCreditNote => doctype == creditNote;

  factory PendingReturn.fromJson(String doctype, Map<String, dynamic> json) =>
      PendingReturn(
        doctype: doctype,
        name: _toText(json['name']),
        customer: _toText(json['customer']),
        customerName: _toText(json['customer_name']),
        returnAgainst: _toText(json['return_against']),
        grandTotal: _toDouble(json['grand_total']),
        currency: _toText(json['currency']),
        remarks: _toText(json['remarks']),
      );
}

/// ما أُنشئ عند حفظ المرتجع: إشعار الدائن، وأذون إرجاع البضاعة، وما فشل منها.
class CreatedReturn {
  final String creditNote;
  final List<String> stockReturns;

  /// أذون التسليم التي تعذّر إنشاء إرجاعها مع سبب الخطأ
  final Map<String, String> stockErrors;

  const CreatedReturn({
    required this.creditNote,
    required this.stockReturns,
    required this.stockErrors,
  });
}

/// هل يُرَدّ مال للعميل بعد اعتماد إشعار الدائن.
class RefundCheck {
  /// موجب: المبلغ الذي يمكن رده (0 = لا شيء)
  final double refundable;

  /// صافي ما على العميل بعد المرتجع (موجب = ما زال مدينًا فلا رد)
  final double customerOutstanding;
  final String currency;

  const RefundCheck({
    required this.refundable,
    required this.customerOutstanding,
    required this.currency,
  });

  bool get canRefund => refundable > 0.005 && customerOutstanding <= 0.005;
}
