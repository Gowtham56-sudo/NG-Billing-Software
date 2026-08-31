import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/sqlite_service.dart';
import '../../../models/sale.dart';
import '../../../models/sale_item.dart';

final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(SalesNotifier.new);

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  @override
  Future<List<Sale>> build() async {
    return _fetchSales();
  }

  Future<List<Sale>> _fetchSales() async {
    final db = await SqliteService.database;
    final List<Map<String, dynamic>> maps = await db.query('sales', orderBy: 'date DESC');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<void> loadSales() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSales());
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await SqliteService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return maps.map((map) => SaleItem.fromMap(map)).toList();
  }

  Future<void> clearAllSales() async {
    final db = await SqliteService.database;
    await db.transaction((txn) async {
      await txn.delete('sale_items');
      await txn.delete('sales');
    });
    await loadSales();
  }

  Future<void> clearTodaysSales() async {
    final db = await SqliteService.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> todaySales = await txn.query(
        'sales',
        columns: ['id'],
        where: 'date LIKE ?',
        whereArgs: ['$todayStr%'],
      );
      for (final s in todaySales) {
        final id = s['id'] as int;
        await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [id]);
      }
      await txn.delete('sales', where: 'date LIKE ?', whereArgs: ['$todayStr%']);
    });
    await loadSales();
  }
}
