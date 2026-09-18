import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/sqlite_service.dart';
import '../../../core/utils/password_helper.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  final bool isAuthenticated;
  final int? userId;
  final String? role;
  final String? username;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.role,
    this.username,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    int? userId,
    String? role,
    String? username,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
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
        where: 'username = ? AND is_active = 1',
        whereArgs: [username],
      );

      if (maps.isEmpty) {
        state = state.copyWith(error: 'Invalid username or password');
        return false;
      }

      final candidate = maps.first;
      final salt = candidate['salt'] as String?;
      final storedHash = candidate['password_hash'] as String?;
      final matches = salt != null &&
          salt.isNotEmpty &&
          storedHash != null &&
          PasswordHelper.hash(password, salt) == storedHash;

      if (matches) {
        final user = candidate;
        state = state.copyWith(
          isAuthenticated: true,
          userId: user['id'] as int,
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
