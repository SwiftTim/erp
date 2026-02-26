// lib/features/students/student_registration_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/student_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class StudentRegistrationPage extends ConsumerStatefulWidget {
  const StudentRegistrationPage({super.key});

  @override
  ConsumerState<StudentRegistrationPage> createState() => _StudentRegistrationPageState();
}

class _StudentRegistrationPageState extends ConsumerState<StudentRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _nameCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  String? _selectedGender;
  String? _selectedGrade;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _upiCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 6),
      firstDate: DateTime(now.year - 18),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      _dobCtrl.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  DateTime get now => DateTime.now();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final student = StudentModel(
      id: _uuid.v4(),
      upi: _upiCtrl.text.trim().toUpperCase(),
      fullName: _nameCtrl.text.trim(),
      gender: _selectedGender!,
      dob: _dobCtrl.text.trim(),
      grade: _selectedGrade!,
      classId: _selectedGrade!.replaceAll(' ', '-').toUpperCase(), 
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final db = await ref.read(databaseProvider.future);
      await db.studentDao.insertStudent(student);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} has been registered.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'New Admission',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              
              _buildInputCard(
                context,
                title: 'Personal Information',
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'e.g. Johnstone Kamau',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.wc_outlined),
                          ),
                          items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => _selectedGender = v),
                          validator: (v) => v == null ? 'Field required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _dobCtrl,
                          readOnly: true,
                          onTap: _pickDob,
                          decoration: const InputDecoration(
                            labelText: 'D.O.B',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Date required' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              _buildInputCard(
                context,
                title: 'School Records',
                children: [
                  TextFormField(
                    controller: _upiCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'UPI Number (NEMIS)',
                      prefixIcon: Icon(Icons.badge_outlined),
                      hintText: 'ABC123456',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'UPI is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'Placement Grade',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    items: AppConstants.allGrades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) => setState(() => _selectedGrade = v),
                    validator: (v) => v == null ? 'Grade required' : null,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving 
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.how_to_reg_outlined),
                label: const Text('Complete Registration'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add New Learner', 
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Fill in the details for government reporting (NEMIS).', 
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
      ],
    );
  }

  Widget _buildInputCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
