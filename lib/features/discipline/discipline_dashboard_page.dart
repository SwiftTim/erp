// lib/features/discipline/discipline_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/discipline_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'package:intl/intl.dart';
import 'widgets/log_incident_dialog.dart';

class DisciplineDashboardPage extends ConsumerStatefulWidget {
  const DisciplineDashboardPage({super.key});

  @override
  ConsumerState<DisciplineDashboardPage> createState() => _DisciplineDashboardPageState();
}

class _DisciplineDashboardPageState extends ConsumerState<DisciplineDashboardPage> {
  List<DisciplineRecordModel> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final db = await ref.read(databaseProvider.future);
    final records = await db.disciplineDao.findAll();
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  Future<void> _showLogIncidentDialog() async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => const LogIncidentDialog(),
    );
    if (success == true) {
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Discipline & Conduct',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogIncidentDialog,
        label: const Text('Log Incident'),
        icon: const Icon(Icons.gavel_outlined),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadRecords,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _records.length,
              itemBuilder: (context, i) {
                final r = _records[i];
                final date = DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(r.timestamp));
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: _getCategoryIcon(r.category),
                    title: Text(r.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: ${r.studentId.substring(0,8)} • $date'),
                    trailing: _getStatusChip(r.status),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Incident Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(r.incidentDescription),
                            const Divider(height: 24),
                            const Text('Action Taken', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(r.actionTaken),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;
    switch (category.toLowerCase()) {
      case 'lateness': icon = Icons.timer_outlined; color = Colors.orange; break;
      case 'bullying': icon = Icons.security_outlined; color = Colors.red; break;
      case 'disruption': icon = Icons.volume_up_outlined; color = Colors.amber; break;
      default: icon = Icons.info_outline; color = Colors.blue;
    }
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _getStatusChip(String status) {
    Color color = status == 'Resolved' ? Colors.green : (status == 'Escalated' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
