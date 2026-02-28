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
import 'widgets/rubric_button.dart';
import 'package:go_router/go_router.dart';

class TeacherLesson {
  final SchoolClassModel schoolClass;
  final LearningAreaModel subject;
  TeacherLesson(this.schoolClass, this.subject);

  String get displayName => '${schoolClass.name} - ${subject.name}';
  String get id => '${schoolClass.id}_${subject.id}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherLesson && schoolClass.id == other.schoolClass.id && subject.id == other.subject.id;

  @override
  int get hashCode => schoolClass.id.hashCode ^ subject.id.hashCode;
}

class AssessmentEntryPage extends ConsumerStatefulWidget {
  const AssessmentEntryPage({super.key});

  @override
  ConsumerState<AssessmentEntryPage> createState() => _AssessmentEntryPageState();
}

class _AssessmentEntryPageState extends ConsumerState<AssessmentEntryPage> {
  final _uuid = const Uuid();

  // Selection state
  TeacherLesson? _selectedLesson;
  StrandModel? _selectedStrand;
  SubStrandModel? _selectedSubStrand;
  String? _selectedAssessmentType;
  
  // Batch scoring state
  Map<String, int?> _studentScores = {}; // studentId -> score (1-4)
  Map<String, String> _studentRemarks = {};
  Map<String, File?> _studentEvidence = {};
  
  bool _isSaving = false;

  // Data lists
  List<TeacherLesson> _myLessons = [];
  List<StudentModel> _students = [];
  List<StrandModel> _strands = [];
  List<SubStrandModel> _subStrands = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider)!;
    
    // 1. Get Teacher Assignments from Timetable
    final activeTimetable = await db.timetableDao.getActiveTimetable();
    final List<TeacherLesson> lessons = [];
    
    if (activeTimetable != null) {
      final slots = await db.timetableDao.getSlotsForTeacher(activeTimetable.id, user.id);
      
      final Set<String> seen = {};
      final allAreas = await db.curriculumDao.findAllLearningAreas();

      for (final s in slots) {
        final key = '${s.classId}_${s.subjectId}';
        if (!seen.contains(key)) {
          final cls = await db.curriculumDao.findClassById(s.classId);
          final sub = allAreas.where((a) => a.id == s.subjectId).firstOrNull;
          
          if (cls != null && sub != null) {
            lessons.add(TeacherLesson(cls, sub));
            seen.add(key);
          }
        }
      }
    }

    // 2. Fallback to assigned class
    if (lessons.isEmpty && user.assignedClassId != null) {
      final cls = await db.curriculumDao.findClassById(user.assignedClassId!);
      if (cls != null) {
        final areas = await db.curriculumDao.findAreasByLevel(AppConstants.gradeBand(cls.grade));
        for (final area in areas) {
          lessons.add(TeacherLesson(cls, area));
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _myLessons = lessons;
      });
      if (_myLessons.length == 1) {
        _onLessonSelected(_myLessons.first);
      }
    }
  }

  Future<void> _onLessonSelected(TeacherLesson? lesson) async {
    if (lesson == null) return;
    final db = await ref.read(databaseProvider.future);
    final strands = await db.curriculumDao.findStrandsByArea(lesson.subject.id);
    
    setState(() {
      _selectedLesson = lesson;
      _strands = strands;
      _selectedStrand = null;
      _selectedSubStrand = null;
      _subStrands = [];
      _students = [];
      _studentScores = {};
    });
  }

  Future<void> _onStrandSelected(StrandModel? strand) async {
    if (strand == null) return;
    final db = await ref.read(databaseProvider.future);
    final subStrands = await db.curriculumDao.findSubStrandsByStrand(strand.id);
    
    setState(() {
      _selectedStrand = strand;
      _subStrands = subStrands;
      _selectedSubStrand = null;
    });
  }

  void _onTypeSelected(String? type) {
    setState(() => _selectedAssessmentType = type);
    _checkAndLoadStudents();
  }

  Future<void> _onSubStrandSelected(SubStrandModel? ss) async {
    setState(() {
      _selectedSubStrand = ss;
    });
    _checkAndLoadStudents();
  }

  Future<void> _checkAndLoadStudents() async {
    if (_selectedLesson != null && _selectedSubStrand != null && _selectedAssessmentType != null) {
      final db = await ref.read(databaseProvider.future);
      final students = await db.studentDao.findByClass(_selectedLesson!.schoolClass.id);
      setState(() {
        _students = students;
        for (var s in students) {
          _studentScores[s.id] = null;
        }
      });
    }
  }

  void _updateStudentScore(String studentId, int score) {
    setState(() {
      _studentScores[studentId] = score;
      _studentRemarks[studentId] = AppConstants.generateNarrative(
        score,
        _selectedLesson?.subject.name ?? 'this subject',
      );
    });
  }

  Future<void> _pickEvidence(String studentId) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (xFile != null) {
      setState(() => _studentEvidence[studentId] = File(xFile.path));
    }
  }

  Future<void> _saveAll() async {
    final validScores = _studentScores.entries.where((e) => e.value != null).toList();
    if (validScores.isEmpty) return;

    setState(() => _isSaving = true);
    final user = ref.read(currentUserProvider)!;
    final db = await ref.read(databaseProvider.future);
    final now = DateTime.now();

    try {
      for (final entry in validScores) {
        final assessment = AssessmentModel(
          id: _uuid.v4(),
          studentId: entry.key,
          subStrandId: _selectedSubStrand!.id,
          teacherId: user.id,
          score: entry.value!,
          assessmentType: _selectedAssessmentType!,
          teacherRemarks: _studentRemarks[entry.key],
          evidencePath: _studentEvidence[entry.key]?.path,
          term: 1, 
          academicYear: '2026',
          dateRecorded: now.millisecondsSinceEpoch,
        );
        await db.assessmentDao.insertAssessment(assessment);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${validScores.length} assessments.')));
        _reset();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _reset() {
    setState(() {
      _selectedStrand = null;
      _selectedSubStrand = null;
      _selectedAssessmentType = null;
      _students = [];
      _studentScores = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Batch Assessment',
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildContextSelector(),
                  if (_students.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Learner Achievements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Record competency levels for all students in this lesson.', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
          ),
          if (_students.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildStudentScoringRow(_students[index]),
                  childCount: _students.length,
                ),
              ),
            ),
          if (_students.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveAll,
                  icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Save All Assessments'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ),
          if (_students.isEmpty && _selectedSubStrand != null && _selectedAssessmentType != null)
             const SliverFillRemaining(child: Center(child: Text('Loading students...'))),
        ],
      ),
    );
  }

  Widget _buildContextSelector() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<TeacherLesson>(
              value: _selectedLesson,
              decoration: const InputDecoration(labelText: 'Select Lesson (Class + Subject)', prefixIcon: Icon(Icons.school_outlined)),
              items: _myLessons.map((l) => DropdownMenuItem(value: l, child: Text(l.displayName))).toList(),
              onChanged: _onLessonSelected,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<StrandModel>(
                    value: _selectedStrand,
                    decoration: const InputDecoration(labelText: 'Strand'),
                    items: _strands.map((s) => DropdownMenuItem(value: s, child: Text(s.strandName))).toList(),
                    onChanged: _onStrandSelected,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<SubStrandModel>(
                    value: _selectedSubStrand,
                    decoration: const InputDecoration(labelText: 'Sub-strand'),
                    items: _subStrands.map((ss) => DropdownMenuItem(value: ss, child: Text(ss.subStrandName))).toList(),
                    onChanged: _onSubStrandSelected,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedAssessmentType,
              decoration: const InputDecoration(labelText: 'Assessment Type', prefixIcon: Icon(Icons.assignment_outlined)),
              items: AppConstants.assessmentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: _onTypeSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentScoringRow(StudentModel student) {
    final score = _studentScores[student.id];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(student.fullName.substring(0, 1), style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
              IconButton(
                icon: Icon(_studentEvidence[student.id] != null ? Icons.image : Icons.add_a_photo_outlined, color: _studentEvidence[student.id] != null ? Colors.green : Colors.grey),
                onPressed: () => _pickEvidence(student.id),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [4, 3, 2, 1].map((s) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: RubricButton(
                  score: s,
                  isSelected: score == s,
                  onTap: () => _updateStudentScore(student.id, s),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
