import 'dart:convert';

import 'sales_invoice.dart';

/// مراحل الطلبية: مسودة ← بانتظار التسليم ← بانتظار الفوترة ← مكتملة.
/// ترتيب القيم هو ترتيب التبويبات في شاشة الطلبات.
enum OrderStage { draft, toDeliver, toBill, completed }

/// فاتورة واحدة محفوظة في قاعدة البيانات.
/// اسم العميل ورقمه نسخة ثابتة (snapshot) لحظة الإنشاء،
/// فلا تتغير الفاتورة إن عُدّل العميل بعد ذلك.
class Invoice {
  final int? id;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final double amount;
  final DateTime createdAt;

  /// رقم الطلبية في ERPNext (Sales Order) إن كانت الفاتورة ناتجة عن طلبية
  final String? orderId;

  /// تاريخ التسليم بصيغة yyyy-MM-dd
  final String? deliveryDate;

  /// أصناف الفاتورة كنص JSON: [{code, name, qty, rate}]
  final String? itemsJson;

  /// true = أُنشئت دون اتصال وطلبيتها لم تُرفع إلى ERPNext بعد
  final bool pendingUpload;

  /// true = اعتُمدت (Submitted) في ERPNext؛ false = مسودة (Draft) تقبل التعديل والحذف
  final bool submitted;

  /// عملة الطلبية (null = الشيكل)
  final String? currency;

  /// ملاحظات كُتبت على الطلبية قبل إرسالها (null = لا ملاحظات)
  final String? notes;

  /// true = سُلِّمت الطلبية بالكامل (سند تسليم في ERPNext)
  final bool delivered;

  /// true = فُوتِرت الطلبية بالكامل (فاتورة مبيعات في ERPNext)
  final bool billed;

  /// رقم سند التسليم (Delivery Note) الذي أنشأه التطبيق لهذه الطلبية.
  /// يبقى مسودة في ERPNext إلى أن يُعتمد هناك (null = لم يُنشأ من التطبيق)
  final String? deliveryNote;

  /// true = في ERPNext سند تسليم مسودة لهذه الطلبية لم يُعتمد بعد، أُنشئ خارج التطبيق
  final bool deliveryDraft;

  /// رقم فاتورة المبيعات (مسودة) التي أنشأها التطبيق للطلبية. يعتمدها المسؤول في
  /// ERPNext، ولا يعود للطلبية «فوترة» إلا إن حُذفت (رُفضت) هناك.
  final String? salesInvoice;

  const Invoice({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.createdAt,
    this.orderId,
    this.deliveryDate,
    this.itemsJson,
    this.pendingUpload = false,
    this.submitted = false,
    this.currency,
    this.notes,
    this.delivered = false,
    this.billed = false,
    this.deliveryNote,
    this.deliveryDraft = false,
    this.salesInvoice,
  });

  /// مرحلة الطلبية الحالية، تحدد التبويب الذي تظهر فيه
  OrderStage get stage {
    if (!submitted) return OrderStage.draft;
    if (!delivered) {
      // أنشأ التطبيق سند تسليم لها: صارت بانتظار الفوترة (تُفعَّل بعد اعتماده)
      return (deliveryNote ?? '').isNotEmpty
          ? OrderStage.toBill
          : OrderStage.toDeliver;
    }
    if (!billed && (salesInvoice ?? '').isEmpty) return OrderStage.toBill;
    return OrderStage.completed;
  }

  /// سند تسليم مسودة في ERPNext أُنشئ خارج التطبيق ولم يُعتمد: يظهر في تبويب
  /// «مسودة» بقسم التسليمات بلا أزرار
  bool get isErpDeliveryDraft =>
      submitted &&
      !delivered &&
      (deliveryNote ?? '').isEmpty &&
      deliveryDraft;

  /// الفوترة متاحة فقط بعد اعتماد سند التسليم في ERPNext (حينها تصير الطلبية «مُسلَّمة»)
  bool get canBill =>
      submitted &&
      delivered &&
      !billed &&
      (salesInvoice ?? '').isEmpty &&
      !pendingUpload &&
      (orderId ?? '').isNotEmpty;

  /// رقم الفاتورة مشتق من الـ id المتسلسل، مثال: INV-00012
  String get number => 'INV-${(id ?? 0).toString().padLeft(5, '0')}';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'orderId': orderId,
      'deliveryDate': deliveryDate,
      'itemsJson': itemsJson,
      'pendingUpload': pendingUpload ? 1 : 0,
      'submitted': submitted ? 1 : 0,
      'currency': currency,
      'notes': notes,
      'delivered': delivered ? 1 : 0,
      'billed': billed ? 1 : 0,
      'deliveryNote': deliveryNote,
      'deliveryDraft': deliveryDraft ? 1 : 0,
      'salesInvoice': salesInvoice,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      orderId: map['orderId'] as String?,
      deliveryDate: map['deliveryDate'] as String?,
      itemsJson: map['itemsJson'] as String?,
      pendingUpload: (map['pendingUpload'] as num?)?.toInt() == 1,
      submitted: (map['submitted'] as num?)?.toInt() == 1,
      currency: map['currency'] as String?,
      notes: map['notes'] as String?,
      delivered: (map['delivered'] as num?)?.toInt() == 1,
      billed: (map['billed'] as num?)?.toInt() == 1,
      deliveryNote: map['deliveryNote'] as String?,
      deliveryDraft: (map['deliveryDraft'] as num?)?.toInt() == 1,
      salesInvoice: map['salesInvoice'] as String?,
    );
  }

  String get _day {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${createdAt.year}-${two(createdAt.month)}-${two(createdAt.day)}';
  }

  /// رقم العرض: رقم الطلبية في ERPNext إن وُجد، وإلا رقم الفاتورة المحلي
  String get displayName => (orderId == null || orderId!.isEmpty) ? number : orderId!;

  /// أصناف الفاتورة من النص المحفوظ (قائمة فارغة إن كان تالفًا)
  List<InvoiceItem> get items {
    final raw = itemsJson;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          () {
            final m = Map<String, dynamic>.from(e as Map);
            final qty = (m['qty'] as num?)?.toDouble() ?? 0;
            final rate = (m['rate'] as num?)?.toDouble() ?? 0;
            return InvoiceItem(
              itemName: (m['name'] ?? m['code'] ?? '').toString(),
              qty: qty,
              rate: rate,
              amount: qty * rate,
            );
          }(),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// حالة العرض: «بانتظار الرفع» حتى تصل الطلبية إلى ERPNext، ثم «مسودة»،
  /// وبعد الاعتماد: «بانتظار التسليم» ثم «بانتظار الفوترة» ثم «مكتملة»
  String get _status => switch (stage) {
        OrderStage.draft => pendingUpload ? 'Pending Upload' : 'Draft',
        OrderStage.toDeliver => 'To Deliver',
        OrderStage.toBill => 'To Bill',
        OrderStage.completed => 'Completed',
      };

  /// صف في قائمة فواتير العميل
  SalesInvoice toListEntry() => SalesInvoice(
        name: displayName,
        customer: '',
        customerName: customerName,
        postingDate: _day,
        dueDate: deliveryDate,
        grandTotal: amount,
        outstandingAmount: 0,
        status: _status,
        currency: currency ?? '',
        isLocal: true,
      );

  /// تفاصيل الفاتورة لشاشة العرض (نفس شاشة فواتير ERPNext)
  SalesInvoiceDetail toDetail() => SalesInvoiceDetail(
        name: displayName,
        customerName: customerName,
        postingDate: _day,
        dueDate: deliveryDate,
        grandTotal: amount,
        totalTaxesAndCharges: 0,
        outstandingAmount: 0,
        status: _status,
        currency: currency ?? '',
        items: items,
      );

  Invoice copyWith({
    int? id,
    double? amount,
    String? deliveryDate,
    String? itemsJson,
    bool? submitted,
    bool? delivered,
    bool? billed,
    String? deliveryNote,
    bool? deliveryDraft,
    String? salesInvoice,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      amount: amount ?? this.amount,
      createdAt: createdAt,
      orderId: orderId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      itemsJson: itemsJson ?? this.itemsJson,
      pendingUpload: pendingUpload,
      submitted: submitted ?? this.submitted,
      currency: currency,
      notes: notes,
      delivered: delivered ?? this.delivered,
      billed: billed ?? this.billed,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      deliveryDraft: deliveryDraft ?? this.deliveryDraft,
      salesInvoice: salesInvoice ?? this.salesInvoice,
    );
  }
}
