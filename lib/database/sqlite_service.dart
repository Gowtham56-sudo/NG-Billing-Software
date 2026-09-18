import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'tables.dart';
import '../core/utils/password_helper.dart';

class SqliteService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  static Future<Database> initDB() async {
    // Initialize FFI for Windows desktop
    DatabaseFactory factory;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    } else {
      factory = databaseFactory;
    }

    String path = join(await factory.getDatabasesPath(), 'nextgen_billing.db');

    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );

    // Ensure default categories exist
    await db.execute("INSERT OR IGNORE INTO categories (id, name) VALUES (1, 'Dairy & Beverages')");
    await db.execute("INSERT OR IGNORE INTO categories (id, name) VALUES (2, 'Oils & Ghee')");
    await db.execute("INSERT OR IGNORE INTO categories (id, name) VALUES (3, 'Snacks & Bakery')");
    await db.execute("INSERT OR IGNORE INTO categories (id, name) VALUES (4, 'Personal Care & Hygiene')");
    await db.execute("INSERT OR IGNORE INTO categories (id, name) VALUES (5, 'Grains, Flours & Dals')");
    await db.execute("INSERT OR IGNORE INTO categories (id, name) VALUES (6, 'Spices & Masalas')");
    await db.execute("INSERT OR IGNORE INTO categories (id, name) VALUES (7, 'Fresh Vegetables & Greens')");

    // Ensure initial products have category_id assigned
    await db.rawUpdate("UPDATE products SET category_id = 1 WHERE category_id IS NULL AND (name LIKE '%milk%' OR name LIKE '%aavin%' OR name LIKE '%tea%' OR name LIKE '%coffee%')");
    await db.rawUpdate("UPDATE products SET category_id = 2 WHERE category_id IS NULL AND (name LIKE '%oil%' OR name LIKE '%ghee%')");
    await db.rawUpdate("UPDATE products SET category_id = 3 WHERE category_id IS NULL AND (name LIKE '%biscuit%' OR name LIKE '%cake%' OR name LIKE '%cookie%')");
    await db.rawUpdate("UPDATE products SET category_id = 4 WHERE category_id IS NULL AND (name LIKE '%shampoo%' OR name LIKE '%soap%' OR name LIKE '%blade%' OR name LIKE '%paste%')");
    await db.rawUpdate("UPDATE products SET category_id = 7 WHERE category_id IS NULL AND (name LIKE '%tomato%' OR name LIKE '%onion%' OR name LIKE '%potato%' OR name LIKE '%carrot%' OR name LIKE '%beans%' OR name LIKE '%brinjal%' OR name LIKE '%cabbage%' OR name LIKE '%chilli%' OR name LIKE '%ginger%' OR name LIKE '%garlic%' OR name LIKE '%lemon%' OR name LIKE '%keerai%' OR name LIKE '%leaves%')");

    // One-time fix for Voice Assistant mapping mismatch
    await db.rawUpdate('UPDATE products SET name = ? WHERE name = ?', ['Sunflower Oil 1L', 'Sunflower Cooking Oil 1L']);
    
    // Ensure a default cashier exists for existing databases
    final cashierSalt = PasswordHelper.generateSalt();
    await db.insert(
      'users',
      {
        'username': 'cashier',
        'password_hash': PasswordHelper.hash('cashier123', cashierSalt),
        'salt': cashierSalt,
        'role': 'cashier',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return db;
  }

  static Future<void> _createDB(Database db, int version) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');

    // Create all tables
    for (String tableSql in DatabaseTables.allTables) {
      await db.execute(tableSql);
    }
    
    // Seed default admin and cashier accounts with salted password hashes.
    final adminSalt = PasswordHelper.generateSalt();
    final cashierSalt = PasswordHelper.generateSalt();
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'users',
      {
        'username': 'admin',
        'password_hash': PasswordHelper.hash('root', adminSalt),
        'salt': adminSalt,
        'role': 'admin',
        'is_active': 1,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.insert(
      'users',
      {
        'username': 'cashier',
        'password_hash': PasswordHelper.hash('cashier123', cashierSalt),
        'salt': cashierSalt,
        'role': 'cashier',
        'is_active': 1,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN hotel_price REAL DEFAULT 0.0');
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('UPDATE products SET gst_percentage = 18.0 WHERE gst_percentage = 0.0 OR gst_percentage IS NULL');
      } catch (e) {
        // Ignore
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN unit_value REAL DEFAULT 1.0');
      } catch (e) {
        // Ignore
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN paid_amount REAL DEFAULT 0.0');
      } catch (e) {
        // Ignore
      }
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN salt TEXT');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE users ADD COLUMN created_at TEXT');
      } catch (e) {
        // Column might already exist
      }

      // Migrate any user still carrying a plaintext password_hash (no salt yet)
      // to a salted hash, so upgrading an existing client database doesn't
      // leave old accounts stored in clear text.
      final plaintextUsers = await db.query(
        'users',
        where: 'salt IS NULL OR salt = ?',
        whereArgs: [''],
      );
      for (final user in plaintextUsers) {
        final salt = PasswordHelper.generateSalt();
        final hashed = PasswordHelper.hash(user['password_hash'] as String, salt);
        await db.update(
          'users',
          {'salt': salt, 'password_hash': hashed},
          where: 'id = ?',
          whereArgs: [user['id']],
        );
      }
    }
  }
}
