import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FirstScreen(),
    );
  }
}

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {

  String? selectedPosition;
  String? selectedTroop;

  bool get isFormValid => selectedPosition != null && selectedTroop != null;

  Widget positionButton(String label) {
    bool isSelected = selectedPosition == label;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.amber[200],
        minimumSize: const Size(120, 60),
      ),
      onPressed: () {
        setState(() {
          selectedPosition = label;
        });
      },
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, color: Colors.black),
      ),
    );
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
              "SELECT POSITION",
              style: TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                positionButton("Gun"),
                positionButton("Troop Leader"),
              ],
            ),

            const SizedBox(height: 60),

            const Text(
              "SELECT TROOP",
              style: TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 20),

            DropdownButton<String>(
              hint: const Text("SELECT"),
              value: selectedTroop,
              items: ["A", "B", "C"].map((troop) {
                return DropdownMenuItem(
                  value: troop,
                  child: Text(troop),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTroop = value;
                });
              },
            ),

            const SizedBox(height: 80),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[200],
                minimumSize: const Size(150, 60),
              ),
              onPressed: isFormValid
              ? () {

                  if (selectedPosition == "Gun") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GunSelectionScreen(
                          position: selectedPosition!,
                          troop: selectedTroop!,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FinalScreen(
                          position: selectedPosition!,
                          troop: selectedTroop!,
                          gun: null,
                        ),
                      ),
                    );
                  }

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

            gunButton("Gun 1"),
            gunButton("Gun 2"),
            gunButton("Gun 3"),

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

class FinalScreen extends StatelessWidget {

  final String position;
  final String troop;
  final String? gun;
  final Map<String,int>? ammoCounts;

  const FinalScreen({
    super.key,
    required this.position,
    required this.troop,
    this.gun,
    this.ammoCounts,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Summary")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Position: $position"),
            Text("Troop: $troop"),
            Text("Gun: ${gun ?? "N/A"}"),

            const SizedBox(height: 20),

            if (ammoCounts != null)
              ...ammoCounts!.entries.map(
                (e) => Text("${e.key} : ${e.value}")
              )
          ],
        ),
      ),
    );
  }
}

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
        setState(() {
          ammoCounts[label] = ammoCounts[label]! + 1;
        });
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