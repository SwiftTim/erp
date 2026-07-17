// lib/features/security/visitor_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/security_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'package:intl/intl.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

class VisitorDashboardPage extends ConsumerStatefulWidget {
  const VisitorDashboardPage({super.key});

  @override
  ConsumerState<VisitorDashboardPage> createState() => _VisitorDashboardPageState();
}

class _VisitorDashboardPageState extends ConsumerState<VisitorDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VisitorLogModel> _activeVisitors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final active = await db.securityDao.findActiveVisitors();
    if (mounted) {
      setState(() {
        _activeVisitors = active;
        _loading = false;
      });
    }
  }

  Future<void> _checkOut(String id) async {
    final db = await ref.read(databaseProvider.future);
    await db.securityDao.checkOut(id, DateTime.now().millisecondsSinceEpoch);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitor checked out')));
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Security Desk — Gate 1',
      actions: [
        TextButton.icon(
          onPressed: () {
            PrintableDocumentHub.show(
              context,
              'Security & Gate',
              DocumentTemplates.getTemplatesForModule('security'),
            );
          },
          icon: const Icon(Icons.print_outlined, size: 18, color: Colors.blue),
          label: const Text('Forms / Slips', style: TextStyle(color: Colors.blue)),
        ),
      ],
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Visitor Log', icon: Icon(Icons.badge_outlined)),
              Tab(text: 'Student Pickup', icon: Icon(Icons.child_care)),
            ],
            labelColor: AppTheme.primary,
          ),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVisitorTab(),
                    _buildPickupTab(),
                  ],
                ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton.extended(
        onPressed: _showCheckInDialog,
        label: const Text('Visitor In'),
        icon: const Icon(Icons.person_add_outlined),
      ) : null,
    );
  }

  Widget _buildVisitorTab() {
    if (_activeVisitors.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeVisitors.length,
      itemBuilder: (context, i) {
        final v = _activeVisitors[i];
        final time = DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(v.checkInTime));
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(v.visitorName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: ${v.idNumber} • In at: $time\nSeeing: ${v.whomToSee} (${v.purpose})'),
            trailing: FilledButton.tonal(onPressed: () => _checkOut(v.id), child: const Text('Out')),
          ),
        );
      },
    );
  }

  Widget _buildPickupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Authorized Pickup Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Verify parent identity and record student exit.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search Student UPI or Name...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Security Protocol: Standard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 2),
                      Text('Check for authorized pickup card. Verify against system photo.', style: TextStyle(color: Colors.blue.shade800, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCheckInDialog() async {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final purposeController = TextEditingController();
    final whomController = TextEditingController();
    final vehicleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Visitor Check-In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: idController, decoration: const InputDecoration(labelText: 'ID No')),
            TextField(controller: whomController, decoration: const InputDecoration(labelText: 'Visit Whom')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              await db.securityDao.insertLog(VisitorLogModel(
                id: const Uuid().v4(),
                visitorName: nameController.text,
                idNumber: idController.text,
                purpose: 'School Business',
                whomToSee: whomController.text,
                checkInTime: DateTime.now().millisecondsSinceEpoch,
                recordedBy: 'SEC-01',
              ));
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_accounts_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No active visitors in the school.'),
        ],
      ),
    );
  }
}
