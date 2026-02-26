// lib/features/health/widgets/log_visit_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/medical_model.dart';
import '../../../data/models/student_model.dart';
import '../../auth/auth_provider.dart';

class LogVisitDialog extends ConsumerStatefulWidget {
  const LogVisitDialog({super.key});

  @override
  ConsumerState<LogVisitDialog> createState() => _LogVisitDialogState();
}

class _LogVisitDialogState extends ConsumerState<LogVisitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _actionController = TextEditingController();
  final _medicationController = TextEditingController();
  
  StudentModel? _selectedStudent;
  List<StudentModel> _students = [];
  bool _loadingStudents = true;

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
    final visit = ClinicVisitModel(
      id: const Uuid().v4(),
      studentId: _selectedStudent!.id,
      symptoms: _symptomsController.text,
      actionTaken: _actionController.text,
      medicationGiven: _medicationController.text.isEmpty ? null : _medicationController.text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      recordedBy: user.id,
    );

    await db.medicalDao.insertVisit(visit);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Clinic Visit'),
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
                TextFormField(
                  controller: _symptomsController,
                  decoration: const InputDecoration(
                    labelText: 'Symptoms / Complaint',
                    hintText: 'e.g. Fever, Headache, Stomach ache',
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _actionController,
                  decoration: const InputDecoration(
                    labelText: 'Action Taken',
                    hintText: 'e.g. Bed rest, First aid',
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _medicationController,
                  decoration: const InputDecoration(
                    labelText: 'Medication Given (Optional)',
                    hintText: 'e.g. Paracetamol 500mg',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save Visit')),
      ],
    );
  }
}
