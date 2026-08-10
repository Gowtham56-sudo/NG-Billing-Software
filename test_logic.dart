import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/features/cashier/providers/voice_billing_provider.dart';
import 'lib/features/products/providers/products_provider.dart';
import 'lib/models/product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  
  // Wait for products to load
  await container.read(productsProvider.notifier).loadProducts();
  final products = container.read(productsProvider).value ?? [];
  print('Total products loaded: ${products.length}');
  for (var p in products) {
    print(' - ${p.name}');
  }
  
  // Simulate receiving "cake"
  final message = jsonEncode({
    "type": "bill_update",
    "transcript": "கேக்!",
    "items": [
      {"product": "Cake", "qty": 1}
    ],
    "unmatched_items": [],
    "source": "regex"
  });
  
  // Note: we can't easily trigger private methods, so we'll just replicate the logic
  int addedCount = 0;
  List<String> notFoundList = [];
  List<String> suggestionList = [];
  
  final items = jsonDecode(message)['items'] as List;
  
  for (final item in items) {
    final productName = item['product']?.toString().toLowerCase().trim() ?? '';
    final rawProductName = item['product']?.toString().trim() ?? '';
    
    if (productName.isNotEmpty) {
      Product? matchedProduct;
      bool multipleMatches = false;
      
      try {
        matchedProduct = products.firstWhere((p) => p.name.toLowerCase() == productName);
        print('Exact match found: \${matchedProduct.name}');
      } catch (_) {
        final containsMatches = products.where((p) => p.name.toLowerCase().contains(productName)).toList();
        print('Contains matches: \${containsMatches.map((e) => e.name).toList()}');
        if (containsMatches.length == 1) {
          matchedProduct = containsMatches.first;
        } else if (containsMatches.length > 1) {
          multipleMatches = true;
          matchedProduct = null;
        } else {
          matchedProduct = null;
        }
      }

      if (matchedProduct != null) {
        addedCount++;
      } else if (multipleMatches) {
        suggestionList.add(rawProductName);
      } else {
        notFoundList.add(rawProductName);
      }
    }
  }
  
  print('Added: $addedCount');
  print('Suggestions: $suggestionList');
  print('Not Found: $notFoundList');
}
