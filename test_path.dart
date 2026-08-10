import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
void main() async {
  sqfliteFfiInit();
  print('Path: ' + await databaseFactoryFfi.getDatabasesPath());
}
