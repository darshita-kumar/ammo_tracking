import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';
import 'dart:io';
import 'download_util.dart';
import 'package:excel/excel.dart' as xl;

class ShootSummaryScreen extends StatefulWidget {
  final String shootingId;
  final Future<void> Function() onLogout;

  const ShootSummaryScreen({
      super.key, 
      required this.shootingId,
      required this.onLogout,
    });

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
  String _shootingName = '';

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
      final results = await Future.wait([
      FirebaseFirestore.instance
          .collection('shootings')
          .doc(widget.shootingId)
          .get(),
      FirebaseFirestore.instance
          .collection('shootings')
          .doc(widget.shootingId)
          .collection('events')
          .orderBy('timestamp')
          .get(),
      ]);

    final shootingDoc = results[0] as DocumentSnapshot;
    final snapshot = results[1] as QuerySnapshot;

    // Extract shoot name
    _shootingName = (shootingDoc.data() 
        as Map<String, dynamic>?)?['name'] ?? 'Unknown Shoot';

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
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

    // ── Shoot name header ──────────────────────────────────────
    sheet
        .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = xl.TextCellValue('Shoot: $_shootingName');

    // ── Summary table (starts at row 2) ───────────────────────
    final headers = ['Gun Platform', ...ammoTypes];
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2))
          .value = xl.TextCellValue(headers[i]);
    }

    for (int r = 0; r < gunRows.length; r++) {
      final gun = gunRows[r];
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 3))
          .value = xl.TextCellValue(gun);

      for (int c = 0; c < ammoTypes.length; c++) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: r + 3))
            .value = xl.IntCellValue(guns[gun]![ammoTypes[c]]!);
      }
    }

    // ── Timings section ────────────────────────────────────────
    int currentRow = gunRows.length + 5;

    for (final gun in gunRows) {
      final events = gunEvents[gun]!;

      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = xl.TextCellValue('$gun — Firing Timings');
      currentRow++;

      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = xl.TextCellValue('#');
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = xl.TextCellValue('Time');
      sheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
          .value = xl.TextCellValue('Ammunition');
      currentRow++;

      if (events.isEmpty) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
            .value = xl.TextCellValue('No rounds fired.');
        currentRow += 2;
      } else {
        for (int i = 0; i < events.length; i++) {
          final event = events[i];
          sheet
              .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
              .value = xl.IntCellValue(i + 1);
          sheet
              .cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
              .value = xl.TextCellValue(_formatTime(event['timestamp']));
          sheet
              .cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
              .value = xl.TextCellValue(event['ammo']);
          currentRow++;
        }
        currentRow++;
      }
    }

    // ── Save to Downloads folder ───────────────────────────────
    await saveExcelToDownloads(
      context: context,
      excel: excel,
      fileName: '${_shootingName.replaceAll(' ', '_')}_${widget.shootingId}.xlsx',
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
        title: Column(
        children: [
          const Text('Shoot Summary'),
          if (_shootingName.isNotEmpty)
            Text(
              _shootingName,
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
            onPressed: _loading ? null : _exportToExcel,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async => await widget.onLogout(),
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