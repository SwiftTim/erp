import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/app_database.dart';
import '../../data/models/user_model.dart';
import '../../data/models/curriculum_models.dart';
import '../../data/models/timetable_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class TeacherCapacityPage extends ConsumerStatefulWidget {
  const TeacherCapacityPage({super.key});

  @override
  ConsumerState<TeacherCapacityPage> createState() => _TeacherCapacityPageState();
}

class _TeacherCapacityPageState extends ConsumerState<TeacherCapacityPage> {
  bool _isLoading = true;
  List<UserModel> _teachers = [];
  List<LearningAreaModel> _subjects = [];
  
  Map<String, TeacherTimetableProfile> _profiles = {};
  Map<String, List<TeacherSubjectCapability>> _capabilities = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = await ref.read(databaseProvider.future);
    
    // Fetch active staff (roles 1-5, considering all potential teachers/deputies)
    final users = await db.userDao.findAllActive();
    _teachers = users.where((u) => u.roleLevel <= AppConstants.roleTeacher).toList();
    
    _subjects = await db.curriculumDao.findAllLearningAreas();
    
    final profilesList = await db.timetableDao.findAllTeacherProfiles();
    _profiles = { for (var p in profilesList) p.teacherId: p };
    
    final capabilitiesList = await db.timetableDao.findAllCapabilities();
    _capabilities = {};
    for (var cap in capabilitiesList) {
      _capabilities.putIfAbsent(cap.teacherId, () => []).add(cap);
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  void _openSetupDialog(UserModel teacher) {
    showDialog(
      context: context,
      builder: (context) => _TeacherSetupDialog(
        teacher: teacher,
        subjects: _subjects,
        initialProfile: _profiles[teacher.id],
        initialCapabilities: _capabilities[teacher.id] ?? [],
        onSaved: (profile, caps) async {
          final db = await ref.read(databaseProvider.future);
          await db.timetableDao.insertTeacherProfile(profile);
          // Simple approach: to replace capabilities we'd ideally delete old and insert new. 
          // Since insert handles replace for same PK, we can just insert, 
          // but we need to ensure we don't have dangling ones. 
          // Actually, TeacherSubjectCapability doesn't have a direct delete, 
          // but we can generate a consistent UUID based on Teacher + Priority Level.
          for (var cap in caps) {
            await db.timetableDao.insertTeacherCapability(cap);
          }
          await _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Teacher Capacities & Subjects',
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _teachers.length,
            itemBuilder: (context, index) {
              final teacher = _teachers[index];
              final profile = _profiles[teacher.id];
              final caps = _capabilities[teacher.id] ?? [];
              
              // Sort caps by priority level (1=Primary, 2=Secondary, 3=Tertiary)
              caps.sort((a, b) => a.priorityLevel.compareTo(b.priorityLevel));

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: AppTheme.primary),
                  ),
                  title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: profile == null
                      ? const Text('Setup Pending: ⚠️ No capacity constraints defined', style: TextStyle(color: Colors.red))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Max Load: ${profile.maxPeriodsPerWeek} periods/wk, ${profile.maxPeriodsPerDay} periods/day'),
                            const SizedBox(height: 4),
                            if (caps.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                children: caps.map((c) {
                                  final subjectName = _subjects.firstWhere((s) => s.id == c.subjectId, orElse: () => const LearningAreaModel(id: '', name: 'Unknown', gradeBand: '', category: '')).name;
                                  final priorityStr = c.priorityLevel == 1 ? 'Primary' : c.priorityLevel == 2 ? 'Secondary' : 'Tertiary';
                                  return Chip(
                                    label: Text('$subjectName ($priorityStr)', style: const TextStyle(fontSize: 10)),
                                    backgroundColor: c.priorityLevel == 1 ? Colors.green.shade50 : Colors.blue.shade50,
                                  );
                                }).toList(),
                              )
                            else 
                              const Text('No subjects assigned', style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _openSetupDialog(teacher),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: profile == null ? AppTheme.secondary : null,
                    ),
                    child: Text(profile == null ? 'Setup' : 'Edit'),
                  ),
                ),
              );
            },
          ),
    );
  }
}

class _TeacherSetupDialog extends StatefulWidget {
  final UserModel teacher;
  final List<LearningAreaModel> subjects;
  final TeacherTimetableProfile? initialProfile;
  final List<TeacherSubjectCapability> initialCapabilities;
  final Function(TeacherTimetableProfile, List<TeacherSubjectCapability>) onSaved;

  const _TeacherSetupDialog({
    required this.teacher,
    required this.subjects,
    this.initialProfile,
    required this.initialCapabilities,
    required this.onSaved,
  });

  @override
  State<_TeacherSetupDialog> createState() => _TeacherSetupDialogState();
}

class _TeacherSetupDialogState extends State<_TeacherSetupDialog> {
  late TextEditingController _maxDayCtrl;
  late TextEditingController _maxWeekCtrl;
  
  String? _primarySubjectId;
  String? _secondarySubjectId;
  String? _tertiarySubjectId;
  
  bool _isClassTeacher = false;

  @override
  void initState() {
    super.initState();
    _maxDayCtrl = TextEditingController(text: widget.initialProfile?.maxPeriodsPerDay.toString() ?? '7');
    _maxWeekCtrl = TextEditingController(text: widget.initialProfile?.maxPeriodsPerWeek.toString() ?? '30');
    _isClassTeacher = widget.initialProfile?.isClassTeacher ?? false;

    for (var cap in widget.initialCapabilities) {
      if (cap.priorityLevel == 1) _primarySubjectId = cap.subjectId;
      if (cap.priorityLevel == 2) _secondarySubjectId = cap.subjectId;
      if (cap.priorityLevel == 3) _tertiarySubjectId = cap.subjectId;
    }
  }

  void _save() {
    int maxDay = int.tryParse(_maxDayCtrl.text) ?? 7;
    int maxWeek = int.tryParse(_maxWeekCtrl.text) ?? 30;

    final profile = TeacherTimetableProfile(
      id: widget.teacher.id, // Using teacher ID as profile ID
      teacherId: widget.teacher.id,
      maxPeriodsPerDay: maxDay,
      maxPeriodsPerWeek: maxWeek,
      isClassTeacher: _isClassTeacher,
    );

    List<TeacherSubjectCapability> caps = [];
    if (_primarySubjectId != null) {
      caps.add(TeacherSubjectCapability(
        id: '${widget.teacher.id}_P1',
        teacherId: widget.teacher.id,
        subjectId: _primarySubjectId!,
        priorityLevel: 1,
      ));
    }
    if (_secondarySubjectId != null) {
      caps.add(TeacherSubjectCapability(
        id: '${widget.teacher.id}_P2',
        teacherId: widget.teacher.id,
        subjectId: _secondarySubjectId!,
        priorityLevel: 2,
      ));
    }
    if (_tertiarySubjectId != null) {
      caps.add(TeacherSubjectCapability(
        id: '${widget.teacher.id}_P3',
        teacherId: widget.teacher.id,
        subjectId: _tertiarySubjectId!,
        priorityLevel: 3,
      ));
    }

    widget.onSaved(profile, caps);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Setup: ${widget.teacher.name}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Timetable Load Constraints', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maxDayCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Periods/Day (e.g. 7)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxWeekCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Periods/Week (e.g. 30)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Is Class Teacher?'),
              value: _isClassTeacher,
              onChanged: (val) => setState(() => _isClassTeacher = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 32),
            const Text('Subject Capabilities', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Primary Subject (Required)', border: OutlineInputBorder()),
              value: _primarySubjectId,
              items: widget.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (val) => setState(() => _primarySubjectId = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Secondary Subject (Optional)', border: OutlineInputBorder()),
              value: _secondarySubjectId,
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('None')),
                ...widget.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
              ],
              onChanged: (val) => setState(() => _secondarySubjectId = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tertiary Subject (Optional)', border: OutlineInputBorder()),
              value: _tertiarySubjectId,
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('None')),
                ...widget.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
              ],
              onChanged: (val) => setState(() => _tertiarySubjectId = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save Constraints'),
        ),
      ],
    );
  }
}
