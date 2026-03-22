// lib/data/local/daos/dept_activity_dao.dart

import 'package:floor/floor.dart';
import '../../models/department_activity_model.dart';

@dao
abstract class DeptActivityDao {

  // ── Documents ──────────────────────────────────────────────────────────────
  @insert
  Future<void> insertDocument(DeptDocument doc);

  @update
  Future<void> updateDocument(DeptDocument doc);

  @Query('SELECT * FROM dept_documents WHERE department_id = :deptId ORDER BY uploaded_at DESC')
  Future<List<DeptDocument>> getDocsByDept(String deptId);

  @Query('SELECT * FROM dept_documents WHERE department_id = :deptId AND category = :category ORDER BY uploaded_at DESC')
  Future<List<DeptDocument>> getDocsByCategory(String deptId, String category);

  @Query('DELETE FROM dept_documents WHERE id = :id')
  Future<void> deleteDocument(String id);

  // ── Meetings ───────────────────────────────────────────────────────────────
  @insert
  Future<void> insertMeeting(DeptMeeting meeting);

  @update
  Future<void> updateMeeting(DeptMeeting meeting);

  @Query('SELECT * FROM dept_meetings WHERE department_id = :deptId ORDER BY scheduled_at DESC')
  Future<List<DeptMeeting>> getMeetingsByDept(String deptId);

  @Query('SELECT * FROM dept_meetings WHERE department_id = :deptId AND status = :status ORDER BY scheduled_at DESC')
  Future<List<DeptMeeting>> getMeetingsByStatus(String deptId, String status);

  // ── Activities (module entries) ────────────────────────────────────────────
  @insert
  Future<void> insertActivity(DeptActivity activity);

  @update
  Future<void> updateActivity(DeptActivity activity);

  @Query('SELECT * FROM dept_activities WHERE department_id = :deptId ORDER BY recorded_at DESC')
  Future<List<DeptActivity>> getActivitiesByDept(String deptId);

  @Query('SELECT * FROM dept_activities WHERE department_id = :deptId AND module_type = :moduleType ORDER BY recorded_at DESC')
  Future<List<DeptActivity>> getActivitiesByModule(String deptId, String moduleType);

  @Query('SELECT * FROM dept_activities WHERE department_id = :deptId AND status = :status ORDER BY recorded_at DESC')
  Future<List<DeptActivity>> getActivitiesByStatus(String deptId, String status);

  // ── Compliance ─────────────────────────────────────────────────────────────
  @insert
  Future<void> insertCompliance(DeptCompliance item);

  @update
  Future<void> updateCompliance(DeptCompliance item);

  @Query('SELECT * FROM dept_compliance WHERE department_id = :deptId AND term = :term AND year = :year')
  Future<List<DeptCompliance>> getComplianceItems(String deptId, String term, String year);

  @Query('SELECT * FROM dept_compliance WHERE department_id = :deptId')
  Future<List<DeptCompliance>> getAllComplianceItems(String deptId);

  @Query('DELETE FROM dept_compliance WHERE id = :id')
  Future<void> deleteCompliance(int id);
}
