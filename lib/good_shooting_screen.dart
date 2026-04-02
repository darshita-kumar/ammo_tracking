import 'package:flutter/material.dart';
import 'shoot_summary_screen.dart';

class GoodShootingScreen extends StatelessWidget {
  final Future<void> Function() onLogout;
  final bool isTroopLeader;
  final String shootingId;

  const GoodShootingScreen({
    super.key, 
      required this.onLogout,
      required this.isTroopLeader,
      required this.shootingId,
    });

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
              'Cease firing, Good shooting!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
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
            if (isTroopLeader) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShootSummaryScreen(shootingId: shootingId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Shoot Summary',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}