import 'dart:async';
import '../../models/product.dart';
import '../../database/sqlite_service.dart';

/// A sample generic repository for loading products from a data source.
/// This ensures the catalog is fully data-driven.
class ProductRepository {
  final _productStreamController = StreamController<List<Product>>.broadcast();
  List<Product> _currentCatalog = [];

  Stream<List<Product>> get productStream => _productStreamController.stream;

  ProductRepository() {
    _init();
  }

  Future<void> _init() async {
    await fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final db = await SqliteService.database;
      final List<Map<String, dynamic>> maps = await db.query('products');
      
      _currentCatalog = maps.map((map) {
        // Here we construct the Product. The aliases field will be populated
        // automatically if it's stored in the DB (e.g., as a comma-separated string).
        return Product.fromMap(map);
      }).toList();

      _productStreamController.add(_currentCatalog);
    } catch (e) {
      print('Error fetching products: $e');
      _productStreamController.add([]);
    }
  }

  // Sample function to simulate a live catalog update
  Future<void> addProduct(Product product) async {
    // In a real app, you would insert into SQLite or Firestore here
    // e.g. await db.insert('products', product.toMap());
    
    // For demonstration, we just update the in-memory list and broadcast
    _currentCatalog.add(product);
    _productStreamController.add(_currentCatalog);
  }

  void dispose() {
    _productStreamController.close();
  }
}
