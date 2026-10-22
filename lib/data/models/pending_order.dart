import 'dart:convert';

/// سطر في طلبية معلّقة: صنف وكمية وسعر وقت إنشاء الطلبية.
class PendingOrderLine {
  final String code;
  final String name;
  final double qty;
  final double rate;

  const PendingOrderLine({
    required this.code,
    required this.name,
    required this.qty,
    required this.rate,
  });

  Map<String, dynamic> toJson() =>
      {'code': code, 'name': name, 'qty': qty, 'rate': rate};

  factory PendingOrderLine.fromJson(Map<String, dynamic> json) {
    double num_(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    return PendingOrderLine(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      qty: num_(json['qty']),
      rate: num_(json['rate']),
    );
  }
}

/// طلبية أُنشئت دون اتصال بالخادم وتنتظر الرفع إلى ERPNext.
class PendingOrder {
  static const statusPending = 'pending';

  /// رفضها الخادم (خطأ تحقق مثلًا): لا تُعاد تلقائيًا، بل يدويًا من الإعدادات
  static const statusFailed = 'failed';
  static const statusSynced = 'synced';

  final int? id;
  final String customerErpId;
  final String customerName;

  /// yyyy-MM-dd
  final String transactionDate;
  final String deliveryDate;
  final List<PendingOrderLine> lines;
  final double total;
  final DateTime createdAt;

  /// الفاتورة المحلية المرتبطة بالطلبية (تُحدَّث برقم الطلبية بعد الرفع)
  final int? invoiceId;
  final String status;
  final String? lastError;
  final String? erpOrderId;

  /// ملاحظات الطلبية (تُرسل مع الطلبية عند رفعها)
  final String? notes;

  const PendingOrder({
    this.id,
    required this.customerErpId,
    required this.customerName,
    required this.transactionDate,
    required this.deliveryDate,
    required this.lines,
    required this.total,
    required this.createdAt,
    this.invoiceId,
    this.status = statusPending,
    this.lastError,
    this.erpOrderId,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customerErpId': customerErpId,
        'customerName': customerName,
        'transactionDate': transactionDate,
        'deliveryDate': deliveryDate,
        'linesJson': jsonEncode([for (final l in lines) l.toJson()]),
        'total': total,
        'createdAt': createdAt.toIso8601String(),
        'invoiceId': invoiceId,
        'status': status,
        'lastError': lastError,
        'erpOrderId': erpOrderId,
        'notes': notes,
      };

  factory PendingOrder.fromMap(Map<String, dynamic> map) {
    List<PendingOrderLine> lines;
    try {
      final raw = jsonDecode(map['linesJson'] as String) as List;
      lines = [
        for (final e in raw)
          PendingOrderLine.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      lines = const [];
    }
    return PendingOrder(
      id: map['id'] as int?,
      customerErpId: map['customerErpId'] as String,
      customerName: map['customerName'] as String,
      transactionDate: map['transactionDate'] as String,
      deliveryDate: map['deliveryDate'] as String,
      lines: lines,
      total: (map['total'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      invoiceId: map['invoiceId'] as int?,
      status: (map['status'] as String?) ?? statusPending,
      lastError: map['lastError'] as String?,
      erpOrderId: map['erpOrderId'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
