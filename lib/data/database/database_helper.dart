import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'debts.db';
  static const _dbVersion = 8;

  static const tableCustomers = 'customers';
  static const tableOperations = 'operations';
  static const tableInvoices = 'invoices';
  static const tableErpCache = 'erp_cache';
  static const tableCatalogGroups = 'catalog_groups';
  static const tableCatalogItems = 'catalog_items';
  static const tableCatalogPricing = 'catalog_pricing';
  static const tablePendingOrders = 'pending_orders';

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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCustomers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        erpId TEXT
      )
    ''');

    await _createCustomerErpIdIndex(db);

    await db.execute('''
      CREATE TABLE $tableOperations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('debt', 'payment')),
        note TEXT,
        date TEXT NOT NULL,
        currency TEXT,
        modeOfPayment TEXT,
        paymentEntry TEXT,
        FOREIGN KEY (customerId) REFERENCES $tableCustomers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_operations_customer_date ON $tableOperations (customerId, date DESC)',
    );

    await _createInvoicesTable(db);
    await _createErpCacheTable(db);
    await _createCatalogTables(db);
    await _createPendingOrdersTable(db);
  }

  /// ترقية قاعدة بيانات موجودة على الجهاز دون فقدان بياناتها:
  /// الإصدار 2 أضاف جدول الفواتير، والإصدار 3 أضاف جدول نسخة ERPNext للعمل دون إنترنت،
  /// والإصدار 4 أضاف عمود erpId في العملاء (رقم العميل في ERPNext).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createInvoicesTable(db);
    }
    if (oldVersion < 3) {
      await _createErpCacheTable(db);
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $tableCustomers ADD COLUMN erpId TEXT');
      await _createCustomerErpIdIndex(db);
    }
    if (oldVersion < 5) {
      // الإصدار 5: فاتورة الطلبية تُحفظ محليًا مع رقم الطلبية وأصنافها
      await db.execute('ALTER TABLE $tableInvoices ADD COLUMN orderId TEXT');
      await db.execute('ALTER TABLE $tableInvoices ADD COLUMN deliveryDate TEXT');
      await db.execute('ALTER TABLE $tableInvoices ADD COLUMN itemsJson TEXT');
    }
    if (oldVersion < 6) {
      // الإصدار 6: كتالوج محلي (أصناف/أسعار/مخزون) + طلبيات تنتظر الرفع للعمل دون إنترنت
      await db.execute(
        'ALTER TABLE $tableInvoices ADD COLUMN pendingUpload INTEGER NOT NULL DEFAULT 0',
      );
      await _createCatalogTables(db);
      await _createPendingOrdersTable(db);
    }
    if (oldVersion < 7) {
      // الإصدار 7: فصل المسودات عن الفواتير المعتمدة (submitted)
      await db.execute(
        'ALTER TABLE $tableInvoices ADD COLUMN submitted INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 8) {
      // الإصدار 8: عملة كل عملية، وطريقة الدفع ورقم Payment Entry للدفعات
      await db.execute('ALTER TABLE $tableOperations ADD COLUMN currency TEXT');
      await db.execute(
        'ALTER TABLE $tableOperations ADD COLUMN modeOfPayment TEXT',
      );
      await db.execute(
        'ALTER TABLE $tableOperations ADD COLUMN paymentEntry TEXT',
      );
    }
  }

  /// فهرس فريد على erpId: لا يتكرر عميل ERPNext أبدًا، والقيم الفارغة (العملاء
  /// المحليون بلا رقم ERPNext) مسموحة بأي عدد في SQLite.
  Future<void> _createCustomerErpIdIndex(Database db) async {
    await db.execute(
      'CREATE UNIQUE INDEX idx_customers_erp_id ON $tableCustomers (erpId)',
    );
  }

  /// نسخة محلية من كتالوج ERPNext: مجموعات الأصناف، الأصناف، وسعر كل صنف ومخزونه.
  Future<void> _createCatalogTables(Database db) async {
    await db.execute('''
      CREATE TABLE $tableCatalogGroups (
        name TEXT PRIMARY KEY
      )
    ''');
    await db.execute('''
      CREATE TABLE $tableCatalogItems (
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        uom TEXT NOT NULL,
        itemGroup TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_catalog_items_group ON $tableCatalogItems (itemGroup)',
    );
    await db.execute('''
      CREATE TABLE $tableCatalogPricing (
        itemCode TEXT PRIMARY KEY,
        rate REAL,
        available REAL NOT NULL,
        savedAt TEXT NOT NULL
      )
    ''');
  }

  /// طلبيات أُنشئت دون اتصال وتنتظر الرفع إلى ERPNext (تُرفع تلقائيًا لاحقًا).
  Future<void> _createPendingOrdersTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tablePendingOrders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerErpId TEXT NOT NULL,
        customerName TEXT NOT NULL,
        transactionDate TEXT NOT NULL,
        deliveryDate TEXT NOT NULL,
        linesJson TEXT NOT NULL,
        total REAL NOT NULL,
        createdAt TEXT NOT NULL,
        invoiceId INTEGER,
        status TEXT NOT NULL DEFAULT 'pending',
        lastError TEXT,
        erpOrderId TEXT
      )
    ''');
  }

  /// نسخة محلية من ردود ERPNext (قوائم الفواتير وتفاصيلها) لتُعرض عند انقطاع الإنترنت.
  /// المفتاح مثل `invoices:12` (فواتير العميل المحلي رقم 12) أو `invoice:ACC-SINV-2026-00004`،
  /// والقيمة نص JSON كما جاء من الخادم، مع وقت الحفظ لنعرض «آخر تحديث».
  Future<void> _createErpCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableErpCache (
        cacheKey TEXT PRIMARY KEY,
        json TEXT NOT NULL,
        savedAt TEXT NOT NULL
      )
    ''');
  }

  /// رقم الفاتورة يُشتق من id (INV-00001...) فلا يتكرر أبدًا،
  /// ولهذا لا يوجد عمود خاص بالرقم.
  Future<void> _createInvoicesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableInvoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        customerName TEXT NOT NULL,
        customerPhone TEXT NOT NULL,
        amount REAL NOT NULL CHECK (amount > 0),
        createdAt TEXT NOT NULL,
        orderId TEXT,
        deliveryDate TEXT,
        itemsJson TEXT,
        pendingUpload INTEGER NOT NULL DEFAULT 0,
        submitted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (customerId) REFERENCES $tableCustomers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_invoices_customer_date ON $tableInvoices (customerId, createdAt DESC)',
    );
  }
}