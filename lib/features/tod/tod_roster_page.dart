import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/widgets/app_shell.dart';
import 'tod_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';
import '../../core/constants/app_constants.dart';

class TodRosterPage extends ConsumerWidget {
  const TodRosterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(dutyRosterProvider);
    final todService = ref.watch(todServiceProvider);

    return AppShell(
      title: 'Teacher Duty Roster',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(dutyRosterProvider),
        ),
      ],
      body: rosterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (rosters) {
          if (rosters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No duty roster generated yet'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await todService.generateRotation();
                      ref.invalidate(dutyRosterProvider);
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Auto-Generate Roster'),
                  ),
                ],
              ),
            );
          }

          // Group by week
          final grouped = <int, List<dynamic>>{};
          for (var r in rosters) {
            grouped.putIfAbsent(r.weekNumber, () => []).add(r);
          }
          final sortedWeeks = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedWeeks.length,
            itemBuilder: (context, index) {
              final week = sortedWeeks[index];
              final weekRosters = grouped[week]!;
              final startDate = DateTime.fromMillisecondsSinceEpoch(weekRosters.first.startDate);
              final endDate = DateTime.fromMillisecondsSinceEpoch(weekRosters.first.endDate);
              final dateRange = "${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}";

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      tileColor: Theme.of(context).primaryColor.withOpacity(0.05),
                      title: Text('Week $week', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(dateRange),
                      trailing: const Icon(Icons.calendar_view_week),
                    ),
                    const Divider(height: 1),
                    ...weekRosters.map((r) => FutureBuilder<UserModel?>(
                      future: _getTeacher(ref, r.teacherId),
                      builder: (context, snapshot) {
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person, size: 20)),
                          title: Text(snapshot.data?.name ?? 'Loading...'),
                          subtitle: const Text('Duty Teacher'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showOverrideDialog(context, ref, r.id),
                          ),
                        );
                      },
                    )),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await todService.generateRotation();
          ref.invalidate(dutyRosterProvider);
        },
        label: const Text('Extend Roster'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<UserModel?> _getTeacher(WidgetRef ref, String id) async {
    final db = await ref.read(databaseProvider.future);
    return db.userDao.findById(id);
  }

  void _showOverrideDialog(BuildContext context, WidgetRef ref, String rosterId) {
    // Basic implementation: show list of teachers to pick from
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Duty Teacher'),
        content: FutureBuilder<List<UserModel>>(
          future: _getAllTeachers(ref),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, i) {
                  final t = snapshot.data![i];
                  return ListTile(
                    title: Text(t.name),
                    onTap: () async {
                      await ref.read(todServiceProvider).overrideRoster(rosterId, t.id);
                      ref.invalidate(dutyRosterProvider);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<List<UserModel>> _getAllTeachers(WidgetRef ref) async {
    final db = await ref.read(databaseProvider.future);
    final users = await db.userDao.findAllActive();
    return users.where((u) => 
      u.roleLevel == AppConstants.roleTeacher || 
      u.roleLevel == AppConstants.roleSeniorTeacher
    ).toList();
  }
}
