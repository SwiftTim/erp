import 'package:floor/floor.dart';

// ── Teacher Timetable Profile (Capacity & Roles) ──────────────────────────────
@Entity(tableName: 'teacher_timetable_profiles')
class TeacherTimetableProfile {
  @PrimaryKey()
  final String id; // Typically the same as teacherId 
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  
  @ColumnInfo(name: 'max_periods_per_day')
  final int maxPeriodsPerDay; // e.g., 6 or 7 based on load balancing
  
  @ColumnInfo(name: 'max_periods_per_week')
  final int maxPeriodsPerWeek; // e.g., 30 (Engine rule to prevent overload)
  
  @ColumnInfo(name: 'is_class_teacher')
  final bool isClassTeacher; // Gives them overview of attendance, reports, etc.
  
  @ColumnInfo(name: 'special_role')
  final String? specialRole; // e.g., 'Deputy', 'Senior Teacher', 'HOD'

  const TeacherTimetableProfile({
    required this.id,
    required this.teacherId,
    required this.maxPeriodsPerDay,
    required this.maxPeriodsPerWeek,
    this.isClassTeacher = false,
    this.specialRole,
  });
}

// ── Teacher Subject Capability ───────────────────────────────────────────────
@Entity(
  tableName: 'teacher_subject_capabilities',
  indices: [Index(value: ['teacher_id', 'subject_id'], unique: true)],
)
class TeacherSubjectCapability {
  @PrimaryKey()
  final String id;
  
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  
  @ColumnInfo(name: 'subject_id') // Maps to LearningAreaModel.id
  final String subjectId;
  
  @ColumnInfo(name: 'priority_level')
  final int priorityLevel; // 1 = Primary, 2 = Secondary, 3 = Tertiary (Engine fallback logic)

  const TeacherSubjectCapability({
    required this.id,
    required this.teacherId,
    required this.subjectId,
    required this.priorityLevel,
  });
}

// ── Class Subject Requirement (Demand) ─────────────────────────────────────────
// Filled by the Deputy to define exact periods per subject for a specific class
@Entity(
  tableName: 'class_subject_requirements',
  indices: [Index(value: ['class_id', 'subject_id'], unique: true)],
)
class ClassSubjectRequirement {
  @PrimaryKey()
  final String id;
  
  @ColumnInfo(name: 'class_id')
  final String classId;
  
  @ColumnInfo(name: 'subject_id')
  final String subjectId;
  
  @ColumnInfo(name: 'periods_per_week')
  final int periodsPerWeek; // e.g., 5 for Mathematics, 3 for CRE

  const ClassSubjectRequirement({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.periodsPerWeek,
  });
}

// ── Timetable (Master Record) ────────────────────────────────────────────────
@Entity(tableName: 'timetables')
class TimetableModel {
  @PrimaryKey()
  final String id;
  
  @ColumnInfo(name: 'academic_year')
  final String academicYear; // e.g., '2026'
  
  final String term; // e.g., 'Term 1'
  
  @ColumnInfo(name: 'is_active')
  final bool isActive;
  
  @ColumnInfo(name: 'created_at')
  final int createdAt;

  const TimetableModel({
    required this.id,
    required this.academicYear,
    required this.term,
    this.isActive = false,
    required this.createdAt,
  });
}

// ── Timetable Slot (The 3D Matrix Blocks) ────────────────────────────────────
// Represents the actual generated schedule for day/period/class combinations
@Entity(
  tableName: 'timetable_slots',
  indices: [
    Index(value: ['timetable_id', 'day_of_week', 'period_number', 'class_id'], unique: true),
    Index(value: ['timetable_id', 'day_of_week', 'period_number', 'teacher_id'], unique: true),
    Index(value: ['timetable_id', 'day_of_week', 'period_number', 'teacher_id_2'], unique: false)
  ]
)
class TimetableSlot {
  @PrimaryKey()
  final String id;
  
  @ColumnInfo(name: 'timetable_id')
  final String timetableId;
  
  @ColumnInfo(name: 'day_of_week')
  final int dayOfWeek; // 1 = Monday, 2 = Tuesday, ..., 5 = Friday
  
  @ColumnInfo(name: 'period_number')
  final int periodNumber; // 1 to 8 (Based on max daily periods constraint)
  
  @ColumnInfo(name: 'class_id')
  final String classId;
  
  @ColumnInfo(name: 'subject_id')
  final String subjectId;
  
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;

  @ColumnInfo(name: 'teacher_id_2')
  final String? teacherId2;
  
  @ColumnInfo(name: 'is_locked')
  final bool isLocked; 

  const TimetableSlot({
    required this.id,
    required this.timetableId,
    required this.dayOfWeek,
    required this.periodNumber,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    this.teacherId2,
    this.isLocked = false,
  });
}

// ── Teacher Club Allocation ──────────────────────────────────────────────────
@Entity(tableName: 'teacher_clubs')
class TeacherClub {
  @PrimaryKey()
  final String id;
  
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  
  @ColumnInfo(name: 'club_name')
  final String clubName; // e.g., 'Wildlife Club', 'Debate Club'

  const TeacherClub({
    required this.id,
    required this.teacherId,
    required this.clubName,
  });
}

// ── Attendance Session (Linked to Timetable Slot) ─────────────────────────────
@Entity(tableName: 'attendance_sessions')
class AttendanceSessionModel {
  @PrimaryKey()
  final String id;
  
  @ColumnInfo(name: 'slot_id')
  final String slotId; // ID of the TimetableSlot
  
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  
  @ColumnInfo(name: 'class_id')
  final String classId;
  
  @ColumnInfo(name: 'subject_id')
  final String subjectId;
  
  final int period;
  final String date; // YYYY-MM-DD
  
  @ColumnInfo(name: 'is_substitute')
  final bool isSubstitute;
  
  @ColumnInfo(name: 'timestamp')
  final int timestamp; // Unix epoch ms

  const AttendanceSessionModel({
    required this.id,
    required this.slotId,
    required this.teacherId,
    required this.classId,
    required this.subjectId,
    required this.period,
    required this.date,
    this.isSubstitute = false,
    required this.timestamp,
  });
}

// ── Lesson Execution (Tracking Coverage & Completion) ──────────────────────────
@Entity(tableName: 'lesson_executions')
class LessonExecutionModel {
  @PrimaryKey()
  final String id;
  
  @ColumnInfo(name: 'slot_id')
  final String slotId;
  
  @ColumnInfo(name: 'attendance_session_id')
  final String attendanceSessionId;
  
  final String status; // Completed | Partial | Missed
  
  @ColumnInfo(name: 'coverage_weight')
  final double coverageWeight; // How much this lesson contributes to the strand coverage
  
  final String? notes;
  
  @ColumnInfo(name: 'evidence_paths')
  final String? evidencePaths; // JSON string list of file paths
  
  @ColumnInfo(name: 'timestamp')
  final int timestamp;

  const LessonExecutionModel({
    required this.id,
    required this.slotId,
    required this.attendanceSessionId,
    required this.status,
    this.coverageWeight = 1.0, 
    this.notes,
    this.evidencePaths,
    required this.timestamp,
  });
}
