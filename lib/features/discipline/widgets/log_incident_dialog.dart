// lib/features/discipline/widgets/log_incident_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/discipline_model.dart';
import '../../../data/models/student_model.dart';
import '../../auth/auth_provider.dart';

class LogIncidentDialog extends ConsumerStatefulWidget {
  const LogIncidentDialog({super.key});

  @override
  ConsumerState<LogIncidentDialog> createState() => _LogIncidentDialogState();
}

class _LogIncidentDialogState extends ConsumerState<LogIncidentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _actionController = TextEditingController();
  
  StudentModel? _selectedStudent;
  List<StudentModel> _students = [];
  bool _loadingStudents = true;
  String _category = 'Lateness';

  final List<String> _categories = ['Lateness', 'Bullying', 'Disruption', 'Theft', 'Academic Dishonesty', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final db = await ref.read(databaseProvider.future);
    final students = await db.studentDao.findAll();
    if (mounted) {
      setState(() {
        _students = students;
        _loadingStudents = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedStudent == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final db = await ref.read(databaseProvider.future);
    final incident = DisciplineRecordModel(
      id: const Uuid().v4(),
      studentId: _selectedStudent!.id,
      category: _category,
      incidentDescription: _descriptionController.text,
      actionTaken: _actionController.text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      recordedBy: user.id,
      status: 'Pending',
    );

    await db.disciplineDao.insertRecord(incident);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Discipline Incident'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loadingStudents)
                  const CircularProgressIndicator()
                else
                  DropdownButtonFormField<StudentModel>(
                    decoration: const InputDecoration(labelText: 'Select Student'),
                    items: _students.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.fullName),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedStudent = val),
                    validator: (val) => val == null ? 'Please select a student' : null,
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  )).toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Incident Description',
                    hintText: 'Describe what happened in detail...',
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _actionController,
                  decoration: const InputDecoration(
                    labelText: 'Action Taken / Response',
                    hintText: 'e.g. Verbal warning, Time out',
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Record Incident')),
      ],
    );
  }
}
