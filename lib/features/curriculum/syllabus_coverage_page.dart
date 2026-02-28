// lib/features/curriculum/syllabus_coverage_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/curriculum_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class SyllabusCoveragePage extends ConsumerStatefulWidget {
  const SyllabusCoveragePage({super.key});

  @override
  ConsumerState<SyllabusCoveragePage> createState() => _SyllabusCoveragePageState();
}

class _SyllabusCoveragePageState extends ConsumerState<SyllabusCoveragePage> {
  bool _loading = true;
  String? _targetClassId;
  String? _targetGrade;
  
  List<LearningAreaModel> _areas = [];
  LearningAreaModel? _selectedArea;
  
  List<StrandModel> _strands = [];
  Set<String> _coveredStrandIds = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider)!;
    
    // 1. Identify target class
    _targetClassId = user.assignedClassId;
    if (_targetClassId == null || _targetClassId!.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final schoolClass = await db.curriculumDao.findClassById(_targetClassId!);
    _targetGrade = schoolClass?.grade;
    if (_targetGrade == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // 2. Load basic areas for grade
    final areas = await db.curriculumDao.findAreasByLevel(AppConstants.gradeBand(_targetGrade!));
    
    // 3. Load baseline coverage for class
    final coverage = await db.curriculumDao.findCoverageForClass(_targetClassId!);
    final covSet = coverage.map((c) => c.strandId).toSet();

    if (mounted) {
      setState(() {
        _areas = areas;
        _coveredStrandIds = covSet;
        _loading = false;
      });
    }
  }

  Future<void> _loadStrands(LearningAreaModel area) async {
    final db = await ref.read(databaseProvider.future);
    final strands = await db.curriculumDao.findStrandsByArea(area.id);
    setState(() {
      _selectedArea = area;
      _strands = strands;
    });
  }

  Future<void> _toggleCoverage(StrandModel strand, bool isCovered) async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider)!;

    if (isCovered) {
      final cov = StrandCoverage(
        id: const Uuid().v4(),
        classId: _targetClassId!,
        strandId: strand.id,
        teacherId: user.id,
        completionDate: DateTime.now().millisecondsSinceEpoch,
      );
      await db.curriculumDao.insertCoverage(cov);
      setState(() => _coveredStrandIds.add(strand.id));
    } else {
      await db.curriculumDao.removeCoverage(_targetClassId!, strand.id);
      setState(() => _coveredStrandIds.remove(strand.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShell(title: 'Syllabus Tracker', body: Center(child: CircularProgressIndicator()));
    }

    if (_targetClassId == null) {
      return AppShell(
        title: 'Syllabus Tracker',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No assigned class.', style: TextStyle(fontSize: 18, color: Colors.grey)),
              TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final progress = _strands.isEmpty ? 0.0 : 
        (_coveredStrandIds.intersection(_strands.map((e) => e.id).toSet()).length / _strands.length);

    return AppShell(
      title: 'Syllabus Tracker',
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pane: Learning Areas
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
              ),
              child: ListView.separated(
                itemCount: _areas.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final a = _areas[i];
                  final isSelected = _selectedArea?.id == a.id;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppTheme.primary.withOpacity(0.1),
                    title: Text(a.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    trailing: const Icon(Icons.chevron_right, size: 16),
                    onTap: () => _loadStrands(a),
                  );
                },
              ),
            ),
          ),

          // Right Pane: Strands & Coverage check
          Expanded(
            flex: 5,
            child: _selectedArea == null
                ? const Center(child: Text('Select a learning area to view strands.', style: TextStyle(color: Colors.grey)))
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedArea!.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Grade: $_targetGrade', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 24),
                        
                        // Progress Bar
                        Row(
                          children: [
                            Text('${(progress * 100).toInt()}% Covered', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            const SizedBox(width: 16),
                            Expanded(child: LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4))),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Strands checklist
                        Expanded(
                          child: _strands.isEmpty
                              ? const Text('No strands found in the curriculum database.')
                              : ListView.builder(
                                  itemCount: _strands.length,
                                  itemBuilder: (context, i) {
                                    final s = _strands[i];
                                    final isCovered = _coveredStrandIds.contains(s.id);
                                    
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: isCovered ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3)),
                                      ),
                                      child: CheckboxListTile(
                                        value: isCovered,
                                        activeColor: Colors.green,
                                        title: Text(s.strandName, style: TextStyle(fontWeight: isCovered ? FontWeight.normal : FontWeight.bold)),
                                        subtitle: isCovered ? const Text('Marked as covered', style: TextStyle(color: Colors.green, fontSize: 10)) : null,
                                        onChanged: (val) {
                                          if (val != null) _toggleCoverage(s, val);
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
