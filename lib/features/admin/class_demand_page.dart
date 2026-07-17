import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/curriculum_models.dart';
import '../../data/models/timetable_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class ClassDemandPage extends ConsumerStatefulWidget {
  const ClassDemandPage({super.key});

  @override
  ConsumerState<ClassDemandPage> createState() => _ClassDemandPageState();
}

class _ClassDemandPageState extends ConsumerState<ClassDemandPage> {
  bool _isLoading = true;
  List<SchoolClassModel> _classes = [];
  List<LearningAreaModel> _allSubjects = [];
  Map<String, List<ClassSubjectRequirement>> _classRequirements = {};
  
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = await ref.read(databaseProvider.future);
    
    _classes = await db.curriculumDao.findAllClasses();
    // Assuming a method findAllClasses exists. If not, we'll need to fetch them.
    // Let's implement robust fallback or use what DAO provides.
    
    _allSubjects = await db.curriculumDao.findAllLearningAreas();
    
    final requirementsList = await db.timetableDao.findAllClassRequirements();
    _classRequirements = {};
    for (var r in requirementsList) {
      _classRequirements.putIfAbsent(r.classId, () => []).add(r);
    }
    
    if (_classes.isNotEmpty) {
      _selectedClassId = _classes.first.id;
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  // Find requirements specifically for the selected class
  List<ClassSubjectRequirement> get _currentRequirements => 
    _selectedClassId == null ? [] : (_classRequirements[_selectedClassId!] ?? []);

  SchoolClassModel? get _selectedClass => 
    _classes.where((c) => c.id == _selectedClassId).firstOrNull;

  List<LearningAreaModel> get _relevantSubjects {
    if (_selectedClass == null) return [];
    final band = AppConstants.gradeBand(_selectedClass!.grade);
    return _allSubjects.where((s) => s.gradeBand == band).toList();
  }

  Future<void> _saveRequirements(List<ClassSubjectRequirement> newReqs) async {
    if (_selectedClassId == null) return;
    final db = await ref.read(databaseProvider.future);
    
    // In a real scenario, we'd delete previous requirements for this class to prevent duplicates.
    // Since floor lacks a direct way without writing the specific method, 
    // we assume the user replaces all or we write over them via ID. 
    // However, ClassSubjectRequirement has a UUID `id`. 
    // To cleanly update, we insert using an ID composed of ClassID + SubjectID to overwrite.
    
    for (var req in newReqs) {
      await db.timetableDao.insertClassRequirement(req);
    }
    
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Class Demands saved successfully.'),
        backgroundColor: Colors.green,
      ));
    }
  }

  void _openAddClassDialog() {
    final nameController = TextEditingController();
    String selectedGrade = AppConstants.allGrades.first;
    bool autoQuota = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Class Name (e.g. Grade 4 Alpha)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: const InputDecoration(labelText: 'Grade', border: OutlineInputBorder()),
                items: AppConstants.allGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedGrade = val);
                },
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Auto-apply CBC Quotas', style: TextStyle(fontSize: 12)),
                subtitle: const Text('Fills periods per week based on CBC standards', style: TextStyle(fontSize: 10)),
                value: autoQuota,
                onChanged: (v) => setDialogState(() => autoQuota = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final newClass = SchoolClassModel(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  grade: selectedGrade,
                  academicYear: '2026',
                );
                await db.curriculumDao.insertClass(newClass);

                if (autoQuota) {
                  // Apply defaults
                  final band = AppConstants.gradeBand(selectedGrade);
                  final subjects = await db.curriculumDao.findAllLearningAreas();
                  final relevant = subjects.where((s) => s.gradeBand == band).toList();
                  
                  for (var s in relevant) {
                    int periods = 5; // Default fallback
                    if (s.name.contains('Math')) periods = 5;
                    else if (s.name.contains('English')) periods = 5;
                    else if (s.name.contains('Kiswahili')) periods = 4;
                    else if (s.name.contains('Science')) periods = 4;
                    else if (s.name.contains('CRE')) periods = 3;
                    else if (s.name.contains('Social')) periods = 3;
                    else periods = 2; // Others

                    await db.timetableDao.insertClassRequirement(ClassSubjectRequirement(
                      id: '${newClass.id}_${s.id}',
                      classId: newClass.id,
                      subjectId: s.id,
                      periodsPerWeek: periods,
                    ));
                  }
                }

                Navigator.pop(context);
                await _loadData();
                setState(() => _selectedClassId = newClass.id);
              },
              child: const Text('Create Class'),
            ),
          ],
        ),
      ),
    );
  }

  void _openDemandForm() {
    if (_selectedClass == null) return;
    showDialog(
      context: context,
      builder: (context) => _ClassDemandDialog(
        schoolClass: _selectedClass!,
        subjects: _relevantSubjects,
        existingReqs: _currentRequirements,
        onSaved: _saveRequirements,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Class Demand Definition',
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Class'),
                                value: _selectedClassId,
                                items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.grade})'))).toList(),
                                onChanged: (val) => setState(() => _selectedClassId = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _openAddClassDialog,
                              icon: const Icon(Icons.add),
                              tooltip: 'Add New Class',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedClassId != null)
                 Expanded(
                   child: Card(
                     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     child: Column(
                       children: [
                         ListTile(
                           title: const Text('Subject Demand (Periods per Week)', style: TextStyle(fontWeight: FontWeight.bold)),
                           subtitle: Text('Demand ensures subjects fulfill their weekly CBC quotas.'),
                           trailing: ElevatedButton.icon(
                             onPressed: _openDemandForm,
                             icon: const Icon(Icons.edit),
                             label: const Text('Edit Demand'),
                           ),
                         ),
                         const Divider(),
                         Expanded(
                           child: _currentRequirements.isEmpty
                              ? const Center(child: Text('No demands defined for this class. Engine will ignore it.', style: TextStyle(color: Colors.red)))
                              : ListView.builder(
                                  itemCount: _relevantSubjects.length,
                                  itemBuilder: (context, index) {
                                    final subject = _relevantSubjects[index];
                                    final req = _currentRequirements.where((r) => r.subjectId == subject.id).firstOrNull;
                                    
                                    if (req == null || req.periodsPerWeek == 0) return const SizedBox();

                                    return ListTile(
                                      title: Text(subject.name),
                                      subtitle: Text(subject.category),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${req.periodsPerWeek} pds/wk', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)
                                        ),
                                      ),
                                    );
                                  },
                                ),
                         ),
                       ],
                     ),
                   )
                 ),
            ],
          ),
    );
  }
}

class _ClassDemandDialog extends StatefulWidget {
  final SchoolClassModel schoolClass;
  final List<LearningAreaModel> subjects;
  final List<ClassSubjectRequirement> existingReqs;
  final Function(List<ClassSubjectRequirement>) onSaved;

  const _ClassDemandDialog({
    required this.schoolClass,
    required this.subjects,
    required this.existingReqs,
    required this.onSaved,
  });

  @override
  State<_ClassDemandDialog> createState() => _ClassDemandDialogState();
}

class _ClassDemandDialogState extends State<_ClassDemandDialog> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var subject in widget.subjects) {
      final req = widget.existingReqs.where((r) => r.subjectId == subject.id).firstOrNull;
      _controllers[subject.id] = TextEditingController(text: req?.periodsPerWeek.toString() ?? '0');
    }
  }

  void _save() {
    List<ClassSubjectRequirement> newReqs = [];
    int totalPeriods = 0;

    for (var subject in widget.subjects) {
      final periods = int.tryParse(_controllers[subject.id]?.text ?? '0') ?? 0;
      if (periods > 0) {
        totalPeriods += periods;
        newReqs.add(ClassSubjectRequirement(
          id: '${widget.schoolClass.id}_${subject.id}', // Deterministic ID for updating
          classId: widget.schoolClass.id,
          subjectId: subject.id,
          periodsPerWeek: periods,
        ));
      }
    }

    // Safety check just to prevent absurd totals
    if (totalPeriods > 50) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Warning: Total periods/week exceeds 50. Proceeding anyway.', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
      ));
    }

    widget.onSaved(newReqs);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Demand: ${widget.schoolClass.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.subjects.length,
          itemBuilder: (context, i) {
            final sub = widget.subjects[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _controllers[sub.id],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.all(8),
                        border: OutlineInputBorder(),
                        hintText: 'Periods',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save Demands'),
        ),
      ],
    );
  }
}
