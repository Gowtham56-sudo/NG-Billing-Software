import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/sqlite_service.dart';
import '../../../models/category.dart';

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(CategoriesNotifier.new);

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() async {
    final db = await SqliteService.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<void> clearAllCategories() async {
    try {
      final db = await SqliteService.database;
      await db.execute('DELETE FROM categories');
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCategories());
  }

  Future<void> addCategory(Category category) async {
    try {
      final db = await SqliteService.database;
      await db.insert('categories', category.toMap());
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final db = await SqliteService.database;
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }
}
