import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TroopLeaderDashboard extends StatefulWidget {

  final String position;
  final String troop;

  const TroopLeaderDashboard({
    super.key,
    required this.position,
    required this.troop,
  });

  @override
  State<TroopLeaderDashboard> createState() => _TroopLeaderDashboardState();
}

class _TroopLeaderDashboardState extends State<TroopLeaderDashboard> {

  Timestamp? sessionStart;
  StreamSubscription? eventSubscription;

  final ammoTypes = [
    "HE Plugged",
    "HE 117",
    "AB",
    "IPP",
    "SMK",
    "SUPERCART",
    "CART"
  ];

  final gunRows = ["Gun1", "Gun2", "Gun3"];

  Map<String,int> initial = {};
  Map<String,int> threshold = {};
  Map<String,Map<String,int>> guns = {};

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
    setState(() {
      started = true;
      sessionStart = Timestamp.now();
      for (var ammo in ammoTypes) {
        for (var gun in gunRows) {
          guns[gun]![ammo] = initial[ammo]!;
        }
      }

    });
    startListeningToEvents();
  }

  bool isThresholdReached(String gun, String ammo) {
    return guns[gun]![ammo]! <= threshold[ammo]!;
  }

  void startListeningToEvents() {
    eventSubscription = FirebaseFirestore.instance
        .collection("events")
        .where("troop", isEqualTo: widget.troop)
        .where("timestamp", isGreaterThan: sessionStart)
        .snapshots()
        .listen((snapshot) {

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          String gun = data["gun"];
          String ammo = data["ammo"];
          setState(() {
            /// 1️⃣ Only update if value > 0
            if (guns[gun]![ammo]! > 0) {
              guns[gun]![ammo] = guns[gun]![ammo]! - 1;
            }
            /// 2️⃣ Update CART logic
            if (ammo != "SUPERCART") {
              if (guns[gun]!["CART"]! > 0) {
                guns[gun]!["CART"] = guns[gun]!["CART"]! - 1;
              }
            } else {
              guns[gun]!["CART"] =
                  guns[gun]!["CART"]! + 1;
            }
          });

        }

      }

    });
  }

  // Dispose the listener
  @override
  void dispose() {
    eventSubscription?.cancel();
    super.dispose();
  }

  //====================== FRONTEND ==============================

  Widget cell(String text,
      {bool bold=false, double width=110, Color? color}) {
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

  Widget inputCell(String ammo, Map<String,int> map) {
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
        controller: TextEditingController(
          text: map[ammo].toString(),
        ),
        onChanged: (v){
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
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      /// HEADER
                      Row(
                        children: [
                          cell("Gun Platform", bold:true, width:150),
                          ...ammoTypes.map((a)=>cell(a,bold:true))
                        ],
                      ),

                      /// INITIAL
                      Row(
                        children: [
                          cell("Initial", bold:true, width:150),
                          ...ammoTypes.map((a)=>inputCell(a, initial))
                        ],
                      ),

                      /// THRESHOLD
                      Row(
                        children: [
                          cell("Threshold", bold:true, width:150),
                          ...ammoTypes.map((a)=>inputCell(a, threshold))
                        ],
                      ),

                      /// GUN ROWS
                      ...gunRows.map((g) => Row(
                        children: [
                          /// Gun name column
                          cell(g, bold:true, width:150),
                          /// Ammo cells
                          ...ammoTypes.map((a) {
                            Color? highlight;
                            if (started && guns[g]![a]! <= threshold[a]!) {
                              highlight = Colors.red.shade200;
                            }
                            return cell(
                              guns[g]![a].toString(),
                              color: highlight,
                            );
                          })
                        ],
                      ))

                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: 220,
              height: 60,
              child: ElevatedButton(
                onPressed: startPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "START",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                  ),
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