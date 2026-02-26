// lib/features/health/health_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/medical_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'package:intl/intl.dart';
import 'widgets/log_visit_dialog.dart';

class HealthDashboardPage extends ConsumerStatefulWidget {
  const HealthDashboardPage({super.key});

  @override
  ConsumerState<HealthDashboardPage> createState() => _HealthDashboardPageState();
}

class _HealthDashboardPageState extends ConsumerState<HealthDashboardPage> {
  bool _loading = true;
  List<ClinicVisitModel> _recentVisits = [];
  int _todayVisits = 0;
  int _alertCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }


  Future<void> _loadVisits() async {
    final db = await ref.read(databaseProvider.future);
    final visits = await db.medicalDao.findRecentVisits();
    
    // Calculate today's visits
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final todayVisits = visits.where((v) => v.timestamp >= todayStart).length;

    // Load alerts (students with chronic conditions or allergies)
    final students = await db.studentDao.findAll();
    int alerts = 0;
    for (final s in students) {
      final med = await db.medicalDao.findForStudent(s.id);
      if (med != null && (med.allergies != null || med.chronicConditions != null)) {
        alerts++;
      }
    }

    if (mounted) {
      setState(() {
        _recentVisits = visits;
        _todayVisits = todayVisits;
        _alertCount = alerts;
        _loading = false;
      });
    }
  }

  Future<void> _showLogVisitDialog() async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => const LogVisitDialog(),
    );
    if (success == true) {
      _loadVisits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'School Clinic Management',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogVisitDialog,
        label: const Text('Log Visit'),
        icon: const Icon(Icons.add_moderator_outlined),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadVisits,
            child: CustomScrollView(
              slivers: [
                _buildStatsGrid(),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('Recent Clinic Visits', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                _buildVisitsList(),
              ],
            ),
          ),
    );
  }

  Widget _buildStatsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard('Today\'s Visits', '$_todayVisits', Icons.medical_services_outlined, Colors.blue),
          _buildStatCard('Medical Alerts', '$_alertCount', Icons.warning_amber_rounded, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitsList() {
    if (_recentVisits.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text('No recent visits recorded.'),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final v = _recentVisits[i];
          final date = DateFormat('MMM d, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(v.timestamp));

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(v.symptoms, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${v.actionTaken} • $date'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: View Student Profile
              },
            ),
          );
        },
        childCount: _recentVisits.length,
      ),
    );
  }
}
