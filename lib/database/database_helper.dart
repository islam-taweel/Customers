import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/customer.dart';
import '../models/customer_with_balance.dart';
import '../models/operation.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'debts.db';
  static const _dbVersion = 1;

  static const tableCustomers = 'customers';
  static const tableOperations = 'operations';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        // تفعيل المفاتيح الأجنبية
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCustomers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableOperations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('debt', 'payment')),
        note TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES $tableCustomers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_operations_customer_date ON $tableOperations (customerId, date DESC)',
    );
  }

  // ───────────────────────── العملاء ─────────────────────────

  /// إضافة عميل جديد، تُرجع id العميل
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return db.insert(tableCustomers, customer.toMap());
  }

  /// جلب كل العملاء مرتبين أبجديًا
  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final maps = await db.query(tableCustomers, orderBy: 'name COLLATE NOCASE ASC');
    return maps.map(Customer.fromMap).toList();
  }

  // ───────────────────────── العمليات ─────────────────────────

  /// إضافة عملية (دين أو دفعة)، تُرجع id العملية
  Future<int> insertOperation(Operation operation) async {
    final db = await database;
    return db.insert(tableOperations, operation.toMap());
  }

  /// جلب عمليات عميل معين من الأحدث إلى الأقدم
  Future<List<Operation>> getOperationsByCustomer(int customerId) async {
    final db = await database;
    final maps = await db.query(
      tableOperations,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC, id DESC',
    );
    return maps.map(Operation.fromMap).toList();
  }

  // ───────────────────────── الرصيد ─────────────────────────

  /// رصيد العميل = مجموع الديون − مجموع الدفعات
  /// القيمة الموجبة: العميل مدين لك، السالبة: له رصيد عندك، صفر: لا شيء عليه
  Future<double> getCustomerBalance(int customerId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(
        CASE WHEN type = 'debt' THEN amount ELSE -amount END
      ), 0) AS balance
      FROM $tableOperations
      WHERE customerId = ?
    ''', [customerId]);

    return (result.first['balance'] as num).toDouble();
  }

  /// جلب كل العملاء مع أرصدتهم في استعلام واحد (أسرع من استدعاء الرصيد لكل عميل)
  Future<List<CustomerWithBalance>> getCustomersWithBalances() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.id, c.name, c.phone,
             COALESCE(SUM(
               CASE WHEN o.type = 'debt' THEN o.amount ELSE -o.amount END
             ), 0) AS balance
      FROM $tableCustomers c
      LEFT JOIN $tableOperations o ON o.customerId = c.id
      GROUP BY c.id
      ORDER BY c.name COLLATE NOCASE ASC
    ''');
    return result.map(CustomerWithBalance.fromMap).toList();
  }
}