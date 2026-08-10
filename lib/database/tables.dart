class DatabaseTables {
  static const String usersTable = '''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL,
      is_active INTEGER DEFAULT 1
    )
  ''';

  static const String categoriesTable = '''
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL
    )
  ''';

  static const String productsTable = '''
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      barcode TEXT,
      sku TEXT,
      category_id INTEGER,
      brand TEXT,
      unit TEXT,
      unit_value REAL DEFAULT 1.0,
      purchase_price REAL DEFAULT 0.0,
      selling_price REAL DEFAULT 0.0,
      wholesale_price REAL DEFAULT 0.0,
      hotel_price REAL DEFAULT 0.0,
      gst_percentage REAL DEFAULT 18.0,
      current_stock REAL DEFAULT 0.0,
      min_stock REAL DEFAULT 0.0,
      batch_number TEXT,
      expiry_date TEXT,
      rack_number TEXT,
      image_path TEXT,
      description TEXT,
      FOREIGN KEY (category_id) REFERENCES categories (id)
    )
  ''';

  static const String customersTable = '''
    CREATE TABLE IF NOT EXISTS customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      mobile TEXT,
      address TEXT,
      gst_number TEXT,
      reward_points INTEGER DEFAULT 0,
      credit_limit REAL DEFAULT 0.0,
      type TEXT,
      pending_amount REAL DEFAULT 0.0,
      paid_amount REAL DEFAULT 0.0
    )
  ''';

  static const String suppliersTable = '''
    CREATE TABLE IF NOT EXISTS suppliers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      mobile TEXT,
      gst_number TEXT,
      address TEXT,
      pending_payments REAL DEFAULT 0.0
    )
  ''';

  static const String purchasesTable = '''
    CREATE TABLE IF NOT EXISTS purchases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      supplier_id INTEGER,
      invoice_number TEXT,
      date TEXT NOT NULL,
      total_amount REAL DEFAULT 0.0,
      gst_amount REAL DEFAULT 0.0,
      FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
    )
  ''';

  static const String purchaseItemsTable = '''
    CREATE TABLE IF NOT EXISTS purchase_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id INTEGER,
      product_id INTEGER,
      qty REAL DEFAULT 0.0,
      purchase_price REAL DEFAULT 0.0,
      gst_amount REAL DEFAULT 0.0,
      expiry TEXT,
      batch TEXT,
      FOREIGN KEY (purchase_id) REFERENCES purchases (id),
      FOREIGN KEY (product_id) REFERENCES products (id)
    )
  ''';

  static const String salesTable = '''
    CREATE TABLE IF NOT EXISTS sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_number TEXT UNIQUE NOT NULL,
      customer_id INTEGER,
      cashier_id INTEGER,
      date TEXT NOT NULL,
      subtotal REAL DEFAULT 0.0,
      discount REAL DEFAULT 0.0,
      gst_amount REAL DEFAULT 0.0,
      grand_total REAL DEFAULT 0.0,
      payment_method TEXT,
      status TEXT,
      paid_amount REAL DEFAULT 0.0,
      balance REAL DEFAULT 0.0,
      FOREIGN KEY (customer_id) REFERENCES customers (id),
      FOREIGN KEY (cashier_id) REFERENCES users (id)
    )
  ''';

  static const String saleItemsTable = '''
    CREATE TABLE IF NOT EXISTS sale_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER,
      product_id INTEGER,
      qty REAL DEFAULT 0.0,
      price REAL DEFAULT 0.0,
      discount REAL DEFAULT 0.0,
      gst_amount REAL DEFAULT 0.0,
      total REAL DEFAULT 0.0,
      FOREIGN KEY (sale_id) REFERENCES sales (id),
      FOREIGN KEY (product_id) REFERENCES products (id)
    )
  ''';

  static const String expensesTable = '''
    CREATE TABLE IF NOT EXISTS expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL,
      amount REAL DEFAULT 0.0,
      date TEXT NOT NULL,
      description TEXT
    )
  ''';

  static const String settingsTable = '''
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
  ''';

  static List<String> get allTables => [
    usersTable,
    categoriesTable,
    productsTable,
    customersTable,
    suppliersTable,
    purchasesTable,
    purchaseItemsTable,
    salesTable,
    saleItemsTable,
    expensesTable,
    settingsTable,
  ];
}
