import 'dart:convert';

import 'sales_invoice.dart';

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
  });

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

  /// صف في قائمة فواتير العميل
  SalesInvoice toListEntry() => SalesInvoice(
        name: displayName,
        customer: '',
        customerName: customerName,
        postingDate: _day,
        dueDate: deliveryDate,
        grandTotal: amount,
        outstandingAmount: 0,
        status: 'Draft',
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
        status: 'Draft',
        currency: '',
        items: items,
      );

  Invoice copyWith({int? id}) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      amount: amount,
      createdAt: createdAt,
      orderId: orderId,
      deliveryDate: deliveryDate,
      itemsJson: itemsJson,
    );
  }
}
