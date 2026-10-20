import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/customer_sort_option.dart';
import '../models/customer_with_balance.dart';
import '../models/deleted_customer.dart';
import '../models/erp_customer.dart';
import '../models/invoice.dart';
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
  static const _invoices = DatabaseHelper.tableInvoices;

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

      // نسخة احتياطية من فواتيره أيضًا، حتى تعود عند التراجع عن الحذف
      final invoiceRows = await txn.query(
        _invoices,
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'id ASC',
      );

      // نحذف العمليات والفواتير صراحةً ثم العميل (ولا نعتمد على ON DELETE CASCADE وحده)
      await txn.delete(_operations, where: 'customerId = ?', whereArgs: [customerId]);
      await txn.delete(_invoices, where: 'customerId = ?', whereArgs: [customerId]);
      await txn.delete(_customers, where: 'id = ?', whereArgs: [customerId]);

      return DeletedCustomer(
        customer: Customer.fromMap(customerRows.first),
        operations: operationRows.map(Operation.fromMap).toList(),
        invoices: invoiceRows.map(Invoice.fromMap).toList(),
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
      for (final invoice in deleted.invoices) {
        batch.insert(_invoices, invoice.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  /// دمج عملاء ERPNext (الاسم والهاتف فقط) في جدول العملاء المحلي، داخل معاملة واحدة.
  ///
  /// نُبقي العملاء في الجدول المحلي لأن الديون والعمليات مربوطة بـ id العميل المحلي،
  /// فلا يتغير شيء فيها. المطابقة بالترتيب:
  /// 1) بعمود erpId (عميل سبقت مزامنته)،
  /// 2) بآخر 9 أرقام من الهاتف، 3) بالاسم، وذلك لعميل محلي لا يملك erpId بعد،
  ///    فيُربط بعميل ERPNext ويحتفظ بديونه.
  /// وإن لم يوجد مطابق يُضاف عميل جديد. الاسم والهاتف يؤخذان من ERPNext،
  /// ولا يُحذف أي عميل محلي غير موجود في ERPNext.
  Future<void> syncFromErp(List<ErpCustomer> remote) async {
    // رد فارغ لا يغيّر شيئًا (حماية من محو أو تعديل البيانات بسبب رد ناقص)
    if (remote.isEmpty) return;
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final rows = await txn.query(
        _customers,
        columns: ['id', 'name', 'phone', 'erpId'],
      );

      final idByErpId = <String, int>{};
      final unlinkedByPhone = <String, int>{};
      final unlinkedByName = <String, int>{};
      for (final row in rows) {
        final id = row['id'] as int;
        final erpId = row['erpId'] as String?;
        if (erpId != null && erpId.isNotEmpty) {
          idByErpId[erpId] = id;
          continue;
        }
        final phoneKey = _phoneKey(row['phone'] as String);
        if (phoneKey != null) unlinkedByPhone.putIfAbsent(phoneKey, () => id);
        unlinkedByName.putIfAbsent(_nameKey(row['name'] as String), () => id);
      }

      final batch = txn.batch();
      for (final customer in remote) {
        var localId = idByErpId[customer.id];

        if (localId == null) {
          final phoneKey = _phoneKey(customer.phone);
          localId = (phoneKey == null ? null : unlinkedByPhone[phoneKey]) ??
              unlinkedByName[_nameKey(customer.name)];

          // العميل المحلي الذي ارتبط الآن لا يجوز أن يرتبط بعميل ERPNext آخر
          if (localId != null) {
            final linkedId = localId;
            unlinkedByPhone.removeWhere((_, id) => id == linkedId);
            unlinkedByName.removeWhere((_, id) => id == linkedId);
          }
        }

        if (localId == null) {
          batch.insert(_customers, {
            'name': customer.name,
            'phone': customer.phone,
            'erpId': customer.id,
          });
        } else {
          batch.update(
            _customers,
            {
              'name': customer.name,
              // عميل ERPNext بلا هاتف لا يمحو الهاتف المحلي
              if (customer.phone.isNotEmpty) 'phone': customer.phone,
              'erpId': customer.id,
            },
            where: 'id = ?',
            whereArgs: [localId],
          );
        }
      }
      await batch.commit(noResult: true);
    });
  }

  /// العملاء المرتبطون بـ ERPNext (لهم erpId) كما حُفظوا محليًا آخر مرة.
  /// تُستخدم قائمة بدل الإنترنت عند إنشاء طلبية دون اتصال.
  Future<List<ErpCustomer>> getErpCustomers() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _customers,
      columns: ['name', 'phone', 'erpId'],
      where: "erpId IS NOT NULL AND erpId != ''",
      orderBy: 'name COLLATE NOCASE',
    );
    return [
      for (final row in rows)
        ErpCustomer(
          id: row['erpId'] as String,
          name: row['name'] as String,
          phone: (row['phone'] as String?) ?? '',
        ),
    ];
  }

  /// ربط كل عميل محلي برقمه في ERPNext (للمزامنة الكاملة للفواتير).
  Future<List<({int id, String erpId})>> getErpLinks() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _customers,
      columns: ['id', 'erpId'],
      where: "erpId IS NOT NULL AND erpId != ''",
    );
    return [
      for (final row in rows)
        (id: row['id'] as int, erpId: row['erpId'] as String),
    ];
  }

  /// آخر 9 أرقام من الهاتف، فتتطابق الصيغ المحلية والدولية (null إن قصر الرقم).
  String? _phoneKey(String raw) {
    final digits = normalizeDigits(raw).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) return null;
    return digits.substring(digits.length - 9);
  }

  /// الاسم بلا فروق في حالة الأحرف أو المسافات الزائدة
  String _nameKey(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

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