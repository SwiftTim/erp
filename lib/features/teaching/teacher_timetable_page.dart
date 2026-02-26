// lib/features/teaching/teacher_timetable_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../data/models/timetable_models.dart';
import '../../services/teaching_pipeline_service.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class TeacherTimetablePage extends ConsumerStatefulWidget {
  const TeacherTimetablePage({super.key});

  @override
  ConsumerState<TeacherTimetablePage> createState() => _TeacherTimetablePageState();
}

class _TeacherTimetablePageState extends ConsumerState<TeacherTimetablePage> {
  List<TimetableSlot> _mySlots = [];
  Map<String, int> _summary = {'scheduled': 0, 'completed': 0, 'pending': 0, 'upcoming': 0};
  bool _isLoading = true;
  TimetableSlot? _currentSlot;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final db = await ref.read(databaseProvider.future);
    final activeTimetable = await db.timetableDao.getActiveTimetable();
    
    if (activeTimetable != null) {
      final pipeline = ref.read(teachingPipelineServiceProvider);
      final slots = await db.timetableDao.getSlotsForTeacher(activeTimetable.id, user.id);
      final current = await pipeline.getActiveSlotForTeacher(user.id);
      final summary = await pipeline.getDailySummary(user.id);
      
      if (mounted) {
        setState(() {
          _mySlots = slots;
          _currentSlot = current;
          _summary = summary;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return AppShell(
      title: 'My Teaching Schedule',
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentTaskHero(),
                  const SizedBox(height: 24),
                  const Text('Weekly Grid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildWeeklyGrid(),
                  const SizedBox(height: 32),
                  _buildSummaryPanel(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCurrentTaskHero() {
    final user = ref.read(currentUserProvider);
    if (_currentSlot == null || user == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha(51)),
        ),
        child: const Row(
          children: [
            Icon(Icons.coffee_outlined, color: Colors.grey),
            SizedBox(width: 16),
            Text('No scheduled lesson right now. Take a break!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final bool isLead = _currentSlot!.teacherId == user.id;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primary.withAlpha(76), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                child: const Text('ACTIVE NOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isLead ? Colors.green : Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLead ? 'LEAD TEACHER' : 'ASSISTANT TEACHER',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text('Period ${_currentSlot!.periodNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_currentSlot!.subjectId, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text('Class: ${_currentSlot!.classId}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const Spacer(),
              const Icon(Icons.circle, color: Colors.red, size: 8),
              const SizedBox(width: 4),
              const Text('Live Session', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openTeachingSession(_currentSlot!),
            icon: const Icon(Icons.play_circle_fill),
            label: Text(isLead ? 'Start Lesson & Mark Attendance' : 'Join Lesson as Assistant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeeklyGrid() {
    final user = ref.read(currentUserProvider);
    return Table(
      border: TableBorder.all(color: Colors.grey.withAlpha(51), borderRadius: BorderRadius.circular(8)),
      children: [
        TableRow(
          children: [
            _Cell('P', isHeader: true, bgColor: Colors.grey.withAlpha(13)),
            ...'Mon Tue Wed Thu Fri'.split(' ').map((d) => _Cell(d, isHeader: true, bgColor: Colors.grey.withAlpha(13))),
          ],
        ),
        ...List.generate(8, (p) {
          final period = p + 1;
          return TableRow(
            children: [
              _Cell('$period', isHeader: true),
              ...List.generate(5, (d) {
                final day = d + 1;
                final slot = _mySlots.where((s) => s.dayOfWeek == day && s.periodNumber == period).firstOrNull;
                final isToday = day == DateTime.now().weekday;
                final isNow = isToday && period == ref.read(teachingPipelineServiceProvider).getCurrentPeriod();
                
                return InkWell(
                  onTap: slot != null ? () => _showSlotDetails(slot) : null,
                  child: Container(
                    height: 60,
                    color: isNow ? Colors.orange.withAlpha(25) : (isToday ? Colors.blue.withAlpha(5) : null),
                    padding: const EdgeInsets.all(4),
                    child: slot == null 
                      ? null 
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(slot.subjectId.length > 5 ? slot.subjectId.substring(0, 5) : slot.subjectId, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
                            Text(slot.classId, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: (slot.teacherId == user?.id ? Colors.green : Colors.blue).withAlpha(30),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                slot.teacherId == user?.id ? 'LEAD' : 'ASST',
                                style: TextStyle(
                                  fontSize: 6, 
                                  fontWeight: FontWeight.bold,
                                  color: slot.teacherId == user?.id ? Colors.green : Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSummaryPanel() {
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: AppTheme.primary.withAlpha(13),
         borderRadius: BorderRadius.circular(12),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           const Text('Daily Teaching Summary', style: TextStyle(fontWeight: FontWeight.bold)),
           const SizedBox(height: 16),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: [
               _summaryItem('Scheduled', '${_summary['scheduled']}', Colors.blue),
               _summaryItem('Completed', '${_summary['completed']}', Colors.green),
               _summaryItem('Pending', '${_summary['pending']}', Colors.orange),
               _summaryItem('Upcoming', '${_summary['upcoming']}', Colors.grey),
             ],
           )
         ],
       ),
     );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showSlotDetails(TimetableSlot slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lesson Details', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.subject),
              title: const Text('Subject'),
              subtitle: Text(slot.subjectId),
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text('Class'),
              subtitle: Text(slot.classId),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                   Navigator.pop(context);
                   _openTeachingSession(slot);
                },
                child: const Text('Open Teaching Hub'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openTeachingSession(TimetableSlot slot) async {
    context.push(Routes.instructionalHub.replaceFirst(':slotId', slot.id));
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final Color? bgColor;
  const _Cell(this.text, {this.isHeader = false, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(text, 
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            fontSize: isHeader ? 12 : 11,
            color: isHeader ? Colors.grey : null
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
