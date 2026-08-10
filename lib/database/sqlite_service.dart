import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'tables.dart';

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
        version: 5,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );

    // Ensure the default admin password is set to 'root' for existing databases
    await db.execute("UPDATE users SET password_hash = 'root' WHERE username = 'admin'");
    
    // One-time fix for Voice Assistant mapping mismatch
    await db.rawUpdate('UPDATE products SET name = ? WHERE name = ?', ['Sunflower Oil 1L', 'Sunflower Cooking Oil 1L']);
    
    // Ensure a default cashier exists for existing databases
    await db.execute('''
      INSERT OR IGNORE INTO users (username, password_hash, role, is_active)
      VALUES ('cashier', 'cashier123', 'cashier', 1)
    ''');

    return db;
  }

  static Future<void> _createDB(Database db, int version) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');

    // Create all tables
    for (String tableSql in DatabaseTables.allTables) {
      await db.execute(tableSql);
    }
    
    // Insert default admin user if not exists
    // We will use a default password 'admin123' hashed (for simplicity here, we'll hash it in auth repository or insert a dummy hash here)
    // Note: In production, password should be properly hashed. Here we insert plain text as a placeholder or a basic hash.
    await db.execute('''
      INSERT OR IGNORE INTO users (username, password_hash, role, is_active)
      VALUES ('admin', 'root', 'admin', 1)
    ''');

    await db.execute('''
      INSERT OR IGNORE INTO users (username, password_hash, role, is_active)
      VALUES ('cashier', 'cashier123', 'cashier', 1)
    ''');
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
  }
}
