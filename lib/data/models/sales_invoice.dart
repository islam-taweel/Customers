/// تحويل آمن لقيمة JSON إلى رقم (ERPNext يرسل الأرقام num، وأحيانًا null)
double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _toText(Object? value) => value?.toString() ?? '';

/// تسوية الفاتورة كما يحسبها ERPNext:
/// قيمة الفاتورة = المسدد من رصيد سابق (total_advance) + المدفوع + الشطب + المتبقي.
///
/// المتبقي هو outstanding_amount من ERPNext كما هو: ERPNext خصم منه الرصيد السابق
/// المخصص للفاتورة (advances) والدفعات المربوطة بها، فلا نخصم شيئًا منه مرة ثانية.
/// «المدفوع» يُشتق بالطرح فقط لعرضه.
///
/// العملة: إن اختلفت عملة حساب العميل (party_account_currency) عن عملة الفاتورة،
/// يحسب ERPNext المتبقي والرصيد السابق بعملة الحساب من base_*، فنقارنها بـ base_*
/// أيضًا ونعرضها بعملة الحساب ([currency]) — لا نطرح عملتين من بعضهما.
class InvoiceSettlement {
  /// عملة المبالغ أدناه (فارغة = عملة الفاتورة نفسها)
  final String currency;

  /// قيمة الفاتورة كاملة بعملة الفاتورة نفسها (للعرض)
  final double documentTotal;

  /// قيمة الفاتورة كاملة بعملة [currency] (rounded_total إن وُجد وإلا grand_total)
  final double total;

  /// ما سُدد من رصيد سابق للعميل (دفعة مقدمة/غير مخصصة) خُصص لهذه الفاتورة
  final double fromAdvance;

  /// ما دُفع على الفاتورة (أو سُوّي بإشعار دائن) غير الرصيد السابق والشطب
  final double paid;

  /// المتبقي على العميل لهذه الفاتورة (outstanding_amount)
  final double outstanding;

  const InvoiceSettlement._({
    required this.currency,
    required this.documentTotal,
    required this.total,
    required this.fromAdvance,
    required this.paid,
    required this.outstanding,
  });

  /// الحقول المطلوبة من Sales Invoice لحسابها
  static const fields = [
    'currency',
    'party_account_currency',
    'grand_total',
    'rounded_total',
    'base_grand_total',
    'base_rounded_total',
    'disable_rounded_total',
    'total_advance',
    'write_off_amount',
    'base_write_off_amount',
    'outstanding_amount',
  ];

  /// نفس معادلة ERPNext (calculate_outstanding_amount): rounded_total إن وُجد وإلا
  /// grand_total، وبقيم base_* إن كانت عملة الحساب غير عملة الفاتورة.
  factory InvoiceSettlement.fromJson(Map<String, dynamic> json) {
    final invoiceCurrency = _toText(json['currency']);
    final partyCurrency = _toText(json['party_account_currency']);
    final inBase = partyCurrency.isNotEmpty &&
        invoiceCurrency.isNotEmpty &&
        partyCurrency != invoiceCurrency;

    double pick(String rounded, String grand) {
      final r = _toDouble(json[rounded]);
      return r != 0 ? r : _toDouble(json[grand]);
    }

    final documentTotal = pick('rounded_total', 'grand_total');
    final total =
        inBase ? pick('base_rounded_total', 'base_grand_total') : documentTotal;
    final advance = _toDouble(json['total_advance']);
    final writeOff = _toDouble(
      json[inBase ? 'base_write_off_amount' : 'write_off_amount'],
    );
    final outstanding = _toDouble(json['outstanding_amount']);
    final paid = total - advance - writeOff - outstanding;
    return InvoiceSettlement._(
      currency: inBase ? partyCurrency : '',
      documentTotal: documentTotal,
      total: total,
      fromAdvance: advance,
      paid: paid > 0.005 ? paid : 0,
      outstanding: outstanding,
    );
  }

  /// عملة العرض: عملة الحساب إن اختلفت، وإلا عملة الفاتورة [invoiceCurrency]
  String displayIn(String invoiceCurrency) =>
      currency.isNotEmpty ? currency : invoiceCurrency;
}

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

  /// قيمة الفاتورة والمسدد منها والمتبقي (null = فاتورة محلية بلا مبالغ ERPNext)
  final InvoiceSettlement? settlement;

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
    this.settlement,
  });

  /// قيمة الفاتورة كاملة بعملتها (بالتقريب إن وُجد) للعرض
  double get invoiceTotal => settlement?.documentTotal ?? grandTotal;

  /// قيمة الفاتورة بنفس عملة outstanding_amount (عملة حساب العميل) للمقارنة
  double get _settlementTotal => settlement?.total ?? grandTotal;

  /// أي تبويب في قسم «الفواتير» تنتمي إليه (المرتجعات وإشعارات الدائن خارج التبويبات)
  InvoiceBucket get bucket {
    if (docstatus == 0) return InvoiceBucket.draft;
    if (docstatus != 1 || isLocal) return InvoiceBucket.other;
    if (status == 'Return' ||
        status == 'Credit Note Issued' ||
        status == 'Cancelled') {
      return InvoiceBucket.other;
    }
    if (_settlementTotal <= 0) return InvoiceBucket.other;
    if (outstandingAmount <= 0.005) return InvoiceBucket.paid;
    // المسدد من رصيد سابق يجعلها «مدفوعة جزئيًا» أيضًا (المقارنة بنفس العملة)
    if (outstandingAmount < _settlementTotal - 0.005) {
      return InvoiceBucket.partlyPaid;
    }
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
      settlement: InvoiceSettlement.fromJson(json),
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

  /// 0 = مسودة، 1 = معتمدة، 2 = ملغاة
  final int docstatus;

  /// قيمة الفاتورة والمسدد منها والمتبقي (null = طلبية محلية)
  final InvoiceSettlement? settlement;

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
    this.docstatus = 1,
    this.settlement,
  });

  factory SalesInvoiceDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final status = _toText(json['status']);
    return SalesInvoiceDetail(
      // نسخة محفوظة قديمة بلا docstatus: نستنتجه من الحالة
      docstatus: json['docstatus'] is num
          ? (json['docstatus'] as num).toInt()
          : status == 'Draft'
              ? 0
              : status == 'Cancelled'
                  ? 2
                  : 1,
      settlement: InvoiceSettlement.fromJson(json),
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
