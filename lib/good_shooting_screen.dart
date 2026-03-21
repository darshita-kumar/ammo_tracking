import 'package:flutter/material.dart';

class GoodShootingScreen extends StatelessWidget {
  final Future<void> Function() onLogout;

  const GoodShootingScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Icon(
              Icons.military_tech,
              size: 80,
              color: Colors.amber,
            ),

            const SizedBox(height: 24),

            const Text(
              'Good Shooting!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'End firing, good shooting!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: 200,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  await onLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}