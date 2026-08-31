import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/sqlite_service.dart';
import '../../../models/purchase.dart';
import '../../products/providers/products_provider.dart';

final purchasesProvider = AsyncNotifierProvider<PurchasesNotifier, List<Purchase>>(PurchasesNotifier.new);

class PurchasesNotifier extends AsyncNotifier<List<Purchase>> {
  @override
  Future<List<Purchase>> build() async {
    return _fetchPurchases();
  }

  Future<List<Purchase>> _fetchPurchases() async {
    final db = await SqliteService.database;
    final List<Map<String, dynamic>> maps = await db.query('purchases');
    return maps.map((map) => Purchase(
      id: map['id'],
      supplierId: map['supplier_id'],
      invoiceNumber: map['invoice_number'],
      date: map['date'],
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      gstAmount: map['gst_amount']?.toDouble() ?? 0.0,
    )).toList();
  }

  Future<void> loadPurchases() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPurchases());
  }

  Future<void> addPurchase(Purchase purchase) async {
    try {
      final db = await SqliteService.database;
      
      await db.transaction((txn) async {
        int purchaseId = await txn.insert('purchases', purchase.toMap());

        for (var item in purchase.items) {
          await txn.insert('purchase_items', item.toMap(purchaseId));
          
          await txn.rawUpdate(
            'UPDATE products SET current_stock = current_stock + ?, purchase_price = ? WHERE id = ?',
            [item.qty, item.purchasePrice, item.productId],
          );
        }
      });
      
      await loadPurchases();
      ref.read(productsProvider.notifier).loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearAllPurchases() async {
    final db = await SqliteService.database;
    await db.transaction((txn) async {
      await txn.delete('purchase_items');
      await txn.delete('purchases');
    });
    await loadPurchases();
  }
}
