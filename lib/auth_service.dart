import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final _db = FirebaseFirestore.instance;
  static const _prefKey = 'logged_in_uid';

  static String _hash(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  // ── Login ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim())
        .where('passwordHash', isEqualTo: _hash(password))
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, doc.id);

    return {...doc.data(), 'uid': doc.id};
  }

  // ── Logout ─────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  // ── Restore session ────────────────────────────────────────
  static Future<Map<String, dynamic>?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_prefKey);
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return {...doc.data()!, 'uid': uid};
  }

  // ── Admin helpers (unchanged from before) ─────────────────
  static Future<void> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final existing = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Username "${username.trim()}" already exists.');
    }

    await _db.collection('users').add({
      'username':     username.trim(),
      'passwordHash': _hash(password),
      'role':         role,
      'createdAt':    FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updatePassword(String uid, String newPassword) async {
    await _db.collection('users').doc(uid).update({
      'passwordHash': _hash(newPassword),
    });
  }

  static Future<void> updateUsername(String uid, String newUsername) async {
    final existing = await _db
        .collection('users')
        .where('username', isEqualTo: newUsername.trim())
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Username already taken.');
    }
    await _db.collection('users').doc(uid).update({
      'username': newUsername.trim(),
    });
  }

  static Future<void> deleteUser(String uid) =>
      _db.collection('users').doc(uid).delete();

  static Stream<QuerySnapshot> usersStream() =>
      _db.collection('users').orderBy('createdAt').snapshots();
}