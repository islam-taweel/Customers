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

  /// كل طلبيات كل العملاء (قسم «الطلبات») من الأحدث إلى الأقدم.
  Future<List<Invoice>> getAllInvoices() async {
    final db = await _dbHelper.database;
    final rows = await db.query(_invoices, orderBy: 'createdAt DESC, id DESC');
    return rows.map(Invoice.fromMap).toList();
  }

  /// فاتورة واحدة بآخر حالة لها في القاعدة (null إن حُذفت).
  Future<Invoice?> getInvoice(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _invoices,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Invoice.fromMap(rows.first);
  }

  /// بعد تعديل مسودة: الأصناف والمبلغ وتاريخ التسليم.
  Future<void> updateDraft(
    int id, {
    required String itemsJson,
    required double amount,
    required String deliveryDate,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      _invoices,
      {'itemsJson': itemsJson, 'amount': amount, 'deliveryDate': deliveryDate},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteInvoice(int id) async {
    final db = await _dbHelper.database;
    await db.delete(_invoices, where: 'id = ?', whereArgs: [id]);
  }

  /// اعتماد المسودة: تنتقل من تبويب «مسودة» إلى «معتمدة».
  Future<void> markSubmitted(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      _invoices,
      {'submitted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// بعد تسليم الطلبية: تنتقل إلى «بانتظار الفوترة».
  Future<void> markDelivered(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      _invoices,
      {'delivered': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// بعد أن أنشأ التطبيق سند تسليم (مسودة) للطلبية: تنتقل إلى «بانتظار الفوترة»
  /// والفوترة مظللة إلى أن يُعتمد السند في ERPNext.
  Future<void> markDeliveryCreated(int id, String deliveryNote) async {
    final db = await _dbHelper.database;
    await db.update(
      _invoices,
      {'deliveryNote': deliveryNote, 'deliveryDraft': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// بعد أن أنشأ التطبيق فاتورة المبيعات (مسودة) للطلبية: تنتقل إلى «مكتملة»،
  /// ويعتمد المسؤول الفاتورة في ERPNext.
  Future<void> markInvoiceCreated(int id, String salesInvoice) async {
    final db = await _dbHelper.database;
    await db.update(
      _invoices,
      {'salesInvoice': salesInvoice},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// أرقام فواتير المبيعات (مسودات) التي أنشأها التطبيق عند «فوترة» الطلبيات.
  /// تظهر في تبويب «غير مدفوعة» من لحظة الفوترة، والدفع يتفعّل بعد اعتمادها.
  Future<Set<String>> billedSalesInvoiceNames() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _invoices,
      columns: ['salesInvoice'],
      where: "salesInvoice IS NOT NULL AND salesInvoice != ''",
    );
    return {for (final r in rows) r['salesInvoice'] as String};
  }

  /// سند التسليم حُذف أو أُلغي في ERPNext (رُفض): تعود الطلبية «بانتظار التسليم».
  Future<void> clearDeliveryNote(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      _invoices,
      {'deliveryNote': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// فاتورة المبيعات حُذفت أو أُلغيت في ERPNext (رُفضت): تعود الطلبية «بانتظار الفوترة».
  Future<void> clearSalesInvoice(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      _invoices,
      {'salesInvoice': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// مزامنة مرحلة الطلبية مع ERPNext (حيث تتم الفوترة وقد يتم التسليم).
  /// [deliveryDraft]: هل يوجد سند تسليم مسودة (غير معتمد) لها في ERPNext.
  Future<void> updateFulfillment(
    int id, {
    required bool delivered,
    required bool billed,
    bool? deliveryDraft,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      _invoices,
      {
        'delivered': delivered ? 1 : 0,
        'billed': billed ? 1 : 0,
        if (deliveryDraft != null) 'deliveryDraft': deliveryDraft ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// حفظ فاتورة جديدة. تُرجع نسخة منها وفيها الـ id (ومنه رقم الفاتورة).
  Future<Invoice> addInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    final id = await db.insert(_invoices, invoice.toMap());
    return invoice.copyWith(id: id);
  }

  /// يحفظ فاتورة طلبية أُنشئت للتو في ERPNext، ويربطها بالعميل المحلي (عبر erpId).
  /// يعيد null إن لم يوجد عميل محلي مرتبط بهذا العميل (لم تتم مزامنته بعد).
  ///
  /// إن كان [order].id فارغًا فالطلبية أُنشئت دون اتصال: تُحفظ الفاتورة بحالة
  /// «بانتظار الرفع» وتُربط برقم الطلبية لاحقًا عبر [markOrderInvoiceSynced].
  Future<Invoice?> saveOrderInvoice({
    required ErpCustomer customer,
    required CreatedOrder order,
    required List<CartLine> lines,
    required DateTime deliveryDate,
    String notes = '',
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
    final offline = order.id.isEmpty;
    if (!offline) {
      final existing = await db.query(
        _invoices,
        where: 'orderId = ?',
        whereArgs: [order.id],
        limit: 1,
      );
      if (existing.isNotEmpty) return Invoice.fromMap(existing.first);
    }

    String two(int n) => n.toString().padLeft(2, '0');
    final invoice = Invoice(
      customerId: local['id'] as int,
      customerName: (local['name'] as String?) ?? customer.name,
      customerPhone: (local['phone'] as String?) ?? customer.phone,
      amount: order.total,
      createdAt: DateTime.now(),
      orderId: offline ? null : order.id,
      pendingUpload: offline,
      currency: order.currency,
      notes: notes.trim().isEmpty ? null : notes.trim(),
      deliveryDate:
          '${deliveryDate.year}-${two(deliveryDate.month)}-${two(deliveryDate.day)}',
      itemsJson: jsonEncode([
        for (final l in lines)
          {'code': l.item.code, 'name': l.item.name, 'qty': l.qty, 'rate': l.rate},
      ]),
    );
    return addInvoice(invoice);
  }

  /// بعد رفع طلبية محفوظة دون اتصال: تحمل فاتورتها المحلية رقم الطلبية في ERPNext.
  Future<void> markOrderInvoiceSynced(int invoiceId, String orderId) async {
    final db = await _dbHelper.database;
    await db.update(
      _invoices,
      {'orderId': orderId, 'pendingUpload': 0},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }
}
