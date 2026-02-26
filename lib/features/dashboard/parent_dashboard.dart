// lib/features/dashboard/parent_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../data/models/student_model.dart';
import '../auth/auth_provider.dart';
import 'widgets/app_shell.dart';

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dbAsync = ref.watch(databaseProvider);

    return AppShell(
      title: 'Family Hub',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            _buildParentProfile(context, user),
            const SizedBox(height: 32),

            // ── Notice Board ────────────────────────────────────────────────
            _buildNoticeBoard(context, dbAsync),
            const SizedBox(height: 32),

            // ── My Children Section ─────────────────────────────────────────
            Text('My Children', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            dbAsync.when(
              data: (db) => _buildChildrenList(context, db),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),

            // ── Quick Links ──────────────────────────────────────────────────
            Text('Quick Services', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildServiceGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeBoard(BuildContext context, dynamic dbAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withRed(100)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text('Institutional Releases', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Academic records for Term 1 have been moderated and released for parent review.', 
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('View Official Memo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildParentProfile(BuildContext context, dynamic user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Text(user?.name.substring(0, 1).toUpperCase() ?? 'P', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(user?.name ?? 'Parent Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.notifications_none, size: 20)),
      ],
    );
  }

  Widget _buildChildrenList(BuildContext context, dynamic db) {
    return FutureBuilder<List<StudentModel>>(
      future: db.studentDao.findAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _EmptyChildrenState();
        }
        
        final children = snapshot.data!;
        return Column(
          children: children.map((child) => _ChildCard(child: child)).toList(),
        );
      },
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _ServiceTile(icon: Icons.receipt_long_outlined, label: 'Fee Statements', color: Colors.blue, onTap: () => context.push(Routes.statement)),
        _ServiceTile(icon: Icons.history_edu_outlined, label: 'Learning Progress', color: Colors.green, onTap: () {}),
        _ServiceTile(icon: Icons.health_and_safety_outlined, label: 'Medical History', color: Colors.red, onTap: () {}),
        _ServiceTile(icon: Icons.chat_bubble_outline, label: 'Teacher Chat', color: Colors.orange, onTap: () => context.push(Routes.messaging)),
      ],
    );
  }
}

class _ChildCard extends ConsumerWidget {
  final StudentModel child;
  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(child: Text(child.fullName.substring(0, 1).toUpperCase(), style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${child.grade} · UPI: ${child.upi}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const SizedBox(height: 6),
                    _ModerationStatusBadge(studentId: child.id),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModerationStatusBadge extends ConsumerWidget {
  final String studentId;
  const _ModerationStatusBadge({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(databaseProvider);
    return dbAsync.when(
      data: (db) => FutureBuilder<List>(
        future: db.assessmentDao.findForStudent(studentId, 1, '2026'),
        builder: (context, snapshot) {
          final assessments = snapshot.data ?? [];
          final moderated = assessments.where((a) => a.isModerated == 2).length;
          
          if (moderated == 0) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.shade200)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 10),
                const SizedBox(width: 4),
                Text('$moderated New Results Released', style: TextStyle(color: Colors.green.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ServiceTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _EmptyChildrenState extends StatelessWidget {
  const _EmptyChildrenState();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: const Column(
        children: [
          Icon(Icons.child_care_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('No children linked yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          Text('Contact the school admin to link your profile.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

