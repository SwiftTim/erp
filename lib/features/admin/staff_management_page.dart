// lib/features/admin/staff_management_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/models/curriculum_models.dart';
import '../../data/models/timetable_models.dart';
import '../../data/models/enterprise_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/services/audit_service.dart';

class StaffManagementPage extends ConsumerStatefulWidget {
  const StaffManagementPage({super.key});

  @override
  ConsumerState<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends ConsumerState<StaffManagementPage> {
  List<UserModel> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final db = await ref.read(databaseProvider.future);
    final users = await db.userDao.findAll();
    if (mounted) {
      setState(() {
        _staff = users.where((u) => u.roleLevel <= 10).toList();
        _loading = false;
      });
    }
  }

  void _showStaffSheet([UserModel? user]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffSheet(user: user, onSaved: _loadStaff),
    );
  }

  void _showAssignmentSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignmentSheet(teacher: user, onSaved: _loadStaff),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'School Faculty',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _staff.length,
                    itemBuilder: (context, i) {
                      final u = _staff[i];
                      return InkWell(
                        onTap: () => _showStaffSheet(u),
                        child: _StaffCard(
                          user: u,
                          onAssign: () => _showAssignmentSheet(u),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStaffSheet(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Staff Member'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        children: [
          _Stat(label: 'Total Staff', value: '${_staff.length}'),
          const VerticalDivider(),
          _Stat(label: 'Active', value: '${_staff.where((u) => u.isActive == 1).length}', color: Colors.green),
          const VerticalDivider(),
          _Stat(label: 'On Leave', value: '0', color: Colors.orange),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAssign;

  const _StaffCard({required this.user, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    final isActive = user.isActive == 1;
    final color = isActive ? AppTheme.primary : Colors.grey;
    final roleName = AppConstants.roleNames[user.roleLevel] ?? 'Staff';
    
    final List<String> flags = user.roleFlags != null 
        ? jsonDecode(user.roleFlags!) is List ? (jsonDecode(user.roleFlags!) as List).map((e) => e.toString()).toList() : []
        : [];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.1),
              child: Text(user.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, decoration: isActive ? null : TextDecoration.lineThrough)),
                  Row(
                    children: [
                      Text(roleName,
                        style: TextStyle(color: isActive ? AppTheme.primary : Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                      if (flags.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text('${flags.length} Specialties', style: const TextStyle(fontSize: 8, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onAssign,
              child: const Text('Assign', style: TextStyle(fontSize: 12)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AssignmentSheet extends ConsumerStatefulWidget {
  final UserModel teacher;
  final VoidCallback onSaved;
  const _AssignmentSheet({required this.teacher, required this.onSaved});

  @override
  ConsumerState<_AssignmentSheet> createState() => _AssignmentSheetState();
}

class _AssignmentSheetState extends ConsumerState<_AssignmentSheet> {
  String? _selectedClassId;
  String? _selectedSubjectId;
  List<SchoolClassModel> _classes = [];
  List<LearningAreaModel> _subjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final classes = await db.curriculumDao.findAllClasses();
    final subjects = await db.curriculumDao.findAllLearningAreas();
    if (mounted) {
      setState(() {
        _classes = classes;
        _subjects = subjects;
        _loading = false;
        _selectedClassId = widget.teacher.assignedClassId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: _loading 
        ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text('Teaching Assignment: ${widget.teacher.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Assign to Class', prefixIcon: Icon(Icons.class_outlined)),
            value: _selectedClassId,
            items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.grade})'))).toList(),
            onChanged: (v) => setState(() => _selectedClassId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Primary Subject', prefixIcon: Icon(Icons.book_outlined)),
            items: _subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: (v) => setState(() => _selectedSubjectId = v),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () async {
              if (_selectedClassId == null || _selectedSubjectId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both class and subject.')));
                return;
              }

              final db = await ref.read(databaseProvider.future);
              
              // 1. Update User Model
              await db.userDao.updateUser(widget.teacher.copyWith(
                assignedClassId: _selectedClassId,
                roleFlags: widget.teacher.hasFlag(AppConstants.flagClassTeacher) 
                  ? widget.teacher.roleFlags 
                  : jsonEncode([...(jsonDecode(widget.teacher.roleFlags ?? '[]') as List), AppConstants.flagClassTeacher]),
              ));

              // 2. Add Teaching Assignment
              await db.enterpriseDao.insertAssignment(TeachingAssignment(
                id: const Uuid().v4(),
                teacherId: widget.teacher.id,
                classId: _selectedClassId!,
                subjectId: _selectedSubjectId!,
                academicYear: 2026,
              ));

              // 3. Ensure Timetable Profile exists
              final existingProfile = await db.timetableDao.findTeacherProfileById(widget.teacher.id);
              if (existingProfile == null) {
                await db.timetableDao.insertTeacherProfile(TeacherTimetableProfile(
                  id: widget.teacher.id,
                  teacherId: widget.teacher.id,
                  maxPeriodsPerDay: 7,
                  maxPeriodsPerWeek: 30,
                  isClassTeacher: true,
                ));
              }

              // 4. Ensure Subject Capability exists
              await db.timetableDao.insertTeacherCapability(TeacherSubjectCapability(
                id: '${widget.teacher.id}_P1',
                teacherId: widget.teacher.id,
                subjectId: _selectedSubjectId!,
                priorityLevel: 1,
              ));

              widget.onSaved();
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assignment saved and Timetable Engine updated!'), backgroundColor: Colors.green)
              );
            },
            child: const Text('Confirm Assignment'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _StaffSheet extends ConsumerStatefulWidget {
  final UserModel? user;
  final VoidCallback onSaved;
  const _StaffSheet({this.user, required this.onSaved});

  @override
  ConsumerState<_StaffSheet> createState() => _StaffSheetState();
}

class _StaffSheetState extends ConsumerState<_StaffSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passCtrl;
  late int _selectedRole;
  late bool _isActive;
  final List<String> _selectedFlags = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name);
    _emailCtrl = TextEditingController(text: widget.user?.email);
    _passCtrl = TextEditingController();
    _selectedRole = widget.user?.roleLevel ?? 5;
    _isActive = widget.user?.isActive == 1;
    
    if (widget.user?.roleFlags != null) {
      try {
        final decoded = jsonDecode(widget.user!.roleFlags!);
        if (decoded is List) {
          _selectedFlags.addAll(decoded.map((e) => e.toString()));
        }
      } catch (e) {
        debugPrint('Error parsing flags: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(widget.user == null ? 'Register New Faculty' : 'Edit Staff Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 16),
            TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.alternate_email))),
            if (widget.user == null) ...[
              const SizedBox(height: 16),
              TextFormField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Default Password', prefixIcon: Icon(Icons.lock_outline))),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Primary Assignment', prefixIcon: Icon(Icons.work_outline)),
              items: AppConstants.roleNames.entries
                  .where((e) => e.key <= 10)
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v ?? 5),
            ),
            const SizedBox(height: 16),
            const Text('Specialty Roles & Responsibilities', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.teacherSpecialties.map((flag) {
                final isSelected = _selectedFlags.contains(flag);
                return FilterChip(
                  label: Text(flag, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black)),
                  selected: isSelected,
                  selectedColor: Colors.orange,
                  onSelected: (v) {
                    setState(() {
                      if (v) _selectedFlags.add(flag);
                      else _selectedFlags.remove(flag);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Account Active'),
              subtitle: const Text('Allow staff to log in to the system'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () async {
                // Store UI-related objects before async gap
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                final auth = ref.read(authNotifierProvider.notifier);
                final db = await ref.read(databaseProvider.future);
                final String? flagJson = _selectedFlags.isEmpty ? null : jsonEncode(_selectedFlags);

                try {
                  // === VALIDATION ===
                  final newEmail = _emailCtrl.text.trim().toLowerCase();
                  if (newEmail.isEmpty) throw Exception('Email address cannot be empty.');

                  final existingUser = await db.userDao.findByEmail(newEmail);
                  if (existingUser != null && existingUser.id != widget.user?.id) {
                    throw Exception('Email address is already in use by another account.');
                  }

                  // === EXECUTION ===
                  if (widget.user == null) {
                     if (_passCtrl.text.isEmpty) throw Exception('Password cannot be empty for new users.');
                    await db.userDao.insertUser(UserModel(
                      id: const Uuid().v4(),
                      name: _nameCtrl.text.trim(),
                      email: newEmail,
                      passwordHash: auth.hashPassword(_passCtrl.text),
                      roleLevel: _selectedRole,
                      roleFlags: flagJson,
                      isActive: _isActive ? 1 : 0,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    ));
                    ref.read(auditServiceProvider).log('CREATE_STAFF', 'Faculty', 'Added ${_nameCtrl.text}');
                  } else {
                    await db.userDao.updateUser(widget.user!.copyWith(
                      name: _nameCtrl.text.trim(),
                      email: newEmail,
                      roleLevel: _selectedRole,
                      roleFlags: flagJson,
                      isActive: _isActive ? 1 : 0,
                    ));
                    ref.read(auditServiceProvider).log('UPDATE_STAFF', 'Faculty', 'Modified ${widget.user!.name}');
                  }
                  
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('User details saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  widget.onSaved();
                  navigator.pop();

                } catch (e) {
                   scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: Text(widget.user == null ? 'Add to Faculty' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
