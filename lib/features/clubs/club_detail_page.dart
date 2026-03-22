// lib/features/clubs/club_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_provider.dart';
import '../../data/models/club_model.dart';
import '../../data/models/student_model.dart';
import '../../data/local/app_database.dart';
import 'club_service.dart';

class ClubDetailPage extends ConsumerStatefulWidget {
  final String clubId;
  const ClubDetailPage({super.key, required this.clubId});

  @override
  ConsumerState<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends ConsumerState<ClubDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ClubModel? _club;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadClub();
  }

  Future<void> _loadClub() async {
    final db = await ref.read(databaseProvider.future);
    final club = await db.clubDao.getClubById(widget.clubId);
    setState(() {
      _club = club;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_club == null) return const Scaffold(body: Center(child: Text('Club not found')));

    return Scaffold(
      appBar: AppBar(
        title: Text(_club!.name),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 24),
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Add Members'),
            Tab(text: 'Activities'),
            Tab(text: 'Attendance'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MembersTab(club: _club!),
          _AddMembersTab(club: _club!),
          _ActivitiesTab(club: _club!),
          _AttendanceTab(club: _club!),
          _ReportsTab(club: _club!),
        ],
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final ClubModel club;
  const _MembersTab({required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<ClubMemberModel>>(
      future: ref.read(databaseProvider.future).then((db) => db.clubDao.getMembersByClub(club.id)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final members = snapshot.data!;
        if (members.isEmpty) return const Center(child: Text('No members yet.'));

        return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final m = members[index];
              return FutureBuilder<StudentModel?>(
                future: ref.read(databaseProvider.future).then((db) => db.studentDao.findById(m.studentId)),
                builder: (context, sSnap) {
                  final s = sSnap.data;
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(s?.fullName ?? 'Loading...'),
                    subtitle: Row(
                      children: [
                        Text(m.role),
                        const SizedBox(width: 8),
                        Icon(m.consentFormSigned ? Icons.assignment_turned_in : Icons.assignment_outlined, 
                          size: 14, color: m.consentFormSigned ? Colors.green : Colors.grey),
                        const SizedBox(width: 4),
                        Icon(m.parentContactVerified ? Icons.verified_user : Icons.no_accounts, 
                          size: 14, color: m.parentContactVerified ? Colors.blue : Colors.grey),
                      ],
                    ),
                    onTap: () => _editRole(context, ref, m),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                      onPressed: () => _confirmRemove(context, ref, s?.fullName ?? 'Student', m.studentId),
                    ),
                  );
                },
              );
            });
      },
    );
  }

  void _editRole(BuildContext context, WidgetRef ref, ClubMemberModel m) {
    final List<String> roles = ['Member', 'Chairperson', 'Secretary', 'Treasurer', 'Class Rep', 'HOD'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Assign Role'),
        children: roles.map((r) => SimpleDialogOption(
          onPressed: () async {
            final db = await ref.read(databaseProvider.future);
            await db.clubDao.insertMember(m.copyWith(role: r)); // Floor @insert with Replace
            Navigator.pop(ctx);
          },
          child: Text(r),
        )).toList(),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, String name, String studentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $name from ${club.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(clubServiceProvider).removeMember(club.id, studentId);
              Navigator.pop(ctx);
              // Trigger refresh - ideally use a StateProvider for members
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddMembersTab extends ConsumerStatefulWidget {
  final ClubModel club;
  const _AddMembersTab({required this.club});

  @override
  ConsumerState<_AddMembersTab> createState() => _AddMembersTabState();
}

class _AddMembersTabState extends ConsumerState<_AddMembersTab> {
  String _searchQuery = '';
  String? _selectedGrade;
  final Set<String> _selectedIds = {};

  final List<String> _validGrades = [
    'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Filter by Grade',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      value: _selectedGrade,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Grades (4-9)')),
                        ..._validGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))),
                      ],
                      onChanged: (v) => setState(() => _selectedGrade = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() {
                      _selectedGrade = null;
                      _searchQuery = '';
                      _selectedIds.clear();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or Admission No...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<StudentModel>>(
            future: ref.read(databaseProvider.future).then((db) => db.clubDao.getEligibleStudentsForClub(widget.club.id)),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final all = snapshot.data!;
              final filtered = all.where((s) {
                final matchSearch = s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                  s.upi.contains(_searchQuery);
                final matchGrade = _selectedGrade == null || s.grade == _selectedGrade;
                return matchSearch && matchGrade;
              }).toList();

              if (filtered.isEmpty) return const Center(child: Text('No eligible students found.'));

              return Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Select All Filtered', style: TextStyle(fontWeight: FontWeight.bold)),
                    value: filtered.every((s) => _selectedIds.contains(s.id)),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.addAll(filtered.map((s) => s.id));
                        } else {
                          for (var s in filtered) {
                            _selectedIds.remove(s.id);
                          }
                        }
                      });
                    },
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final s = filtered[index];
                        return CheckboxListTile(
                          title: Text(s.fullName),
                          subtitle: Text('${s.grade} - ${s.upi}'),
                          value: _selectedIds.contains(s.id),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) _selectedIds.add(s.id);
                              else _selectedIds.remove(s.id);
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _addSelected,
              child: Text('Add Selected Members (${_selectedIds.length})'),
            ),
          ),
      ],
    );
  }

  void _addSelected() async {
    final user = ref.read(currentUserProvider);
    final service = ref.read(clubServiceProvider);
    
    int success = 0;
    String? lastError;

    for (var id in _selectedIds) {
      final error = await service.addMember(widget.club.id, id, user?.id ?? 'system');
      if (error == null) success++;
      else lastError = error;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Added $success members. ${lastError ?? ''}'),
        backgroundColor: lastError != null ? Colors.orange : Colors.green,
      ));
      setState(() => _selectedIds.clear());
    }
  }
}

class _ActivitiesTab extends ConsumerWidget {
  final ClubModel club;
  const _ActivitiesTab({required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogActivity(context, ref),
        label: const Text('Log Activity'),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ClubActivityModel>>(
        future: ref.read(databaseProvider.future).then((db) => db.clubDao.getActivitiesByClub(club.id)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final activities = snapshot.data!;
          if (activities.isEmpty) return const Center(child: Text('No activities recorded yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final a = activities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: _getActivityIcon(a.type),
                  title: Text(a.title),
                  subtitle: Text('${a.type} • ${DateTime.fromMillisecondsSinceEpoch(a.scheduledAt).toString().split(' ')[0]}'),
                  trailing: Text(a.status.toUpperCase(), style: TextStyle(
                    color: a.status == 'completed' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  )),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getActivityIcon(String type) {
    IconData icon;
    switch (type) {
      case 'Meeting': icon = Icons.groups; break;
      case 'Competition': icon = Icons.emoji_events; break;
      case 'Field Trip': icon = Icons.bus_alert; break;
      default: icon = Icons.event;
    }
    return CircleAvatar(child: Icon(icon, size: 20));
  }

  void _showLogActivity(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String type = 'Meeting';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log New Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: type,
              items: ['Meeting', 'Competition', 'Field Trip', 'Project'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => type = v!,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              await db.clubDao.insertActivity(ClubActivityModel(
                id: const Uuid().v4(),
                clubId: club.id,
                title: titleController.text,
                description: descController.text,
                type: type,
                scheduledAt: DateTime.now().millisecondsSinceEpoch,
                venue: 'School Grounds',
                recordedAt: DateTime.now().millisecondsSinceEpoch,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTab extends ConsumerStatefulWidget {
  final ClubModel club;
  const _AttendanceTab({required this.club});

  @override
  ConsumerState<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<_AttendanceTab> {
  ClubActivityModel? _latestActivity;
  List<ClubMemberModel> _members = [];
  final Map<String, String> _attendance = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final activities = await db.clubDao.getActivitiesByClub(widget.club.id);
    final members = await db.clubDao.getMembersByClub(widget.club.id);
    
    setState(() {
      _latestActivity = activities.isEmpty ? null : activities.first;
      _members = members;
      for (var m in members) {
        _attendance[m.studentId] = 'present';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_latestActivity == null) {
      return const Center(child: Text('Please log an activity first to record attendance.'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primary.withOpacity(0.05),
          child: Row(
            children: [
              const Icon(Icons.event_available, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_latestActivity!.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Recording attendance for ${DateTime.fromMillisecondsSinceEpoch(_latestActivity!.scheduledAt).toString().split(' ')[0]}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final m = _members[index];
              return FutureBuilder<StudentModel?>(
                future: ref.read(databaseProvider.future).then((db) => db.studentDao.findById(m.studentId)),
                builder: (context, sSnap) {
                  final s = sSnap.data;
                  final status = _attendance[m.studentId] ?? 'present';
                  return ListTile(
                    title: Text(s?.fullName ?? 'Loading...'),
                    subtitle: Text(m.role),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'present', label: Text('P')),
                        ButtonSegment(value: 'absent', label: Text('A')),
                      ],
                      selected: {status},
                      onSelectionChanged: (val) {
                        setState(() => _attendance[m.studentId] = val.first);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text('Save Attendance'),
          ),
        ),
      ],
    );
  }

  void _save() async {
    final db = await ref.read(databaseProvider.future);
    for (var entry in _attendance.entries) {
      await db.clubDao.insertAttendance(ClubAttendanceModel(
        activityId: _latestActivity!.id,
        studentId: entry.key,
        status: entry.value,
      ));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance recorded!')));
    }
  }
}


class _ReportsTab extends ConsumerStatefulWidget {
  final ClubModel club;
  const _ReportsTab({required this.club});

  @override
  ConsumerState<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<_ReportsTab> {
  final _contentController = TextEditingController();
  int _selectedTerm = 1;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submit Term Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Provide a summary of the club\'s achievements, challenges, and overall progress this term.'),
          const SizedBox(height: 24),
          DropdownButtonFormField<int>(
            value: _selectedTerm,
            decoration: const InputDecoration(labelText: 'Term', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Term 1')),
              DropdownMenuItem(value: 2, child: Text('Term 2')),
              DropdownMenuItem(value: 3, child: Text('Term 3')),
            ],
            onChanged: (v) => setState(() => _selectedTerm = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Achievements: e.g. Won regional drama festival...\nChallenges: e.g. Limited sports equipment...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Report to Co-Curricular HOD'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (_contentController.text.isEmpty) return;
    
    final user = ref.read(currentUserProvider);
    final db = await ref.read(databaseProvider.future);
    
    await db.clubDao.insertReport(ClubReportModel(
      id: const Uuid().v4(),
      clubId: widget.club.id,
      term: _selectedTerm,
      year: '2026',
      content: _contentController.text,
      submittedAt: DateTime.now().millisecondsSinceEpoch,
      patronId: user?.id ?? 'system',
      status: 'submitted',
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!')));
      _contentController.clear();
    }
  }
}

