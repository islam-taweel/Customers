import '../api/erp_config.dart';
import '../database/database_helper.dart';
import '../models/operation.dart';
import 'outstanding_repository.dart';

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

  /// رصيد العميل **لكل عملة على حدة** = مجموع الديون − مجموع الدفعات بتلك العملة
  /// (موجب: مستحق على العميل، سالب: له رصيد). لا تُجمع العملات المختلفة معًا ولا
  /// تُحوَّل: دين بالشيكل ودفعة بالدولار رصيدان منفصلان. العمليات القديمة بلا عملة
  /// تُحسب بعملة الشركة. الأرصدة الصفرية (المسدَّدة) لا تُعاد، فالقائمة الفارغة = مسدد.
  /// العملة الافتراضية أولًا ثم الباقي أبجديًا.
  Future<List<CurrencyAmount>> getBalances(int customerId) async {
    final db = await _dbHelper.database;
    final base = ErpConfig.priceListCurrency;
    final rows = await db.rawQuery('''
      SELECT COALESCE(NULLIF(currency, ''), ?) AS cur,
             SUM(CASE WHEN type = 'debt' THEN amount ELSE -amount END) AS balance
      FROM $_operations
      WHERE customerId = ?
      GROUP BY cur
    ''', [base, customerId]);

    final result = [
      for (final row in rows)
        if (((row['balance'] as num?) ?? 0).abs() >= 0.005)
          CurrencyAmount(
            row['cur'] as String,
            (row['balance'] as num).toDouble(),
          ),
    ]..sort((a, b) {
        if (a.currency == base) return -1;
        if (b.currency == base) return 1;
        return a.currency.compareTo(b.currency);
      });
    return result;
  }

  /// إضافة عملية، تُرجع id العملية
  Future<int> addOperation(Operation operation) async {
    final db = await _dbHelper.database;
    return db.insert(_operations, operation.toMap());
  }
}