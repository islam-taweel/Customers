import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// يحفظ ردود ERPNext في قاعدة البيانات المحلية ويقرؤها.
/// أي فشل في القراءة أو الكتابة يُتجاهل (مع تسجيله): النسخة المحلية ميزة إضافية
/// ولا يجوز أن توقف التطبيق.
class ErpCacheStore {
  ErpCacheStore(this._dbHelper);

  final DatabaseHelper _dbHelper;

  static const _table = DatabaseHelper.tableErpCache;

  Future<({String json, DateTime savedAt})?> read(String key) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        _table,
        where: 'cacheKey = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return (
        json: rows.first['json'] as String,
        savedAt: DateTime.parse(rows.first['savedAt'] as String),
      );
    } catch (e) {
      debugPrint('ErpCacheStore.read($key) failed: $e');
      return null;
    }
  }

  Future<void> write(String key, String json) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        _table,
        {
          'cacheKey': key,
          'json': json,
          'savedAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('ErpCacheStore.write($key) failed: $e');
    }
  }
}
