import 'package:floor/floor.dart';
import '../../models/tod_model.dart';
import '../../models/user_model.dart';
import '../../models/student_model.dart';

@dao
abstract class TodDao {
  // --- Duty Roster ---
  @Query('SELECT * FROM duty_roster')
  Future<List<DutyRosterModel>> getAllDutyRosters();

  @Query('SELECT * FROM duty_roster WHERE week_number = :weekNumber')
  Future<List<DutyRosterModel>> getDutyRostersByWeek(int weekNumber);

  @Query('SELECT * FROM duty_roster WHERE teacher_id = :teacherId')
  Future<List<DutyRosterModel>> getDutyRostersByTeacher(String teacherId);
  
  @Query('SELECT * FROM duty_roster WHERE :date BETWEEN start_date AND end_date')
  Future<List<DutyRosterModel>> getDutyRosterForDate(int date);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertDutyRoster(DutyRosterModel roster);

  @insert
  Future<void> insertDutyRosters(List<DutyRosterModel> rosters);

  @Query('DELETE FROM duty_roster')
  Future<void> clearDutyRosters();

  @Query('DELETE FROM duty_roster WHERE week_number = :weekNumber')
  Future<void> clearDutyRostersByWeek(int weekNumber);

  // --- Tod Records ---
  @Query('SELECT * FROM tod_records ORDER BY date DESC')
  Future<List<TodRecordModel>> getAllTodRecords();

  @Query('SELECT * FROM tod_records WHERE teacher_id = :teacherId ORDER BY date DESC')
  Future<List<TodRecordModel>> getTodRecordsByTeacher(String teacherId);

  @Query('SELECT * FROM tod_records WHERE student_id = :studentId ORDER BY date DESC')
  Future<List<TodRecordModel>> getTodRecordsByStudent(String studentId);
  
  @Query('SELECT * FROM tod_records WHERE date >= :startOfDay AND date <= :endOfDay')
  Future<List<TodRecordModel>> getTodRecordsByDateRange(int startOfDay, int endOfDay);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertTodRecord(TodRecordModel record);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateTodRecord(TodRecordModel record);

  // --- Student Behavior ---
  @Query('SELECT * FROM student_behavior')
  Future<List<StudentBehaviorModel>> getAllStudentBehaviors();

  @Query('SELECT * FROM student_behavior WHERE student_id = :studentId')
  Future<StudentBehaviorModel?> getStudentBehavior(String studentId);
  
  @Query('SELECT * FROM student_behavior WHERE status = :status')
  Future<List<StudentBehaviorModel>> getStudentBehaviorsByStatus(String status);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertStudentBehavior(StudentBehaviorModel behavior);
  
  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateStudentBehavior(StudentBehaviorModel behavior);
  
  @Query('DELETE FROM student_behavior')
  Future<void> clearStudentBehaviors();
}
