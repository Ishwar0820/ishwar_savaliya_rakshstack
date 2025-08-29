// lib/features/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_models.dart';
import 'properties_list_page.dart';
import 'add_edit_pg_page.dart';

import '../../data/auth_repository.dart';
import '../auth/select_role_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmLogout() async {
    const primaryBlue = Color(0xFF537FF4);

    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          title: Row(
            children: const [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: primaryBlue, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      final repo = AuthRepository();
      await repo.clearAdmin();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SelectRolePage()),
            (_) => false,
      );
    }
  }

  Future<void> _addNew() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPgPage()));
  }

  Future<void> _edit(AdminPg pg) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditPgPage(existing: pg)));
  }

  Future<void> _delete(AdminPg pg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete PG?'),
        content: Text('This will permanently delete “${pg.name}”.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await FirebaseFirestore.instance.collection('pgs').doc(pg.id).delete();
        _toast('PG deleted');
      } catch (e) {
        _toast('Delete failed: $e');
      }
    }
  }

  Future<void> _toggleHide(AdminPg pg) async {
    try {
      await FirebaseFirestore.instance
          .collection('pgs')
          .doc(pg.id)
          .set({'hidden': !pg.hidden, 'isActive': pg.hidden}, SetOptions(merge: true));
    } catch (e) {
      _toast('Update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pgs')
            .orderBy('name')
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data?.docs
              .map((d) => AdminPg.fromDoc(d))
              .toList() ??
              const <AdminPg>[];

          return PropertiesListPage(
            items: items,
            onAddNew: _addNew,
            onEdit: _edit,
            onDelete: _delete,
            onToggleHide: _toggleHide,
          );
        },
      ),
      const _SettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_work_outlined), label: 'Properties'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: const [
        ListTile(
          leading: Icon(Icons.security),
          title: Text('Roles & Permissions'),
          subtitle: Text('(Phase 2) Configure users and access'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.tune),
          title: Text('General Settings'),
          subtitle: Text('Coming Soon...'),
        ),
      ],
    );
  }
}
