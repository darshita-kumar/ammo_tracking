import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'db_helper.dart';
import 'constants.dart';
import 'good_shooting_screen.dart';

class AmmunitionScreen extends StatefulWidget {
  final String position;
  final String troop;
  final String gun;
  final String shootingId;
  final String shootingName;
  final Future<void> Function() onLogout;

  const AmmunitionScreen({
    super.key,
    required this.position,
    required this.troop,
    required this.gun,
    required this.shootingId,
    required this.shootingName,
    required this.onLogout,
  });

  @override
  State<AmmunitionScreen> createState() => _AmmunitionScreenState();
}

class _AmmunitionScreenState extends State<AmmunitionScreen> {

  bool _navigated = false;

  Map<String, int> ammoCounts = {
    Constants.HE_PLUGGED: 0,
    Constants.AB:         0,
    Constants.SMK:        0,
    Constants.HE_117:     0,
    Constants.ILL:        0,
    Constants.SUPERCART:  0,
  };

  @override
  void initState() {
    super.initState();
    _watchStatus();
  }

  // ── Status watcher ──────────────────────────────────────────
  // Runs continuously — server holds connection until status changes
  Future<void> _watchStatus() async {
    while (mounted && !_navigated) {
      try {
        final data = await ApiService.get(
          '/api/shootings/${widget.shootingId}/status/watch',
        ) as Map<String, dynamic>;

        if (!mounted || _navigated) return;

        if (data['status'] == 'ended') {
          _navigated = true;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => GoodShootingScreen(
                onLogout:      widget.onLogout,
                isTroopLeader: false,
                shootingId:    widget.shootingId,
              ),
            ),
            (route) => false,
          );
          return;
        }
        // Status unchanged — loop immediately
      } catch (e) {
        debugPrint('Status watch error: $e');
        if (mounted && !_navigated) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  @override
  void dispose() {
    _navigated = true; // stops _watchStatus loop
    super.dispose();
  }

  Color getAmmoColor(String ammo) {
    switch (ammo) {
      case Constants.HE_PLUGGED:
      case Constants.HE_117:
        return Colors.amber;
      case Constants.ILL:
        return Colors.white;
      case Constants.SMK:
        return Colors.green;
      case Constants.SUPERCART:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Set<String> flashingButtons = {};

  Widget ammoButton(String label) {
    bool isFlashing = flashingButtons.contains(label);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isFlashing
            ? getAmmoColor(label).withValues(alpha: 0.4)
            : getAmmoColor(label),
        side: const BorderSide(color: Colors.black),
        minimumSize: const Size(160, 60),
      ),
      onPressed: () async {
        setState(() {
          flashingButtons.add(label);
          ammoCounts[label] = ammoCounts[label]! + 1;
        });

        sendAmmoEvent(
          shootingId: widget.shootingId,
          gun:        widget.gun,
          ammo:       label,
        );

        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) setState(() => flashingButtons.remove(label));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.black)),
          Text(ammoCounts[label].toString(),
              style: const TextStyle(fontSize: 18, color: Colors.black)),
        ],
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
            onPressed: () async => await widget.onLogout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const SizedBox(height: 20),

            // ── Info banner ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black54),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(children: [
                    const Text("TROOP",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text(widget.troop,
                        style: const TextStyle(fontSize: 20)),
                  ]),
                  Column(children: [
                    const Text("GUN",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text(widget.gun,
                        style: const TextStyle(fontSize: 20)),
                  ]),
                  Column(children: [
                    const Text("SHOOTING",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text(widget.shootingName,
                        style: const TextStyle(fontSize: 16)),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text("SELECT AMMUNITION",
                style: TextStyle(fontSize: 22)),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ammoButton(Constants.HE_PLUGGED),
                ammoButton(Constants.HE_117),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ammoButton(Constants.AB),
                ammoButton(Constants.ILL),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ammoButton(Constants.SMK),
                ammoButton(Constants.SUPERCART),
              ],
            ),
          ],
        ),
      ),
    );
  }
}