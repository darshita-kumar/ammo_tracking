import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ammunition_screen.dart';
import 'constants.dart';

class GunSelectionScreen extends StatefulWidget {
  final String position;
  final String troop;
  final Future<void> Function() onLogout;

  const GunSelectionScreen({
    super.key,
    required this.position,
    required this.troop,
    required this.onLogout,
  });

  @override
  State<GunSelectionScreen> createState() => _GunSelectionScreenState();
}

class _GunSelectionScreenState extends State<GunSelectionScreen> {
  String? selectedGun;

  // Fetches the active shooting for this troop
  Future<Map<String, dynamic>?> _fetchActiveShooting() async {
    final query = await FirebaseFirestore.instance
        .collection('shootings')
        .where('troop', isEqualTo: widget.troop)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return {
      'shootingId':   query.docs.first.id,
      'shootingName': query.docs.first.data()['name'] ?? '',
    };
  }

  Widget gunButton(String label) {
    bool isSelected = selectedGun == label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.orange : Colors.amber[200],
          minimumSize: const Size(180, 60),
        ),
        onPressed: () => setState(() => selectedGun = label),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
    );
  }

  Future<void> _goPressed() async {
    if (selectedGun == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final shooting = await _fetchActiveShooting();
    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (shooting == null) {
      // No active session — tell the gun user to wait
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No Active Shooting'),
          content: Text(
            'There is no active shooting session for Troop ${widget.troop}.\n\n'
            'Please wait for the Troop Leader to start one.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AmmunitionScreen(
          position:     widget.position,
          troop:        widget.troop,
          gun:          selectedGun!,
          shootingId:   shooting['shootingId']!,
          shootingName: shooting['shootingName']!,
          onLogout:     widget.onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text("SELECT GUN", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 40),

            gunButton(Constants.GUN1),
            gunButton(Constants.GUN2),
            gunButton(Constants.GUN3),

            const SizedBox(height: 80),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[200],
                minimumSize: const Size(150, 60),
              ),
              onPressed: selectedGun == null ? null : _goPressed,
              child: const Text(
                "GO",
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}