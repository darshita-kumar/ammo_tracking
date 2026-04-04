import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as xl;
import 'dart:io';
import 'constants.dart';

class CombinedShootSummaryScreen extends StatefulWidget {
  final String shootName;
  // Each entry has 'id' and 'troop'
  final List<Map<String, dynamic>> shoots;

  const CombinedShootSummaryScreen({
    super.key,
    required this.shootName,
    required this.shoots,
  });

  @override
  State<CombinedShootSummaryScreen> createState() =>
      _CombinedShootSummaryScreenState();
}

class _CombinedShootSummaryScreenState
    extends State<CombinedShootSummaryScreen> {
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

  // troopData[troop][gun][ammo] = count
  Map<String, Map<String, Map<String, int>>> troopData = {};
  // troopEvents[troop][gun] = list of events
  Map<String, Map<String, List<Map<String, dynamic>>>> troopEvents = {};

  @override
  void initState() {
    super.initState();
    _fetchAllSummaries();
  }

  Future<void> _fetchAllSummaries() async {
    try {
      // Sort shoots by troop before fetching
      final sortedShoots = [...widget.shoots]
      ..sort((a, b) => (a['troop'] as String)
          .compareTo(b['troop'] as String));

      // Fetch all shoots in parallel
      await Future.wait(sortedShoots.map((shoot) =>
          _fetchSummaryForShoot(shoot['id'], shoot['troop'] as String)));

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load summary: $e';
        _loading = false;
      });
    }
  }

  Future<void> _fetchSummaryForShoot(String shootingId, String troop) async {
    // Initialise
    troopData[troop] = {};
    troopEvents[troop] = {};
    for (var g in gunRows) {
      troopData[troop]![g] = {};
      troopEvents[troop]![g] = [];
      for (var a in ammoTypes) {
        troopData[troop]![g]![a] = 0;
      }
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('shootings')
        .doc(shootingId)
        .collection('events')
        .orderBy('timestamp')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final gun       = data['gun']       as String?;
      final ammo      = data['ammo']      as String?;
      final timestamp = data['timestamp'] as Timestamp?;

      if (gun == null || ammo == null) continue;
      if (!troopData[troop]!.containsKey(gun)) continue;
      if (!troopData[troop]![gun]!.containsKey(ammo)) continue;

      troopData[troop]![gun]![ammo] =
          troopData[troop]![gun]![ammo]! + 1;

      if (ammo != Constants.SUPERCART) {
        troopData[troop]![gun]![Constants.CART] =
            troopData[troop]![gun]![Constants.CART]! + 1;
      } else {
        troopData[troop]![gun]![Constants.CART] =
            troopData[troop]![gun]![Constants.CART]! - 1;
      }

      if (timestamp != null) {
        troopEvents[troop]![gun]!
            .add({'ammo': ammo, 'timestamp': timestamp});
      }
    }
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate().toLocal();
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    final s  = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _cell(String text,
      {bool bold = false, double width = 110, Color? color}) {
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

  Widget _troopSection(String troop) {
    final guns = troopData[troop]!;
    final events = troopEvents[troop]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Troop header ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Troop: $troop',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // ── Summary table ──────────────────────────────────
        Row(
          children: [
            _cell('Gun Platform', bold: true, width: 150),
            ...ammoTypes.map((a) => _cell(a, bold: true)),
          ],
        ),
        ...gunRows.map((g) => Row(
          children: [
            _cell(g, bold: true, width: 150),
            ...ammoTypes.map((a) => _cell(
                  guns[g]![a].toString(),
                  color: guns[g]![a]! > 0
                      ? Colors.amber.shade50
                      : null,
                )),
          ],
        )),

        // ── Timings ────────────────────────────────────────
        const SizedBox(height: 24),
        const Text('Firing Timings',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...gunRows.map((gun) {
          final gunEventList = events[gun]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 400,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  color: Colors.blueGrey.shade100,
                  child: Text(gun,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ),
                if (gunEventList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No rounds fired.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  SizedBox(
                    width: 400,
                    child: Table(
                      border: TableBorder.all(color: Colors.black45),
                      columnWidths: const {
                        0: FixedColumnWidth(50),
                        1: FixedColumnWidth(120),
                        2: FlexColumnWidth(),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200),
                          children: const [
                            Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('#',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold))),
                            Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Time',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold))),
                            Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Ammunition',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold))),
                          ],
                        ),
                        ...gunEventList.asMap().entries.map((e) {
                          return TableRow(
                            decoration: BoxDecoration(
                              color: e.key.isEven
                                  ? Colors.white
                                  : Colors.grey.shade50,
                            ),
                            children: [
                              Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text('${e.key + 1}')),
                              Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(_formatTime(
                                      e.value['timestamp']))),
                              Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(e.value['ammo'])),
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

        const Divider(thickness: 2),
      ],
    );
  }

  Future<void> _exportToExcel() async {
    final excel = xl.Excel.createExcel();
    final sheet = excel['Shoot Summary'];

    int currentRow = 0;

    // Shoot name header
    sheet
        .cell(xl.CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: currentRow))
        .value = xl.TextCellValue('Shoot: ${widget.shootName}');
    currentRow += 2;

    for (final troop in troopData.keys) {
      // Troop header
      sheet
          .cell(xl.CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: currentRow))
          .value = xl.TextCellValue('Troop: $troop');
      currentRow++;

      // Summary table headers
      final headers = ['Gun Platform', ...ammoTypes];
      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(
                columnIndex: i, rowIndex: currentRow))
            .value = xl.TextCellValue(headers[i]);
      }
      currentRow++;

      // Gun rows
      for (final gun in gunRows) {
        sheet
            .cell(xl.CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: currentRow))
            .value = xl.TextCellValue(gun);
        for (int c = 0; c < ammoTypes.length; c++) {
          sheet
              .cell(xl.CellIndex.indexByColumnRow(
                  columnIndex: c + 1, rowIndex: currentRow))
              .value = xl.IntCellValue(
                  troopData[troop]![gun]![ammoTypes[c]]!);
        }
        currentRow++;
      }
      currentRow++; // blank row

      // Timings
      sheet
          .cell(xl.CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: currentRow))
          .value = xl.TextCellValue('Firing Timings');
      currentRow++;

      for (final gun in gunRows) {
        final events = troopEvents[troop]![gun]!;

        sheet
            .cell(xl.CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: currentRow))
            .value = xl.TextCellValue(gun);
        currentRow++;

        // Timing column headers
        sheet
            .cell(xl.CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: currentRow))
            .value = xl.TextCellValue('#');
        sheet
            .cell(xl.CellIndex.indexByColumnRow(
                columnIndex: 1, rowIndex: currentRow))
            .value = xl.TextCellValue('Time');
        sheet
            .cell(xl.CellIndex.indexByColumnRow(
                columnIndex: 2, rowIndex: currentRow))
            .value = xl.TextCellValue('Ammunition');
        currentRow++;

        if (events.isEmpty) {
          sheet
              .cell(xl.CellIndex.indexByColumnRow(
                  columnIndex: 0, rowIndex: currentRow))
              .value = xl.TextCellValue('No rounds fired.');
          currentRow += 2;
        } else {
          for (int i = 0; i < events.length; i++) {
            sheet
                .cell(xl.CellIndex.indexByColumnRow(
                    columnIndex: 0, rowIndex: currentRow))
                .value = xl.IntCellValue(i + 1);
            sheet
                .cell(xl.CellIndex.indexByColumnRow(
                    columnIndex: 1, rowIndex: currentRow))
                .value = xl.TextCellValue(
                    _formatTime(events[i]['timestamp']));
            sheet
                .cell(xl.CellIndex.indexByColumnRow(
                    columnIndex: 2, rowIndex: currentRow))
                .value = xl.TextCellValue(events[i]['ammo']);
            currentRow++;
          }
          currentRow++;
        }
      }
      currentRow += 2; // extra space between troops
    }

    // ── Save to Downloads folder ───────────────────────────────
    try {
      final bytes = excel.encode()!;
      final fileName =
          '${widget.shootName.replaceAll(' ', '_')}_combined.xlsx';
      final file = File('/storage/emulated/0/Download/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: $fileName'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Shoot Summary'),
            Text(widget.shootName,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Excel',
            onPressed: _loading ? null : _exportToExcel,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red)))
              : SafeArea(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: troopData.keys
                            .map((troop) => _troopSection(troop))
                            .toList(),
                      ),
                    ),
                  ),
                ),
    );
  }
}