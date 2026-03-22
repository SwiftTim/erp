// lib/features/departments/department_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/dashboard/widgets/app_shell.dart';
import '../../data/models/department_model.dart';
import '../../data/models/department_activity_model.dart';
import '../../data/models/user_model.dart';
import 'department_service.dart';
import 'dept_config.dart';
import 'widgets/dept_module_panel.dart';
import 'widgets/dept_upload_button.dart';

class DepartmentDashboardPage extends ConsumerStatefulWidget {
  final String deptId;
  const DepartmentDashboardPage({super.key, required this.deptId});

  @override
  ConsumerState<DepartmentDashboardPage> createState() => _DeptDashboardState();
}

class _DeptDashboardState extends ConsumerState<DepartmentDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  String _error = '';

  DepartmentModel? _dept;
  DeptConfig? _config;
  String _role = 'member';
  List<UserModel> _members = [];
  List<DeptDocument> _docs = [];
  List<DeptMeeting> _meetings = [];
  List<DeptActivity> _activities = [];
  List<DeptCompliance> _compliance = [];
  double _healthScore = 0;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
    Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'Members'),
    Tab(icon: Icon(Icons.bar_chart_outlined, size: 18), text: 'Performance'),
    Tab(icon: Icon(Icons.event_note_outlined, size: 18), text: 'Planning'),
    Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Reports'),
    Tab(icon: Icon(Icons.folder_outlined, size: 18), text: 'Resources'),
    Tab(icon: Icon(Icons.rule_outlined, size: 18), text: 'Compliance'),
    Tab(icon: Icon(Icons.meeting_room_outlined, size: 18), text: 'Meetings'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final db = await ref.read(databaseProvider.future);
      final user = ref.read(currentUserProvider);

      final dept = await db.departmentDao.getDepartmentById(widget.deptId);
      if (dept == null) { setState(() { _error = 'Department not found'; _loading = false; }); return; }

      final memberships = await db.departmentDao.getMembersByDepartment(widget.deptId);
      String myRole = 'member';
      final List<UserModel> memberList = [];
      for (var m in memberships) {
        if (m.teacherId == user?.id) myRole = m.role;
        final u = await db.userDao.findById(m.teacherId);
        if (u != null) memberList.add(u);
      }

      final health = await ref.read(departmentServiceProvider).calculateDepartmentHealth(widget.deptId);
      final docs = await db.deptActivityDao.getDocsByDept(widget.deptId);
      final meetings = await db.deptActivityDao.getMeetingsByDept(widget.deptId);
      final activities = await db.deptActivityDao.getActivitiesByDept(widget.deptId);

      final now = DateTime.now();
      final term = now.month <= 4 ? '1' : now.month <= 8 ? '2' : '3';
      final year = now.year.toString();
      var compliance = await db.deptActivityDao.getComplianceItems(widget.deptId, term, year);

      // Seed compliance checklist if empty
      final config = findConfigForDept(dept.name);
      if (compliance.isEmpty && config != null) {
        for (final item in config.complianceItems) {
          final rec = DeptCompliance(
            departmentId: widget.deptId,
            item: item,
            term: term,
            year: year,
          );
          await db.deptActivityDao.insertCompliance(rec);
        }
        compliance = await db.deptActivityDao.getComplianceItems(widget.deptId, term, year);
      }

      if (mounted) {
        setState(() {
          _dept = dept;
          _config = config;
          _role = myRole;
          _members = memberList;
          _healthScore = health;
          _docs = docs;
          _meetings = meetings;
          _activities = activities;
          _compliance = compliance;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHod = _role == 'hod';
    final config = _config;
    final dept = _dept;

    return AppShell(
      title: dept?.name ?? 'Department',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildError()
              : Column(
                  children: [
                    _buildHeader(dept!, isHod),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _OverviewTab(dept: dept, config: config, role: _role, health: _healthScore, members: _members, activities: _activities),
                          _MembersTab(deptId: widget.deptId, members: _members, role: _role, onRefresh: _load),
                          _PerformanceTab(deptId: widget.deptId, config: config, activities: _activities),
                          _PlanningTab(deptId: widget.deptId, config: config, activities: _activities, isHod: isHod, onAdd: _addActivity, onUpdate: _updateActivity),
                          _ReportsTab(dept: dept, config: config, docs: _docs, isHod: isHod, deptId: widget.deptId, onRefresh: _load),
                          _ResourcesTab(deptId: widget.deptId, docs: _docs, isHod: isHod, userId: ref.read(currentUserProvider)?.id ?? '', onRefresh: _load),
                          _ComplianceTab(deptId: widget.deptId, items: _compliance, isHod: isHod, userId: ref.read(currentUserProvider)?.id ?? '', onRefresh: _load),
                          _MeetingsTab(deptId: widget.deptId, meetings: _meetings, isHod: isHod, userId: ref.read(currentUserProvider)?.id ?? '', onRefresh: _load),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader(DepartmentModel dept, bool isHod) {
    final color = _config?.color ?? AppTheme.primary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Icon(_config?.icon ?? Icons.business_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dept.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_config?.mandate ?? dept.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
              ),
              Column(children: [
                Text('DPI', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                Text(_healthScore.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            _HeaderChip(label: _role.toUpperCase(), icon: isHod ? Icons.star : Icons.person_outline),
            const SizedBox(width: 8),
            _HeaderChip(label: '${_members.length} Members', icon: Icons.group_outlined),
            const SizedBox(width: 8),
            _HeaderChip(label: '${_activities.length} Activities', icon: Icons.list_outlined),
          ]),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _config?.color ?? AppTheme.primary,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        tabs: _tabs,
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
      const SizedBox(height: 12),
      Text(_error, style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 16),
      FilledButton(onPressed: _load, child: const Text('Retry')),
    ]),
  );

  Future<void> _addActivity(DeptActivity a) async {
    final db = await ref.read(databaseProvider.future);
    await db.deptActivityDao.insertActivity(a);
    _load();
  }

  Future<void> _updateActivity(DeptActivity a) async {
    final db = await ref.read(databaseProvider.future);
    await db.deptActivityDao.updateActivity(a);
    _load();
  }
}

class _HeaderChip extends StatelessWidget {
  final String label; final IconData icon;
  const _HeaderChip({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 12),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 – OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final DepartmentModel dept;
  final DeptConfig? config;
  final String role;
  final double health;
  final List<UserModel> members;
  final List<DeptActivity> activities;

  const _OverviewTab({
    required this.dept, required this.config, required this.role,
    required this.health, required this.members, required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final isHod = role == 'hod';
    final color = config?.color ?? AppTheme.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // -- Stats row
        Row(children: [
          _StatTile('Members', '${members.length}', Icons.people_outlined, color),
          const SizedBox(width: 12),
          _StatTile('Activities', '${activities.length}', Icons.list_alt_outlined, Colors.blue),
          const SizedBox(width: 12),
          _StatTile('Health', '${health.toStringAsFixed(0)}%',
              health > 70 ? Icons.thumb_up_outlined : Icons.warning_amber_outlined,
              health > 70 ? Colors.green : Colors.orange),
        ]),
        const SizedBox(height: 20),

        // -- Mandate
        _SectionCard(
          title: 'Core Mandate',
          icon: Icons.flag_outlined,
          color: color,
          child: Text(config?.mandate ?? dept.description,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.6)),
        ),
        const SizedBox(height: 16),

        // -- Subjects served
        if (config != null) ...[
          _SectionCard(
            title: 'Subjects Served',
            icon: Icons.auto_stories_outlined,
            color: color,
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: config!.subjects.map((s) => Chip(
                label: Text(s, style: const TextStyle(fontSize: 11)),
                backgroundColor: color.withOpacity(0.08),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // -- HOD responsibilities
        if (isHod && config != null)
          _SectionCard(
            title: 'Your HOD Responsibilities',
            icon: Icons.star_outlined,
            color: Colors.amber.shade700,
            child: Column(
              children: config!.hodResponsibilities.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r, style: const TextStyle(fontSize: 12))),
                ]),
              )).toList(),
            ),
          )
        else if (config != null)
          _SectionCard(
            title: 'Member Responsibilities',
            icon: Icons.person_outlined,
            color: Colors.blue,
            child: Column(
              children: config!.memberResponsibilities.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  const Icon(Icons.arrow_right_outlined, color: Colors.blue, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(r, style: const TextStyle(fontSize: 12))),
                ]),
              )).toList(),
            ),
          ),

        const SizedBox(height: 16),

        // -- Recent activity
        _SectionCard(
          title: 'Recent Activity',
          icon: Icons.history_outlined,
          color: Colors.grey,
          child: activities.isEmpty
              ? const Text('No activity recorded yet.',
                  style: TextStyle(color: Colors.black45, fontSize: 12))
              : Column(
                  children: activities.take(5).map((a) {
                    final date = DateFormat('MMM d').format(
                        DateTime.fromMillisecondsSinceEpoch(a.recordedAt));
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.circle, size: 8, color: AppTheme.primary),
                      title: Text(a.title, style: const TextStyle(fontSize: 12)),
                      trailing: Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    );
                  }).toList(),
                ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 – MEMBERS
// ─────────────────────────────────────────────────────────────────────────────
class _MembersTab extends ConsumerWidget {
  final String deptId;
  final List<UserModel> members;
  final String role;
  final VoidCallback onRefresh;

  const _MembersTab({required this.deptId, required this.members, required this.role, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHod = role == 'hod';
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isHod ? FloatingActionButton.extended(
        onPressed: () => _showAddMember(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Member'),
      ) : null,
      body: members.isEmpty
          ? const Center(child: Text('No members assigned yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (ctx, i) {
                final m = members[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(m.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ),
                    title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(m.email, style: const TextStyle(fontSize: 11)),
                    trailing: isHod ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                      onPressed: () => _removeMember(context, ref, m),
                    ) : null,
                  ),
                );
              },
            ),
    );
  }

  void _removeMember(BuildContext ctx, WidgetRef ref, UserModel m) async {
    final ok = await showDialog<bool>(context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${m.name} from this department?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(departmentServiceProvider).removeMember(m.id, deptId);
      onRefresh();
    }
  }

  void _showAddMember(BuildContext ctx, WidgetRef ref) async {
    final db = await ref.read(databaseProvider.future);
    final all = await db.userDao.findAll();
    final available = all.where((t) => t.roleLevel <= 5 && !members.any((m) => m.id == t.id)).toList();
    if (!ctx.mounted) return;
    showDialog(
      context: ctx,
      builder: (dlg) => AlertDialog(
        title: const Text('Add Member'),
        content: SizedBox(
          width: 360,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (_, i) => ListTile(
              leading: CircleAvatar(child: Text(available[i].name[0])),
              title: Text(available[i].name),
              subtitle: Text(available[i].email, style: const TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.pop(dlg);
                await ref.read(departmentServiceProvider).addMember(available[i].id, deptId);
                onRefresh();
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 – PERFORMANCE
// ─────────────────────────────────────────────────────────────────────────────
class _PerformanceTab extends StatelessWidget {
  final String deptId;
  final DeptConfig? config;
  final List<DeptActivity> activities;

  const _PerformanceTab({required this.deptId, required this.config, required this.activities});

  @override
  Widget build(BuildContext context) {
    final color = config?.color ?? AppTheme.primary;
    final byModule = <String, int>{};
    for (final a in activities) {
      byModule[a.moduleType] = (byModule[a.moduleType] ?? 0) + 1;
    }
    final byStatus = <String, int>{};
    for (final a in activities) {
      byStatus[a.status] = (byStatus[a.status] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Activity Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _StatusSummaryRow(byStatus: byStatus),
        const SizedBox(height: 20),

        Text('Module Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (byModule.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32),
              child: Text('No data yet. Start logging activities in Planning.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black45))))
        else
          ...byModule.entries.map((e) => _ModuleBar(
            label: e.key.replaceAll('_', ' '),
            count: e.value,
            total: activities.length,
            color: color,
          )),

        const SizedBox(height: 20),

        if (config != null) ...[
          Text('Performance Reports Required', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...config!.reportTypes.map((r) => ListTile(
            dense: true,
            leading: const Icon(Icons.insert_chart_outlined, color: AppTheme.primary, size: 18),
            title: Text(r, style: const TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.chevron_right, size: 16),
          )),
        ],
      ]),
    );
  }
}

class _StatusSummaryRow extends StatelessWidget {
  final Map<String, int> byStatus;
  const _StatusSummaryRow({required this.byStatus});
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Open', byStatus['open'] ?? 0, Colors.blue),
      ('In Progress', byStatus['in_progress'] ?? 0, Colors.orange),
      ('Completed', byStatus['completed'] ?? 0, Colors.green),
      ('Flagged', byStatus['flagged'] ?? 0, Colors.red),
    ];
    return Row(children: items.map((e) => Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: e.$3.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: e.$3.withOpacity(0.2))),
        child: Column(children: [
          Text('${e.$2}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: e.$3)),
          Text(e.$1, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ]),
      ),
    ))).toList());
  }
}

class _ModuleBar extends StatelessWidget {
  final String label; final int count; final int total; final Color color;
  const _ModuleBar({required this.label, required this.count, required this.total, required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 160, child: Text(label, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 10, color: color, backgroundColor: color.withOpacity(0.1)))),
        const SizedBox(width: 8),
        Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 – PLANNING (modules)
// ─────────────────────────────────────────────────────────────────────────────
class _PlanningTab extends StatelessWidget {
  final String deptId;
  final DeptConfig? config;
  final List<DeptActivity> activities;
  final bool isHod;
  final Future<void> Function(DeptActivity) onAdd;
  final Future<void> Function(DeptActivity) onUpdate;

  const _PlanningTab({
    required this.deptId, required this.config, required this.activities,
    required this.isHod, required this.onAdd, required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (config == null) {
      return const Center(child: Text('No modules configured for this department.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: config!.modules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) {
        final mod = config!.modules[i];
        final modActivities = activities.where((a) => a.moduleType == mod.moduleType).toList();
        return DeptModulePanel(
          deptId: deptId,
          config: mod,
          activities: modActivities,
          isHod: isHod,
          onAdd: onAdd,
          onUpdateStatus: onUpdate,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 5 – REPORTS
// ─────────────────────────────────────────────────────────────────────────────
class _ReportsTab extends ConsumerWidget {
  final DepartmentModel dept;
  final DeptConfig? config;
  final List<DeptDocument> docs;
  final bool isHod;
  final String deptId;
  final VoidCallback onRefresh;

  const _ReportsTab({required this.dept, required this.config, required this.docs, required this.isHod, required this.deptId, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportDocs = docs.where((d) => d.category == 'report').toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isHod) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.send_outlined, color: Colors.amber),
                SizedBox(width: 8),
                Text('Submit Report to Deputy', style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              if (config != null)
                Wrap(spacing: 8, runSpacing: 8,
                  children: config!.reportTypes.map((r) => ActionChip(
                    avatar: const Icon(Icons.upload_outlined, size: 14),
                    label: Text(r, style: const TextStyle(fontSize: 11)),
                    onPressed: () => _showReportUpload(context, ref, r),
                  )).toList(),
                ),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        Text('Submitted Reports', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        if (reportDocs.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24),
            child: Text('No reports submitted yet.', style: TextStyle(color: Colors.black45))))
        else
          ...reportDocs.map((d) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1A1565C0),
                child: Icon(Icons.description_outlined, color: AppTheme.primary),
              ),
              title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(DateFormat('MMM d, y').format(DateTime.fromMillisecondsSinceEpoch(d.uploadedAt)),
                  style: const TextStyle(fontSize: 11)),
              trailing: _StatusBadge(status: d.status),
            ),
          )),
      ]),
    );
  }

  void _showReportUpload(BuildContext context, WidgetRef ref, String reportType) {
    String? fileName, filePath;
    final notesCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text('Submit: $reportType', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Summary Notes'), maxLines: 3),
          const SizedBox(height: 12),
          DeptUploadButton(label: 'Upload Report Document', onFilePicked: (name, path) {
            set(() { fileName = name; filePath = path; });
          }),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            Navigator.pop(ctx);
            final user = ref.read(currentUserProvider);
            final db = await ref.read(databaseProvider.future);
            await db.deptActivityDao.insertDocument(DeptDocument(
              id: const Uuid().v4(),
              departmentId: deptId,
              title: reportType,
              category: 'report',
              filePath: filePath,
              fileName: fileName ?? 'report.pdf',
              description: notesCtrl.text,
              uploadedBy: user?.id ?? '',
              uploadedAt: DateTime.now().millisecondsSinceEpoch,
              status: 'pending',
            ));
            onRefresh();
          }, child: const Text('Submit')),
        ],
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 6 – RESOURCES
// ─────────────────────────────────────────────────────────────────────────────
class _ResourcesTab extends ConsumerWidget {
  final String deptId, userId;
  final List<DeptDocument> docs;
  final bool isHod;
  final VoidCallback onRefresh;

  const _ResourcesTab({required this.deptId, required this.docs, required this.isHod, required this.userId, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ['scheme', 'plan', 'moderation', 'minutes', 'safety'];
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context, ref),
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Upload Document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ...categories.map((cat) {
            final catDocs = docs.where((d) => d.category == cat).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_catLabel(cat), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              if (catDocs.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                  child: const Text('No files uploaded', style: TextStyle(color: Colors.black45, fontSize: 12)),
                )
              else
                ...catDocs.map((d) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(dense: true,
                    leading: const Icon(Icons.attach_file, color: AppTheme.primary),
                    title: Text(d.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('${d.fileName} • ${DateFormat('MMM d').format(DateTime.fromMillisecondsSinceEpoch(d.uploadedAt))}', style: const TextStyle(fontSize: 11)),
                    trailing: _StatusBadge(status: d.status),
                  ),
                )),
              const Divider(),
            ]);
          }),
        ]),
      ),
    );
  }

  String _catLabel(String cat) {
    switch (cat) {
      case 'scheme': return '📋 Schemes of Work';
      case 'plan': return '📝 Lesson Plans';
      case 'moderation': return '✅ Moderation Forms';
      case 'minutes': return '📄 Meeting Minutes';
      case 'safety': return '⚠️ Safety Documents';
      default: return cat;
    }
  }

  void _showUploadDialog(BuildContext context, WidgetRef ref) {
    String? fileName, filePath;
    String category = 'scheme';
    final titleCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: const Text('Upload Department Document'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Document Title')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              const DropdownMenuItem(value: 'scheme', child: Text('Scheme of Work')),
              const DropdownMenuItem(value: 'plan', child: Text('Lesson Plan')),
              const DropdownMenuItem(value: 'moderation', child: Text('Moderation Form')),
              const DropdownMenuItem(value: 'minutes', child: Text('Meeting Minutes')),
              const DropdownMenuItem(value: 'safety', child: Text('Safety Document')),
            ],
            onChanged: (v) => set(() => category = v!),
          ),
          const SizedBox(height: 12),
          DeptUploadButton(label: 'Select File', onFilePicked: (name, path) {
            set(() { fileName = name; filePath = path; });
          }),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (titleCtrl.text.isEmpty || fileName == null) return;
            Navigator.pop(ctx);
            final db = await ref.read(databaseProvider.future);
            await db.deptActivityDao.insertDocument(DeptDocument(
              id: const Uuid().v4(),
              departmentId: deptId,
              title: titleCtrl.text,
              category: category,
              filePath: filePath,
              fileName: fileName!,
              uploadedBy: userId,
              uploadedAt: DateTime.now().millisecondsSinceEpoch,
              status: 'pending',
            ));
            onRefresh();
          }, child: const Text('Upload')),
        ],
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 7 – COMPLIANCE
// ─────────────────────────────────────────────────────────────────────────────
class _ComplianceTab extends ConsumerWidget {
  final String deptId, userId;
  final List<DeptCompliance> items;
  final bool isHod;
  final VoidCallback onRefresh;

  const _ComplianceTab({required this.deptId, required this.items, required this.isHod, required this.userId, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = items.where((i) => i.isDone == 1).length;
    final pct = items.isEmpty ? 0.0 : done / items.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              pct >= 0.8 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red,
              (pct >= 0.8 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red).withOpacity(0.7),
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Compliance Score', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              Text('$done of ${items.length} items completed', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            CircularProgressIndicator(value: pct, backgroundColor: Colors.white38, color: Colors.white, strokeWidth: 6),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Checklist', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: item.isDone == 1,
            onChanged: isHod ? (v) => _toggle(context, ref, item, v ?? false) : null,
            title: Text(item.item, style: TextStyle(
              fontSize: 13,
              decoration: item.isDone == 1 ? TextDecoration.lineThrough : null,
              color: item.isDone == 1 ? Colors.black45 : null,
            )),
            subtitle: item.completedBy != null
                ? Text('Marked done • ${DateFormat('MMM d').format(DateTime.fromMillisecondsSinceEpoch(item.completedAt!))}',
                    style: const TextStyle(fontSize: 10, color: Colors.green))
                : null,
            activeColor: Colors.green,
          ),
        )),
        if (!isHod)
          const Padding(padding: EdgeInsets.all(12),
            child: Text('Only the HOD can mark compliance items.', style: TextStyle(color: Colors.black45, fontSize: 12, fontStyle: FontStyle.italic))),
      ]),
    );
  }

  void _toggle(BuildContext ctx, WidgetRef ref, DeptCompliance item, bool done) async {
    final db = await ref.read(databaseProvider.future);
    final updated = item.copyWith(
      isDone: done ? 1 : 0,
      completedBy: done ? userId : null,
      completedAt: done ? DateTime.now().millisecondsSinceEpoch : null,
    );
    await db.deptActivityDao.updateCompliance(updated);
    onRefresh();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 8 – MEETINGS
// ─────────────────────────────────────────────────────────────────────────────
class _MeetingsTab extends ConsumerWidget {
  final String deptId, userId;
  final List<DeptMeeting> meetings;
  final bool isHod;
  final VoidCallback onRefresh;

  const _MeetingsTab({required this.deptId, required this.meetings, required this.isHod, required this.userId, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isHod ? FloatingActionButton.extended(
        onPressed: () => _showScheduleDialog(context, ref),
        icon: const Icon(Icons.add_outlined),
        label: const Text('Schedule Meeting'),
      ) : null,
      body: meetings.isEmpty
          ? const Center(child: Text('No meetings scheduled.', style: TextStyle(color: Colors.black45)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: meetings.length,
              itemBuilder: (ctx, i) {
                final m = meetings[i];
                final date = DateFormat('EEE, MMM d • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(m.scheduledAt));
                final statusColor = m.status == 'completed' ? Colors.green : m.status == 'cancelled' ? Colors.red : Colors.blue;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.1),
                        child: Icon(Icons.groups_outlined, color: statusColor, size: 20)),
                    title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('$date • ${m.venue}', style: const TextStyle(fontSize: 11)),
                    trailing: _StatusBadge(status: m.status),
                    children: [
                      Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Agenda:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(m.agenda, style: const TextStyle(fontSize: 12)),
                        if (m.minutes != null) ...[
                          const SizedBox(height: 8),
                          const Text('Minutes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(m.minutes!, style: const TextStyle(fontSize: 12)),
                        ],
                        if (isHod && m.status == 'scheduled') ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: OutlinedButton(onPressed: () => _addMinutes(context, ref, m), child: const Text('Add Minutes', style: TextStyle(fontSize: 11)))),
                            const SizedBox(width: 8),
                            Expanded(child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () => _cancel(ref, m),
                              child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                            )),
                          ]),
                        ],
                      ])),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showScheduleDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final agendaCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    DateTime? picked;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: const Text('Schedule Department Meeting'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Meeting Title')),
          const SizedBox(height: 8),
          TextField(controller: agendaCtrl, decoration: const InputDecoration(labelText: 'Agenda'), maxLines: 3),
          const SizedBox(height: 8),
          TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Venue')),
          const SizedBox(height: 8),
          ListTile(contentPadding: EdgeInsets.zero,
            title: Text(picked == null ? 'Pick Date & Time' : DateFormat('EEE, MMM d yyyy').format(picked!), style: TextStyle(color: picked == null ? Colors.black45 : null, fontSize: 13)),
            trailing: const Icon(Icons.calendar_today_outlined, size: 18),
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
              if (d != null) set(() => picked = d);
            }),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (titleCtrl.text.isEmpty || picked == null) return;
            Navigator.pop(ctx);
            final db = await ref.read(databaseProvider.future);
            await db.deptActivityDao.insertMeeting(DeptMeeting(
              id: const Uuid().v4(),
              departmentId: deptId,
              title: titleCtrl.text,
              agenda: agendaCtrl.text,
              scheduledAt: picked!.millisecondsSinceEpoch,
              venue: venueCtrl.text.isEmpty ? 'Department Room' : venueCtrl.text,
              organizedBy: userId,
            ));
            onRefresh();
          }, child: const Text('Schedule')),
        ],
      ),
    ));
  }

  void _addMinutes(BuildContext context, WidgetRef ref, DeptMeeting meeting) {
    final ctrl = TextEditingController(text: meeting.minutes);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Record Meeting Minutes'),
      content: TextField(controller: ctrl, maxLines: 8, decoration: const InputDecoration(hintText: 'Enter minutes of the meeting...')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          Navigator.pop(ctx);
          final db = await ref.read(databaseProvider.future);
          await db.deptActivityDao.updateMeeting(DeptMeeting(
            id: meeting.id, departmentId: meeting.departmentId, title: meeting.title,
            agenda: meeting.agenda, scheduledAt: meeting.scheduledAt, venue: meeting.venue,
            minutes: ctrl.text, organizedBy: meeting.organizedBy, status: 'completed',
          ));
          onRefresh();
        }, child: const Text('Save')),
      ],
    ));
  }

  void _cancel(WidgetRef ref, DeptMeeting meeting) async {
    final db = await ref.read(databaseProvider.future);
    await db.deptActivityDao.updateMeeting(DeptMeeting(
      id: meeting.id, departmentId: meeting.departmentId, title: meeting.title,
      agenda: meeting.agenda, scheduledAt: meeting.scheduledAt, venue: meeting.venue,
      minutes: meeting.minutes, organizedBy: meeting.organizedBy, status: 'cancelled',
    ));
    onRefresh();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.15))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
    ]),
  ));
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.color, required this.child});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ]),
      const Divider(height: 20),
      child,
    ])),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }
  Color _color(String s) {
    switch (s.toLowerCase()) {
      case 'approved': case 'completed': return Colors.green;
      case 'pending': case 'scheduled': return Colors.blue;
      case 'rejected': case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }
}
