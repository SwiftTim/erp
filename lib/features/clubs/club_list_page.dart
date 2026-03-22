// lib/features/clubs/club_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/dashboard/widgets/app_shell.dart';
import '../../data/models/club_model.dart';
import '../../data/models/user_model.dart';
import '../../data/local/app_database.dart';
import 'club_service.dart';

class ClubListPage extends ConsumerStatefulWidget {
  const ClubListPage({super.key});

  @override
  ConsumerState<ClubListPage> createState() => _ClubListPageState();
}

class _ClubListPageState extends ConsumerState<ClubListPage> {
  int _refreshKey = 0;

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final service = ref.watch(clubServiceProvider);

    return AppShell(
      title: 'Clubs & Societies',
      actions: [
        if (user?.roleLevel != null && user!.roleLevel <= 3) // HOD/Admin
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Initialize Default Clubs',
            onPressed: () => _handleSeed(service),
          ),
      ],
      body: FutureBuilder<List<ClubModel>>(
        key: ValueKey(_refreshKey),
        future: _loadClubs(ref, user?.id, user?.roleLevel),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final clubs = snapshot.data ?? [];

          if (clubs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No clubs found.'),
                  if (user?.roleLevel != null && user!.roleLevel <= 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: () => _handleSeed(service),
                        child: const Text('Initialize Default Clubs'),
                      ),
                    ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              final c = clubs[index];
              final isAdmin = user?.roleLevel != null && user!.roleLevel <= 3;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => context.push('/clubs/${c.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _getCategoryColor(c.category).withOpacity(0.1),
                              child: Icon(_getCategoryIcon(c.category), color: _getCategoryColor(c.category), size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                  const SizedBox(height: 4),
                                  Text(c.category, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                            FutureBuilder<double>(
                              future: service.calculateClubHealth(c.id),
                              builder: (context, snap) {
                                final health = snap.data ?? 0;
                                return _HealthGauge(score: health);
                              }
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: FutureBuilder<UserModel?>(
                                future: c.patronId == null ? Future.value(null) : 
                                       ref.read(databaseProvider.future).then((db) => db.userDao.findById(c.patronId!)),
                                builder: (context, snap) {
                                  return Text(
                                    'Patron: ${snap.data?.name ?? "Not Assigned"}',
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  );
                                }
                              ),
                            ),
                            FutureBuilder<List<ClubMemberModel>>(
                              future: ref.read(databaseProvider.future).then((db) => db.clubDao.getMembersByClub(c.id)),
                              builder: (context, snap) {
                                final count = snap.data?.length ?? 0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('$count Members', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                );
                              }
                            ),
                          ],
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.person_add_alt_1, size: 18),
                                label: const Text('Assign Patron'),
                                onPressed: () => _showAssignPatron(c),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.event_note, size: 18),
                                label: const Text('Schedule'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onPressed: () => _showScheduleMeeting(c),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleSeed(ClubService service) async {
    final status = await service.seedDefaultClubs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status),
        backgroundColor: status.contains('Success') ? Colors.green : Colors.orange,
      ));
      _refresh();
    }
  }

  void _showAssignPatron(ClubModel club) async {
    final db = await ref.read(databaseProvider.future);
    final teachers = await db.userDao.findByRole(AppConstants.roleTeacher);
    final seniors = await db.userDao.findByRole(AppConstants.roleSeniorTeacher);
    final all = [...seniors, ...teachers];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Assign Club Patron', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: all.length,
                itemBuilder: (context, index) {
                  final t = all[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(t.name),
                    subtitle: Text(t.departmentId ?? 'No Department'),
                    selected: t.id == club.patronId,
                    onTap: () async {
                      await ref.read(clubServiceProvider).updateClubPatron(club.id, t.id);
                      if (mounted) {
                        Navigator.pop(context);
                        _refresh();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patron assigned successfully.')));
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleMeeting(ClubModel club) {
    final titleController = TextEditingController(text: 'General Meeting');
    final descController = TextEditingController();
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Schedule for ${club.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Activity Title')),
            const SizedBox(height: 8),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Agenda / Description')),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(date.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) date = d;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              await db.clubDao.insertActivity(ClubActivityModel(
                id: Uuid().v4(),
                clubId: club.id,
                title: titleController.text,
                description: descController.text,
                type: 'Meeting',
                scheduledAt: date.millisecondsSinceEpoch,
                venue: 'School Grounds',
                recordedAt: DateTime.now().millisecondsSinceEpoch,
              ));
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity scheduled successfully.')));
              }
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  Future<List<ClubModel>> _loadClubs(WidgetRef ref, String? userId, int? roleLevel) async {
    final db = await ref.read(databaseProvider.future);
    if (userId == null) return [];
    
    if (roleLevel != null && roleLevel <= 3) {
      return db.clubDao.getAllClubs(); // Admin/Deputy see all
    } else {
      return db.clubDao.getClubsByPatron(userId); // Patrons see their own
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Academic': return Colors.blue;
      case 'Arts': return Colors.purple;
      case 'Sports': return Colors.green;
      case 'Leadership': return Colors.orange;
      case 'Special Interest': return Colors.teal;
      default: return AppTheme.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Academic': return Icons.menu_book_outlined;
      case 'Arts': return Icons.palette_outlined;
      case 'Sports': return Icons.sports_soccer_outlined;
      case 'Leadership': return Icons.gavel_outlined;
      case 'Special Interest': return Icons.volunteer_activism_outlined;
      default: return Icons.groups_outlined;
    }
  }
}

class _HealthGauge extends StatelessWidget {
  final double score;
  const _HealthGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.red;
    if (score > 70) color = Colors.green;
    else if (score > 40) color = Colors.orange;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          width: 36,
          child: CircularProgressIndicator(
            value: score / 100,
            backgroundColor: color.withOpacity(0.2),
            color: color,
            strokeWidth: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text('${score.toInt()}%', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

