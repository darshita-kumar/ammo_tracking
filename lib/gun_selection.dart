import 'package:flutter/material.dart';
import 'ammunnition_screen.dart';

class GunSelectionScreen extends StatefulWidget {

  final String position;
  final String troop;

  const GunSelectionScreen({
    super.key,
    required this.position,
    required this.troop,
  });

  @override
  State<GunSelectionScreen> createState() => _GunSelectionScreenState();
}

class _GunSelectionScreenState extends State<GunSelectionScreen> {

  String? selectedGun;

  Widget gunButton(String label) {

    bool isSelected = selectedGun == label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.orange : Colors.amber[200],
          minimumSize: const Size(180, 60),
        ),
        onPressed: () {
          setState(() {
            selectedGun = label;
          });
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "SELECT GUN",
              style: TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 40),

            gunButton("Gun1"),
            gunButton("Gun2"),
            gunButton("Gun3"),

            const SizedBox(height: 80),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[200],
                minimumSize: const Size(150, 60),
              ),
              onPressed: selectedGun == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AmmunitionScreen(
                            position: widget.position,
                            troop: widget.troop,
                            gun: selectedGun!,
                          ),
                        ),
                      );
                    },
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