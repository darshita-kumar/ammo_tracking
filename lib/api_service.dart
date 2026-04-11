import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiService {
  static const _prefKey = 'server_ip';
  static const _defaultPort = '8000';

  // ── Server IP ───────────────────────────────────────────────
  static String? _serverIp;

  static Future<String?> getServerIp() async {
    if (_serverIp != null) return _serverIp;
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString(_prefKey);
    return _serverIp;
  }

  static Future<void> saveServerIp(String ip) async {
    _serverIp = ip.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, ip.trim());
  }

  static Future<String> _baseUrl() async {
    final ip = await getServerIp();
    if (ip == null || ip.isEmpty) {
      throw Exception('Server IP not configured.');
    }
    return 'http://$ip:$_defaultPort';
  }

  static Future<String> _wsBaseUrl() async {
    final ip = await getServerIp();
    if (ip == null || ip.isEmpty) {
      throw Exception('Server IP not configured.');
    }
    return 'ws://$ip:$_defaultPort';
  }

  // ── HTTP Helpers ────────────────────────────────────────────

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await _baseUrl()}$path');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  static Future<dynamic> get(String path) async {
    final url = Uri.parse('${await _baseUrl()}$path');
    final response = await http.get(url);
    return _handleRaw(response);
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await _baseUrl()}$path');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final url = Uri.parse('${await _baseUrl()}$path');
    final response = await http.delete(url);
    return _handle(response);
  }

  // ── WebSocket ───────────────────────────────────────────────
  // Returns a WebSocketChannel that streams shoot status updates.
  // Listen to .stream for incoming messages.

  static Future<WebSocketChannel> connectToShoot(String shootingId) async {
    final url = Uri.parse('${await _wsBaseUrl()}/ws/shootings/$shootingId');
    return WebSocketChannel.connect(url);
  }

  // ── Response Handlers ───────────────────────────────────────

  static Map<String, dynamic> _handle(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }
    final detail = (body as Map<String, dynamic>)['detail'] ?? 'Unknown error';
    throw Exception(detail);
  }

  static dynamic _handleRaw(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    final detail = (body as Map<String, dynamic>)['detail'] ?? 'Unknown error';
    throw Exception(detail);
  }
}