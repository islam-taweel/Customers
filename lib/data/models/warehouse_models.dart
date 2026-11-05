double _n(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
String _s(Object? v) => v?.toString() ?? '';

/// مستودع فعلي (ليس مجموعة) غير معطّل. [name] هو القيمة التي تُرسل في كل مكان.
class Warehouse {
  final String name;
  final String label;
  final String parent;

  const Warehouse({
    required this.name,
    required this.label,
    required this.parent,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    final name = _s(json['name']);
    final label = _s(json['warehouse_name']);
    return Warehouse(
      name: name,
      label: label.isEmpty ? name : label,
      parent: _s(json['parent_warehouse']),
    );
  }
}

/// رصيد صنف في مستودع (صف Bin) مع اسم الصنف من Item.
class WarehouseStock {
  final String itemCode;
  final String itemName;
  final String itemGroup;

  /// الموجود فعليًا في المستودع
  final double actualQty;

  /// المحجوز لأوامر بيع
  final double reservedQty;
  final double projectedQty;
  final String uom;

  /// الوحدة لا تقبل كسورًا (UOM.must_be_whole_number)
  final bool wholeNumber;

  const WarehouseStock({
    required this.itemCode,
    required this.itemName,
    required this.itemGroup,
    required this.actualQty,
    required this.reservedQty,
    required this.projectedQty,
    required this.uom,
    required this.wholeNumber,
  });

  /// المتاح = الموجود − المحجوز
  double get availableQty => actualQty - reservedQty;

  factory WarehouseStock.fromBin(
    Map<String, dynamic> bin, {
    Map<String, dynamic>? item,
    bool wholeNumber = false,
  }) {
    final code = _s(bin['item_code']);
    final name = _s(item?['item_name']);
    return WarehouseStock(
      itemCode: code,
      itemName: name.isEmpty ? code : name,
      itemGroup: _s(item?['item_group']),
      actualQty: _n(bin['actual_qty']),
      reservedQty: _n(bin['reserved_qty']),
      projectedQty: _n(bin['projected_qty']),
      uom: _s(bin['stock_uom']),
      wholeNumber: wholeNumber,
    );
  }
}

/// صف في قيد نقل المخزون
class TransferItem {
  final String itemCode;
  final String itemName;
  final double qty;
  final String uom;
  final String source;
  final String target;

  const TransferItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.uom,
    required this.source,
    required this.target,
  });

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    final code = _s(json['item_code']);
    final name = _s(json['item_name']);
    return TransferItem(
      itemCode: code,
      itemName: name.isEmpty ? code : name,
      qty: _n(json['qty']),
      uom: _s(json['uom']).isNotEmpty ? _s(json['uom']) : _s(json['stock_uom']),
      source: _s(json['s_warehouse']),
      target: _s(json['t_warehouse']),
    );
  }
}

/// قيد نقل مخزون (Stock Entry من نوع Material Transfer) ينتظر الاعتماد.
/// [items] فارغة في القائمة، وتُملأ من تفاصيل القيد.
class StockTransfer {
  final String name;
  final String postingDate;
  final String fromWarehouse;
  final String toWarehouse;
  final String remarks;
  final List<TransferItem> items;

  const StockTransfer({
    required this.name,
    required this.postingDate,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.remarks,
    this.items = const [],
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    return StockTransfer(
      name: _s(json['name']),
      postingDate: _s(json['posting_date']),
      fromWarehouse: _s(json['from_warehouse']),
      toWarehouse: _s(json['to_warehouse']),
      remarks: _s(json['remarks']),
      items: [
        if (items is List)
          for (final r in items)
            if (r is Map) TransferItem.fromJson(Map<String, dynamic>.from(r)),
      ],
    );
  }
}
