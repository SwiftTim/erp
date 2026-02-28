// lib/features/attendance/attendance_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/curriculum_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  final _uuid = const Uuid();
  late final String _today;

  List<StudentModel> _students = [];
  final Map<String, String> _attendance = {};
  bool _loading = true;
  bool _saving = false;
  SchoolClassModel? _class;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider)!;
    final todayEpoch = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0).millisecondsSinceEpoch;

    // 1. Check for Substitution Rights first
    final subs = await db.enterpriseDao.findActiveSubstitutions(user.id, todayEpoch);
    String? targetClassId = user.assignedClassId;
    
    if (subs.isNotEmpty) {
      // If teacher is subbing today, use the subbed class ID
      targetClassId = subs.first.classId;
    }

    if (targetClassId == null || targetClassId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final schoolClass = await db.curriculumDao.findClassById(targetClassId);
    final students = await db.studentDao.findByClass(targetClassId);
    final existingRecords = await db.attendanceDao.findForClassByDate(targetClassId, _today);

    if (mounted) {
      setState(() {
        _class = schoolClass;
        _students = students;
        for (final s in students) {
          final existing = existingRecords.where((r) => r.studentId == s.id).firstOrNull;
          _attendance[s.id] = existing?.status ?? AppConstants.present;
        }
        _loading = false;
      });
    }
  }


  Future<void> _save() async {
    setState(() => _saving = true);
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider)!;

    try {
      for (final s in _students) {
        final status = _attendance[s.id] ?? AppConstants.present;
        
        // ── AUTOMATED ABSENCE ALERTS ──
        if (status == AppConstants.absent && s.parentId != null) {
          final alertMessage = MessageModel(
            id: _uuid.v4(),
            senderId: 'SYSTEM',
            recipientId: s.parentId,
            subject: 'Attendance Alert: ${s.fullName}',
            body: '${s.fullName} was marked absent today (${_today}) during the morning roll call. Kindly verify with the teacher or administration.',
            sentAt: DateTime.now().millisecondsSinceEpoch,
            messageType: 'Direct',
          );
          await db.messagingDao.insertMessage(alertMessage);
        }

        // Use an "upsert" operation
        await db.attendanceDao.upsertAttendance(AttendanceModel(
          id: _uuid.v4(),
          studentId: s.id,
          classId: s.classId,
          date: _today,
          status: status,
          recordedBy: user.id,
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance recorded successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Roll Call — ${_class?.name ?? _today}',
      actions: [
        if (_class != null && _students.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              setState(() { for (var id in _attendance.keys) { _attendance[id] = AppConstants.present; } });
            },
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark All Present'),
          ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? _buildNoAssignmentState()
              : Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _students.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = _students[i];
                          final status = _attendance[s.id] ?? AppConstants.present;
                          return _AttendanceTile(
                            student: s,
                            status: status,
                            onChanged: (newVal) => setState(() => _attendance[s.id] = newVal),
                          );
                        },
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
    );
  }

  Widget _buildNoAssignmentState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_ind_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 24),
            const Text(
              'No Class Assigned',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have not been assigned as a Class Teacher for any class. Please contact the administration to be assigned a class for roll call.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Total', value: '${_students.length}'),
          _Stat(label: 'Present', value: '${_attendance.values.where((v) => v == AppConstants.present).length}', color: Colors.green),
          _Stat(label: 'Absent', value: '${_attendance.values.where((v) => v == AppConstants.absent).length}', color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Icon(Icons.cloud_upload_outlined),
        label: const Text('Save & Sync Attendance'),
        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final StudentModel student;
  final String status;
  final ValueChanged<String> onChanged;

  const _AttendanceTile({required this.student, required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: color.withOpacity(0.1),
        child: Text(student.fullName.substring(0, 1).toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
      title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(student.grade, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Present', label: Text('P', style: TextStyle(fontSize: 12))),
          ButtonSegment(value: 'Absent', label: Text('A', style: TextStyle(fontSize: 12))),
          ButtonSegment(value: 'Late', label: Text('L', style: TextStyle(fontSize: 12))),
        ],
        selected: {status},
        onSelectionChanged: (set) => onChanged(set.first),
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          selectedBackgroundColor: color,
          selectedForegroundColor: Colors.white,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'Absent') return Colors.red;
    if (status == 'Late') return Colors.orange;
    return AppTheme.primary;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
