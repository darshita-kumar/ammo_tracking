import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'server_config_screen.dart';
import 'dart:io';

class LoginScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> userData) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter username and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await AuthService.login(_userCtrl.text, _passCtrl.text);
      if (data == null) {
        setState(() => _error = 'Invalid username or password.');
      } else {
        widget.onLoginSuccess(data);
      }
    } on SocketException {
      // Server unreachable — likely wrong IP
      setState(() => _error =
          'Could not reach server. Please check your server IP in settings.');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Invalid username or password')) {
        setState(() => _error = 'Invalid username or password.');
      } else if (msg.contains('Connection') || msg.contains('SocketException')) {
        setState(() => _error =
            'Could not reach server. Please check your server IP in settings.');
      } else {
        setState(() => _error = 'Error: $msg');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Server Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServerConfigScreen(
                    onConfigured: () => Navigator.pop(context),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Login',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!,
                    style: const TextStyle(
                        color: Colors.red, fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Text('Login',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}