import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/sqlite_service.dart';
import '../../../models/supplier.dart';

final suppliersProvider = AsyncNotifierProvider<SuppliersNotifier, List<Supplier>>(SuppliersNotifier.new);

class SuppliersNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    return _fetchSuppliers();
  }

  Future<List<Supplier>> _fetchSuppliers() async {
    final db = await SqliteService.database;
    final List<Map<String, dynamic>> maps = await db.query('suppliers');
    return maps.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<void> loadSuppliers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSuppliers());
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      final db = await SqliteService.database;
      await db.insert('suppliers', supplier.toMap());
      await loadSuppliers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      final db = await SqliteService.database;
      await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
      await loadSuppliers();
    } catch (e) {
      rethrow;
    }
  }
}
