// lib/features/assessment/competency_matrix_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/student_model.dart';
import '../../data/models/curriculum_models.dart';
import '../../data/models/assessment_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class CompetencyMatrixPage extends ConsumerStatefulWidget {
  const CompetencyMatrixPage({super.key});

  @override
  ConsumerState<CompetencyMatrixPage> createState() => _CompetencyMatrixPageState();
}

class _CompetencyMatrixPageState extends ConsumerState<CompetencyMatrixPage> {
  String? _selectedGrade;
  LearningAreaModel? _selectedArea;
  
  List<LearningAreaModel> _areas = [];
  List<StudentModel> _students = [];
  List<SubStrandModel> _subStrands = [];
  Map<String, Map<String, int>> _matrix = {}; // {studentId: {subStrandId: score}}

  @override
  void initState() {
    super.initState();
    // Default to first grade in list
    _selectedGrade = AppConstants.allGrades.first;
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider);
    
    // 1. Load Areas for Grade
    final areas = await db.curriculumDao.findAreasByLevel(AppConstants.gradeBand(_selectedGrade!));
    
    // 2. Fetch visible students based on user role
    List<StudentModel> students;
    if (user != null && user.roleLevel <= 3) {
      // Management sees all students for the grade
      students = await db.studentDao.findByGrade(_selectedGrade!);
    } else if (user != null) {
      // Teachers see students in their assigned classes
      final Set<String> classIds = {};
      if (user.assignedClassId != null) classIds.add(user.assignedClassId!);
      
      final activeTimetable = await db.timetableDao.getActiveTimetable();
      if (activeTimetable != null) {
        final slots = await db.timetableDao.getSlotsForTeacher(activeTimetable.id, user.id);
        for (final s in slots) {
          classIds.add(s.classId);
        }
      }
      
      if (classIds.isNotEmpty) {
        students = await db.studentDao.findByClasses(classIds.toList());
        // Filter by selected grade for the matrix view
        students = students.where((s) => s.grade == _selectedGrade).toList();
      } else {
        students = [];
      }
    } else {
      students = [];
    }

    setState(() {
      _areas = areas;
      _students = students;
      if (_areas.isNotEmpty && _selectedArea == null) {
        _selectedArea = _areas.first;
      }
    });

    if (_selectedArea != null) {
      await _loadMatrix();
    }
  }

  Future<void> _loadMatrix() async {
    final db = await ref.read(databaseProvider.future);
    
    // 1. Get all sub-strands for this area
    final strands = await db.curriculumDao.findStrandsByArea(_selectedArea!.id);
    List<SubStrandModel> allSubStrands = [];
    for (final s in strands) {
      final ss = await db.curriculumDao.findSubStrandsByStrand(s.id);
      allSubStrands.addAll(ss);
    }

    // 2. Get assessments for these students
    Map<String, Map<String, int>> matrix = {};
    for (final student in _students) {
      final assessments = await db.assessmentDao.findForStudent(student.id, 1, '2026');
      Map<String, int> scores = {};
      for (final a in assessments) {
        scores[a.subStrandId] = a.score;
      }
      matrix[student.id] = scores;
    }

    setState(() {
      _subStrands = allSubStrands;
      _matrix = matrix;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Achievement Matrix',
      body: Column(
        children: [
          _buildFilters(),
          _buildLegend(),
          const Divider(height: 1),
          Expanded(child: _buildMatrix()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedGrade,
              decoration: const InputDecoration(labelText: 'Grade', contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              items: AppConstants.allGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) {
                setState(() => _selectedGrade = v);
                _loadData();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<LearningAreaModel>(
              value: _selectedArea,
              decoration: const InputDecoration(labelText: 'Subject', contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) {
                setState(() => _selectedArea = v);
                _loadMatrix();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [4, 3, 2, 1].map((s) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.rubricColor(s), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text(AppConstants.rubricCode[s]!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.rubricColor(s))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMatrix() {
    if (_subStrands.isEmpty) return const Center(child: Text('No sub-strands found for this subject.'));
    if (_students.isEmpty) return const Center(child: Text('No students found in this grade.'));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(100),
            columnWidths: const {0: FixedColumnWidth(160)},
            border: TableBorder.all(color: Colors.grey.shade200, width: 1, borderRadius: BorderRadius.circular(12)),
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)),
                children: [
                  const _Cell('Student Name', isHeader: true),
                  ..._subStrands.map((ss) => _Cell(ss.subStrandName, isHeader: true)),
                ],
              ),
              // Data Rows
              ..._students.map((student) => TableRow(
                children: [
                  _Cell(student.fullName),
                  ..._subStrands.map((ss) {
                    final score = _matrix[student.id]?[ss.id];
                    return InkWell(
                      onTap: () => _showScorePicker(student, ss, score),
                      child: _ScoreBox(score: score),
                    );
                  }),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showScorePicker(StudentModel student, SubStrandModel ss, int? currentScore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assess ${student.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(ss.subStrandName, style: Theme.of(context).textTheme.titleMedium),
            ),
            ...[4, 3, 2, 1].map((s) => ListTile(
              leading: Icon(Icons.circle, color: AppTheme.rubricColor(s)),
              title: Text(AppConstants.rubricLabel[s]!),
              trailing: currentScore == s ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () => _updateScore(student.id, ss.id, s),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _updateScore(String studentId, String subStrandId, int score) async {
    Navigator.pop(context); // Close dialog
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider)!;
    
    final assessment = AssessmentModel(
      id: const Uuid().v4(),
      studentId: studentId,
      subStrandId: subStrandId,
      teacherId: user.id,
      score: score,
      assessmentType: 'Formative',
      term: 1,
      academicYear: '2026',
      dateRecorded: DateTime.now().millisecondsSinceEpoch,
    );

    await db.assessmentDao.insertAssessment(assessment);
    await _loadMatrix(); // Refresh UI
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _Cell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
          fontSize: isHeader ? 10 : 12,
          color: isHeader ? Theme.of(context).colorScheme.primary : null,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int? score;
  const _ScoreBox({this.score});

  @override
  Widget build(BuildContext context) {
    final color = score != null ? AppTheme.rubricColor(score!) : Colors.grey.shade400;
    return Container(
      height: 44,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: score != null ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: score != null ? color.withOpacity(0.3) : Colors.grey.shade100),
      ),
      child: Center(
        child: score != null 
          ? Text(AppConstants.rubricCode[score!]!, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))
          : const Icon(Icons.add, size: 14, color: Colors.grey),
      ),
    );
  }
}
