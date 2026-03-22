import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/student_model.dart';
import '../../data/models/curriculum_models.dart';
import '../dashboard/widgets/app_shell.dart';
import '../auth/auth_provider.dart';
import 'tod_provider.dart';

class TodRecordsPage extends ConsumerStatefulWidget {
  const TodRecordsPage({super.key});

  @override
  ConsumerState<TodRecordsPage> createState() => _TodRecordsPageState();
}

class _TodRecordsPageState extends ConsumerState<TodRecordsPage> {
  String? _selectedGrade;
  SchoolClassModel? _selectedClass;
  final List<String> _selectedStudentIds = [];
  String? _selectedOffence;
  String? _selectedPunishment;
  final _remarksController = TextEditingController();

  final List<String> _offences = [
    'Late coming',
    'Noise making in class',
    'Fighting',
    'Bullying',
    'Disrespect to teacher',
    'Incomplete homework',
    'Truancy / Absenteeism',
    'Uniform violation',
    'Possession of prohibited items',
    'Class disruption',
    'Cheating in tests',
    'Vandalism',
  ];

  final List<String> _punishments = [
    'Warning',
    'Manual work',
    'Cleaning duty',
    'Counseling referral',
    'Parent call',
    'Detention',
    'Sent to deputy',
  ];

  List<SchoolClassModel> _classes = [];
  List<StudentModel> _students = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final db = await ref.read(databaseProvider.future);
    final classes = await db.curriculumDao.findAllClasses();
    setState(() {
      _classes = classes;
    });
  }

  Future<void> _loadStudents(String classId) async {
    final db = await ref.read(databaseProvider.future);
    final students = await db.studentDao.findByClass(classId);
    setState(() {
      _students = students;
      _selectedStudentIds.clear();
    });
  }

  Future<void> _submit() async {
    if (_selectedStudentIds.isEmpty || _selectedOffence == null || _selectedPunishment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not logged in. Please restart the app.')),
      );
      return;
    }

    setState(() => _loading = true);
    final todService = ref.read(todServiceProvider);

    try {
      for (final studentId in _selectedStudentIds) {
        await todService.recordOffence(
          studentId: studentId,
          teacherId: user.id,
          offence: _selectedOffence!,
          punishment: _selectedPunishment!,
          remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedStudentIds.length} record(s) submitted successfully!')),
        );
        // Reset form instead of popping — this is a top-level page
        setState(() {
          _selectedGrade = null;
          _selectedClass = null;
          _selectedStudentIds.clear();
          _students.clear();
          _selectedOffence = null;
          _selectedPunishment = null;
          _remarksController.clear();
        });
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      debugPrint('TOD submit error: $e\n$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grades = _classes.map((c) => c.grade).toSet().toList()..sort();

    return AppShell(
      title: 'TOD Records',
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Step 1: Select Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Grade', border: OutlineInputBorder()),
                        value: _selectedGrade,
                        items: grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedGrade = val;
                            _selectedClass = null;
                            _students = [];
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<SchoolClassModel>(
                        decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                        value: _selectedClass,
                        items: _classes
                            .where((c) => c.grade == _selectedGrade)
                            .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedClass = val);
                          if (val != null) _loadStudents(val.id);
                        },
                      ),
                    ),
                  ],
                ),
                if (_students.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Step 2: Select Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _students.length,
                      itemBuilder: (context, i) {
                        final s = _students[i];
                        final isSelected = _selectedStudentIds.contains(s.id);
                        return CheckboxListTile(
                          title: Text(s.fullName),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedStudentIds.add(s.id);
                              } else {
                                _selectedStudentIds.remove(s.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                if (_selectedStudentIds.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Step 3: Offence Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Offence Type', border: OutlineInputBorder()),
                    value: _selectedOffence,
                    items: _offences.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (val) => setState(() => _selectedOffence = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Punishment', border: OutlineInputBorder()),
                    value: _selectedPunishment,
                    items: _punishments.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPunishment = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _remarksController,
                    decoration: const InputDecoration(labelText: 'Remarks (Optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Record Discipline Case'),
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }
}
