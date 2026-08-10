import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/sqlite_service.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  final bool isAuthenticated;
  final String? role;
  final String? username;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.role,
    this.username,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? role,
    String? username,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      username: username ?? this.username,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState();

  Future<bool> login(String username, String password) async {
    try {
      final db = await SqliteService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'username = ? AND password_hash = ? AND is_active = 1',
        whereArgs: [username, password],
      );

      if (maps.isNotEmpty) {
        final user = maps.first;
        state = state.copyWith(
          isAuthenticated: true,
          role: user['role'] as String,
          username: user['username'] as String,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(error: 'Invalid username or password');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Database error: $e');
      return false;
    }
  }

  void logout() {
    state = AuthState();
  }
}
