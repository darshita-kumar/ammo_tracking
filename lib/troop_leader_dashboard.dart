import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';
import 'constants.dart';
import 'good_shooting_screen.dart';

class TroopLeaderDashboard extends StatefulWidget {
  final String position;
  final String troop;
  final String shootingId;
  final String shootingName;
  final Future<void> Function() onLogout;

  const TroopLeaderDashboard({
    super.key,
    required this.position,
    required this.troop,
    required this.shootingId,
    required this.shootingName,
    required this.onLogout,
  });

  @override
  State<TroopLeaderDashboard> createState() => _TroopLeaderDashboardState();
}

class _TroopLeaderDashboardState extends State<TroopLeaderDashboard> {
  // ── WebSocket for shoot status ──────────────────────────────
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _navigated = false; // prevent double navigation
  bool _polling = false;

  // ── Polling for ammo events ─────────────────────────────────
  Timer? _pollTimer;
  final Set<String> _processedEventIds = {};

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

  Map<String, int> initial   = {};
  Map<String, int> threshold = {};
  Map<String, Map<String, int>> guns = {};
  Set<String> flashingCells = {};
  bool started  = false;
  bool _ending  = false;

  @override
  void initState() {
    super.initState();
    for (var a in ammoTypes) {
      initial[a]   = 0;
      threshold[a] = 0;
    }
    for (var g in gunRows) {
      guns[g] = {};
      for (var a in ammoTypes) {
        guns[g]![a] = 0;
      }
    }
    _connectWebSocket();
  }

  // ── WebSocket ───────────────────────────────────────────────
  Future<void> _connectWebSocket() async {
    // Don't reconnect if already navigated away
    if (_navigated || !mounted) return;

    try {
      _wsChannel = await ApiService.connectToShoot(widget.shootingId);
      _wsSubscription = _wsChannel!.stream.listen(
        (message) {
          final data = jsonDecode(message as String);
          if (data['status'] == 'ended' && mounted) {
            _navigated = true;
            _navigateToGoodShooting();
          }
        },
        onError: (e) {
          debugPrint('WebSocket error: $e — reconnecting...');
          _reconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed — reconnecting...');
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket failed: $e — reconnecting...');
      _reconnect();
    }
  }

  void _reconnect() {
    if (_navigated || !mounted) return;
    // Wait 2 seconds then reconnect
    Future.delayed(const Duration(seconds: 2), () {
      if (!_navigated && mounted) _connectWebSocket();
    });
  }

  // ── End shooting ────────────────────────────────────────────
  Future<void> _endShooting() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Shooting?'),
        content: const Text(
            'This will end the session for all gun positions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade300),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Shooting',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _ending = true);
    try {
      await ApiService.patch(
        '/api/shootings/${widget.shootingId}/status',
        {'status': 'ended'},
      );
      // WebSocket broadcast from server will trigger _navigateToGoodShooting
    } on TimeoutException {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Request timed out. Check server connection and try again.'
        )),
      );
    }
  } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error ending session: $e')));
      }
    } finally {
      if (mounted) setState(() => _ending = false);
    }
  }

  void _navigateToGoodShooting() {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    _pollTimer?.cancel();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => GoodShootingScreen(
          onLogout:     widget.onLogout,
          isTroopLeader: true,
          shootingId:   widget.shootingId,
        ),
      ),
      (route) => false,
    );
  }

  // ── Start shooting + event polling ──────────────────────────
  void startPressed() {
    setState(() {
      started = true;
      _processedEventIds.clear();
      for (var ammo in ammoTypes) {
        for (var gun in gunRows) {
          guns[gun]![ammo] = initial[ammo]!;
        }
      }
    });

    // Mark all existing events as already seen before polling starts
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      try {
        final List<dynamic> existing = await ApiService.get(
          '/api/shootings/${widget.shootingId}/events',
        );
        for (final e in existing) {
          _processedEventIds.add(e['id'] as String);
        }
      } catch (_) {}
      if (mounted) _startPolling();
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchNewEvents();
    });
  }

  // In _fetchNewEvents(), batch all events then setState once:
  Future<void> _fetchNewEvents() async {
    if (_polling) return;
    _polling = true;
    try {
      final List<dynamic> events = await ApiService.get(
        '/api/shootings/${widget.shootingId}/events',
      );

      if (!mounted) return;

      // Collect all new events first
      final newEvents = <Map<String, dynamic>>[];
      for (final event in events) {
        final id = event['id'] as String;
        if (_processedEventIds.contains(id)) continue;
        _processedEventIds.add(id);
        newEvents.add(event);
      }

      // Apply all at once in a single setState
      if (newEvents.isNotEmpty) {
        setState(() {
          for (final event in newEvents) {
            _applyEventNoSetState(
              event['gun']  as String,
              event['ammo'] as String,
            );
          }
        });
        // Flash cells after setState
        for (final event in newEvents) {
          flashCell(event['gun'] as String, event['ammo'] as String);
          flashCell(event['gun'] as String, Constants.CART);
        }
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    } finally {
      _polling = false;
    }
  }

  // New method — applies event logic without calling setState:
  void _applyEventNoSetState(String gun, String ammo) {
    if (!guns.containsKey(gun)) return;
    if (!guns[gun]!.containsKey(ammo)) return;

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
  }

  void flashCell(String gun, String ammo) {
    final key = '$gun|$ammo';
    setState(() => flashingCells.add(key));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => flashingCells.remove(key));
    });
  }

  @override
  void dispose() {
    _navigated = true;
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // FRONTEND
  // ══════════════════════════════════════════════════════════

  Widget cell(String text,
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

  Widget editableCell(String gun, String ammo) {
    int value      = guns[gun]![ammo]!;
    final isFlashing = flashingCells.contains('$gun|$ammo');

    Color? highlight;
    if (isFlashing) {
      highlight = Colors.yellow.shade200;
    } else if (started && value <= threshold[ammo]!) {
      highlight = Colors.red.shade200;
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
        title: Column(
          children: [
            Text("Troop ${widget.troop} Dashboard"),
            Text(widget.shootingName,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async => await widget.onLogout(),
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

            // ── START + END SHOOTING buttons ────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: started ? null : startPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          started ? Colors.grey : Colors.green.shade300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('START',
                        style: TextStyle(
                            fontSize: 22, color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 180,
                  height: 60,
                  child: ElevatedButton(
                    onPressed:
                        (!started || _ending) ? null : _endShooting,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (!started || _ending)
                          ? Colors.grey
                          : Colors.red.shade300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _ending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : const Text('END SHOOTING',
                            style: TextStyle(
                                fontSize: 16, color: Colors.black)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}