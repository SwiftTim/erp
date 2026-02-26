import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/timetable_models.dart';
import '../../data/models/student_model.dart';
import '../../services/teaching_pipeline_service.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class InstructionalHubPage extends ConsumerStatefulWidget {
  final String slotId;
  const InstructionalHubPage({super.key, required this.slotId});

  @override
  ConsumerState<InstructionalHubPage> createState() => _InstructionalHubPageState();
}

class _InstructionalHubPageState extends ConsumerState<InstructionalHubPage> {
  TimetableSlot? _slot;
  List<StudentModel> _students = [];
  final Map<String, String> _attendance = {};
  AttendanceSessionModel? _session;
  int _step = 0; // 0=Attendance, 1=Lesson Status, 2=Evidence
  bool _loading = true;
  double _coveragePercent = 0.0;
  String _lessonStatus = 'Completed';
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final db = await ref.read(databaseProvider.future);
    final slot = await db.timetableDao.findSlotById(widget.slotId);
    if (slot == null) return;

    final students = await db.studentDao.findByClass(slot.classId);
    
    // Auto-create or resume session
    final pipeline = ref.read(teachingPipelineServiceProvider);
    final session = await pipeline.openAttendanceSession(slot);
    final coverage = await pipeline.getCoverageAnalytics(slot.classId, slot.subjectId);

    if (mounted) {
      setState(() {
        _slot = slot;
        _students = students;
        _session = session;
        _coveragePercent = coverage;
        for (var s in students) _attendance[s.id] = AppConstants.present;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return AppShell(
      title: 'Classroom Hub: ${_slot!.subjectId}',
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _step,
        onStepContinue: _handleStepContinue,
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: FilledButton(
              onPressed: details.onStepContinue,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_step == 2 ? 'Finalize Lesson' : 'Confirm & Continue'),
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Roll Call'),
            isActive: _step >= 0,
            content: _buildAttendanceStep(),
          ),
          Step(
            title: const Text('Teaching'),
            isActive: _step >= 1,
            content: _buildStatusStep(),
          ),
          Step(
            title: const Text('Evidence'),
            isActive: _step >= 2,
            content: _buildEvidenceStep(),
          ),
        ],
      ),
    );
  }

  void _handleStepContinue() async {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      // Finalize
      final pipeline = ref.read(teachingPipelineServiceProvider);
      await pipeline.completeLesson(
        session: _session!,
        status: _lessonStatus,
        notes: _notesController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Syllabus Coverage auto-updated. Lesson record secured.'), 
            backgroundColor: Colors.green
          )
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _buildAttendanceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mark attendance for ${_slot!.classId}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._students.map((s) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.fullName, style: const TextStyle(fontSize: 14)),
          trailing: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: AppConstants.present, label: Text('P')),
              ButtonSegment(value: AppConstants.absent, label: Text('A')),
            ],
            selected: {_attendance[s.id] ?? AppConstants.present},
            onSelectionChanged: (set) => setState(() => _attendance[s.id] = set.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        )),
      ],
    );
  }

  Widget _buildStatusStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Lesson Coverage Status', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${_coveragePercent.toStringAsFixed(1)}% Syllabus Covered', style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: _coveragePercent / 100, backgroundColor: Colors.grey.withAlpha(25)),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _lessonStatus,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: 'Completed', child: Text('Completed (Standard Weight)')),
            DropdownMenuItem(value: 'Partially Completed', child: Text('Partially Completed')),
            DropdownMenuItem(value: 'Not Covered', child: Text('Not Covered / Missed')),
          ],
          onChanged: (val) => setState(() => _lessonStatus = val!),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Reflection / Observations',
            hintText: 'e.g., Most learners struggled with long division...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceStep() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withAlpha(51), style: BorderStyle.solid),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Drag photos or click to upload', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionBtn(Icons.camera_alt, 'Camera'),
            _actionBtn(Icons.photo_library, 'Gallery'),
            _actionBtn(Icons.picture_as_pdf, 'PDF/Doc'),
          ],
        )
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label) {
    return Column(
      children: [
        IconButton.filledTonal(onPressed: () {}, icon: Icon(icon)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
