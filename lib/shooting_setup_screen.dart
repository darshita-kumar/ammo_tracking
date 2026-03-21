import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'troop_leader_dashboard.dart';

class ShootingSetupScreen extends StatefulWidget {
  final String troop;
  final Future<void> Function() onLogout;

  const ShootingSetupScreen({
    super.key,
    required this.troop,
    required this.onLogout,
  });

  @override
  State<ShootingSetupScreen> createState() => _ShootingSetupScreenState();
}

class _ShootingSetupScreenState extends State<ShootingSetupScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _startShooting() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a shooting name.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // Create the shooting document
      final docRef = await FirebaseFirestore.instance
          .collection('shootings')
          .add({
        'name':      _nameCtrl.text.trim(),
        'troop':     widget.troop,
        'status':    'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TroopLeaderDashboard(
            troop:      widget.troop,
            position:   'Troop Leader',
            shootingId: docRef.id,
            shootingName: _nameCtrl.text.trim(),
            onLogout:   widget.onLogout,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Troop ${widget.troop} — New Shooting"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await widget.onLogout();
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
              const Text(
                'New Shooting Session',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Troop ${widget.troop}',
                style: TextStyle(
                    fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Shooting Name',
                  hintText: 'e.g. Morning Shoot, Exercise Alpha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _startShooting(),
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
                  onPressed: _loading ? null : _startShooting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Text('Begin Shooting',
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