import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'final_screen.dart';

class AmmunitionScreen extends StatefulWidget {

  final String position;
  final String troop;
  final String gun;

  const AmmunitionScreen({
    super.key,
    required this.position,
    required this.troop,
    required this.gun,
  });

  @override
  State<AmmunitionScreen> createState() => _AmmunitionScreenState();
}

class _AmmunitionScreenState extends State<AmmunitionScreen> {

  Map<String, int> ammoCounts = {
    "HE Plugged": 0,
    "AB": 0,
    "SMK": 0,
    "HE 117": 0,
    "ILL": 0,
    "Supercart": 0,
  };

  Widget ammoButton(String label) {

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber[200],
        minimumSize: const Size(160, 60),
      ),
      onPressed: () {
        sendAmmoEvent(
          troop: widget.troop,
          gun: widget.gun,
          ammo: "SMK",
        );

      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          Text(
            ammoCounts[label].toString(),
            style: const TextStyle(fontSize: 18, color: Colors.black),
          ),
        ],
      ),
    );
  }

  bool get hasSelection {
    return ammoCounts.values.any((v) => v > 0);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "SELECT AMMUNITION",
              style: TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ammoButton("HE Plugged"),
                ammoButton("HE 117"),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ammoButton("AB"),
                ammoButton("ILL"),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ammoButton("SMK"),
                ammoButton("Supercart"),
              ],
            ),

            const SizedBox(height: 80),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[200],
                minimumSize: const Size(150, 60),
              ),
              onPressed: hasSelection
                  ? () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FinalScreen(
                            position: widget.position,
                            troop: widget.troop,
                            gun: widget.gun,
                            ammoCounts: ammoCounts,
                          ),
                        ),
                      );

                    }
                  : null,
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