// lib/features/dashboard/teacher_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_provider.dart';
import 'widgets/app_shell.dart';
import 'widgets/stat_card.dart';
import 'widgets/sync_badge.dart';
import '../../data/models/enterprise_models.dart';
import '../../core/services/audit_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../../data/models/timetable_models.dart';
import '../../services/teaching_pipeline_service.dart';
import 'package:uuid/uuid.dart';

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dbAsync = ref.watch(databaseProvider);
    
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : now.hour < 17 ? 'Good afternoon' : 'Good evening';

    return AppShell(
      title: 'Teacher Home',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            _buildHeading(context, greeting, user),
            const SizedBox(height: 24),

            // ── Staff Clock-In/Out ──────────────────────────────────────────
            dbAsync.when(
              data: (db) => _StaffPresenceWidget(db: db, userId: user?.id),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // ── Today's Schedule Glance ────────────────────────────────────
            if (user != null)
              _TeacherScheduleCard(userId: user.id),
            const SizedBox(height: 20),

            // ── Real-time Stats from DB ─────────────────────────────────────
            dbAsync.when(
              data: (db) => _buildStats(db, user?.id),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading stats: $e'),
            ),
            const SizedBox(height: 20),

            // ── Approval Workflow Prompt ───────────────────────────────────
            dbAsync.when(
              data: (db) => _buildModerationPrompt(context, db, user?.id),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 28),

            // ── Quick Action Grid ───────────────────────────────────────────
            Text('Quick Launch', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildActionGrid(context, user),
            const SizedBox(height: 28),

            // ── Recent Activity Placeholder ────────────────────────────────
            _buildRecentActivity(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.assessment),
        icon: const Icon(Icons.add),
        label: const Text('Record Assessment'),
      ),
    );
  }

  Widget _buildHeading(BuildContext context, String greeting, dynamic user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$greeting,', style: Theme.of(context).textTheme.titleLarge),
            Text(user?.name ?? 'Teacher', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ],
        ),
        const SyncBadge(),
      ],
    );
  }

  Widget _buildModerationPrompt(BuildContext context, dynamic db, String? userId) {
    if (userId == null) return const SizedBox.shrink();
    
    return FutureBuilder<int?>(
      future: db.assessmentDao.countDraftsForTeacher(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.pending_actions, color: Colors.orange),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$count Draft Assessments', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const Text('Results are hidden from parents until submitted and moderated.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () async {
                   await db.assessmentDao.submitAllForTeacher(userId);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessments submitted to HOD.')));
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Submit all'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats(dynamic db, String? userId) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<int?>(
            future: db.studentDao.countAll(),
            builder: (context, snapshot) => StatCard(
              label: 'My Students',
              value: '${snapshot.data ?? 0}',
              icon: Icons.people_outline,
              trend: 'Active',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<int?>(
            future: userId != null ? db.assessmentDao.countDraftsForTeacher(userId) : Future.value(0),
            builder: (context, snapshot) => StatCard(
              label: 'Unsubmitted Drafts',
              value: '${snapshot.data ?? 0}',
              icon: Icons.assignment_outlined,
              color: (snapshot.data ?? 0) > 0 ? Colors.orange : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, UserModel? user) {
    final isClassTeacher = user?.hasFlag(AppConstants.flagClassTeacher) == true && user?.assignedClassId != null;
    final isClubAdvisor = user?.hasFlag(AppConstants.flagClubAdvisor) == true;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        if (isClassTeacher)
          _ActionTile(
            icon: Icons.how_to_reg_outlined,
            title: 'Class Roll Call',
            subtitle: 'Room: ${user!.assignedClassId}',
            color: Colors.orange,
            onTap: () => context.push(Routes.attendance),
          ),
        _ActionTile(
          icon: Icons.edit_calendar_outlined,
          title: 'CBC Assessments',
          subtitle: 'Daily entries',
          color: AppTheme.primary,
          onTap: () => context.push(Routes.assessment),
        ),
        _ActionTile(
          icon: Icons.grid_on_outlined,
          title: 'Rubric Matrix',
          subtitle: 'Batch marking',
          color: Colors.purple,
          onTap: () => context.push(Routes.matrix),
        ),
        if (isClassTeacher)
          _ActionTile(
            icon: Icons.library_books_outlined,
            title: 'Syllabus Tracker',
            subtitle: 'Module coverage',
            color: Colors.indigo,
            onTap: () => context.push(Routes.syllabus),
          ),

        if (isClubAdvisor)
          _ActionTile(
            icon: Icons.groups_outlined,
            title: 'My Clubs',
            subtitle: 'Advisor portal',
            color: Colors.teal,
            onTap: () => context.push(Routes.clubs),
          ),
        _ActionTile(
          icon: Icons.photo_library_outlined,
          title: 'Evidence Vault',
          subtitle: 'Upload media',
          color: Colors.blue,
          onTap: () => context.push('/evidence/select'),
        ),
        _ActionTile(
          icon: Icons.corporate_fare_outlined,
          title: 'Department',
          subtitle: 'HOD portal',
          color: Colors.brown,
          onTap: () => context.push(Routes.departments),
        ),
        _ActionTile(
          icon: Icons.monetization_on_outlined,
          title: 'Loan Requests',
          subtitle: 'Staff advances',
          color: Colors.amber.shade700,
          onTap: () => context.push(Routes.staffLoanRequest),
        ),
        _ActionTile(
          icon: Icons.shopping_cart_checkout_outlined,
          title: 'Store Request',
          subtitle: 'Class resources',
          color: Colors.teal.shade700,
          onTap: () => context.push(Routes.teacherProcurementRequest),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, color: Colors.grey, size: 40),
                  SizedBox(height: 8),
                  Text('No recent assessments recorded.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon, 
    required this.title, 
    required this.subtitle,
    required this.color, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, 
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1),
            Text(subtitle, 
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _StaffPresenceWidget extends ConsumerStatefulWidget {
  final dynamic db;
  final String? userId;
  const _StaffPresenceWidget({required this.db, this.userId});

  @override
  ConsumerState<_StaffPresenceWidget> createState() => _StaffPresenceWidgetState();
}

class _StaffPresenceWidgetState extends ConsumerState<_StaffPresenceWidget> {
  StaffAttendance? _attendance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    if (widget.userId == null) return;
    final today = int.parse(DateTime.now().year.toString() + 
                 DateTime.now().month.toString().padLeft(2, '0') + 
                 DateTime.now().day.toString().padLeft(2, '0'));
    
    final record = await widget.db.enterpriseDao.findStaffAttendance(widget.userId!, today);
    if (mounted) {
      setState(() {
        _attendance = record;
        _loading = false;
      });
    }
  }

  Future<void> _clockIn() async {
    final today = int.parse(DateTime.now().year.toString() + 
                 DateTime.now().month.toString().padLeft(2, '0') + 
                 DateTime.now().day.toString().padLeft(2, '0'));
                 
    final record = StaffAttendance(
      id: const Uuid().v4(),
      staffId: widget.userId!,
      date: today,
      clockIn: DateTime.now().millisecondsSinceEpoch,
    );

    await widget.db.enterpriseDao.clockIn(record);
    ref.read(auditServiceProvider).log('STAFF_CLOCK_IN', 'Personnel', 'Logged daily arrival');
    _loadStatus();
  }

  Future<void> _clockOut() async {
    if (_attendance == null) return;
    
    final updated = StaffAttendance(
      id: _attendance!.id,
      staffId: _attendance!.staffId,
      date: _attendance!.date,
      clockIn: _attendance!.clockIn,
      clockOut: DateTime.now().millisecondsSinceEpoch,
    );

    await widget.db.enterpriseDao.clockOut(updated);
    ref.read(auditServiceProvider).log('STAFF_CLOCK_OUT', 'Personnel', 'Logged daily departure');
    _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || widget.userId == null) return const SizedBox.shrink();

    final isClockedIn = _attendance != null;
    final isClockedOut = _attendance?.clockOut != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isClockedOut ? Colors.grey.shade200 : AppTheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isClockedOut ? Colors.grey.shade100 : (isClockedIn ? Colors.green.shade100 : AppTheme.primary.withOpacity(0.1)),
              child: Icon(
                isClockedOut ? Icons.bedtime_outlined : (isClockedIn ? Icons.login : Icons.access_time),
                color: isClockedOut ? Colors.grey : (isClockedIn ? Colors.green : AppTheme.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isClockedOut ? 'Shift Ended' : (isClockedIn ? 'On Campus' : 'Not Clocked In'),
                    style: TextStyle(fontWeight: FontWeight.bold, color: isClockedOut ? Colors.grey : (isClockedIn ? Colors.green : Colors.black)),
                  ),
                  if (isClockedIn)
                    Text(
                      'Arrived at ${DateTime.fromMillisecondsSinceEpoch(_attendance!.clockIn).toLocal().toString().substring(11, 16)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (!isClockedOut)
              FilledButton(
                onPressed: isClockedIn ? _clockOut : _clockIn,
                style: FilledButton.styleFrom(
                  backgroundColor: isClockedIn ? Colors.red.shade400 : AppTheme.primary,
                ),
                child: Text(isClockedIn ? 'Clock Out' : 'Clock In'),
              ),
            if (isClockedOut)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _TeacherScheduleCard extends ConsumerWidget {
  final String userId;
  const _TeacherScheduleCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<TimetableSlot?>(
      future: ref.read(teachingPipelineServiceProvider).getActiveSlotForTeacher(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
        final slot = snapshot.data;

        return InkWell(
          onTap: () => context.push(Routes.teacherTimetable),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slot != null ? [AppTheme.primary, AppTheme.primaryLight] : [Colors.grey.shade400, Colors.grey.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: (slot != null ? AppTheme.primary : Colors.grey).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(slot != null ? Icons.play_lesson_outlined : Icons.timer_outlined, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(slot != null ? 'ACTIVE LESSON NOW' : 'NEXT LESSON PENDING', 
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(slot?.subjectId ?? 'No active lesson', 
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                if (slot != null)
                  Text('Class: ${slot.classId} • Period ${slot.periodNumber}', 
                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('View Full Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
