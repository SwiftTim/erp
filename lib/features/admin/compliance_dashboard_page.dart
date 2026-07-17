// lib/features/admin/compliance_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/compliance_service.dart';
import '../../data/models/student_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class ComplianceDashboardPage extends ConsumerStatefulWidget {
  const ComplianceDashboardPage({super.key});

  @override
  ConsumerState<ComplianceDashboardPage> createState() => _ComplianceDashboardPageState();
}

class _ComplianceDashboardPageState extends ConsumerState<ComplianceDashboardPage> {
  List<StudentModel> _students = [];
  Map<String, TransitionScore> _scores = {};
  Map<String, String> _pathways = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadComplianceData();
  }

  Future<void> _loadComplianceData() async {
    final db = await ref.read(databaseProvider.future);
    final students = await db.studentDao.findAll();
    
    // Filter for transition grades (Grade 6 and Grade 9)
    final transitionStudents = students.where((s) => s.grade == 'Grade 6' || s.grade == 'Grade 9').toList();
    
    Map<String, TransitionScore> scoreMap = {};
    Map<String, String> pathwayMap = {};

    final service = ref.read(complianceServiceProvider);
    for (final s in transitionStudents) {
      scoreMap[s.id] = await service.calculateTransitionScore(s.id);
      pathwayMap[s.id] = await service.recommendPathway(s.id);
    }

    if (mounted) {
      setState(() {
        _students = transitionStudents;
        _scores = scoreMap;
        _pathways = pathwayMap;
        _loading = false;
      });
    }
  }

  Future<void> _exportKnec() async {
    await ref.read(complianceServiceProvider).generateKnecExport(['Grade 6', 'Grade 9']);
    // In real app, write to file or share. Here we show success.
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.file_download, color: Colors.green),
              SizedBox(width: 12),
              Text('KNEC Export Ready'),
            ],
          ),
          content: Text('Bulk data for ${_students.length} students has been standardized and is ready for institutional upload.\n\nFormat: KNEC-V2 Standard CSV'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Download CSV')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'KNEC Compliance & Transition',
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryStats(),
                const SizedBox(height: 32),
                const Text('Transition Candidates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildCandidateList(),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportKnec,
        label: const Text('Bulk KNEC Export'),
        icon: const Icon(Icons.upload_file_outlined),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Ready for G10',
            value: '${_students.where((s) => s.grade == 'Grade 9').length}',
            icon: Icons.school,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatBox(
            label: 'Waitlist',
            value: '0',
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _students.length,
      itemBuilder: (context, i) {
        final s = _students[i];
        final score = _scores[s.id];
        final pathway = _pathways[s.id];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('UPI: ${s.upi} · Current: ${s.grade}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text('${score?.finalTotal.toStringAsFixed(1)}%', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, size: 16, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text('AI Pathway Recommendation:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(pathway ?? 'N/A', style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 12),
                _buildWeightBreakdown(score),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeightBreakdown(TransitionScore? score) {
    if (score == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _WeightMetric(label: 'G6 SBA', val: score.sbaGrade6.toStringAsFixed(1), weight: '20%'),
          _WeightMetric(label: 'G7 SBA', val: score.sbaGrade7.toStringAsFixed(1), weight: '10%'),
          _WeightMetric(label: 'G8 SBA', val: score.sbaGrade8.toStringAsFixed(1), weight: '10%'),
          _WeightMetric(label: 'G9 Exam', val: score.examGrade9.toStringAsFixed(1), weight: '60%'),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _WeightMetric extends StatelessWidget {
  final String label;
  final String val;
  final String weight;
  const _WeightMetric({required this.label, required this.val, required this.weight});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text('($weight)', style: const TextStyle(fontSize: 8, color: Colors.grey)),
      ],
    );
  }
}
