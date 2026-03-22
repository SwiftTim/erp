import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/student_model.dart';
import '../dashboard/widgets/app_shell.dart';
import '../auth/auth_provider.dart';
import 'tod_provider.dart';

class TodWatchlistPage extends ConsumerWidget {
  final String statusFilter; // 'Amber' or 'Red'

  const TodWatchlistPage({super.key, required this.statusFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final behaviorAsync = ref.watch(studentBehaviorProvider);
    final color = statusFilter == 'Red' ? Colors.red : Colors.orange;

    return AppShell(
      title: '$statusFilter Watchlist',
      body: behaviorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (behaviors) {
          final filtered = behaviors.where((b) => b.status == statusFilter).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade200),
                   const SizedBox(height: 16),
                   Text('No students on $statusFilter Watchlist'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final b = filtered[i];
              return FutureBuilder<StudentModel?>(
                future: _getStudent(ref, b.studentId),
                builder: (context, snapshot) {
                  final student = snapshot.data;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(Icons.warning_amber_rounded, color: color),
                      ),
                      title: Text(student?.fullName ?? 'Loading...'),
                      subtitle: Text('${student?.grade ?? ""} • ${b.weeklyOffences} incidents this week'),
                      trailing: statusFilter == 'Red' 
                        ? ElevatedButton(
                            onPressed: () => _showEscalationDialog(context, student?.fullName ?? ""),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Escalate'),
                          )
                        : TextButton(
                            onPressed: () {},
                            child: const Text('Call Student'),
                          ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<StudentModel?> _getStudent(WidgetRef ref, String id) async {
    final db = await ref.read(databaseProvider.future);
    return db.studentDao.findById(id);
  }

  void _showEscalationDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escalate to Headteacher'),
        content: Text('Send discipline report for $name to the Headteacher for further action?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalated successfully')));
            },
            child: const Text('Confirm Escalation'),
          ),
        ],
      ),
    );
  }
}
