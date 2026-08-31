import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/sqlite_service.dart';

class AppUser {
  final int? id;
  final String username;
  final String role;
  final bool isActive;
  final String? createdAt;

  AppUser({
    this.id,
    required this.username,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      username: map['username'] as String? ?? '',
      role: map['role'] as String? ?? 'cashier',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String?,
    );
  }
}

final usersProvider = AsyncNotifierProvider<UsersNotifier, List<AppUser>>(UsersNotifier.new);

class UsersNotifier extends AsyncNotifier<List<AppUser>> {
  @override
  Future<List<AppUser>> build() async {
    return _fetchUsers();
  }

  Future<List<AppUser>> _fetchUsers() async {
    final db = await SqliteService.database;
    final List<Map<String, dynamic>> maps = await db.query('users', orderBy: 'id ASC');
    return maps.map((map) => AppUser.fromMap(map)).toList();
  }

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }

  Future<void> addUser({required String username, required String password, required String role}) async {
    final db = await SqliteService.database;
    await db.insert('users', {
      'username': username.trim(),
      'password_hash': password.trim(),
      'role': role,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
    await loadUsers();
  }

  Future<void> updateUser({required int id, String? password, String? role, bool? isActive}) async {
    final db = await SqliteService.database;
    final Map<String, dynamic> updates = {};
    if (password != null && password.isNotEmpty) updates['password_hash'] = password.trim();
    if (role != null) updates['role'] = role;
    if (isActive != null) updates['is_active'] = isActive ? 1 : 0;

    if (updates.isNotEmpty) {
      await db.update('users', updates, where: 'id = ?', whereArgs: [id]);
      await loadUsers();
    }
  }

  Future<void> deleteUser(int id) async {
    final db = await SqliteService.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
    await loadUsers();
  }
}
