import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/customer_sort_option.dart';
import '../models/customer_with_balance.dart';
import '../models/deleted_customer.dart';
import '../models/operation.dart';

/// صفحة واحدة من العملاء، مع إشارة إلى وجود المزيد بعدها
class CustomersPage {
  final List<CustomerWithBalance> items;
  final bool hasMore;

  const CustomersPage({required this.items, required this.hasMore});
}

/// الوسيط بين التطبيق وقاعدة البيانات: كل ما يخص العملاء يمر من هنا،
/// والمكان الوحيد الذي تُكتب فيه استعلامات SQL الخاصة بهم.
class CustomerRepository {
  CustomerRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;

  /// عدد العملاء في كل دفعة
  static const int pageSize = AppConstants.customersPageSize;

  static const _customers = DatabaseHelper.tableCustomers;
  static const _operations = DatabaseHelper.tableOperations;

  /// جلب دفعة من العملاء مع أرصدتهم.
  ///
  /// - الدفعة الأولى: `getCustomers()` أي offset = 0.
  /// - كل دفعة تالية: `getCustomers(offset: عدد_ما_حُمّل_حتى_الآن)`.
  /// - [query] يصفّي بالاسم على كل العملاء وليس على من حُمّل منهم فقط.
  /// - [limit] الافتراضي 20، ويمكن رفعه لإعادة تحديث كل ما هو معروض دفعة واحدة.
  /// - [sort] ترتيب النتائج (الاسم افتراضيًا)، ويُطبَّق في SQL عبر `ORDER BY`
  ///   قبل `LIMIT/OFFSET` حتى يكون الترتيب صحيحًا على كل الصفحات.
  Future<CustomersPage> getCustomers({
    int offset = 0,
    int limit = pageSize,
    String query = '',
    CustomerSortOption sort = CustomerSortOption.name,
  }) async {
    assert(offset >= 0 && limit > 0);
    final db = await _dbHelper.database;

    final args = <Object?>[];
    var where = '';
    final q = query.trim();
    if (q.isNotEmpty) {
      // تعطيل الرموز الخاصة في LIKE حتى لا يُفسَّر % و _ كأحرف بحث
      final escaped = q
          .replaceAll('!', '!!')
          .replaceAll('%', '!%')
          .replaceAll('_', '!_');
      where = "WHERE c.name LIKE ? ESCAPE '!'";
      args.add('%$escaped%');
    }

    // نطلب صفًا زائدًا واحدًا لنعرف بدقة هل توجد دفعة تالية،
    // دون استعلام إضافي ودون طلب فارغ في النهاية.
    args
      ..add(limit + 1)
      ..add(offset);

    final rows = await db.rawQuery('''
      SELECT c.id, c.name, c.phone,
             COALESCE((
               SELECT SUM(CASE WHEN o.type = 'debt' THEN o.amount ELSE -o.amount END)
               FROM $_operations o
               WHERE o.customerId = c.id
             ), 0) AS balance
      FROM $_customers c
      $where
      ORDER BY ${sort.orderBy}
      LIMIT ? OFFSET ?
    ''', args);

    return CustomersPage(
      items: rows.take(limit).map(CustomerWithBalance.fromMap).toList(),
      hasMore: rows.length > limit,
    );
  }

  /// إجمالي الديون لكل العملاء (مجموع الأرصدة الموجبة فقط)،
  /// مستقل عن الصفحات المحمّلة وعن البحث.
  Future<double> getTotalDebts() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(b), 0) AS total
      FROM (
        SELECT SUM(CASE WHEN type = 'debt' THEN amount ELSE -amount END) AS b
        FROM $_operations
        GROUP BY customerId
        HAVING b > 0
      )
    ''');
    return (rows.first['total'] as num).toDouble();
  }

  /// إضافة عميل جديد، تُرجع id العميل
  Future<int> addCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return db.insert(_customers, customer.toMap());
  }

  /// تعديل اسم عميل وهاتفه (يُحدَّد بالـ id)، وتُرجع عدد الصفوف المتأثرة
  /// (0 يعني أن العميل غير موجود).
  Future<int> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    return db.update(
      _customers,
      {'name': customer.name, 'phone': customer.phone},
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// حذف عميل وكل عملياته (ديونه ودفعاته) داخل **معاملة واحدة**: إما أن يُحذف
  /// كل شيء أو لا يُحذف شيء إذا فشلت أي خطوة (rollback).
  ///
  /// تُرجع نسخة من المحذوف لاستعادته، أو null إذا كان العميل غير موجود.
  Future<DeletedCustomer?> deleteCustomer(int customerId) async {
    final db = await _dbHelper.database;

    // داخل المعاملة نستخدم txn وليس db، وإلا حدث تعليق (deadlock)
    return db.transaction<DeletedCustomer?>((txn) async {
      final customerRows = await txn.query(
        _customers,
        where: 'id = ?',
        whereArgs: [customerId],
      );
      if (customerRows.isEmpty) return null;

      // نسخة احتياطية من العمليات قبل حذفها (في المعاملة نفسها فتكون متسقة)
      final operationRows = await txn.query(
        _operations,
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'id ASC',
      );

      // نحذف العمليات صراحةً ثم العميل (ولا نعتمد على ON DELETE CASCADE وحده)
      await txn.delete(_operations, where: 'customerId = ?', whereArgs: [customerId]);
      await txn.delete(_customers, where: 'id = ?', whereArgs: [customerId]);

      return DeletedCustomer(
        customer: Customer.fromMap(customerRows.first),
        operations: operationRows.map(Operation.fromMap).toList(),
      );
    });
  }

  /// استعادة عميل محذوف وكل عملياته بنفس الـ id، داخل معاملة واحدة
  /// (الـ AUTOINCREMENT لا يعيد استخدام الـ id، فلا يحدث تعارض مع عملاء جدد).
  Future<void> restoreCustomer(DeletedCustomer deleted) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.insert(_customers, deleted.customer.toMap());
      final batch = txn.batch();
      for (final operation in deleted.operations) {
        batch.insert(_operations, operation.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  /// إضافة عدة عملاء دفعة واحدة داخل معاملة واحدة (إما أن تُحفظ كلها أو لا شيء).
  Future<void> addCustomers(List<Customer> customers) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final customer in customers) {
      batch.insert(_customers, customer.toMap());
    }
    await batch.commit(noResult: true);
  }
}