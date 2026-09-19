// lib/database/local_database.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('my_pos_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Version 4 သို့ တိုးမြှင့်၍ sales table တွင် payment_method ထည့်သွင်းသည်
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT UNIQUE NOT NULL,
        pin_code TEXT NOT NULL,
        role TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        store_id TEXT NOT NULL,
        updated_at TEXT DEFAULT '',
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 2. Suppliers Table
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        address TEXT,
        note TEXT,
        owner_id TEXT NOT NULL,
        updated_at TEXT DEFAULT '',
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 3. Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_code TEXT NOT NULL,
        name TEXT NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0.0,
        sale_price REAL NOT NULL DEFAULT 0.0,
        quantity INTEGER NOT NULL DEFAULT 0,
        profit REAL NOT NULL DEFAULT 0.0,
        discount_price REAL DEFAULT 0.0,
        barcode TEXT,
        supplier TEXT DEFAULT '',
        supplier_id INTEGER,
        owner_id TEXT NOT NULL,
        updated_at TEXT DEFAULT '',
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE SET NULL
      )
    ''');

    // 4. Stock Ins Main Table
    await db.execute('''
      CREATE TABLE stock_ins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voucher_no TEXT NOT NULL,
        supplier TEXT NOT NULL,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        note TEXT,
        owner_id TEXT NOT NULL,
        updated_at TEXT DEFAULT '',
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 4.1 Stock In Details Table
    await db.execute('''
      CREATE TABLE stock_in_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stock_in_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        cost_price REAL NOT NULL,
        sale_price REAL NOT NULL DEFAULT 0.0,
        item_total REAL NOT NULL,
        FOREIGN KEY (stock_in_id) REFERENCES stock_ins (id) ON DELETE CASCADE
      )
    ''');

    // 5. Sales Transactions Table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'Cash',
        staff_name TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        store_id TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT '',
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 5.1 Sale Items Table
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        sub_total REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // 6. Debts Table
    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        phone TEXT,
        total_debt REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        remaining_balance REAL DEFAULT 0,
        status TEXT NOT NULL,
        due_date TEXT,
        owner_id TEXT NOT NULL,
        updated_at TEXT DEFAULT '',
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 7. Debt Transactions Table
    await db.execute('''
      CREATE TABLE debt_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debt_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        updated_at TEXT DEFAULT '',
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (debt_id) REFERENCES debts (id) ON DELETE CASCADE
      )
    ''');

    // 8. Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_code TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0.0,
        category TEXT NOT NULL,
        date_time TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        note TEXT,
        image_path TEXT,
        owner_id TEXT NOT NULL DEFAULT '',
        updated_at TEXT DEFAULT '',
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 9. VIP Members Table
    await db.execute('''
      CREATE TABLE vips (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT UNIQUE NOT NULL,
        tier TEXT NOT NULL DEFAULT 'Silver',
        total_spent REAL DEFAULT 0.0,
        points INTEGER DEFAULT 0,
        last_purchase_date TEXT DEFAULT '',
        owner_id TEXT NOT NULL DEFAULT '',
        updated_at TEXT DEFAULT '',
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 10. VIP Transactions Table
    await db.execute('''
      CREATE TABLE vip_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vip_id TEXT NOT NULL,
        amount REAL NOT NULL,
        points_earned INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (vip_id) REFERENCES vips (id) ON DELETE CASCADE
      )
    ''');

    // 11. VIP Tier Settings Table
    await db.execute('''
      CREATE TABLE vip_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tier_name TEXT NOT NULL UNIQUE,
        min_amount REAL NOT NULL,
        discount_percent REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // Default VIP Tier Configuration
    await db.execute("INSERT INTO vip_settings (tier_name, min_amount, discount_percent) VALUES ('Silver', 0.0, 0.0)");
    await db.execute("INSERT INTO vip_settings (tier_name, min_amount, discount_percent) VALUES ('Gold', 300000.0, 5.0)");
    await db.execute("INSERT INTO vip_settings (tier_name, min_amount, discount_percent) VALUES ('Diamond', 500000.0, 10.0)");

    // --- Performance Indexes ---
    await db.execute('CREATE INDEX idx_products_barcode ON products (barcode);');
    await db.execute('CREATE INDEX idx_products_code ON products (product_code);');
    await db.execute('CREATE INDEX idx_products_name ON products (name);');
    await db.execute('CREATE INDEX idx_debts_phone ON debts (phone);');
    await db.execute('CREATE INDEX idx_users_phone ON users (phone);');
    await db.execute('CREATE INDEX idx_sales_date ON sales (sale_date);');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses (date_time);');
    await db.execute('CREATE INDEX idx_vips_phone ON vips (phone);');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vips (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT UNIQUE NOT NULL,
          tier TEXT NOT NULL DEFAULT 'Silver',
          total_spent REAL DEFAULT 0.0,
          points INTEGER DEFAULT 0,
          last_purchase_date TEXT DEFAULT '',
          owner_id TEXT NOT NULL DEFAULT '',
          updated_at TEXT DEFAULT '',
          is_synced INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS vip_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vip_id TEXT NOT NULL,
          amount REAL NOT NULL,
          points_earned INTEGER NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (vip_id) REFERENCES vips (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_vips_phone ON vips (phone);');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vip_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tier_name TEXT NOT NULL UNIQUE,
          min_amount REAL NOT NULL,
          discount_percent REAL NOT NULL DEFAULT 0.0
        )
      ''');

      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM vip_settings'));
      if (count == null || count == 0) {
        await db.execute("INSERT INTO vip_settings (tier_name, min_amount, discount_percent) VALUES ('Silver', 0.0, 0.0)");
        await db.execute("INSERT INTO vip_settings (tier_name, min_amount, discount_percent) VALUES ('Gold', 300000.0, 5.0)");
        await db.execute("INSERT INTO vip_settings (tier_name, min_amount, discount_percent) VALUES ('Diamond', 500000.0, 10.0)");
      }
    }

    if (oldVersion < 4) {
      await db.execute("ALTER TABLE sales ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'Cash'");
    }
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_pos_app.db');

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    await deleteDatabase(path);
    _database = await _initDB('my_pos_app.db');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
