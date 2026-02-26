// lib/features/assessment/hod_moderation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/assessment_model.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class HodModerationPage extends ConsumerStatefulWidget {
  const HodModerationPage({super.key});

  @override
  ConsumerState<HodModerationPage> createState() => _HodModerationPageState();
}

class _HodModerationPageState extends ConsumerState<HodModerationPage> {
  List<UserModel> _deptTeachers = [];
  Map<String, int> _pendingCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.departmentId == null) return;

    final db = await ref.read(databaseProvider.future);
    
    // 1. Get teachers in this department
    final teachers = await db.userDao.findAllActive();
    final deptTeachers = teachers.where((u) => u.departmentId == user.departmentId && u.id != user.id).toList();

    // 2. Get pending assessment counts
    final Map<String, int> counts = {};
    for (final t in deptTeachers) {
      final pending = await db.assessmentDao.findPendingModerationByDept(user.departmentId!);
      counts[t.id] = pending.where((a) => a.teacherId == t.id).length;
    }

    if (mounted) {
      setState(() {
        _deptTeachers = deptTeachers;
        _pendingCounts = counts;
        _loading = false;
      });
    }
  }

  Future<void> _approveAll(UserModel teacher) async {
    final hod = ref.read(currentUserProvider);
    if (hod == null) return;

    final db = await ref.read(databaseProvider.future);
    await db.assessmentDao.moderateAllForTeacher(teacher.id, hod.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assessments for ${teacher.name} moderated successfully')),
    );
    _loadData();
  }

  void _showTeacherAssessments(UserModel teacher) async {
    final assessments = await (await ref.read(databaseProvider.future)).assessmentDao.findSubmittedForTeacher(teacher.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scroll) => _ModerationReviewSheet(
          teacher: teacher,
          assessments: assessments,
          onAction: _loadData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dept = user?.departmentId ?? 'Department';

    return AppShell(
      title: 'HOD Moderation — $dept',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _deptTeachers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _deptTeachers.length,
                  itemBuilder: (context, i) {
                    final t = _deptTeachers[i];
                    final pending = _pendingCounts[t.id] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        onTap: pending > 0 ? () => _showTeacherAssessments(t) : null,
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(t.name.substring(0, 1).toUpperCase(), 
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.email, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: pending > 0 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                pending > 0 ? '$pending Pending Review' : 'All Moderated',
                                style: TextStyle(
                                  fontSize: 11, 
                                  fontWeight: FontWeight.bold,
                                  color: pending > 0 ? Colors.orange : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: pending > 0 
                          ? FilledButton.tonal(
                              onPressed: () => _approveAll(t),
                              child: const Text('Moderate All'),
                            )
                          : const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No pending reviews in your department.', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ModerationReviewSheet extends ConsumerStatefulWidget {
  final UserModel teacher;
  final List<AssessmentModel> assessments;
  final VoidCallback onAction;
  const _ModerationReviewSheet({required this.teacher, required this.assessments, required this.onAction});

  @override
  ConsumerState<_ModerationReviewSheet> createState() => _ModerationReviewSheetState();
}

class _ModerationReviewSheetState extends ConsumerState<_ModerationReviewSheet> {
  Future<void> _moderate(String assessmentId) async {
    final db = await ref.read(databaseProvider.future);
    final hod = ref.read(currentUserProvider)!;
    await db.assessmentDao.moderate(assessmentId, hod.id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record Released')));
    widget.onAction();
    Navigator.pop(context);
  }

  Future<void> _reject(String assessmentId) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Assessment'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Reason / Feedback for Teacher'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm Reject')),
        ],
      ),
    );

    if (confirm == true && reasonCtrl.text.isNotEmpty) {
      final db = await ref.read(databaseProvider.future);
      final hod = ref.read(currentUserProvider)!;
      await db.assessmentDao.reject(assessmentId, hod.id, reasonCtrl.text);
      widget.onAction();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reviewing: ${widget.teacher.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: widget.assessments.length,
              itemBuilder: (context, i) {
                final a = widget.assessments[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Score: ${AppConstants.rubricCode[a.score]}', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.rubricColor(a.score))),
                            Text(DateTime.fromMillisecondsSinceEpoch(a.dateRecorded).toString().substring(0, 10)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(a.teacherRemarks ?? 'No remarks provided.', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton(onPressed: () => _reject(a.id), child: const Text('Reject', style: TextStyle(color: Colors.red)))),
                            const SizedBox(width: 12),
                            Expanded(child: FilledButton(onPressed: () => _moderate(a.id), child: const Text('Approve & Release'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
