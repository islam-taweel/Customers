import 'dart:convert';

import '../database/database_helper.dart';
import '../models/erp_customer.dart';
import '../models/invoice.dart';
import '../models/order_models.dart';

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

  /// يحفظ فاتورة طلبية أُنشئت للتو في ERPNext، ويربطها بالعميل المحلي (عبر erpId).
  /// يعيد null إن لم يوجد عميل محلي مرتبط بهذا العميل (لم تتم مزامنته بعد).
  Future<Invoice?> saveOrderInvoice({
    required ErpCustomer customer,
    required CreatedOrder order,
    required List<CartLine> lines,
    required DateTime deliveryDate,
  }) async {
    final db = await _dbHelper.database;

    final rows = await db.query(
      DatabaseHelper.tableCustomers,
      columns: ['id', 'name', 'phone'],
      where: 'erpId = ?',
      whereArgs: [customer.id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final local = rows.first;

    // لا نكرر حفظ نفس الطلبية (مثلًا لو أُعيدت المحاولة)
    final existing = await db.query(
      _invoices,
      where: 'orderId = ?',
      whereArgs: [order.id],
      limit: 1,
    );
    if (existing.isNotEmpty) return Invoice.fromMap(existing.first);

    String two(int n) => n.toString().padLeft(2, '0');
    final invoice = Invoice(
      customerId: local['id'] as int,
      customerName: (local['name'] as String?) ?? customer.name,
      customerPhone: (local['phone'] as String?) ?? customer.phone,
      amount: order.total,
      createdAt: DateTime.now(),
      orderId: order.id,
      deliveryDate:
          '${deliveryDate.year}-${two(deliveryDate.month)}-${two(deliveryDate.day)}',
      itemsJson: jsonEncode([
        for (final l in lines)
          {'code': l.item.code, 'name': l.item.name, 'qty': l.qty, 'rate': l.rate},
      ]),
    );
    return addInvoice(invoice);
  }
}
