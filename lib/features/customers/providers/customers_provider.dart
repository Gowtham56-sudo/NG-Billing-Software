import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/sqlite_service.dart';
import '../../../models/customer.dart';

final customersProvider = AsyncNotifierProvider<CustomersNotifier, List<Customer>>(CustomersNotifier.new);

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    return _fetchCustomers();
  }

  Future<List<Customer>> _fetchCustomers() async {
    final db = await SqliteService.database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomers());
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      final db = await SqliteService.database;
      await db.insert('customers', customer.toMap());
      await loadCustomers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      final db = await SqliteService.database;
      await db.delete('customers', where: 'id = ?', whereArgs: [id]);
      await loadCustomers();
    } catch (e) {
      rethrow;
    }
  }
}
