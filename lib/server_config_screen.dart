import 'package:flutter/material.dart';
import 'api_service.dart';

class ServerConfigScreen extends StatefulWidget {
  final VoidCallback onConfigured;
  const ServerConfigScreen({super.key, required this.onConfigured});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _ipCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentIp();
  }

  Future<void> _loadCurrentIp() async {
    final ip = await ApiService.getServerIp();
    if (ip != null && mounted) {
      setState(() => _ipCtrl.text = ip);
    }
  }

  Future<void> _save() async {
    if (_ipCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the server IP address.');
      return;
    }
    await ApiService.saveServerIp(_ipCtrl.text.trim());
    widget.onConfigured();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi, size: 64, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text('Server Setup',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Enter the IP address of the server laptop.\n'
                'Make sure you are on the same WiFi network.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _ipCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Server IP Address',
                  hintText: 'e.g. 192.168.1.100',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.computer),
                ),
                onSubmitted: (_) => _save(),
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
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Connect',
                      style: TextStyle(
                          fontSize: 16, color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}