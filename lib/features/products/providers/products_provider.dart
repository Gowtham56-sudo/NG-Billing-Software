import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/sqlite_service.dart';
import '../../../models/product.dart';
final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final db = await SqliteService.database;
    
    // Seed some products if the table is empty
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    final count = (countResult.isNotEmpty ? (countResult.first['count'] as int?) : 0) ?? 0;
    
    if (count == 0) {
      final sampleProducts = [
        {
          'name': 'Premium Fresh Grocery',
          'selling_price': 45.0,
          'current_stock': 120,
          'description': 'Fresh organic vegetables and fruits.',
          'image_path': 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'Sunflower Oil 1L',
          'selling_price': 120.0,
          'current_stock': 50,
          'description': '100% pure sunflower oil for healthy cooking.',
          'image_path': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'Luxury Bath Soap',
          'selling_price': 25.0,
          'current_stock': 200,
          'description': 'Handcrafted moisturizing body soap.',
          'image_path': 'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'Herbal Shampoo',
          'selling_price': 150.0,
          'current_stock': 75,
          'description': 'Anti-hairfall organic herbal shampoo.',
          'image_path': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'Clinic Plus Shampoo',
          'selling_price': 80.0,
          'current_stock': 120,
          'description': 'Strong and long hair shampoo.',
          'image_path': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'Mixed Spices Pack',
          'selling_price': 60.0,
          'current_stock': 100,
          'description': 'Aromatic blend of essential kitchen spices.',
          'image_path': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'Chocolate Fudge Cake',
          'selling_price': 450.0,
          'current_stock': 10,
          'description': 'Delicious double chocolate layered fudge cake.',
          'image_path': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'milk',
          'selling_price': 25.0,
          'current_stock': 50,
          'description': 'Fresh dairy milk.',
          'image_path': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'Biscuit',
          'selling_price': 30.0,
          'current_stock': 150,
          'description': 'Crunchy tea time biscuits.',
          'image_path': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'Chocolate Cake',
          'selling_price': 350.0,
          'current_stock': 15,
          'description': 'Rich and moist chocolate layer cake.',
          'image_path': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'Black Forest Cake',
          'selling_price': 400.0,
          'current_stock': 12,
          'description': 'Classic German chocolate cake with cherry filling.',
          'image_path': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=500&q=60',
        },
        {
          'name': 'Butterscotch Cake',
          'selling_price': 380.0,
          'current_stock': 18,
          'description': 'Caramel butterscotch flavor sponge cake.',
          'image_path': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=500&q=60',
        }
      ];

      for (final p in sampleProducts) {
        await db.insert('products', p);
      }
    }

    final List<Map<String, dynamic>> maps = await db.query('products');
    final products = maps.map((map) => Product.fromMap(map)).toList();
    
    // Auto-sync products to voice assistant's products.json
    _syncProductsToJson(products);
    
    return products;
  }

  Future<void> _syncProductsToJson(List<Product> products) async {
    try {
      final file = File(r'd:\Billing-software-main\voice_assistant_temp\products.json');
      if (!await file.exists()) return;
      
      final content = await file.readAsString();
      final Map<String, dynamic> catalog = jsonDecode(content);
      
      bool updated = false;
      for (final p in products) {
        if (!catalog.containsKey(p.name)) {
          // Add new product with just its name as alias (user can add tamil later)
          catalog[p.name] = [p.name.toLowerCase()];
          updated = true;
        }
      }
      
      if (updated) {
        await file.writeAsString(jsonEncode(catalog));
        debugPrint('Synced new products to products.json for Voice Assistant');
      }
    } catch (e) {
      debugPrint('Failed to sync products to json: $e');
    }
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProducts());
  }

  Future<void> addProduct(Product product) async {
    try {
      final db = await SqliteService.database;
      await db.insert('products', product.toMap());
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final db = await SqliteService.database;
      await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final db = await SqliteService.database;
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }
}
