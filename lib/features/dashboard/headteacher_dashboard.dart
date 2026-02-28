// lib/features/dashboard/headteacher_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_provider.dart';
import 'widgets/app_shell.dart';
import 'widgets/stat_card.dart';
import '../../data/models/timetable_models.dart';
import '../../data/models/curriculum_models.dart';

class HeadteacherDashboard extends ConsumerWidget {
  const HeadteacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dbAsync = ref.watch(databaseProvider);
    final isDesktop = MediaQuery.sizeOf(context).width > 900;

    return AppShell(
      title: 'School Hub',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Card ───────────────────────────────────────────────
            _buildWelcomeCard(context, user),
            const SizedBox(height: 32),

            // ── Vital stats ────────────────────────────────────────────────
            Text('School-wide Vitality', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            dbAsync.when(
              data: (db) => _buildKpiGrid(db, isDesktop),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),

            // ── Quick Navigation ───────────────────────────────────────────
            Text('Administrative Links', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 32),

            // ── Recent System Flags ────────────────────────────────────────
            _buildAlerts(context),
            const SizedBox(height: 32),

            // ── Strategic Oversight (Deputy/Principal Feature) ──────────────
            if ((user?.roleLevel ?? 99) <= AppConstants.roleDeputy) ...[
              _StrategicOversight(dbAsync: dbAsync),
              const SizedBox(height: 32),
            ],

            // ── Timetable Oversight (Deputy Feature) ────────────────────────
            if ((user?.roleLevel ?? 99) <= AppConstants.roleDeputy)
              _TimetableOversight(dbAsync: dbAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
              Text(user?.name ?? 'Headteacher', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  _SummaryMiniStat(label: 'Total Pupils', value: '42'), // TODO: Real count
                  const SizedBox(width: 32),
                  _SummaryMiniStat(label: 'Today Absences', value: '0'), // TODO: Real count
                ],
              ),
            ],
          ),
          Positioned(
            right: 0, top: 0,
            child: Icon(Icons.school_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(dynamic db, bool isDesktop) {
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        FutureBuilder<int?>(
          future: db.studentDao.countAll(),
          builder: (context, s) => StatCard(label: 'Students', value: '${s.data ?? 0}', icon: Icons.people_outline, color: Colors.blue, trend: '+2 this week'),
        ),
        FutureBuilder<int?>(
          future: db.userDao.countAll(),
          builder: (context, s) => StatCard(label: 'Staff Members', value: '${s.data ?? 0}', icon: Icons.badge_outlined, color: Colors.purple),
        ),
        const StatCard(label: 'Fee Status', value: '64%', icon: Icons.pie_chart_outline, color: Colors.orange, trend: 'Normal'),
        const StatCard(label: 'Assessments', value: '18', icon: Icons.history_edu_outlined, color: Colors.teal),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ActionChip(
          avatar: const Icon(Icons.picture_as_pdf_outlined, size: 16),
          label: const Text('Reports'),
          onPressed: () => context.push(Routes.reports),
        ),
        ActionChip(
          avatar: const Icon(Icons.payments_outlined, size: 16),
          label: const Text('School Fees'),
          onPressed: () => context.push(Routes.finance),
        ),
        ActionChip(
          avatar: const Icon(Icons.corporate_fare_outlined, size: 16),
          label: const Text('Departments'),
          onPressed: () => context.push(Routes.departments),
        ),
        ActionChip(
          avatar: const Icon(Icons.settings_outlined, size: 16),
          label: const Text('System Config'),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildAlerts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
          child: const ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('All systems operational', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Local database sync is healthy. No pending flags.'),
          ),
        ),
      ],
    );
  }
}

class _TimetableOversight extends StatefulWidget {
  final AsyncValue<dynamic> dbAsync;
  const _TimetableOversight({required this.dbAsync});

  @override
  State<_TimetableOversight> createState() => _TimetableOversightState();
}

class _TimetableOversightState extends State<_TimetableOversight> {
  String? _selectedClassId;
  List<TimetableSlot> _slots = [];
  TimetableModel? _activeTimetable;
  int _totalSlots = 0;
  bool _loadingSlots = false;
  bool _loadingOverview = true;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  void _loadOverview() async {
    widget.dbAsync.whenData((db) async {
      final tt = await db.timetableDao.getActiveTimetable();
      if (tt != null) {
        final all = await db.timetableDao.getSlotsForTimetable(tt.id);
        if (mounted) {
          setState(() {
            _activeTimetable = tt;
            _totalSlots = all.length;
            _loadingOverview = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingOverview = false);
      }
    });
  }

  void _loadClassTimetable(dynamic db, String classId) async {
    setState(() => _loadingSlots = true);
    final activeTt = await db.timetableDao.getActiveTimetable();
    if (activeTt != null) {
      final slots = await db.timetableDao.getSlotsForClass(activeTt.id, classId);
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    } else {
      setState(() => _loadingSlots = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.dbAsync.when(
      data: (db) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Timetable Oversight', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push(Routes.timetableEngine),
                icon: const Icon(Icons.bolt, size: 14),
                label: const Text('Open Engine', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Active Timetable Status Banner ─────────────────────────────
          if (_loadingOverview)
            const LinearProgressIndicator()
          else if (_activeTimetable == null)
            Card(
              elevation: 0,
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.orange.shade200)),
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                title: const Text('No Active Timetable', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                subtitle: const Text('Go to Timetable Engine → Run Engine to generate one.'),
                trailing: TextButton(
                  onPressed: () => context.push(Routes.timetableEngine),
                  child: const Text('Generate'),
                ),
              ),
            )
          else
            Card(
              elevation: 0,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.green.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active: ${_activeTimetable!.academicYear} — ${_activeTimetable!.term}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          Text('$_totalSlots lesson slots scheduled across all classes', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text('$_totalSlots', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                        const Text('Slots', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // ── Class Inspector ────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  FutureBuilder<List<SchoolClassModel>>(
                    future: db.curriculumDao.findAllClasses(),
                    builder: (context, snapshot) {
                      final classes = snapshot.data ?? [];
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Inspect a Class Timetable',
                          prefixIcon: Icon(Icons.class_outlined),
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedClassId,
                        items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.grade})'))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedClassId = val);
                            _loadClassTimetable(db, val);
                          }
                        },
                      );
                    },
                  ),
                  if (_selectedClassId != null) ...[
                    const SizedBox(height: 20),
                    if (_loadingSlots)
                      const CircularProgressIndicator()
                    else if (_slots.isEmpty)
                      const Text('No slots for this class. Re-run the engine.', style: TextStyle(color: Colors.red, fontSize: 12))
                    else
                       _MiniTimetableGrid(slots: _slots),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MiniTimetableGrid extends StatelessWidget {
  final List<TimetableSlot> slots;
  const _MiniTimetableGrid({required this.slots});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grid_on, color: Colors.grey),
            const SizedBox(height: 8),
            Text('${slots.length} lessons scheduled this week', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Future: Navigate to full class timetable view
              },
              child: const Text('View Full Grid'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrategicOversight extends ConsumerWidget {
  final AsyncValue<dynamic> dbAsync;
  const _StrategicOversight({required this.dbAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Strategic Departmental Oversight', 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                 _buildDeptComparisonTable(context),
                 const Divider(height: 32),
                 _buildAlertPanel(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeptComparisonTable(BuildContext context) {
    // Mock data for demonstration as per requirements
    final rows = [
      {'dept': 'Mathematics', 'avg': '2.9', 'coverage': '85%', 'load': 'Fair'},
      {'dept': 'Languages', 'avg': '3.1', 'coverage': '92%', 'load': 'High'},
      {'dept': 'Science', 'avg': '2.4', 'coverage': '68%', 'load': 'Optimal'},
      {'dept': 'Humanities', 'avg': '2.8', 'coverage': '75%', 'load': 'Fair'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Department Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            headingRowHeight: 40,
            columns: const [
              DataColumn(label: Text('Department', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Avg Score', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Coverage %', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Load Var', style: TextStyle(fontSize: 12))),
            ],
            rows: rows.map((r) => DataRow(cells: [
              DataCell(Text(r['dept']!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
              DataCell(Text(r['avg']!, style: const TextStyle(fontSize: 12))),
              DataCell(_buildCoverageBadge(r['coverage']!)),
              DataCell(Text(r['load']!, style: const TextStyle(fontSize: 12))),
            ])).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverageBadge(String text) {
    final val = double.tryParse(text.replaceAll('%', '')) ?? 0;
    final color = val >= 90 ? Colors.green : val >= 75 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAlertPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Critical Governance Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
        const SizedBox(height: 12),
        _AlertItem(
          icon: Icons.priority_high,
          label: 'Underperforming Subject',
          details: 'Standard 7 Integrated Science is 15% below school average.',
          color: Colors.red,
        ),
        _AlertItem(
          icon: Icons.person_off_outlined,
          label: 'Assmt Compliance Gap',
          details: '3 teachers in Humanities have 0 recorded strands this month.',
          color: Colors.orange,
        ),
        _AlertItem(
          icon: Icons.balance_outlined,
          label: 'Teacher Load Risk',
          details: 'Teacher Otieno handles 85% of Math Department periods.',
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _AlertItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String details;
  final Color color;

  const _AlertItem({required this.icon, required this.label, required this.details, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                Text(details, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _SummaryMiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      ],
    );
  }
}
