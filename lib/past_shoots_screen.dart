import 'package:flutter/material.dart';
import 'api_service.dart';
import 'combined_shoot_summary_screen.dart';

class PastShootsScreen extends StatefulWidget {
  final Future<void> Function() onLogout;
  const PastShootsScreen({super.key,required this.onLogout,});

  @override
  State<PastShootsScreen> createState() => _PastShootsScreenState();
}

class _PastShootsScreenState extends State<PastShootsScreen> {
  DateTime? _selectedDate;
  bool _loading = false;
  String? _error;

  // Grouped by shoot name → list of shoots with that name
  Map<String, List<Map<String, dynamic>>> _shootsByName = {};

  // Currently selected shoot name in dropdown
  String? _selectedName;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _shootsByName = {};
      _selectedName = null;
      _loading = true;
      _error = null;
    });

    await _fetchShootsForDate(picked);
  }

  Future<void> _fetchShootsForDate(DateTime date) async {
    try {
      final dateFrom = '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      final dateTo = dateFrom; // same day

      final List<dynamic> result = await ApiService.get(
        '/api/shootings?status=ended&date_from=$dateFrom&date_to=$dateTo',
      );

      // Group by shoot name
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final shoot in result) {
        final data = shoot as Map<String, dynamic>;
        final name = data['name'] as String? ?? 'Unknown';
        grouped.putIfAbsent(name, () => []).add(data);
      }

      setState(() {
        _shootsByName = grouped;
        _loading      = false;
      });
    } catch (e) {
      setState(() {
        _error   = 'Failed to fetch shoots: $e';
        _loading = false;
      });
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Shoots'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async => await widget.onLogout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Date picker ────────────────────────────────
            Row(
              children: [
                const Text('Select Date:',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade200,
                  ),
                  label: Text(
                    _selectedDate == null
                        ? 'Pick a date'
                        : _formatDate(_selectedDate!),
                  ),
                  onPressed: _pickDate,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Shoot dropdown ─────────────────────────────
            if (_loading)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_selectedDate != null && _shootsByName.isEmpty)
              const Text('No ended shoots found for this date.',
                  style: TextStyle(color: Colors.grey))
            else if (_shootsByName.isNotEmpty) ...[
              const Text('Select Shoot:',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedName,
                hint: const Text('Select a shoot'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _shootsByName.keys.map((name) {
                  return DropdownMenuItem(
                    value: name,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedName = value),
              ),
              const SizedBox(height: 24),
              if (_selectedName != null)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CombinedShootSummaryScreen(
                            shootName: _selectedName!,
                            shoots: _shootsByName[_selectedName!]!,
                            onLogout: widget.onLogout, 
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('View Summary',
                        style: TextStyle(
                            fontSize: 16, color: Colors.black)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}