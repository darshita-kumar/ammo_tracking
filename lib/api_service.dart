import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiService {
  static const _prefKey = 'server_ip';
  static const _defaultPort = '8000';
  static final http.Client _client = http.Client();

  // ── Server IP ───────────────────────────────────────────────
  static String? _serverIp;

  static Future<String?> getServerIp() async {
    if (_serverIp != null) return _serverIp;
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString(_prefKey);
    return _serverIp;
  }

  static String? _cachedBaseUrl;
  static String? _cachedWsUrl;

  static Future<void> saveServerIp(String ip) async {
    _serverIp = ip.trim();
    _cachedBaseUrl = null;
    _cachedWsUrl   = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, ip.trim());
  }

  static Future<String> _baseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    final ip = await getServerIp();
    if (ip == null || ip.isEmpty) {
      throw Exception('Server IP not configured.');
    }
    _cachedBaseUrl = 'http://$ip:$_defaultPort';
    return _cachedBaseUrl!;
  }

  static Future<String> _wsBaseUrl() async {
    if (_cachedWsUrl != null) return _cachedWsUrl!;
    final ip = await getServerIp();
    if (ip == null || ip.isEmpty) {
      throw Exception('Server IP not configured.');
    }
    _cachedWsUrl = 'ws://$ip:$_defaultPort';
    return _cachedWsUrl!;
  }

  // ── HTTP Helpers ────────────────────────────────────────────

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await _baseUrl()}$path');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 5));
    return _handle(response);
  }

  static Future<dynamic> get(String path) async {
    final url = Uri.parse('${await _baseUrl()}$path');
    final response = await _client.get(url).timeout(const Duration(seconds: 5));
    return _handleRaw(response);
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await _baseUrl()}$path');
    final response = await _client.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    return _handle(response);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final url = Uri.parse('${await _baseUrl()}$path');
    final response = await _client.delete(url).timeout(const Duration(seconds: 5));
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