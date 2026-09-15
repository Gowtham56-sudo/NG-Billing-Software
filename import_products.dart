import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  String dbPath = join(await databaseFactory.getDatabasesPath(), 'nextgen_billing.db');
  print('Connecting to database at: $dbPath');
  
  var db = await databaseFactory.openDatabase(dbPath);

  File file = File('raw_products_list.txt');
  if (!await file.exists()) {
    print('Error: raw_products_list.txt not found.');
    exit(1);
  }
  
  List<String> lines = await file.readAsLines();
  print('Loaded ${lines.length} products. Starting import...');

  int successCount = 0;
  int errorCount = 0;

  for (String line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    String name = line;
    double price = 0.0;
    int categoryId = 7; // Default to Fresh Vegetables & Greens/Others

    // Extract price if it ends with XXRS or XX RS
    RegExp regExp = RegExp(r'([\d.]+)\s*RS', caseSensitive: false);
    var match = regExp.firstMatch(line);
    if (match != null) {
      price = double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }

    // Category assignment based on keywords
    String lower = line.toLowerCase();
    if (lower.contains('milk') || lower.contains('tea') || lower.contains('coffee') || lower.contains('curd') || lower.contains('butter') || lower.contains('cheese')) {
      categoryId = 1; // Dairy & Beverages
    } else if (lower.contains('oil') || lower.contains('ghee')) {
      categoryId = 2; // Oils & Ghee
    } else if (lower.contains('biscuit') || lower.contains('cake') || lower.contains('cookie') || lower.contains('chocolate') || lower.contains('snack') || lower.contains('chips') || lower.contains('rusk') || lower.contains('sweet')) {
      categoryId = 3; // Snacks & Bakery
    } else if (lower.contains('shampoo') || lower.contains('soap') || lower.contains('paste') || lower.contains('brush') || lower.contains('powder') || lower.contains('cream') || lower.contains('liquid') || lower.contains('perfume') || lower.contains('wash')) {
      categoryId = 4; // Personal Care
    } else if (lower.contains('rice') || lower.contains('atta') || lower.contains('maida') || lower.contains('dal') || lower.contains('parupu') || lower.contains('gothumai') || lower.contains('flour') || lower.contains('kurunai') || lower.contains('ulundhu')) {
      categoryId = 5; // Grains
    } else if (lower.contains('masala') || lower.contains('thool') || lower.contains('spice') || lower.contains('pepper') || lower.contains('salt') || lower.contains('sugar') || lower.contains('podi')) {
      categoryId = 6; // Spices & Masalas
    }

    try {
      await db.insert('products', {
        'name': name,
        'selling_price': price,
        'category_id': categoryId,
        'current_stock': 100.0,
        'unit': 'Piece',
        'unit_value': 1.0,
        'gst_percentage': 18.0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      successCount++;
    } catch (e) {
      errorCount++;
      print('Failed to insert $name: $e');
    }
  }

  print('Import complete! Successfully inserted: $successCount, Errors: $errorCount');
  await db.close();
  exit(0);
}
