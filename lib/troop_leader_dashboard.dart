import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'auth_service.dart';

class TroopLeaderDashboard extends StatefulWidget {
  final String position;
  final String troop;
  final VoidCallback onLogout;

  const TroopLeaderDashboard({
    super.key,
    required this.position,
    required this.troop,
    required this.onLogout,
  });

  @override
  State<TroopLeaderDashboard> createState() => _TroopLeaderDashboardState();
}

class _TroopLeaderDashboardState extends State<TroopLeaderDashboard> {
  Timestamp? sessionStart;
  StreamSubscription? eventSubscription;

  final ammoTypes = [
    Constants.HE_PLUGGED,
    Constants.HE_117,
    Constants.AB,
    Constants.ILL,
    Constants.SMK,
    Constants.SUPERCART,
    Constants.CART
  ];

  final gunRows = [Constants.GUN1, Constants.GUN2, Constants.GUN3];

  Map<String, int> initial = {};
  Map<String, int> threshold = {};
  Map<String, Map<String, int>> guns = {};

  // Tracks which cells are currently flashing
  Set<String> flashingCells = {};

  bool started = false;

  @override
  void initState() {
    super.initState();

    for (var a in ammoTypes) {
      initial[a] = 0;
      threshold[a] = 0;
    }

    for (var g in gunRows) {
      guns[g] = {};
      for (var a in ammoTypes) {
        guns[g]![a] = 0;
      }
    }
  }

  void startPressed() {
    final startTime = Timestamp.now();
    setState(() {
      started = true;
      sessionStart = startTime;
      for (var ammo in ammoTypes) {
        for (var gun in gunRows) {
          guns[gun]![ammo] = initial[ammo]!;
        }
      }
    });
    // Small delay so the listener doesn't catch events right at the boundary
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) startListeningToEvents();
    });
  }

  /// Triggers a short flash highlight on a specific cell
  void flashCell(String gun, String ammo) {
    final key = '$gun|$ammo';
    setState(() => flashingCells.add(key));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => flashingCells.remove(key));
    });
  }

  void startListeningToEvents() {
    bool initialLoadDone = false;

    eventSubscription = FirebaseFirestore.instance
        .collection("events")
        .where("troop", isEqualTo: widget.troop)
        .where("timestamp", isGreaterThan: sessionStart)
        .snapshots()
        .listen((snapshot) {

          if (!initialLoadDone) {                          // ← skip first batch
            initialLoadDone = true;
            return;
          }

          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              String gun = data["gun"];
              String ammo = data["ammo"];

              setState(() {
                if (guns[gun]![ammo]! > 0) {
                  guns[gun]![ammo] = guns[gun]![ammo]! - 1;
                }
                if (ammo != Constants.SUPERCART) {
                  if (guns[gun]![Constants.CART]! > 0) {
                    guns[gun]![Constants.CART] = guns[gun]![Constants.CART]! - 1;
                  }
                } else {
                  guns[gun]![Constants.CART] = guns[gun]![Constants.CART]! + 1;
                }
              });

              flashCell(gun, ammo);
              flashCell(gun, Constants.CART);
            }
          }
        });
  }

  @override
  void dispose() {
    eventSubscription?.cancel();
    super.dispose();
  }

  //====================== FRONTEND ==============================

  Widget cell(String text, {bool bold = false, double width = 110, Color? color}) {
    return Container(
      width: width,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget editableCell(String gun, String ammo) {
    int value = guns[gun]![ammo]!;
    final isFlashing = flashingCells.contains('$gun|$ammo');

    Color? highlight;
    if (isFlashing) {
      highlight = Colors.yellow.shade200;      // flash on DB update
    } else if (started && value <= threshold[ammo]!) {
      highlight = Colors.red.shade200;       // threshold warning
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 110,
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: highlight,
        border: Border.all(color: Colors.black),
      ),
      child: TextField(
        enabled: started,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        controller: TextEditingController(text: value.toString()),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(border: InputBorder.none),
        onSubmitted: (val) {
          int? newVal = int.tryParse(val);
          if (newVal != null) setState(() => guns[gun]![ammo] = newVal);
        },
      ),
    );
  }

  Widget inputCell(String ammo, Map<String, int> map) {
    return Container(
      width: 110,
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: TextField(
        enabled: !started,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        controller: TextEditingController(text: map[ammo].toString()),
        onChanged: (v) {
          map[ammo] = int.tryParse(v) ?? 0;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Troop ${widget.troop} Dashboard"),
        centerTitle: true,
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 900),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              cell("Gun Platform", bold: true, width: 150),
                              ...ammoTypes.map((a) => cell(a, bold: true)),
                            ],
                          ),
                          Row(
                            children: [
                              cell("Initial", bold: true, width: 150),
                              ...ammoTypes.map((a) => inputCell(a, initial)),
                            ],
                          ),
                          Row(
                            children: [
                              cell("Threshold", bold: true, width: 150),
                              ...ammoTypes.map((a) => inputCell(a, threshold)),
                            ],
                          ),
                          ...gunRows.map(
                            (g) => Row(
                              children: [
                                cell(g, bold: true, width: 150),
                                ...ammoTypes.map((a) => editableCell(g, a)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              height: 60,
              child: ElevatedButton(
                onPressed: started ? null : startPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: started ? Colors.grey : Colors.green.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "START",
                  style: TextStyle(fontSize: 22, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}