import 'package:floor/floor.dart';
import '../../models/timetable_models.dart';

@dao
abstract class TimetableDao {
  // ── Teacher Profiles ────────────────────────────────────────────────────────
  @Query('SELECT * FROM teacher_timetable_profiles')
  Future<List<TeacherTimetableProfile>> findAllTeacherProfiles();

  @Query('SELECT * FROM teacher_timetable_profiles WHERE teacher_id = :teacherId')
  Future<TeacherTimetableProfile?> findTeacherProfileById(String teacherId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertTeacherProfile(TeacherTimetableProfile profile);

  // ── Teacher Subject Capabilities ────────────────────────────────────────────
  @Query('SELECT * FROM teacher_subject_capabilities WHERE teacher_id = :teacherId')
  Future<List<TeacherSubjectCapability>> findCapabilitiesByTeacher(String teacherId);

  @Query('SELECT * FROM teacher_subject_capabilities')
  Future<List<TeacherSubjectCapability>> findAllCapabilities();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertTeacherCapability(TeacherSubjectCapability capability);

  // ── Class Subject Requirements (Demand) ──────────────────────────────────────
  @Query('SELECT * FROM class_subject_requirements')
  Future<List<ClassSubjectRequirement>> findAllClassRequirements();

  @Query('SELECT * FROM class_subject_requirements WHERE class_id = :classId')
  Future<List<ClassSubjectRequirement>> findRequirementsByClass(String classId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertClassRequirement(ClassSubjectRequirement requirement);

  // ── Timetable Entries & Slots ────────────────────────────────────────────────
  @Query('SELECT * FROM timetables WHERE is_active = 1 ORDER BY created_at DESC LIMIT 1')
  Future<TimetableModel?> getActiveTimetable();

  @Query('UPDATE timetables SET is_active = 0')
  Future<void> deactivateAllTimetables();

  @Query('DELETE FROM timetables')
  Future<void> clearAllTimetables();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertTimetable(TimetableModel timetable);

  @Query('SELECT * FROM timetable_slots WHERE id = :id')
  Future<TimetableSlot?> findSlotById(String id);

  @Query('SELECT * FROM timetable_slots WHERE timetable_id = :timetableId')
  Future<List<TimetableSlot>> getSlotsForTimetable(String timetableId);

  @Query('SELECT * FROM timetable_slots WHERE timetable_id = :timetableId AND class_id = :classId')
  Future<List<TimetableSlot>> getSlotsForClass(String timetableId, String classId);

  @Query('SELECT * FROM timetable_slots WHERE timetable_id = :timetableId AND (teacher_id = :teacherId OR teacher_id_2 = :teacherId)')
  Future<List<TimetableSlot>> getSlotsForTeacher(String timetableId, String teacherId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertTimetableSlots(List<TimetableSlot> slots);

  @Query('DELETE FROM timetable_slots WHERE timetable_id = :timetableId')
  Future<void> clearSlotsForTimetable(String timetableId);

  @Query('DELETE FROM teacher_timetable_profiles')
  Future<void> clearAllTeacherProfiles();

  @Query('DELETE FROM teacher_subject_capabilities')
  Future<void> clearAllCapabilities();

  @Query('DELETE FROM class_subject_requirements')
  Future<void> clearAllRequirements();

  // ── Attendance Session & Lesson Execution ───────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAttendanceSession(AttendanceSessionModel session);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLessonExecution(LessonExecutionModel execution);

  @Query('SELECT * FROM attendance_sessions WHERE slot_id = :slotId AND date = :date')
  Future<AttendanceSessionModel?> findSessionBySlotAndDate(String slotId, String date);

  @Query('SELECT * FROM lesson_executions WHERE attendance_session_id = :sessionId')
  Future<LessonExecutionModel?> findExecutionBySession(String sessionId);

  @Query('''
    SELECT COUNT(*) FROM lesson_executions le
    JOIN attendance_sessions asess ON le.attendance_session_id = asess.id
    WHERE asess.class_id = :classId 
    AND asess.subject_id = :subjectId 
    AND le.status = 'Completed'
  ''')
  Future<int?> getCompletedLessonsCount(String classId, String subjectId);
}
