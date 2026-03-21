import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import 'select_role_screen.dart';
import 'admin_dashboard.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _restoreSession();
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
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(onLoginSuccess: _onLoginSuccess),
      ),
      (route) => false,
    );
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_checkingSession) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_userData == null) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    // Admin goes to admin dashboard, everyone else to role selection
    if (_userData!['role'] == 'admin') {
      return AdminDashboard(onLogout: _onLogout);
    }

    return SelectRoleScreen(onLogout: _onLogout);
  }
}