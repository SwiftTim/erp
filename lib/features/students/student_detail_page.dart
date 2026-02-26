// lib/features/students/student_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../dashboard/widgets/app_shell.dart';

import '../../data/models/student_model.dart';
import '../../data/models/assessment_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/finance_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'package:intl/intl.dart';

class StudentDetailPage extends ConsumerStatefulWidget {
  final String id;
  const StudentDetailPage({super.key, required this.id});

  @override
  ConsumerState<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends ConsumerState<StudentDetailPage> {
  StudentModel? _student;
  List<AssessmentModel> _assessments = [];
  double _totalPaid = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final student = await db.studentDao.findById(widget.id);
    if (student != null) {
      final assessments = await db.assessmentDao.findForStudent(student.id, 1, '2026');
      final paid = await db.financeDao.totalPaid(student.id);
      
      setState(() {
        _student = student;
        _assessments = assessments;
        _totalPaid = paid ?? 0;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_student == null) return const Scaffold(body: Center(child: Text('Student not found')));

    return AppShell(
      title: 'Learner Profile',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildDetailsTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Text(_student!.fullName[0].toUpperCase(), 
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ),
        const SizedBox(height: 16),
        Text(_student!.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('UPI: ${_student!.upi}  •  ${_student!.grade}', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
          child: const Text('ACTIVE STUDENT', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(icon: Icons.edit_note, label: 'Assess', color: Colors.blue, 
          onTap: () => context.push(Routes.matrix)),
        _ActionButton(icon: Icons.payment, label: 'Pay Fee', color: Colors.green, 
          onTap: () => context.push(Routes.ledger.replaceAll(':studentId', _student!.id))),
        _ActionButton(icon: Icons.camera_alt_outlined, label: 'Evidence', color: Colors.purple, 
          onTap: () => context.push(Routes.evidence.replaceAll(':studentId', _student!.id))),
      ],
    );
  }

  Widget _buildDetailsTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Academic'),
              Tab(text: 'Financial'),
              Tab(text: 'Bio-Data'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildAcademicView(),
                _buildFinancialView(),
                _buildBioView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicView() {
    if (_assessments.isEmpty) return const Center(child: Text('No assessments recorded yet.'));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _assessments.length,
      itemBuilder: (context, i) {
        final a = _assessments[i];
        final color = AppTheme.rubricColor(a.score);
        return Card(
          child: ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(AppConstants.rubricCode[a.score]!, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
            ),
            title: Text('Learning Area Code: ${a.subStrandId}'),
            subtitle: Text('Recorded on ${DateFormat('MMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(a.dateRecorded))}'),
          ),
        );
      },
    );
  }

  Widget _buildFinancialView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _FinanceBrief(label: 'Total Paid', amount: _totalPaid, color: Colors.green),
          const SizedBox(height: 12),
          const _FinanceBrief(label: 'Balance Remaining', amount: 15000, color: Colors.red),
          const Spacer(),
          OutlinedButton(
            onPressed: () => context.push(Routes.ledger.replaceAll(':studentId', _student!.id)),
            child: const Text('View Detailed Statement'),
          ),
        ],
      ),
    );
  }

  Widget _buildBioView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _BioRow(label: 'D.O.B', value: _student!.dob),
          _BioRow(label: 'Gender', value: _student!.gender),
          _BioRow(label: 'Admission Date', value: DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(_student!.createdAt))),
          _BioRow(label: 'Class ID', value: _student!.classId),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _FinanceBrief extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _FinanceBrief({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('KES ${NumberFormat("#,##0").format(amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _BioRow extends StatelessWidget {
  final String label;
  final String value;
  const _BioRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
