import '../database/database_helper.dart';
import '../models/pending_order.dart';

/// الطلبيات التي أُنشئت دون اتصال وتنتظر الرفع إلى ERPNext.
class PendingOrderRepository {
  PendingOrderRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;

  static const _table = DatabaseHelper.tablePendingOrders;

  Future<int> add(PendingOrder order) async {
    final db = await _dbHelper.database;
    return db.insert(_table, order.toMap());
  }

  /// الطلبيات التي ستُرفع تلقائيًا (الأقدم أولًا ليبقى ترتيب إنشائها كما هو).
  Future<List<PendingOrder>> getPending() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _table,
      where: 'status = ?',
      whereArgs: [PendingOrder.statusPending],
      orderBy: 'id ASC',
    );
    return rows.map(PendingOrder.fromMap).toList();
  }

  /// عدد المعلّق وعدد المرفوض من الخادم.
  Future<({int pending, int failed})> counts() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT status, COUNT(*) AS n FROM $_table GROUP BY status',
    );
    var pending = 0;
    var failed = 0;
    for (final row in rows) {
      final n = (row['n'] as num).toInt();
      if (row['status'] == PendingOrder.statusPending) pending = n;
      if (row['status'] == PendingOrder.statusFailed) failed = n;
    }
    return (pending: pending, failed: failed);
  }

  /// بعد نجاح الرفع نحتفظ بالصف (حالة synced) مدة قصيرة بدل حذفه فورًا، فلا تُرفع
  /// الطلبية مرتين لو أُغلق التطبيق بين الرفع وتحديث الفاتورة.
  Future<void> markSynced(int id, String erpOrderId) async {
    final db = await _dbHelper.database;
    await db.update(
      _table,
      {
        'status': PendingOrder.statusSynced,
        'erpOrderId': erpOrderId,
        'lastError': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(int id, String error) async {
    final db = await _dbHelper.database;
    await db.update(
      _table,
      {'status': PendingOrder.statusFailed, 'lastError': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// إعادة المرفوضة إلى الانتظار (عند الضغط على «مزامنة» يدويًا).
  Future<void> resetFailed() async {
    final db = await _dbHelper.database;
    await db.update(
      _table,
      {'status': PendingOrder.statusPending},
      where: 'status = ?',
      whereArgs: [PendingOrder.statusFailed],
    );
  }

  /// تنظيف الطلبيات التي رُفعت قبل أكثر من أسبوع.
  Future<void> purgeSynced() async {
    final db = await _dbHelper.database;
    final limit =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    await db.delete(
      _table,
      where: 'status = ? AND createdAt < ?',
      whereArgs: [PendingOrder.statusSynced, limit],
    );
  }
}
