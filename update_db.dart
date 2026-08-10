import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  String path = join(await databaseFactory.getDatabasesPath(), 'nextgen_billing.db');
  
  if (!File(path).existsSync()) {
    print('Database not found at $path');
    return;
  }
  
  var db = await databaseFactory.openDatabase(path);
  await db.rawDelete('DELETE FROM products');
  print('Cleared products table. Please restart the Flutter app to re-seed.');
}
