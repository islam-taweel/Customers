import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/customer_with_balance.dart';

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
  static const int pageSize = 20;

  static const _customers = DatabaseHelper.tableCustomers;
  static const _operations = DatabaseHelper.tableOperations;

  /// جلب دفعة من العملاء مع أرصدتهم.
  ///
  /// - الدفعة الأولى: `getCustomers()` أي offset = 0.
  /// - كل دفعة تالية: `getCustomers(offset: عدد_ما_حُمّل_حتى_الآن)`.
  /// - [query] يصفّي بالاسم على كل العملاء وليس على من حُمّل منهم فقط.
  /// - [limit] الافتراضي 20، ويمكن رفعه لإعادة تحديث كل ما هو معروض دفعة واحدة.
  Future<CustomersPage> getCustomers({
    int offset = 0,
    int limit = pageSize,
    String query = '',
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
      ORDER BY c.name COLLATE NOCASE ASC, c.id ASC
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