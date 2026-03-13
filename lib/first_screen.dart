import 'package:flutter/material.dart';
import 'gun_selection.dart';
import 'final_screen.dart';

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