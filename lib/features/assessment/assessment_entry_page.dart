// lib/features/assessment/assessment_entry_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/assessment_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/curriculum_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../health/widgets/health_alert.dart';
import 'widgets/rubric_button.dart';
import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/sanitization_service.dart';


class AssessmentEntryPage extends ConsumerStatefulWidget {
  const AssessmentEntryPage({super.key});

  @override
  ConsumerState<AssessmentEntryPage> createState() => _AssessmentEntryPageState();
}

class _AssessmentEntryPageState extends ConsumerState<AssessmentEntryPage> {
  final _uuid = const Uuid();

  // Selection state
  StudentModel? _selectedStudent;
  LearningAreaModel? _selectedArea;
  StrandModel? _selectedStrand;
  SubStrandModel? _selectedSubStrand;
  int? _selectedScore;
  final TextEditingController _remarksCtrl = TextEditingController();
  File? _evidenceFile;
  bool _isSaving = false;

  // Data lists
  List<StudentModel> _students = [];
  List<LearningAreaModel> _areas = [];
  List<StrandModel> _strands = [];
  List<SubStrandModel> _subStrands = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider)!;
    final todayEpoch = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0).millisecondsSinceEpoch;

    // 1. Check for Substitution Rights
    final subs = await db.enterpriseDao.findActiveSubstitutions(user.id, todayEpoch);
    String targetClassId = user.assignedClassId ?? '';
    
    if (subs.isNotEmpty) {
      // Use the subbed class ID for this session
      targetClassId = subs.first.classId;
    }

    // 2. Find students in the target class
    final students = await db.studentDao.findByClass(targetClassId);
    
    // 3. Find the class details to get the grade
    final schoolClass = await db.curriculumDao.findClassById(targetClassId);
    
    if (mounted) {
      setState(() {
        _students = students;
      });

      if (schoolClass != null) {
        _loadAreas(schoolClass.grade);
      }
    }
  }


  Future<void> _loadAreas(String grade) async {
    final db = await ref.read(databaseProvider.future);
    // Grade mapping: "Grade 1" -> "Grade 1", "PP1" -> "PP1"
    final areas = await db.curriculumDao.findAreasByLevel(grade);
    setState(() {
      _areas = areas;
      _strands = [];
      _subStrands = [];
    });
  }

  Future<void> _loadStrands(String areaId) async {
    final db = await ref.read(databaseProvider.future);
    final strands = await db.curriculumDao.findStrandsByArea(areaId);
    setState(() {
      _strands = strands;
      _subStrands = [];
    });
  }

  Future<void> _loadSubStrands(String strandId) async {
    final db = await ref.read(databaseProvider.future);
    final subStrands = await db.curriculumDao.findSubStrandsByStrand(strandId);
    setState(() {
      _subStrands = subStrands;
    });
  }

  void _onScoreSelected(int score) {
    setState(() {
      _selectedScore = score;
      if (_selectedSubStrand != null) {
        _remarksCtrl.text = AppConstants.generateNarrative(
          score,
          _selectedArea?.name ?? 'this subject',
        );
      }
    });
  }

  Future<void> _pickEvidence() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (xFile != null) {
      setState(() => _evidenceFile = File(xFile.path));
    }
  }

  Future<void> _save() async {
    if (_selectedStudent == null || _selectedSubStrand == null || _selectedScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all selections.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final user = ref.read(currentUserProvider)!;
    final db = await ref.read(databaseProvider.future);
    
    // ── MODERATION LOCK CHECK ──
    final existing = await db.assessmentDao.findLatestForSubStrand(_selectedStudent!.id, _selectedSubStrand!.id);
    if (existing != null && existing.isModerated >= 2) {
      if (mounted) {
        setState(() => _isSaving = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(children: [Icon(Icons.lock, color: Colors.red), SizedBox(width: 8), Text('Record Locked')]),
            content: const Text('This assessment has already been moderated/approved by the HOD and cannot be modified. Please contact your Department Head for reversals.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Understood'))],
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final assessment = AssessmentModel(
      id: _uuid.v4(),
      studentId: _selectedStudent!.id,
      subStrandId: _selectedSubStrand!.id,
      teacherId: user.id,
      score: _selectedScore!,
      teacherRemarks: _remarksCtrl.text.isNotEmpty 
          ? SanitizationService.sanitizeNarrative(_remarksCtrl.text) 
          : null,
      evidencePath: _evidenceFile?.path,
      term: 1, 
      academicYear: '2026',
      dateRecorded: now.millisecondsSinceEpoch,
    );


    await db.assessmentDao.insertAssessment(assessment);


    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assessment saved for ${_selectedStudent!.fullName}'),
          backgroundColor: AppTheme.rubricColor(_selectedScore!),
        ),
      );
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _selectedStudent = null;
      _selectedArea = null;
      _selectedStrand = null;
      _selectedSubStrand = null;
      _selectedScore = null;
      _remarksCtrl.clear();
      _evidenceFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Record Assessment',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(
              steps: const ['Student', 'Area', 'Strand', 'Sub-strand', 'Score'],
              currentStep: _currentStep,
            ),
            const SizedBox(height: 24),

            // Step 1: Student
            _AssessmentSection(
              title: 'Who is being assessed?',
              icon: Icons.person_outline,
              child: _students.isEmpty
                  ? _EmptyState(
                      icon: Icons.people_outline,
                      message: 'No students found. Register students first.',
                      onAction: () => context.go('/students/new'),
                      actionLabel: 'Register Student',
                    )
                  : DropdownButtonFormField<StudentModel>(
                      value: _selectedStudent,
                      decoration: const InputDecoration(labelText: 'Select Student'),
                      items: _students.map((s) => DropdownMenuItem(value: s, child: Text(s.fullName))).toList(),
                      onChanged: (v) {
                        setState(() { _selectedStudent = v; _resetSelections(); });
                        if (v != null) _loadAreas(v.grade);
                      },
                    ),
            ),
                        if (_selectedStudent != null) ...[
                  HealthAlert(studentId: _selectedStudent!.id),
                  const SizedBox(height: 16),
                ],
                
                // Step 2: Learning Area Selection (Only if Student selected)
                if (_selectedStudent != null)
              PageTransitionSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
                    FadeThroughTransition(animation: primaryAnimation, secondaryAnimation: secondaryAnimation, child: child),
                child: _AssessmentSection(
                  key: ValueKey(_selectedStudent?.id),
                  title: 'Learning Area (Grade: ${_selectedStudent?.grade})',
                  icon: Icons.menu_book_outlined,
                  child: _areas.isEmpty
                      ? const Text('Loading curriculum areas...')
                      : DropdownButtonFormField<LearningAreaModel>(
                          value: _selectedArea,
                          decoration: const InputDecoration(labelText: 'Select Subject'),
                          items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                          onChanged: (v) {
                            setState(() { _selectedArea = v; _selectedStrand = null; _selectedSubStrand = null; });
                            if (v != null) _loadStrands(v.id);
                          },
                        ),
                ),
              ),

            // Step 3: Strand
            if (_selectedArea != null)
              _AssessmentSection(
                title: 'Strand / Topic',
                icon: Icons.topic_outlined,
                child: _strands.isEmpty
                    ? const Text('No strands found for this area.')
                    : DropdownButtonFormField<StrandModel>(
                        value: _selectedStrand,
                        decoration: const InputDecoration(labelText: 'Select Strand'),
                        items: _strands.map((s) => DropdownMenuItem(value: s, child: Text(s.strandName))).toList(),
                        onChanged: (v) {
                          setState(() { _selectedStrand = v; _selectedSubStrand = null; });
                          if (v != null) _loadSubStrands(v.id);
                        },
                      ),
              ),

            // Step 4: Sub-strand
            if (_selectedStrand != null)
              _AssessmentSection(
                title: 'Sub-strand / Sub-topic',
                icon: Icons.bookmark_outline,
                child: _subStrands.isEmpty
                    ? const Text('No sub-strands available.')
                    : DropdownButtonFormField<SubStrandModel>(
                        value: _selectedSubStrand,
                        decoration: const InputDecoration(labelText: 'Select Sub-strand'),
                        items: _subStrands.map((ss) => DropdownMenuItem(value: ss, child: Text(ss.subStrandName))).toList(),
                        onChanged: (v) => setState(() { _selectedSubStrand = v; _selectedScore = null; }),
                      ),
              ),

            // Step 5: Score
            if (_selectedSubStrand != null)
              _AssessmentSection(
                title: 'Achievement Level',
                icon: Icons.grade_outlined,
                child: Column(
                  children: [
                    Row(
                      children: [4, 3, 2, 1].map((score) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: RubricButton(
                            score: score,
                            isSelected: _selectedScore == score,
                            onTap: () => _onScoreSelected(score),
                          ),
                        ),
                      )).toList(),
                    ),
                    if (_selectedScore != null) ...[
                      const SizedBox(height: 16),
                      _RubricFeedbackView(score: _selectedScore!),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _remarksCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Teacher Remarks',
                          hintText: 'Edit the generated narrative...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _EvidencePicker(
                        file: _evidenceFile,
                        onPicker: _pickEvidence,
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 32),
            if (_selectedSubStrand != null)
              FilledButton.icon(
                onPressed: _isSaving || _selectedScore == null ? null : _save,
                icon: _isSaving ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.check),
                label: const Text('Confirm & Save Assessment'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
          ],
        ),
      ),
    );
  }

  void _resetSelections() {
    _selectedArea = null;
    _selectedStrand = null;
    _selectedSubStrand = null;
    _selectedScore = null;
    _remarksCtrl.clear();
    _evidenceFile = null;
  }

  int get _currentStep {
    if (_selectedScore != null) return 5;
    if (_selectedSubStrand != null) return 4;
    if (_selectedStrand != null) return 3;
    if (_selectedArea != null) return 2;
    if (_selectedStudent != null) return 1;
    return 0;
  }
}

class _AssessmentSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _AssessmentSection({super.key, required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

class _RubricFeedbackView extends StatelessWidget {
  final int score;
  const _RubricFeedbackView({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.rubricColor(score);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppConstants.rubricDescription[score] ?? '',
              style: TextStyle(color: color, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidencePicker extends StatelessWidget {
  final File? file;
  final VoidCallback onPicker;
  const _EvidencePicker({this.file, required this.onPicker});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPicker,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file!, width: double.infinity, fit: BoxFit.cover),
              )
            : const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                    SizedBox(height: 4),
                    Text('Add Evidence (Photo)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onAction;
  final String actionLabel;

  const _EmptyState({required this.icon, required this.message, required this.onAction, required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 48, color: Colors.grey.withOpacity(0.5)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 12),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentStep;

  const _StepIndicator({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(steps.length, (i) {
          final isDone = i < currentStep;
          final isCurrent = i == currentStep;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: isDone ? Colors.green : (isCurrent ? AppTheme.primary : Colors.grey.shade300),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text('${i + 1}', style: TextStyle(color: isCurrent ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(steps[i], style: TextStyle(fontSize: 10, color: isCurrent ? AppTheme.primary : Colors.grey, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
              if (i < steps.length - 1)
                Container(
                  width: 24, height: 2,
                  margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
                  color: isDone ? Colors.green : Colors.grey.shade300,
                ),
            ],
          );
        }),
      ),
    );
  }
}
