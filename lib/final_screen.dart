import 'package:flutter/material.dart';

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