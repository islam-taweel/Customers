import '../database/database_helper.dart';
import '../models/operation.dart';

/// الوسيط بين التطبيق وقاعدة البيانات لكل ما يخص عمليات العميل (ديون ودفعات).
/// المكان الوحيد الذي تُكتب فيه استعلامات SQL الخاصة بالعمليات.
class OperationRepository {
  OperationRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;

  static const _operations = DatabaseHelper.tableOperations;

  /// عمليات عميل معيّن من الأحدث إلى الأقدم
  /// (id كمعيار ثانٍ ليبقى الترتيب ثابتًا عند تساوي الوقت)
  Future<List<Operation>> getOperations(int customerId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _operations,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Operation.fromMap).toList();
  }

  /// رصيد العميل = مجموع الديون − مجموع الدفعات
  /// (موجب: مستحق على العميل، سالب: له رصيد، صفر: مسدد)
  Future<double> getBalance(int customerId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(
        CASE WHEN type = 'debt' THEN amount ELSE -amount END
      ), 0) AS balance
      FROM $_operations
      WHERE customerId = ?
    ''', [customerId]);
    return (rows.first['balance'] as num).toDouble();
  }

  /// إضافة عملية، تُرجع id العملية
  Future<int> addOperation(Operation operation) async {
    final db = await _dbHelper.database;
    return db.insert(_operations, operation.toMap());
  }
}