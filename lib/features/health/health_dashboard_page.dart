// lib/features/health/health_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/medical_model.dart';
import '../../data/models/student_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';
import 'widgets/log_visit_dialog.dart';

class HealthDashboardPage extends ConsumerStatefulWidget {
  const HealthDashboardPage({super.key});

  @override
  ConsumerState<HealthDashboardPage> createState() => _HealthDashboardPageState();
}

class _HealthDashboardPageState extends ConsumerState<HealthDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = true;
  List<ClinicVisitModel> _recentVisits = [];
  List<Map<String, dynamic>> _alertStudents = [];
  int _todayVisits = 0;

  static const _accent = Color(0xFF0D9488); // teal

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final db = await ref.read(databaseProvider.future);
    final visits = await db.medicalDao.findRecentVisits();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final todayCount = visits.where((v) => v.timestamp >= todayStart).length;

    // Build alert list from students with medical conditions
    final students = await db.studentDao.findAll();
    final List<Map<String, dynamic>> alerts = [];
    for (final s in students) {
      final med = await db.medicalDao.findForStudent(s.id);
      if (med != null &&
          ((med.allergies != null && med.allergies!.isNotEmpty) ||
              (med.chronicConditions != null && med.chronicConditions!.isNotEmpty))) {
        alerts.add({
          'student': s,
          'allergies': med.allergies ?? '',
          'conditions': med.chronicConditions ?? '',
        });
      }
    }

    if (mounted) {
      setState(() {
        _recentVisits = visits;
        _todayVisits = todayCount;
        _alertStudents = alerts;
        _loading = false;
      });
    }
  }

  Future<void> _showLogVisitDialog() async {
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => const LogVisitDialog(),
    );
    if (success == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return AppShell(
      title: 'School Clinic',
      actions: [
        TextButton.icon(
          onPressed: () => PrintableDocumentHub.show(
            context,
            'School Health / Sanatorium',
            DocumentTemplates.getTemplatesForModule('nurse'),
          ),
          icon: const Icon(Icons.print_outlined, size: 18, color: _accent),
          label: const Text('Forms', style: TextStyle(color: _accent)),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogVisitDialog,
        label: const Text('Log Visit'),
        icon: const Icon(Icons.add_moderator_outlined),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildWelcomeCard(user),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildTabSection(),
                ]),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          Text(user?.name ?? 'School Nurse',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(children: [
            _miniStat('Today\'s Visits', '$_todayVisits'),
            const SizedBox(width: 32),
            _miniStat('Total Clinic Records', '${_recentVisits.length}'),
            const SizedBox(width: 32),
            _miniStat('Medical Alerts', '${_alertStudents.length}'),
          ]),
        ]),
        Positioned(
          right: 0, top: 0,
          child: Icon(Icons.medical_services_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
        ),
      ]),
    );
  }

  Widget _miniStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
    ],
  );

  Widget _buildStatsGrid() {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5,
      children: [
        _statCard('Today\'s Visits', '$_todayVisits', Icons.today_outlined, _accent),
        _statCard('All Records', '${_recentVisits.length}', Icons.folder_open_outlined, Colors.blue),
        _statCard('Medical Alerts', '${_alertStudents.length}', Icons.warning_amber_outlined, Colors.red),
        _statCard('Clinic Status', 'Open', Icons.local_hospital_outlined, Colors.green),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildTabSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Clinic Records', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Column(children: [
          TabBar(
            controller: _tab,
            labelColor: _accent, indicatorColor: _accent,
            unselectedLabelColor: Colors.grey, dividerColor: Colors.transparent,
            tabs: [
              const Tab(text: 'Visit Logs'),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Medical Alerts'),
                if (_alertStudents.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 8, backgroundColor: Colors.red,
                    child: Text('${_alertStudents.length}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ],
              ])),
            ],
          ),
          SizedBox(
            height: 480,
            child: TabBarView(controller: _tab, children: [
              _buildVisitsTab(),
              _buildAlertsTab(),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildVisitsTab() {
    if (_recentVisits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.medical_services_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No clinic visits recorded yet.', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _recentVisits.length,
      itemBuilder: (_, i) {
        final v = _recentVisits[i];
        final date = DateFormat('dd MMM, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(v.timestamp));
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _accent.withValues(alpha: 0.1),
              child: const Icon(Icons.person_outline, color: _accent, size: 18),
            ),
            title: Text(v.symptoms, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(date),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _detailRow('Action Taken', v.actionTaken),
                  if (v.medicationGiven != null && v.medicationGiven!.isNotEmpty)
                    _detailRow('Medication', v.medicationGiven!),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 110,
          child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _buildAlertsTab() {
    if (_alertStudents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
            SizedBox(height: 12),
            Text('No medical alerts on file.', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _alertStudents.length,
      itemBuilder: (_, i) {
        final entry = _alertStudents[i];
        final student = entry['student'] as StudentModel;
        final allergies = entry['allergies'] as String;
        final conditions = entry['conditions'] as String;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.shade100),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFE4E4),
              child: Icon(Icons.warning_amber_outlined, color: Colors.red, size: 18),
            ),
            title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Grade: ${student.grade}', style: const TextStyle(fontSize: 11)),
              if (allergies.isNotEmpty) Text('Allergies: $allergies', style: const TextStyle(fontSize: 11)),
              if (conditions.isNotEmpty) Text('Conditions: $conditions', style: const TextStyle(fontSize: 11)),
            ]),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
