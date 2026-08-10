import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  sqfliteFfiInit();
  var db = await databaseFactoryFfi.openDatabase(join(await databaseFactoryFfi.getDatabasesPath(), 'nextgen_billing.db'));
  var products = await db.query('products');
  for (var p in products) {
    if (p['id'] == 2) print('NAME: "${p['name']}"');
  }
}
