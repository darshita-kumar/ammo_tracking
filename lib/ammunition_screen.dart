import 'package:flutter/material.dart';
import 'db_helper.dart';

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
    "HE PLUGGED": 0,
    "AB": 0,
    "SMK": 0,
    "HE 117": 0,
    "ILL": 0,
    "SUPERCART": 0,
  };

  Widget ammoButton(String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber[200],
        minimumSize: const Size(160, 60),
      ),
      onPressed: () {
        setState(() {
          ammoCounts[label] = ammoCounts[label]! + 1;
        });
        sendAmmoEvent(
          troop: widget.troop,
          gun: widget.gun,
          ammo: label,
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

            const SizedBox(height: 20),
            /// Troop + Gun Info
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

                  Column(
                    children: [
                      const Text(
                        "TROOP",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.troop,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      const Text(
                        "GUN",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.gun,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),

                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "SELECT AMMUNITION",
              style: TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ammoButton("HE PLUGGED"),
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
                ammoButton("SUPERCART"),
              ],
            ),

          ],
        ),
      ),
    );
  }
}