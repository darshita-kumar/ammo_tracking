import 'package:flutter/material.dart';
import 'ammunition_screen.dart';
import 'constants.dart';
import 'auth_service.dart';

class GunSelectionScreen extends StatefulWidget {

  final String position;
  final String troop;
  final VoidCallback onLogout;

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
      appBar: AppBar(                        
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService.logout();
              widget.onLogout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "SELECT GUN",
              style: TextStyle(fontSize: 22),
            ),

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
                            onLogout: widget.onLogout,
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