import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const _prefKey = 'logged_in_uid';
  static const _usernameKey = 'logged_in_username';
  static const _roleKey = 'logged_in_role';

  // ── Login ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    try {
      final data = await ApiService.post('/api/login', {
        'username': username.trim(),
        'password': password,
      });

      // Persist session locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, data['uid']);
      await prefs.setString(_usernameKey, data['username']);
      await prefs.setString(_roleKey, data['role']);

      return data;
    } catch (e) {
      // Invalid credentials returns a 401 from server
      if (e.toString().contains('Invalid username or password')) {
        return null;
      }
      rethrow;
    }
  }

  // ── Logout ─────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
  }

  // ── Restore session ────────────────────────────────────────
  // No server call needed — session is stored locally
  static Future<Map<String, dynamic>?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid      = prefs.getString(_prefKey);
    final username = prefs.getString(_usernameKey);
    final role     = prefs.getString(_roleKey);

    if (uid == null || username == null || role == null) return null;

    return {
      'uid':      uid,
      'username': username,
      'role':     role,
    };
  }

  // ── Admin helpers ──────────────────────────────────────────

  static Future<void> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    await ApiService.post('/api/users', {
      'username': username.trim(),
      'password': password,
      'role':     role,
    });
  }

  static Future<void> updatePassword(
      String uid, String newPassword) async {
    await ApiService.patch('/api/users/$uid/password', {
      'new_password': newPassword,
    });
  }

  static Future<void> updateUsername(
      String uid, String newUsername) async {
    await ApiService.patch('/api/users/$uid/username', {
      'new_username': newUsername.trim(),
    });
  }

  static Future<void> deleteUser(String uid) async {
    await ApiService.delete('/api/users/$uid');
  }

  // ── Users list (replaces usersStream) ─────────────────────
  // Returns a list of all users — call this to refresh the list.
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final data = await ApiService.get('/api/users');
    return List<Map<String, dynamic>>.from(data);
  }
}