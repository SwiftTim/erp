// lib/features/admin/substitution_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/enterprise_models.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/services/audit_service.dart';

class SubstitutionManagementPage extends ConsumerStatefulWidget {
  const SubstitutionManagementPage({super.key});

  @override
  ConsumerState<SubstitutionManagementPage> createState() => _SubstitutionManagementPageState();
}

class _SubstitutionManagementPageState extends ConsumerState<SubstitutionManagementPage> {
  List<Substitution> _substitutions = [];
  List<UserModel> _teachers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final subs = await db.enterpriseDao.findAllSubstitutionsByDate(
      DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0).millisecondsSinceEpoch
    );
    final users = await db.userDao.findAllActive();
    
    if (mounted) {
      setState(() {
        _substitutions = subs;
        _teachers = users.where((u) => u.roleLevel <= 5).toList();
        _loading = false;
      });
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSubstitutionSheet(teachers: _teachers, onSaved: _loadData),
    );
  }

  Future<void> _deleteSub(Substitution sub) async {
    final db = await ref.read(databaseProvider.future);
    await db.enterpriseDao.deleteSubstitution(sub);
    ref.read(auditServiceProvider).log('DELETE_SUBSTITUTION', 'Faculty', 'Removed substitution for period ${sub.periodNumber}');
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Substitution Desk',
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildStats(),
              Expanded(
                child: _substitutions.isEmpty 
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _substitutions.length,
                      itemBuilder: (context, i) {
                        final sub = _substitutions[i];
                        final orig = _teachers.where((t) => t.id == sub.originalTeacherId).firstOrNull;
                        final subst = _teachers.where((t) => t.id == sub.substituteTeacherId).firstOrNull;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.swap_horiz, color: Colors.white)),
                            title: Text('${subst?.name ?? "Unknown"} covering for ${orig?.name ?? "Unknown"}'),
                            subtitle: Text('Period ${sub.periodNumber} · ${sub.subjectId} · ${sub.classId}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteSub(sub),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Assign Sub'),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.orange.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Active Subs', value: '${_substitutions.length}', color: Colors.orange),
          _Stat(label: 'Teachers on Leave', value: '2', color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No active substitutions for today.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _AddSubstitutionSheet extends StatefulWidget {
  final List<UserModel> teachers;
  final VoidCallback onSaved;
  const _AddSubstitutionSheet({required this.teachers, required this.onSaved});

  @override
  State<_AddSubstitutionSheet> createState() => _AddSubstitutionSheetState();
}

class _AddSubstitutionSheetState extends State<_AddSubstitutionSheet> {
  UserModel? _original;
  UserModel? _substitute;
  int _period = 1;
  final _classCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Create Temporary Substitution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          DropdownButtonFormField<UserModel>(
            value: _original,
            decoration: const InputDecoration(labelText: 'Absent Teacher'),
            items: widget.teachers.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
            onChanged: (v) => setState(() => _original = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _classCtrl, decoration: const InputDecoration(labelText: 'Class (e.g. 4A)'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject'))),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _period,
            decoration: const InputDecoration(labelText: 'Period'),
            items: List.generate(8, (i) => i + 1).map((i) => DropdownMenuItem(value: i, child: Text('Period $i'))).toList(),
            onChanged: (v) => setState(() => _period = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<UserModel>(
            value: _substitute,
            decoration: const InputDecoration(labelText: 'Substitute Teacher'),
            items: widget.teachers.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
            onChanged: (v) => setState(() => _substitute = v),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 56)),
            child: const Text('Confirm Substitution'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_original == null || _substitute == null) return;
    
    final container = ProviderScope.containerOf(context);
    final db = await container.read(databaseProvider.future);
    
    final sub = Substitution(
      id: const Uuid().v4(),
      originalTeacherId: _original!.id,
      substituteTeacherId: _substitute!.id,
      classId: _classCtrl.text,
      subjectId: _subjectCtrl.text,
      date: DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0).millisecondsSinceEpoch,
      periodNumber: _period,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await db.enterpriseDao.insertSubstitution(sub);
    container.read(auditServiceProvider).log('CREATE_SUBSTITUTION', 'Faculty', 'Assigned ${_substitute!.name} as sub for ${_original!.name}');
    
    widget.onSaved();
    Navigator.pop(context);
  }
}
