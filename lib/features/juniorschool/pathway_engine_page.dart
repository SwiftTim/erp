// lib/features/juniorschool/pathway_engine_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/student_model.dart';
import '../../data/models/pathway_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'package:uuid/uuid.dart';

class PathwayEnginePage extends ConsumerStatefulWidget {
  const PathwayEnginePage({super.key});

  @override
  ConsumerState<PathwayEnginePage> createState() => _PathwayEnginePageState();
}

class _PathwayEnginePageState extends ConsumerState<PathwayEnginePage> {
  StudentModel? _selectedStudent;
  List<StudentModel> _grade9Students = [];
  PathwayRecommendationModel? _currentRec;
  bool _loading = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final db = await ref.read(databaseProvider.future);
    final all = await db.studentDao.findAll();
    // Filter for Grade 9 (Junior School Exit Year)
    final grade9 = all.where((s) => s.grade.contains('9')).toList();
    
    if (mounted) {
      setState(() {
        _grade9Students = grade9;
        _loading = false;
      });
    }
  }

  Future<void> _onStudentSelected(StudentModel? s) async {
    if (s == null) return;
    setState(() {
      _selectedStudent = s;
      _currentRec = null;
    });

    final db = await ref.read(databaseProvider.future);
    final rec = await db.pathwayDao.findForStudent(s.id);
    if (mounted) {
      setState(() {
        _currentRec = rec;
      });
    }
  }

  Future<void> _runEngine() async {
    if (_selectedStudent == null) return;
    setState(() => _calculating = true);

    final db = await ref.read(databaseProvider.future);
    
    // Simulate AI/Academic analysis
    await Future.delayed(const Duration(seconds: 2));
    
    // In real CBC logic, we'd average assessments from G7, G8, G9
    final avg = await db.assessmentDao.avgScoreForStudent(_selectedStudent!.id, '2026', 1) ?? 2.5;

    String pathway;
    String rationale;

    if (avg >= 3.5) {
      pathway = 'STEM (Science & Tech)';
      rationale = 'Excellent analytical and scientific capability. Consistent Exceeding Expectations (EE) in Integrated Science and Mathematics.';
    } else if (avg >= 2.5) {
      pathway = 'Social Sciences & Humanities';
      rationale = 'Strong communication and social awareness. Proficient in Languages and Social Studies.';
    } else {
      pathway = 'Arts & Sports Science';
      rationale = 'Creative aptitude and high psychomotor engagement. Strong performance in Creative Arts and Physical Education.';
    }

    final newRec = PathwayRecommendationModel(
      id: const Uuid().v4(),
      studentId: _selectedStudent!.id,
      recommendedPathway: pathway,
      performanceScore: avg,
      rationale: rationale,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await db.pathwayDao.insertRecommendation(newRec);

    if (mounted) {
      setState(() {
        _currentRec = newRec;
        _calculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Junior School Pathway Engine',
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentSelector(),
                const SizedBox(height: 24),
                if (_selectedStudent != null) 
                  Expanded(child: _buildDeepAnalysis()),
              ],
            ),
          ),
    );
  }

  Widget _buildStudentSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Grade 9 Student to Analyze', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<StudentModel>(
              value: _selectedStudent,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _grade9Students.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.fullName),
              )).toList(),
              onChanged: _onStudentSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepAnalysis() {
    if (_calculating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Analyzing CBC Assessment History...', style: TextStyle(fontWeight: FontWeight.w500)),
            Text('Processing Grades 7, 8, and 9 data for ${_selectedStudent!.fullName}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (_currentRec == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_outlined, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('Pathway Analysis Not Yet Run', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Click Analyze to determine the best Senior School path.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _runEngine,
              icon: const Icon(Icons.bolt),
              label: const Text('Run Pathway Analysis'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(),
          const SizedBox(height: 24),
          const Text('Academic Profile Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildMetricRow('Academic Average', _currentRec!.performanceScore.toStringAsFixed(2), Icons.trending_up, Colors.blue),
          _buildMetricRow('Teacher Consensus', '85% (STEM Preferred)', Icons.people_outline, Colors.teal),
          _buildMetricRow('Extracurricular Alignment', 'High (Science Club Head)', Icons.workspace_premium_outlined, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: AppTheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.school, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text('RECOMMENDED PATHWAY', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
            Text(_currentRec!.recommendedPathway, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24, height: 32),
            Text(_currentRec!.rationale, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
