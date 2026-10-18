import '../database/database_helper.dart';
import '../models/invoice.dart';

/// الوسيط بين التطبيق وقاعدة البيانات لكل ما يخص الفواتير.
/// المكان الوحيد الذي تُكتب فيه استعلامات SQL الخاصة بالفواتير.
class InvoiceRepository {
  InvoiceRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;

  static const _invoices = DatabaseHelper.tableInvoices;

  /// فواتير عميل معيّن من الأحدث إلى الأقدم
  /// (id كمعيار ثانٍ ليبقى الترتيب ثابتًا عند تساوي الوقت)
  Future<List<Invoice>> getInvoices(int customerId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _invoices,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC, id DESC',
    );
    return rows.map(Invoice.fromMap).toList();
  }

  /// حفظ فاتورة جديدة. تُرجع نسخة منها وفيها الـ id (ومنه رقم الفاتورة).
  Future<Invoice> addInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    final id = await db.insert(_invoices, invoice.toMap());
    return invoice.copyWith(id: id);
  }
}
