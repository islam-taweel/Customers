/// صنف قابل للبيع كما يأتي من ERPNext (قائمة أصناف المجموعة).
class ErpItem {
  /// معرّف الصنف: هو الذي يُرسل عند إنشاء الطلبية
  final String code;
  final String name;

  /// وحدة القياس (stock_uom) مثل Nos أو Kg
  final String uom;

  const ErpItem({required this.code, required this.name, required this.uom});
}

/// السعر والمخزون المتاح لصنف، يُجلبان معًا عند الضغط على الصنف.
class ItemPricing {
  /// price_list_rate من «Standard Selling». null = لا يوجد سعر لهذا الصنف
  final double? rate;

  /// المتاح = actual_qty - reserved_qty (لا يقل عن صفر)
  final double available;

  const ItemPricing({required this.rate, required this.available});

  bool get hasPrice => rate != null;
  bool get inStock => available > 0;

  /// يمكن إضافته للطلبية فقط إذا كان له سعر ومخزون
  bool get orderable => hasPrice && inStock;
}

/// سطر في سلة الطلبية: صنف + كمية + سعر الوحدة.
class CartLine {
  final ErpItem item;
  final ItemPricing pricing;
  final double qty;

  const CartLine({
    required this.item,
    required this.pricing,
    required this.qty,
  });

  double get rate => pricing.rate ?? 0;
  double get total => qty * rate;

  /// المتبقي في المخزن بعد خصم هذه الكمية
  double get remaining => pricing.available - qty;

  CartLine withQty(double newQty) =>
      CartLine(item: item, pricing: pricing, qty: newQty);
}

/// نتيجة إنشاء الطلبية في ERPNext.
class CreatedOrder {
  /// رقم الطلبية مثل SAL-ORD-2026-00009
  final String id;
  final double total;
  final int itemCount;

  const CreatedOrder({
    required this.id,
    required this.total,
    required this.itemCount,
  });
}
