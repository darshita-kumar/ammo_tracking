import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'select_role_screen.dart';
import 'admin_dashboard.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'server_config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, dynamic>? _userData;
  bool _checkingSession = true;
  Key _appKey = UniqueKey();

  bool _serverConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkServerConfig();
  }

  Future<void> _checkServerConfig() async {
    final ip = await ApiService.getServerIp();
    setState(() => _serverConfigured = ip != null && ip.isNotEmpty);
    if (_serverConfigured) _restoreSession();
  }

  Future<void> _restoreSession() async {
    final data = await AuthService.restoreSession();
    setState(() {
      _userData = data;
      _checkingSession = false;
    });
  }

  void _onLoginSuccess(Map<String, dynamic> userData) =>
      setState(() => _userData = userData);

  Future<void> _onLogout() async {
    await AuthService.logout();       // clears SharedPreferences
    setState(() => _userData = null);
    _appKey = UniqueKey();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: _appKey,      
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!_serverConfigured) {
      return ServerConfigScreen(
        onConfigured: () {
          setState(() => _serverConfigured = true);
          _restoreSession();
        },
      );
    }

    if (_checkingSession) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_userData == null) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    if (_userData!['role'] == 'admin') {
      return AdminDashboard(onLogout: _onLogout);
    }

    return SelectRoleScreen(onLogout: _onLogout);
  }
}