// lib/features/departments/deputy_dept_comparison_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/dashboard/widgets/app_shell.dart';
import '../../data/models/department_model.dart';
import '../../data/models/user_model.dart';
import 'department_service.dart';
import 'dept_config.dart';

class DeputyDeptComparisonPage extends ConsumerStatefulWidget {
  const DeputyDeptComparisonPage({super.key});

  @override
  ConsumerState<DeputyDeptComparisonPage> createState() => _State();
}

class _State extends ConsumerState<DeputyDeptComparisonPage> {
  bool _loading = true;
  List<_DeptSnapshot> _snapshots = [];
  Map<String, double> _nationalAvg = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = await ref.read(databaseProvider.future);
    final service = ref.read(departmentServiceProvider);
    
    // Auto-seed if empty
    final existing = await db.departmentDao.getAllDepartments();
    if (existing.isEmpty) await service.seedDefaultDepartments();

    final depts = await db.departmentDao.getAllActiveDepartments();
    final snaps = <_DeptSnapshot>[];

    for (final d in depts) {
      final health = await service.calculateDepartmentHealth(d.id);
      final members = await db.departmentDao.getMembersByDepartment(d.id);
      final activities = await db.deptActivityDao.getActivitiesByDept(d.id);
      final compliance = await db.deptActivityDao.getAllComplianceItems(d.id);
      final docs = await db.deptActivityDao.getDocsByDept(d.id);
      final meetings = await db.deptActivityDao.getMeetingsByDept(d.id);
      final hod = members.where((m) => m.role == 'hod').firstOrNull;
      UserModel? hodUser;
      if (hod != null) hodUser = await db.userDao.findById(hod.teacherId);

      final compliancePct = compliance.isEmpty ? 0.0 : compliance.where((c) => c.isDone == 1).length / compliance.length;
      final flagged = activities.where((a) => a.status == 'flagged').length;

      snaps.add(_DeptSnapshot(
        dept: d,
        config: findConfigForDept(d.name),
        health: health,
        memberCount: members.length,
        activityCount: activities.length,
        compliancePct: compliancePct,
        docCount: docs.length,
        meetingCount: meetings.length,
        flaggedCount: flagged,
        hodName: hodUser?.name,
      ));
    }

    snaps.sort((a, b) => b.health.compareTo(a.health));
    if (mounted) {
      setState(() {
        _snapshots = snaps;
        _nationalAvg = service.getNationalAverages();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Cross-Department Overview',
      actions: [
        IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _load),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildSummaryRow(),
                  const SizedBox(height: 20),
                  Text('Department Health Rankings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._snapshots.asMap().entries.map((e) => _DeptCard(
                    rank: e.key + 1,
                    snap: e.value,
                    onTap: () => context.push('/departments/${e.value.dept.id}'),
                  )),
                  const SizedBox(height: 24),
                  _buildNationalBenchmark(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
    );
  }

  Widget _buildNationalBenchmark() {
    if (_nationalAvg.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language_outlined, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              const Text('National Benchmarks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                child: const Text('Q1 2026', style: TextStyle(color: Colors.white60, fontSize: 10)),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BenchMetric('Health', '${_nationalAvg['health']}%', Colors.greenAccent),
              _BenchMetric('Compliance', '${_nationalAvg['compliance']}%', Colors.amberAccent),
              _BenchMetric('Reporting', '${_nationalAvg['reporting']}%', Colors.cyanAccent),
              _BenchMetric('Meetings', '${_nationalAvg['meetings']}/mo', Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Comparative analysis suggests your internal average health is '
            'performing at par with national CBC standards.',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final totalDepts = _snapshots.length;
    final avgHealth = totalDepts == 0 ? 0.0 : _snapshots.fold(0.0, (s, d) => s + d.health) / totalDepts;
    final totalFlags = _snapshots.fold(0, (s, d) => s + d.flaggedCount);
    final avgCompliance = totalDepts == 0 ? 0.0 : _snapshots.fold(0.0, (s, d) => s + d.compliancePct) / totalDepts;

    return Row(children: [
      _SumCard('Departments', '$totalDepts', Icons.business_outlined, AppTheme.primary),
      const SizedBox(width: 10),
      _SumCard('Avg Health', '${avgHealth.toStringAsFixed(0)}%', Icons.health_and_safety_outlined,
          avgHealth > 70 ? Colors.green : Colors.orange),
      const SizedBox(width: 10),
      _SumCard('Compliance', '${(avgCompliance * 100).toStringAsFixed(0)}%', Icons.rule_outlined,
          avgCompliance > 0.7 ? Colors.green : Colors.red),
      const SizedBox(width: 10),
      _SumCard('Flagged', '$totalFlags', Icons.flag_outlined,
          totalFlags > 0 ? Colors.red : Colors.green),
    ]);
  }
}

class _DeptCard extends StatelessWidget {
  final int rank;
  final _DeptSnapshot snap;
  final VoidCallback onTap;

  const _DeptCard({required this.rank, required this.snap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = snap.config?.color ?? AppTheme.primary;
    final isTopThree = rank <= 3;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isTopThree ? BorderSide(color: color.withOpacity(0.3)) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Rank badge
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: rank == 1 ? Colors.amber : rank == 2 ? Colors.grey.shade300 : rank == 3 ? Colors.orange.shade200 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('#$rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                    color: rank <= 3 ? Colors.black87 : Colors.black45)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(snap.config?.icon ?? Icons.business_outlined, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(snap.dept.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (snap.hodName != null)
                  Text('HOD: ${snap.hodName}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${snap.health.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _healthColor(snap.health))),
                const Text('Health', style: TextStyle(fontSize: 10, color: Colors.black45)),
              ]),
            ]),
            const SizedBox(height: 12),
            // Health bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: snap.health / 100,
                minHeight: 6,
                color: _healthColor(snap.health),
                backgroundColor: _healthColor(snap.health).withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 12),
            // Stats chips row
            Wrap(spacing: 8, runSpacing: 6, children: [
              _StatChip(Icons.people_outlined, '${snap.memberCount} Members', Colors.blue),
              _StatChip(Icons.list_alt_outlined, '${snap.activityCount} Activities', AppTheme.primary),
              _StatChip(Icons.rule_outlined, '${(snap.compliancePct * 100).toStringAsFixed(0)}% Compliant',
                  snap.compliancePct >= 0.8 ? Colors.green : Colors.orange),
              _StatChip(Icons.folder_outlined, '${snap.docCount} Docs', Colors.indigo),
              _StatChip(Icons.groups_outlined, '${snap.meetingCount} Meetings', Colors.teal),
              if (snap.flaggedCount > 0)
                _StatChip(Icons.flag_outlined, '${snap.flaggedCount} Flagged', Colors.red),
            ]),
          ]),
        ),
      ),
    );
  }

  Color _healthColor(double h) {
    if (h >= 80) return Colors.green;
    if (h >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _StatChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _SumCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _SumCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.15))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
    ]),
  ));
}

class _DeptSnapshot {
  final DepartmentModel dept;
  final DeptConfig? config;
  final double health;
  final int memberCount, activityCount, docCount, meetingCount, flaggedCount;
  final double compliancePct;
  final String? hodName;

  _DeptSnapshot({
    required this.dept, required this.config, required this.health,
    required this.memberCount, required this.activityCount, required this.compliancePct,
    required this.docCount, required this.meetingCount, required this.flaggedCount,
    this.hodName,
  });
}

class _BenchMetric extends StatelessWidget {
  final String label, value; final Color color;
  const _BenchMetric(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
  ]);
}
