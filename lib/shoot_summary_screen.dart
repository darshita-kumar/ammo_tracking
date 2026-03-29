import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ShootSummaryScreen extends StatefulWidget {
  final String shootingId;

  const ShootSummaryScreen({super.key, required this.shootingId});

  @override
  State<ShootSummaryScreen> createState() => _ShootSummaryScreenState();
}

class _ShootSummaryScreenState extends State<ShootSummaryScreen> {
  bool _loading = true;
  String? _error;

  final ammoTypes = [
    Constants.HE_PLUGGED,
    Constants.HE_117,
    Constants.AB,
    Constants.ILL,
    Constants.SMK,
    Constants.SUPERCART,
    Constants.CART,
  ];

  final gunRows = [Constants.GUN1, Constants.GUN2, Constants.GUN3];

  // guns[gun][ammo] = total count
  Map<String, Map<String, int>> guns = {};
  Map<String, List<Map<String, dynamic>>> gunEvents = {};

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    for (var g in gunRows) {
      guns[g] = {};
      gunEvents[g] = []; // add this
      for (var a in ammoTypes) {
        guns[g]![a] = 0;
      }
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('shootings')
          .doc(widget.shootingId)
          .collection('events')
          .orderBy('timestamp') // add ordering
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final gun       = data['gun']       as String?;
        final ammo      = data['ammo']      as String?;
        final timestamp = data['timestamp'] as Timestamp?;

        if (gun == null || ammo == null) continue;
        if (!guns.containsKey(gun)) continue;
        if (!guns[gun]!.containsKey(ammo)) continue;

        guns[gun]![ammo] = guns[gun]![ammo]! + 1;

        if (ammo != Constants.SUPERCART) {
          guns[gun]![Constants.CART] = guns[gun]![Constants.CART]! + 1;
        } else {
          guns[gun]![Constants.CART] = guns[gun]![Constants.CART]! - 1;
        }

        // Store event for timings section
        if (timestamp != null) {
          gunEvents[gun]!.add({'ammo': ammo, 'timestamp': timestamp});
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load summary: $e';
        _loading = false;
      });
    }
  }

  Future<void> _exportToExcel() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Shoot Summary'];

    final headers = ['Gun Platform', ...ammoTypes];
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = xl.TextCellValue(headers[i]);
    }

    for (int r = 0; r < gunRows.length; r++) {
      final gun = gunRows[r];
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 1))
          .value = xl.TextCellValue(gun);

      for (int c = 0; c < ammoTypes.length; c++) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: r + 1))
            .value = xl.IntCellValue(guns[gun]![ammoTypes[c]]!);
      }
    }

    final bytes = excel.encode()!;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/shoot_summary_${widget.shootingId}.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Shoot Summary',
    );
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate().toLocal();
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    final s  = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _timingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Firing Timings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        ...gunRows.map((gun) {
          final events = gunEvents[gun]!;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gun header — fixed width instead of double.infinity
                Container(
                  width: 400, // fixed width, not double.infinity
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  color: Colors.blueGrey.shade100,
                  child: Text(
                    gun,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No rounds fired.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  SizedBox(
                    width: 400, // constrain the table to a fixed width
                    child: Table(
                      border: TableBorder.all(color: Colors.black45),
                      columnWidths: const {
                        0: FixedColumnWidth(50),
                        1: FixedColumnWidth(120),
                        2: FlexColumnWidth(),
                      },
                      children: [
                        TableRow(
                          decoration:
                              BoxDecoration(color: Colors.grey.shade200),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('#',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Time',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Ammunition',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        ...events.asMap().entries.map((entry) {
                          final i     = entry.key;
                          final event = entry.value;
                          return TableRow(
                            decoration: BoxDecoration(
                              color: i.isEven
                                  ? Colors.white
                                  : Colors.grey.shade50,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('${i + 1}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                    _formatTime(event['timestamp'])),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(event['ammo']),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false, double width = 110, Color? color}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoot Summary'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
            onPressed: _loading ? null : _exportToExcel,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header row
                            Row(
                              children: [
                                _cell('Gun Platform', bold: true, width: 150),
                                ...ammoTypes.map((a) => _cell(a, bold: true)),
                              ],
                            ),
                            // One row per gun
                            ...gunRows.map(
                              (g) => Row(
                                children: [
                                  _cell(g, bold: true, width: 150),
                                  ...ammoTypes.map((a) => _cell(
                                        guns[g]![a].toString(),
                                        color: guns[g]![a]! > 0
                                            ? Colors.amber.shade50
                                            : null,
                                      )),
                                ],
                              ),
                            ),
                            _timingsSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}