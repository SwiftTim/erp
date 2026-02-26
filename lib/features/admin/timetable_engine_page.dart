// lib/features/admin/timetable_engine_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cbc_school/core/theme/app_theme.dart';
import 'package:cbc_school/data/models/timetable_models.dart';
import 'package:cbc_school/services/timetable_engine_service.dart';
import 'package:cbc_school/features/dashboard/widgets/app_shell.dart';
import 'package:cbc_school/data/models/user_model.dart';
import 'package:cbc_school/features/auth/auth_provider.dart';
import 'package:cbc_school/services/timetable_bootstrap_service.dart';
import 'package:cbc_school/services/test_data_seeder.service.dart';

class TimetableEnginePage extends ConsumerStatefulWidget {
  const TimetableEnginePage({super.key});

  @override
  ConsumerState<TimetableEnginePage> createState() => _TimetableEnginePageState();
}

class _TimetableEnginePageState extends ConsumerState<TimetableEnginePage> {
  List<TimetableSlot> _entries = [];
  List<UserModel> _teachers = [];
  Map<String, dynamic>? _lastReport;
  bool _loading = false;
  String _selectedClassId = 'ALL';
  String? _simulatedAbsentTeacherId;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final dbFuture = ref.read(databaseProvider.future);
    final db = await dbFuture;
    final activeTimetable = await db.timetableDao.getActiveTimetable();
    final allTeachers = await db.userDao.findAllActive();
    
    if (mounted) {
      setState(() {
        _teachers = allTeachers.where((u) => u.roleLevel <= 5).toList();
      });
    }
    
    if (activeTimetable != null) {
      final slots = await db.timetableDao.getSlotsForTimetable(activeTimetable.id);
      if (mounted) {
        setState(() {
          _entries = slots;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _entries = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _runEngine({bool isSimulation = false}) async {
    setState(() => _loading = true);

    try {
      final engine = ref.read(timetableEngineServiceProvider);
      // Generate with slight randomness
      final result = await engine.generateTimetable(
        academicYear: '2026', 
        term: 'Term 1', 
        daysPerWeek: 5, 
        periodsPerDay: 7,
        absentTeacherId: isSimulation ? _simulatedAbsentTeacherId : null,
      );
      
      if (!mounted) return;

      setState(() {
        _lastReport = result;
        if (isSimulation) {
          _entries = result['slots'] as List<TimetableSlot>? ?? [];
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isSimulation 
            ? 'Simulation Successful: New coverage generated.' 
            : 'Timetable generated successfully without conflicts!'),
        backgroundColor: Colors.green,
      ));
      
      if (!isSimulation) {
        _refresh();
      } else {
        setState(() => _loading = false);
      }
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Generation Failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('OK')
            ),
          ],
        )
      );
    }
  }

  Future<void> _bootstrapData() async {
    setState(() => _loading = true);
    try {
      await ref.read(timetableBootstrapServiceProvider).bootstrapTestData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Test Constraints Seeded! You can now run the Engine.'),
        backgroundColor: Colors.blue,
      ));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bootstrap failed: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _seedFullData() async {
    setState(() => _loading = true);
    try {
      await ref.read(testDataSeederProvider).seedAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Full MoE School Data Injected! 20 Teachers, 11 Classes, 220 Students generated.'),
        backgroundColor: Colors.green,
      ));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Seeding failed: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final classIds = _entries.map((e) => e.classId).toSet().toList()..sort();

    return AppShell(
      title: 'Timetable Engine',
      actions: [
        if (!_loading && _entries.isNotEmpty) // Use _loading as isGenerating lock
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedClassId,
              hint: const Text('View Class...'),
              items: [
                const DropdownMenuItem(value: 'ALL', child: Text('All Classes')),
                ...classIds.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: _loading ? null : (val) {
                if (val != null) setState(() => _selectedClassId = val);
              },
            ),
          )
      ],
      body: _loading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Constraint Satisfaction Engine Running...', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Solving 3D Matrix (Days × Periods × Classes)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ))
          : Column(
              children: [
                if (_lastReport != null && _entries.isNotEmpty)
                  _buildGenerationReport(),
                if (_entries.isNotEmpty)
                  Expanded(child: _buildScheduleGrid()),
                if (_entries.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No timetable generated for the current term.\nClick "Run Timetable Engine" to auto-schedule.',
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _seedFullData, 
                            icon: const Icon(Icons.school),
                            label: const Text('Inject Full MoE Standard School Data'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _bootstrapData, 
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('Seed Sample Constraints (Quick Test)'),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                            child: Text('This will auto-assign subjects to teachers and define class demands so you can test the engine immediately.', 
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                  )
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_entries.isNotEmpty && !_loading)
            FloatingActionButton.extended(
              heroTag: 'sim',
              onPressed: () => _showSimulationDialog(),
              icon: const Icon(Icons.psychology),
              label: const Text('Simulate Absence'),
              backgroundColor: AppTheme.secondary,
            ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'gen',
            onPressed: _loading ? null : () => _runEngine(),
            icon: const Icon(Icons.bolt),
            label: Text(_loading ? 'Generating...' : 'Run Timetable Engine'),
          ),
        ],
      ),
    );
  }

  void _showSimulationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict Simulation Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a teacher to "remove" from the school. The engine will try to re-route all their lessons to other qualified staff without breaks.'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Teacher to Simulate Absence', border: OutlineInputBorder()),
              items: _teachers.map((UserModel t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
              onChanged: (val) => _simulatedAbsentTeacherId = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _runEngine(isSimulation: true);
            },
            child: const Text('Start Simulation'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerationReport() {
    final time = _lastReport!['dbTimeMs'] ?? 0;
    final steps = _lastReport!['steps'] ?? 0;
    final variance = (_lastReport!['variance'] as double?)?.toStringAsFixed(1) ?? '0.0';
    final unused = (_lastReport!['unusedPercentage'] as double?)?.toStringAsFixed(1) ?? '0.0';
    final loads = _lastReport!['weeklyLoad'] as Map<String, int>? ?? {};

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Generation Diagnostics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metric('Time', '${time}ms'),
              _metric('Backtrack Steps', '$steps'),
              _metric('Load Variance', variance),
              _metric('Unused Cap.', '$unused%'),
            ],
          ),
          const Divider(height: 24),
          const Text('Teacher Load Visualization (Top 10)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: loads.entries
                  .take(10) // Show a sample of top assigned teachers
                  .map((e) => Tooltip(
                    message: '${e.key}: ${e.value} periods',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 32,
                      decoration: BoxDecoration(
                        color: e.value > 25 ? Colors.orange : AppTheme.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      height: (e.value / 35) * 80, // Max 35 scaling
                      child: Center(
                        child: Text('${e.value}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildScheduleGrid() {
    const int periodsPerDay = 7;
    const int daysPerWeek = 5;

    final filteredEntries = _selectedClassId == 'ALL' 
        ? _entries 
        : _entries.where((e) => e.classId == _selectedClassId).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: daysPerWeek,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: daysPerWeek * periodsPerDay,
      itemBuilder: (context, i) {
        final day = (i % daysPerWeek) + 1;
        final period = (i ~/ daysPerWeek) + 1;
        
        final slotEntries = filteredEntries.where((e) => e.dayOfWeek == day && e.periodNumber == period).toList();

        return Container(
          decoration: BoxDecoration(
            color: slotEntries.isEmpty ? Colors.grey.shade50 : AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: slotEntries.length > 1 && _selectedClassId != 'ALL' ? Colors.red : Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Day $day - P$period', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 4),
              if (slotEntries.isNotEmpty) ...[
                if (_selectedClassId != 'ALL') ...[
                  Text(slotEntries.first.subjectId.toUpperCase(), 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)
                  ),
                  Text(slotEntries.first.teacherId, style: const TextStyle(fontSize: 10)),
                ] else ...[
                  Text('${slotEntries.length} Classes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const Text('Active', style: TextStyle(fontSize: 10)),
                ]
              ]
            ],
          ),
        );
      },
    );
  }
}
