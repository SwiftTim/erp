// lib/features/students/students_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/student_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/services/archiving_service.dart';


class StudentsListPage extends ConsumerStatefulWidget {
  const StudentsListPage({super.key});

  @override
  ConsumerState<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends ConsumerState<StudentsListPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterGrade;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canAdd = (user?.roleLevel ?? 5) <= AppConstants.roleTeacher;
    final dbAsync = ref.watch(databaseProvider);

    return AppShell(
      title: 'Students',
      actions: [
        if (user != null && user.roleLevel <= 2)
          IconButton(
            icon: const Icon(Icons.upgrade_outlined),
            tooltip: 'End of Year Promotion Workflow',
            onPressed: () => _confirmPromoteAll(context, user.id, ref),
          ),
        if (canAdd)
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Register Student',
            onPressed: () => context.push(Routes.studentNew),
          ),
      ],
      body: Column(
        children: [
          _buildSearchAndFilterBar(context),
          Expanded(
            child: dbAsync.when(
              data: (db) => _buildStudentList(db),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.studentNew),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Register Student'),
            )
          : null,
    );
  }

  Future<void> _confirmPromoteAll(BuildContext context, String executorId, WidgetRef ref) async {
    final act = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Execute Master Promotion')]),
        content: const Text('Are you sure you want to promote the **ENTIRE** student body to the next respective grade level? Grade 9 learners will graduate.\n\nAll specific class pairings will be cleared for the new year. This action is not easily reversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.upgrade), label: const Text('Confirm Promote All')),
        ],
      )
    );

    if (act == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Executing Multi-Year Archiving... Do not close.')));
      await ref.read(archivingServiceProvider).promoteAllStudents(executorId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End of Year workflow completed.'), backgroundColor: Colors.green));
    }
  }

  Widget _buildSearchAndFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by name or UPI...',
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String?>(
              value: _filterGrade,
              hint: const Text('All Grades', style: TextStyle(fontSize: 13)),
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, size: 20),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Grades')),
                ...AppConstants.allGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))),
              ],
              onChanged: (v) => setState(() => _filterGrade = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(dynamic db) {
    return StreamBuilder<List<StudentModel>>(
      // In production, you'd use a reactive stream from Floor. 
      // For now we'll use a Future and convert to a stream-like behavior.
      stream: Stream.fromFuture(db.studentDao.findAll()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final students = snapshot.data!.where((s) {
          final matchesQuery = s.fullName.toLowerCase().contains(_query) || s.upi.toLowerCase().contains(_query);
          final matchesGrade = _filterGrade == null || s.grade == _filterGrade;
          return matchesQuery && matchesGrade;
        }).toList();

        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(_query.isEmpty ? 'No students registered Yet' : 'No results for "$_query"', 
                  style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, i) {
            final s = students[i];
            return StudentListTile(
              student: s,
              onTap: () => context.push(Routes.studentDetail.replaceFirst(':id', s.id)),
            );
          },
        );
      },
    );
  }
}

class StudentListTile extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;

  const StudentListTile({super.key, required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Text(student.fullName.substring(0, 1).toUpperCase(), 
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ),
        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(student.grade, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSecondaryContainer)),
              ),
              const SizedBox(width: 8),
              Text('UPI: ${student.upi}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
