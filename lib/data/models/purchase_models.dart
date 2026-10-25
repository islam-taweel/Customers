/// نماذج قسم «المشتريات»: أمر الشراء (Purchase Order) والاستلام (Purchase Receipt)
/// وفاتورة المشتريات (Purchase Invoice). كلها تُقرأ من ERPNext مباشرة.

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _toText(Object? value) => value?.toString() ?? '';

int _toInt(Object? value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

bool _isComplete(Object? percent) => _toDouble(percent) >= 99.99;

/// مراحل أمر الشراء = تبويباته: مسودة ← بانتظار الاستلام ← بانتظار الفوترة ← مكتملة.
enum PurchaseStage { draft, toReceive, toBill, completed }

/// حالة الاستلام المرتبط بأمر شراء في ERPNext.
enum ReceiptLink { none, draft, submitted }

/// أمر شراء كما يظهر في القوائم.
class PurchaseOrder {
  final String name;
  final String supplier;
  final String supplierName;
  final String transactionDate;
  final String? scheduleDate;
  final double grandTotal;
  final double totalQty;
  final String currency;

  /// 0 = مسودة، 1 = معتمد
  final int docstatus;
  final String status;
  final bool received;
  final bool billed;

  /// أحدث حالة استلام مرتبط به (استلام مسودة أو معتمد)
  final ReceiptLink receipt;

  const PurchaseOrder({
    required this.name,
    required this.supplier,
    required this.supplierName,
    required this.transactionDate,
    required this.scheduleDate,
    required this.grandTotal,
    required this.totalQty,
    required this.currency,
    required this.docstatus,
    required this.status,
    required this.received,
    required this.billed,
    this.receipt = ReceiptLink.none,
  });

  String get displaySupplier => supplierName.isEmpty ? supplier : supplierName;

  PurchaseOrder withReceipt(ReceiptLink link) => PurchaseOrder(
        name: name,
        supplier: supplier,
        supplierName: supplierName,
        transactionDate: transactionDate,
        scheduleDate: scheduleDate,
        grandTotal: grandTotal,
        totalQty: totalQty,
        currency: currency,
        docstatus: docstatus,
        status: status,
        received: received,
        billed: billed,
        receipt: link,
      );

  /// المرحلة. المعتمد الذي أُنشئ له استلام مسودة ينتقل إلى «بانتظار الفوترة»
  /// وتبقى الفوترة مظللة إلى أن يعتمد ERPNext الاستلام (كما في المبيعات).
  PurchaseStage get stage {
    if (docstatus == 0) return PurchaseStage.draft;
    if (received && billed) return PurchaseStage.completed;
    if (received || receipt == ReceiptLink.draft) return PurchaseStage.toBill;
    return PurchaseStage.toReceive;
  }

  /// مسموح الاستلام: معتمد، لم يُستلم بالكامل، وليس له استلام مسودة بالفعل
  bool get canReceive =>
      docstatus == 1 && !received && receipt != ReceiptLink.draft;

  /// الفوترة تحتاج استلامًا معتمدًا
  bool get canBill => docstatus == 1 && received && !billed;

  /// استلام مسودة بانتظار اعتماد ERPNext
  bool get awaitingReceiptApproval =>
      docstatus == 1 && !received && receipt == ReceiptLink.draft;

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => PurchaseOrder(
        name: _toText(json['name']),
        supplier: _toText(json['supplier']),
        supplierName: _toText(json['supplier_name']),
        transactionDate: _toText(json['transaction_date']),
        scheduleDate: json['schedule_date']?.toString(),
        grandTotal: _toDouble(json['grand_total']),
        totalQty: _toDouble(json['total_qty']),
        currency: _toText(json['currency']),
        docstatus: _toInt(json['docstatus'], 1),
        status: _toText(json['status']),
        received: _isComplete(json['per_received']),
        billed: _isComplete(json['per_billed']),
      );
}

/// استلام (Purchase Receipt).
class PurchaseReceipt {
  final String name;
  final String supplier;
  final String supplierName;
  final String postingDate;
  final double grandTotal;
  final double totalQty;
  final String currency;
  final int docstatus;
  final String status;
  final bool billed;

  /// أمر الشراء المرتبط (فارغ إن لم يُعرف)
  final String purchaseOrder;

  const PurchaseReceipt({
    required this.name,
    required this.supplier,
    required this.supplierName,
    required this.postingDate,
    required this.grandTotal,
    required this.totalQty,
    required this.currency,
    required this.docstatus,
    required this.status,
    required this.billed,
    required this.purchaseOrder,
  });

  String get displaySupplier => supplierName.isEmpty ? supplier : supplierName;

  /// زر «فوترة» يظهر على الاستلام المعتمد (To Bill) فقط
  bool get canBill => docstatus == 1 && !billed && status != 'Return';

  factory PurchaseReceipt.fromJson(Map<String, dynamic> json) {
    return PurchaseReceipt(
      name: _toText(json['name']),
      supplier: _toText(json['supplier']),
      supplierName: _toText(json['supplier_name']),
      postingDate: _toText(json['posting_date']),
      grandTotal: _toDouble(json['grand_total']),
      totalQty: _toDouble(json['total_qty']),
      currency: _toText(json['currency']),
      docstatus: _toInt(json['docstatus'], 1),
      status: _toText(json['status']),
      billed: _isComplete(json['per_billed']),
      purchaseOrder: _toText(json['purchase_order']),
    );
  }
}

/// تبويبات فواتير المشتريات (تُحسب من المبالغ لا من نص الحالة).
enum PurchaseInvoiceBucket { draft, unpaid, partlyPaid, paid, other }

/// فاتورة مشتريات.
class PurchaseInvoice {
  final String name;
  final String supplier;
  final String supplierName;
  final String postingDate;
  final String? dueDate;
  final double grandTotal;

  /// الإجمالي بعد التقريب (rounded_total). ERPNext يحسب المتبقي منه لا من
  /// grand_total، فإذا كان التقريب مفعّلًا يصير المتبقي أقل من الإجمالي
  /// بفرق التقريب وتظهر الفاتورة «مدفوعة جزئيًا» وهي غير مدفوعة أصلًا.
  final double roundedTotal;
  final double outstandingAmount;
  final double totalQty;
  final String status;
  final String currency;
  final int docstatus;

  /// أمر الشراء المرتبط (فارغ إن لم يُعرف)
  final String purchaseOrder;

  const PurchaseInvoice({
    required this.name,
    required this.supplier,
    required this.supplierName,
    required this.postingDate,
    required this.dueDate,
    required this.grandTotal,
    this.roundedTotal = 0,
    required this.outstandingAmount,
    required this.totalQty,
    required this.status,
    required this.currency,
    required this.docstatus,
    required this.purchaseOrder,
  });

  String get displaySupplier => supplierName.isEmpty ? supplier : supplierName;

  /// المبلغ الذي يُقاس عليه المتبقي (كما يفعل ERPNext): المقرَّب إن وُجد.
  double get _invoiceTotal => roundedTotal > 0 ? roundedTotal : grandTotal;

  PurchaseInvoiceBucket get bucket {
    if (docstatus == 0) return PurchaseInvoiceBucket.draft;
    if (docstatus != 1) return PurchaseInvoiceBucket.other;
    if (status == 'Return' ||
        status == 'Debit Note Issued' ||
        status == 'Cancelled') {
      return PurchaseInvoiceBucket.other;
    }
    if (grandTotal <= 0) return PurchaseInvoiceBucket.other;
    if (outstandingAmount <= 0.005) return PurchaseInvoiceBucket.paid;
    // ERPNext نفسه حكم أنها غير مدفوعة (المتبقي = كامل المبلغ)
    if (status == 'Unpaid') return PurchaseInvoiceBucket.unpaid;
    // مدفوعة جزئيًا فقط إذا نقص المتبقي عن إجمالي الفاتورة (المقرَّب) فعلًا
    if (outstandingAmount < _invoiceTotal - 0.01) {
      return PurchaseInvoiceBucket.partlyPaid;
    }
    return PurchaseInvoiceBucket.unpaid;
  }

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoice(
      name: _toText(json['name']),
      supplier: _toText(json['supplier']),
      supplierName: _toText(json['supplier_name']),
      postingDate: _toText(json['posting_date']),
      dueDate: json['due_date']?.toString(),
      grandTotal: _toDouble(json['grand_total']),
      roundedTotal: _toDouble(json['rounded_total']),
      outstandingAmount: _toDouble(json['outstanding_amount']),
      totalQty: _toDouble(json['total_qty']),
      status: _toText(json['status']),
      currency: _toText(json['currency']),
      docstatus: _toInt(json['docstatus'], 1),
      purchaseOrder: _toText(json['purchase_order']),
    );
  }
}

/// بند (صنف) داخل مستند مشتريات.
class PurchaseLine {
  /// رقم صف البند (name). لازم لتعديله دون أن يضيف ERPNext صفًا جديدًا
  final String rowName;
  final String itemCode;
  final String itemName;
  final double qty;
  final double rate;
  final double amount;

  /// وحدة الصف (للعرض) والمستودع المسجَّل على الصف (للعرض فقط)
  final String uom;
  final String warehouse;

  const PurchaseLine({
    this.rowName = '',
    this.itemCode = '',
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
    this.uom = '',
    this.warehouse = '',
  });

  factory PurchaseLine.fromJson(Map<String, dynamic> json) => PurchaseLine(
        rowName: _toText(json['name']),
        itemCode: _toText(json['item_code']),
        itemName: _toText(json['item_name']),
        qty: _toDouble(json['qty']),
        rate: _toDouble(json['rate']),
        amount: _toDouble(json['amount']),
        uom: _toText(json['uom']),
        warehouse: _toText(json['warehouse']),
      );
}

/// تعديل كمية بند في مستند مسودة. السعر لا يُرسل أبدًا فيبقى كما هو في ERPNext.
class PurchaseLineEdit {
  final String rowName;
  final double qty;

  const PurchaseLineEdit({required this.rowName, required this.qty});

  Map<String, dynamic> toJson() => {'name': rowName, 'qty': qty};
}

/// تفاصيل مستند مشتريات (عند الضغط عليه): الحقول العامة والأصناف والضريبة.
class PurchaseDocDetail {
  final String name;
  final String supplierName;
  final String date;
  final double netTotal;
  final double taxes;
  final double grandTotal;
  final String currency;

  /// 0 = مسودة (بنودها قابلة للتعديل)، 1 = معتمد
  final int docstatus;
  final List<PurchaseLine> lines;

  bool get isDraft => docstatus == 0;

  const PurchaseDocDetail({
    required this.name,
    required this.supplierName,
    required this.date,
    required this.netTotal,
    required this.taxes,
    required this.grandTotal,
    required this.currency,
    this.docstatus = 1,
    required this.lines,
  });

  factory PurchaseDocDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return PurchaseDocDetail(
      name: _toText(json['name']),
      supplierName: _toText(json['supplier_name']).isEmpty
          ? _toText(json['supplier'])
          : _toText(json['supplier_name']),
      date: _toText(json['transaction_date'] ?? json['posting_date']),
      netTotal: _toDouble(json['net_total'] ?? json['total']),
      taxes: _toDouble(json['total_taxes_and_charges']),
      grandTotal: _toDouble(json['grand_total']),
      currency: _toText(json['currency']),
      docstatus: _toInt(json['docstatus'], 1),
      lines: [
        if (raw is List)
          for (final r in raw)
            PurchaseLine.fromJson(Map<String, dynamic>.from(r as Map)),
      ],
    );
  }
}

/// مورّد للاختيار عند إنشاء أمر شراء.
class ErpSupplier {
  final String id;
  final String name;

  const ErpSupplier({required this.id, required this.name});
}

/// صنف قابل للشراء.
class PurchasableItem {
  final String code;
  final String name;
  final String uom;

  /// آخر سعر شراء أو السعر القياسي (0 إن لم يوجد)
  final double rate;

  const PurchasableItem({
    required this.code,
    required this.name,
    required this.uom,
    required this.rate,
  });
}

/// سطر في أمر الشراء الجديد.
class NewPurchaseLine {
  final PurchasableItem item;
  final double qty;
  final double rate;

  const NewPurchaseLine({
    required this.item,
    required this.qty,
    required this.rate,
  });

  double get total => qty * rate;
}
