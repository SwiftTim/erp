import 'package:uuid/uuid.dart';
import '../data/local/app_database.dart';
import '../data/models/tod_model.dart';
import '../../core/constants/app_constants.dart';

class TodService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  TodService(this._db);

  // --- Duty Rotation Engine ---

  /// Generates a rotation for the next [weeksCount] weeks.
  /// Minimum 2 teachers per week.
  Future<void> generateRotation({int weeksCount = 12, int teachersPerWeek = 2}) async {
    // 1. Load all active users and filter for Teachers (Role 5) and Senior Teachers (Role 4)
    final activeUsers = await _db.userDao.findAllActive();
    final teachers = activeUsers.where((u) => 
      u.roleLevel == AppConstants.roleTeacher || 
      u.roleLevel == AppConstants.roleSeniorTeacher
    ).toList();
    
    if (teachers.isEmpty) return;

    // 2. Clear existing roster or find where we left off
    // For simplicity in this engine, we'll generate starting from current week if roster is empty.
    
    final now = DateTime.now();
    int currentWeek = _getWeekNumber(now);
    
    // Sort teachers to ensure consistent rotation order
    teachers.sort((a, b) => a.id.compareTo(b.id));

    List<DutyRosterModel> newRosters = [];
    int teacherIndex = 0;

    for (int w = 0; w < weeksCount; w++) {
      int weekNum = currentWeek + w;
      DateTime startOfWeek = _findStartOfWeek(now.add(Duration(days: 7 * w)));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

      for (int i = 0; i < teachersPerWeek; i++) {
        final teacher = teachers[teacherIndex % teachers.length];
        newRosters.add(DutyRosterModel(
          id: _uuid.v4(),
          teacherId: teacher.id,
          weekNumber: weekNum,
          startDate: startOfWeek.millisecondsSinceEpoch,
          endDate: endOfWeek.millisecondsSinceEpoch,
        ));
        teacherIndex++;
      }
    }

    await _db.todDao.insertDutyRosters(newRosters);
  }

  /// Override a specific roster entry
  Future<void> overrideRoster(String rosterId, String newTeacherId) async {
    // This assumes we have a way to fetch a single roster by ID, which I should add to DAO if not there.
    // Or just fetch all, modify, and re-insert.
    final all = await _db.todDao.getAllDutyRosters();
    final index = all.indexWhere((r) => r.id == rosterId);
    if (index != -1) {
      final old = all[index];
      await _db.todDao.insertDutyRoster(DutyRosterModel(
        id: old.id,
        teacherId: newTeacherId,
        weekNumber: old.weekNumber,
        startDate: old.startDate,
        endDate: old.endDate,
      ));
    }
  }

  // --- Discipline Logic ---

  Future<void> recordOffence({
    required String studentId,
    required String teacherId,
    required String offence,
    required String punishment,
    String? remarks,
  }) async {
    final record = TodRecordModel(
      id: _uuid.v4(),
      studentId: studentId,
      offence: offence,
      punishment: punishment,
      remarks: remarks,
      teacherId: teacherId,
      date: DateTime.now().millisecondsSinceEpoch,
      status: 'Recorded',
    );

    await _db.todDao.insertTodRecord(record);
    await _updateStudentBehavior(studentId);
  }

  Future<void> _updateStudentBehavior(String studentId) async {
    // Count offences in current week
    final now = DateTime.now();
    final startOfWeek = _findStartOfWeek(now).millisecondsSinceEpoch;
    final endOfWeek = startOfWeek + (7 * 24 * 60 * 60 * 1000);

    final records = await _db.todDao.getAllTodRecords();
    final weeklyRecords = records.where((r) => 
      r.studentId == studentId && 
      r.date >= startOfWeek && 
      r.date <= endOfWeek
    ).toList();

    int count = weeklyRecords.length;
    String status = 'Normal';
    if (count >= 3) {
      status = 'Red';
    } else if (count >= 2) {
      status = 'Amber';
    }

    await _db.todDao.insertStudentBehavior(StudentBehaviorModel(
      studentId: studentId,
      weeklyOffences: count,
      status: status,
    ));
  }

  Future<Map<String, dynamic>> compileDailyReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + (24 * 60 * 60 * 1000);

    final records = await _db.todDao.getTodRecordsByDateRange(startOfDay, endOfDay);
    
    // Group records or just return summary
    return {
      'date': date,
      'totalCases': records.length,
      'records': records,
    };
  }

  // --- Helpers ---

  int _getWeekNumber(DateTime date) {
    // Simple week number calculation
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  DateTime _findStartOfWeek(DateTime date) {
    // Assume Monday is start of week
    return date.subtract(Duration(days: date.weekday - 1)).subtract(
      Duration(hours: date.hour, minutes: date.minute, seconds: date.second, milliseconds: date.millisecond, microseconds: date.microsecond)
    );
  }
}
