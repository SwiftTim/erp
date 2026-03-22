// lib/data/local/daos/club_dao.dart

import 'package:floor/floor.dart';
import '../../models/club_model.dart';
import '../../models/student_model.dart';

@dao
abstract class ClubDao {
  @insert
  Future<void> insertClub(ClubModel club);

  @update
  Future<void> updateClub(ClubModel club);

  @Query('SELECT * FROM clubs WHERE status = "active"')
  Future<List<ClubModel>> getAllActiveClubs();

  @Query('SELECT * FROM clubs WHERE id = :id')
  Future<ClubModel?> getClubById(String id);

  @Query('SELECT * FROM clubs WHERE patron_id = :patronId')
  Future<List<ClubModel>> getClubsByPatron(String patronId);

  // Membership
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertMember(ClubMemberModel member);

  @delete
  Future<void> removeMember(ClubMemberModel member);

  @Query('SELECT * FROM club_members WHERE club_id = :clubId')
  Future<List<ClubMemberModel>> getMembersByClub(String clubId);

  @Query('SELECT COUNT(*) FROM club_members WHERE student_id = :studentId')
  Future<int?> getStudentClubCount(String studentId);

  @Query('SELECT * FROM club_members WHERE student_id = :studentId AND club_id = :clubId')
  Future<ClubMemberModel?> getMembership(String studentId, String clubId);
  
  @Query('DELETE FROM club_members WHERE student_id = :studentId AND club_id = :clubId')
  Future<void> removeStudentFromClub(String studentId, String clubId);

  // Activities
  @insert
  Future<void> insertActivity(ClubActivityModel activity);

  @update
  Future<void> updateActivity(ClubActivityModel activity);

  @Query('SELECT * FROM club_activities WHERE club_id = :clubId ORDER BY scheduled_at DESC')
  Future<List<ClubActivityModel>> getActivitiesByClub(String clubId);

  @Query('SELECT * FROM club_activities WHERE id = :id')
  Future<ClubActivityModel?> getActivityById(String id);

  // Attendance
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAttendance(ClubAttendanceModel attendance);

  @Query('SELECT * FROM club_attendance WHERE activity_id = :activityId')
  Future<List<ClubAttendanceModel>> getAttendanceByActivity(String activityId);

  // Reports
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertReport(ClubReportModel report);

  @Query('SELECT * FROM club_reports WHERE club_id = :clubId ORDER BY submitted_at DESC')
  Future<List<ClubReportModel>> getReportsByClub(String clubId);
  
  @Query('SELECT * FROM clubs')
  Future<List<ClubModel>> getAllClubs();

  @Query('''
    SELECT * FROM students 
    WHERE CAST(SUBSTR(grade, 7) AS INTEGER) BETWEEN 4 AND 9 
    AND id NOT IN (SELECT student_id FROM club_members WHERE club_id = :clubId)
  ''')
  // Note: SUBSTR(grade, 7) is risky if grade name varies. 
  // Better to use a specific filter in service if needed, but this is a rough SQL for Grade 4-9
  Future<List<StudentModel>> getEligibleStudentsForClub(String clubId);
}
