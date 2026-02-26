// lib/features/counseling/counseling_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/counseling_model.dart';
import '../../data/models/student_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'package:intl/intl.dart';

class CounselingDashboardPage extends ConsumerStatefulWidget {
  const CounselingDashboardPage({super.key});

  @override
  ConsumerState<CounselingDashboardPage> createState() => _CounselingDashboardPageState();
}

class _CounselingDashboardPageState extends ConsumerState<CounselingDashboardPage> {
  List<CounselingLogModel> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final logs = await db.counselingDao.findAll();
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  Future<void> _showNewSessionDialog() async {
    final issueController = TextEditingController();
    final summaryController = TextEditingController();
    final notesController = TextEditingController();
    StudentModel? selectedStudent;
    List<StudentModel> students = [];
    
    final db = await ref.read(databaseProvider.future);
    students = await db.studentDao.findAll();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Counseling Session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<StudentModel>(
                items: students.map((s) => DropdownMenuItem(value: s, child: Text(s.fullName))).toList(),
                onChanged: (s) => selectedStudent = s,
                decoration: const InputDecoration(labelText: 'Select Student'),
              ),
              TextField(controller: issueController, decoration: const InputDecoration(labelText: 'Primary Issue (e.g. Grief)')),
              TextField(controller: summaryController, decoration: const InputDecoration(labelText: 'High-level Summary')),
              TextField(
                controller: notesController, 
                maxLines: 5, 
                decoration: const InputDecoration(labelText: 'Detailed Confidential Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (selectedStudent == null || issueController.text.isEmpty) return;
              final user = ref.read(currentUserProvider);
              if (user == null) return;

              await db.counselingDao.insertLog(CounselingLogModel(
                id: const Uuid().v4(),
                studentId: selectedStudent!.id,
                issue: issueController.text,
                summary: summaryController.text,
                notes: notesController.text,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                counselorId: user.id,
              ));
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Save Confidential Log'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Guidance & Counseling Portal',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewSessionDialog,
        label: const Text('New Session'),
        icon: const Icon(Icons.psychology_outlined),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _logs.length,
            itemBuilder: (context, i) {
              final log = _logs[i];
              final date = DateFormat('MMM d, yyyy h:mm a').format(DateTime.fromMillisecondsSinceEpoch(log.timestamp));
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const Icon(Icons.lock_outline, color: Colors.purple),
                  title: Text(log.issue, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ID: ${log.studentId.substring(0,8)} • $date'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(log.summary),
                          const SizedBox(height: 12),
                          const Text('Confidential Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(log.notes, style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
