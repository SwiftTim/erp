// lib/features/admissions/admissions_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/student_model.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class AdmissionsDashboardPage extends ConsumerStatefulWidget {
  const AdmissionsDashboardPage({super.key});

  @override
  ConsumerState<AdmissionsDashboardPage> createState() => _AdmissionsDashboardPageState();
}

class _AdmissionsDashboardPageState extends ConsumerState<AdmissionsDashboardPage> {
  List<StudentModel> _recentStudents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final students = await db.studentDao.findAll();
    // Sort by creation date if available, or just take last 10
    final recent = students.reversed.take(10).toList();
    
    if (mounted) {
      setState(() {
        _recentStudents = recent;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Admissions & Enrollment',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.studentNew),
        label: const Text('New Admission'),
        icon: const Icon(Icons.person_add_alt_outlined),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                _buildQuickStats(),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Recent Admissions', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                _buildStudentsList(),
              ],
            ),
          ),
    );
  }

  Widget _buildQuickStats() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard('Total Enrolled', '${_recentStudents.length}', Icons.groups, Colors.blue),
          _buildStatCard('Pending UPI', '2', Icons.badge_outlined, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final s = _recentStudents[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(child: Text(s.fullName[0])),
              title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${s.grade} • UPI: ${s.upi}'),
              trailing: IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                onPressed: () => _printAdmissionLetter(s),
                tooltip: 'Print Admission Letter',
              ),
              onTap: () => context.push(Routes.studentDetail.replaceAll(':id', s.id)),
            ),
          );
        },
        childCount: _recentStudents.length,
      ),
    );
  }

  void _printAdmissionLetter(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admission Letter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generating official admission letter for:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Grade: ${student.grade}'),
            Text('UPI: ${student.upi}'),
            const Divider(height: 32),
            const Text('Status: Ready for Printing', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to Printer...')));
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Now'),
          ),
        ],
      ),
    );
  }
}
