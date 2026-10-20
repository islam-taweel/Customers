import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/order_models.dart';

/// نسخة محلية من كتالوج ERPNext (مجموعات الأصناف، الأصناف، الأسعار والمخزون)
/// ليعمل إنشاء الطلبيات دون اتصال.
class CatalogStore {
  CatalogStore(this._dbHelper);

  final DatabaseHelper _dbHelper;

  static const _groups = DatabaseHelper.tableCatalogGroups;
  static const _items = DatabaseHelper.tableCatalogItems;
  static const _pricing = DatabaseHelper.tableCatalogPricing;

  // ───────── المجموعات ─────────

  /// null = لا شيء محفوظ بعد
  Future<List<String>?> readGroups() async {
    final db = await _dbHelper.database;
    final rows = await db.query(_groups, orderBy: 'name');
    if (rows.isEmpty) return null;
    return [for (final r in rows) r['name'] as String];
  }

  Future<void> saveGroups(List<String> groups) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(_groups);
      final batch = txn.batch();
      for (final g in groups) {
        batch.insert(
          _groups,
          {'name': g},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // ───────── الأصناف ─────────

  /// null = لا أصناف محفوظة لهذه المجموعة
  Future<List<ErpItem>?> readItems(String group) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _items,
      where: 'itemGroup = ?',
      whereArgs: [group],
    );
    if (rows.isEmpty) return null;
    final items = rows.map(_itemFromRow).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  /// يستبدل أصناف مجموعة واحدة (عند جلبها من الخادم أثناء الاستخدام).
  Future<void> saveItemsForGroup(String group, List<ErpItem> items) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(_items, where: 'itemGroup = ?', whereArgs: [group]);
      final batch = txn.batch();
      for (final item in items) {
        batch.insert(
          _items,
          _itemToRow(item, group),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// يستبدل كل الأصناف دفعة واحدة (المزامنة الكاملة من الإعدادات).
  Future<void> saveAllItems(Map<String, List<ErpItem>> byGroup) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(_items);
      final batch = txn.batch();
      byGroup.forEach((group, items) {
        for (final item in items) {
          batch.insert(
            _items,
            _itemToRow(item, group),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      await batch.commit(noResult: true);
    });
  }

  // ───────── السعر والمخزون ─────────

  Future<ItemPricing?> readPricing(String code) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _pricing,
      where: 'itemCode = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ItemPricing(
      rate: (row['rate'] as num?)?.toDouble(),
      available: (row['available'] as num).toDouble(),
    );
  }

  Future<void> savePricing(String code, ItemPricing pricing) async {
    final db = await _dbHelper.database;
    await db.insert(
      _pricing,
      _pricingToRow(code, pricing),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveAllPricing(Map<String, ItemPricing> pricing) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(_pricing);
      final batch = txn.batch();
      pricing.forEach((code, p) {
        batch.insert(
          _pricing,
          _pricingToRow(code, p),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      await batch.commit(noResult: true);
    });
  }

  // ───────── مساعدات ─────────

  ErpItem _itemFromRow(Map<String, Object?> row) => ErpItem(
        code: row['code'] as String,
        name: row['name'] as String,
        uom: (row['uom'] as String?) ?? '',
      );

  Map<String, Object?> _itemToRow(ErpItem item, String group) => {
        'code': item.code,
        'name': item.name,
        'uom': item.uom,
        'itemGroup': group,
      };

  Map<String, Object?> _pricingToRow(String code, ItemPricing p) => {
        'itemCode': code,
        'rate': p.rate,
        'available': p.available,
        'savedAt': DateTime.now().toIso8601String(),
      };
}
