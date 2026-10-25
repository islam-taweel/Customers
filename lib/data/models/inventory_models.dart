/// نماذج قسم «الجرد»: صنف تم التعرف عليه من الباركود مع كميته الحالية.

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

/// صنف في المستودع الرئيسي: الكمية الفعلية من Bin. (لا سعر في الجرد.)
class InventoryItem {
  final String code;
  final String name;
  final String uom;

  /// الكمية الفعلية الحالية في [warehouse]
  final double qty;

  /// تكلفة الوحدة الحالية في المستودع (0 إن لم تُعرف) — تُرسل مع التسوية كما هي
  final double valuationRate;

  final String warehouse;

  /// صنف برقم تسلسلي أو دفعة: لا يُرسل في قائمة الجرد (يُبلَّغ عنه للمسؤول)
  final bool hasSerialOrBatch;

  const InventoryItem({
    required this.code,
    required this.name,
    required this.uom,
    required this.qty,
    required this.valuationRate,
    required this.warehouse,
    this.hasSerialOrBatch = false,
  });

  factory InventoryItem.fromRows({
    required Map<String, dynamic> item,
    required Map<String, dynamic>? bin,
    required String warehouse,
  }) {
    final code = (item['item_code'] ?? item['name']).toString();
    return InventoryItem(
      code: code,
      name: (item['item_name'] ?? code).toString(),
      uom: (item['stock_uom'] ?? '').toString(),
      qty: bin == null ? 0 : _toDouble(bin['actual_qty']),
      valuationRate: bin == null ? 0 : _toDouble(bin['valuation_rate']),
      warehouse: warehouse,
      hasSerialOrBatch: _toDouble(item['has_serial_no']) != 0 ||
          _toDouble(item['has_batch_no']) != 0,
    );
  }
}

/// سطر في قائمة الجرد: الصنف + الكمية المعدودة (+ التكلفة إن لزمت).
class CountLine {
  CountLine(this.item) : qty = item.qty;

  final InventoryItem item;

  /// الكمية النهائية المعدودة في المستودع (ليست الإضافة). null = غير صالحة/فارغة
  double? qty;

  /// تكلفة الوحدة؛ مطلوبة فقط إن لم يكن للصنف تكلفة معروفة في المستودع
  double? rate;

  bool get needsRate => item.valuationRate <= 0;

  bool get qtyValid => qty != null && qty! >= 0;

  bool get rateValid => !needsRate || (rate != null && rate! > 0);

  bool get valid => qtyValid && rateValid;

  Map<String, dynamic> toRow(String warehouse) {
    final r = rate ?? (item.valuationRate > 0 ? item.valuationRate : null);
    return {
      'item_code': item.code,
      'warehouse': warehouse,
      'qty': qty,
      if (r != null && r > 0) 'valuation_rate': r,
    };
  }
}

