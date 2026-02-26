import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../data/models/timetable_models.dart';
import '../features/auth/auth_provider.dart';

final teachingPipelineServiceProvider = Provider<TeachingPipelineService>((ref) {
  return TeachingPipelineService(ref);
});

class TeachingPipelineService {
  final Ref _ref;

  TeachingPipelineService(this._ref);

  /// Standard Kenya CBC Period Timings
  static const Map<int, List<int>> _timings = {
    1: [8, 0, 8, 40],
    2: [8, 40, 9, 20],
    3: [9, 20, 10, 0],
    // Break 10:00 - 10:30
    4: [10, 30, 11, 10],
    5: [11, 10, 11, 50],
    6: [11, 50, 12, 30],
    // Lunch 12:30 - 14:00
    7: [14, 0, 14, 40],
    8: [14, 40, 15, 20],
  };

  /// Detects which period we are currently in based on system time.
  /// Returns null if outside teaching hours or during breaks.
  int? getCurrentPeriod() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final totalMinutes = hour * 60 + minute;

    for (var entry in _timings.entries) {
      final start = entry.value[0] * 60 + entry.value[1];
      final end = entry.value[2] * 60 + entry.value[3];
      if (totalMinutes >= start && totalMinutes < end) {
        return entry.key;
      }
    }
    return null;
  }

  /// Gets the day of week (1=Mon, 5=Fri)
  int getCurrentDayOfWeek() {
    return DateTime.now().weekday;
  }

  /// Fetches the active slot for a teacher right now
  Future<TimetableSlot?> getActiveSlotForTeacher(String teacherId) async {
    final db = await _ref.read(databaseProvider.future);
    final activeTimetable = await db.timetableDao.getActiveTimetable();
    if (activeTimetable == null) return null;

    final period = getCurrentPeriod();
    final day = getCurrentDayOfWeek();
    if (period == null || day > 5) return null;

    final slots = await db.timetableDao.getSlotsForTeacher(activeTimetable.id, teacherId);
    try {
      return slots.firstWhere((s) => s.dayOfWeek == day && s.periodNumber == period);
    } catch (_) {
      return null;
    }
  }

  /// Opens a teaching session: Creating an AttendanceSessionModel
  Future<AttendanceSessionModel> openAttendanceSession(TimetableSlot slot) async {
    final db = await _ref.read(databaseProvider.future);
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Check if session already exists for this slot today
    final existing = await db.timetableDao.findSessionBySlotAndDate(slot.id, date);
    if (existing != null) return existing;

    final session = AttendanceSessionModel(
      id: const Uuid().v4(),
      slotId: slot.id,
      teacherId: slot.teacherId,
      classId: slot.classId,
      subjectId: slot.subjectId,
      period: slot.periodNumber,
      date: date,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await db.timetableDao.insertAttendanceSession(session);
    return session;
  }

  /// Completes a lesson execution and updates coverage
  Future<void> completeLesson({
    required AttendanceSessionModel session,
    required String status,
    String? notes,
    List<String>? evidencePaths,
  }) async {
    final db = await _ref.read(databaseProvider.future);
    
    final execution = LessonExecutionModel(
      id: const Uuid().v4(),
      slotId: session.slotId,
      attendanceSessionId: session.id,
      status: status,
      notes: notes,
      evidencePaths: evidencePaths?.toString(), // Simple serialization for now
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await db.timetableDao.insertLessonExecution(execution);
  }

  /// Module 6: Auto Coverage Calculation
  /// Coverage % = (Completed lessons / Required lessons in term) * 100
  Future<double> getCoverageAnalytics(String classId, String subjectId) async {
    final db = await _ref.read(databaseProvider.future);
    
    // 1. Get weekly demand
    final requirements = await db.timetableDao.findRequirementsByClass(classId);
    final req = requirements.where((r) => r.subjectId == subjectId).firstOrNull;
    if (req == null) return 0.0;

    // 2. Estimate term demand (13 weeks standard)
    final totalRequired = req.periodsPerWeek * 13;

    // 3. Get completed count
    final completed = await db.timetableDao.getCompletedLessonsCount(classId, subjectId) ?? 0;

    if (totalRequired == 0) return 0.0;
    return (completed / totalRequired) * 100;
  }

  /// Module 5: Daily Teaching Summary
  Future<Map<String, int>> getDailySummary(String teacherId) async {
    final db = await _ref.read(databaseProvider.future);
    final activeTimetable = await db.timetableDao.getActiveTimetable();
    if (activeTimetable == null) {
      return {'scheduled': 0, 'completed': 0, 'pending': 0, 'upcoming': 0};
    }

    final day = getCurrentDayOfWeek();
    final period = getCurrentPeriod() ?? 0;
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final mySlots = await db.timetableDao.getSlotsForTeacher(activeTimetable.id, teacherId);
    final todaySlots = mySlots.where((s) => s.dayOfWeek == day).toList();

    int completedCount = 0;
    int upcomingCount = 0;

    for (var slot in todaySlots) {
      final session = await db.timetableDao.findSessionBySlotAndDate(slot.id, date);
      if (session != null) {
        final execution = await db.timetableDao.findExecutionBySession(session.id);
        if (execution?.status == 'Completed') {
          completedCount++;
        }
      } else if (slot.periodNumber > period) {
        upcomingCount++;
      }
    }

    final pendingCount = todaySlots.length - completedCount - upcomingCount;

    return {
      'scheduled': todaySlots.length,
      'completed': completedCount,
      'pending': pendingCount > 0 ? pendingCount : 0,
      'upcoming': upcomingCount,
    };
  }
}
