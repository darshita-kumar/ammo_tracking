import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'past_shoots_screen.dart';

class AdminDashboard extends StatefulWidget {
  final Future<void> Function() onLogout;
  const AdminDashboard({super.key, required this.onLogout});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role    = 'on_field';
  bool   _creating = false;

  Future<void> _createUser() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      _snack('Username and password are required.');
      return;
    }
    setState(() => _creating = true);
    try {
      await AuthService.createUser(
        username: _userCtrl.text,
        password: _passCtrl.text,
        role: _role,
      );
      _userCtrl.clear();
      _passCtrl.clear();
      _snack('User created successfully.');
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _showEditDialog(String uid, Map<String, dynamic> data) async {
    final userCtrl = TextEditingController(text: data['username']);
    final passCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(
                  labelText: 'Username', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'New password (leave blank to keep)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final newUser = userCtrl.text.trim();
                if (newUser != data['username']) {
                  await AuthService.updateUsername(uid, newUser);
                }
                if (passCtrl.text.isNotEmpty) {
                  await AuthService.updatePassword(uid, passCtrl.text);
                }
                _snack('User updated.');
              } catch (e) {
                _snack('$e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String uid, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Remove "$username"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.deleteUser(uid);
      _snack('"$username" removed.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await widget.onLogout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('View Past Shoot Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade200,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PastShootsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Create user form ──────────────────────────
            const Text('Create User',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _role,
                    decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'on_field',
                          child: Text('On-field')),
                      DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin')),
                    ],
                    onChanged: (v) => setState(() => _role = v!),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _creating ? null : _createUser,
                  icon: _creating
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 12),

            // ── User list ─────────────────────────────────
            const Text('Existing Users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: AuthService.usersStream(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No users yet.'));
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final d   = docs[i].data() as Map<String, dynamic>;
                      final uid = docs[i].id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: d['role'] == 'admin'
                              ? Colors.orange.shade200
                              : Colors.blue.shade200,
                          child: Icon(
                            d['role'] == 'admin'
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            size: 18,
                          ),
                        ),
                        title: Text(d['username'] ?? ''),
                        subtitle: Text(d['role'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit',
                              onPressed: () => _showEditDialog(uid, d),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () => _confirmDelete(
                                  uid, d['username'] ?? uid),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}