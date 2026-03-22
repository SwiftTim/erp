// lib/data/local/daos/enterprise_dao.dart

import 'package:floor/floor.dart';
import '../../models/enterprise_models.dart';
import '../../models/student_model.dart';

@dao
abstract class EnterpriseDao {
  // ── Teaching Assignments ──────────────────────────────────────────────────
  @Query('SELECT * FROM teaching_assignments WHERE teacherId = :teacherId')
  Future<List<TeachingAssignment>> findAssignmentsByTeacher(String teacherId);

  @Query('SELECT * FROM teaching_assignments WHERE classId = :classId')
  Future<List<TeachingAssignment>> findAssignmentsByClass(String classId);

  @insert
  Future<void> insertAssignment(TeachingAssignment assignment);


  // ── Official Memos ────────────────────────────────────────────────────────
  @Query('SELECT * FROM official_memos ORDER BY createdAt DESC')
  Future<List<OfficialMemo>> findAllMemos();

  @Query('SELECT * FROM official_memos WHERE targetGroup = :group OR targetGroup = "ALL" ORDER BY createdAt DESC')
  Future<List<OfficialMemo>> findMemosForGroup(String group);

  @insert
  Future<void> insertMemo(OfficialMemo memo);

  @insert
  Future<void> logMemoRead(MemoReadRecord record);

  @Query('SELECT COUNT(*) FROM memo_reads WHERE memoId = :memoId')
  Future<int?> getMemoReadCount(String memoId);

  // ── Staff Leaves ──────────────────────────────────────────────────────────
  @Query('SELECT * FROM staff_leaves WHERE status = "PENDING"')
  Future<List<StaffLeave>> findPendingLeaves();

  @update
  Future<void> updateLeave(StaffLeave leave);

  @insert
  Future<void> requestLeave(StaffLeave leave);

  // ── Inventory ─────────────────────────────────────────────────────────────
  @Query('SELECT * FROM inventory_assets')
  Future<List<InventoryAsset>> findAllAssets();

  @insert
  Future<void> insertAsset(InventoryAsset asset);

  @Query('SELECT * FROM asset_maintenance_logs WHERE asset_id = :assetId ORDER BY serviced_at DESC')
  Future<List<AssetMaintenanceLog>> findMaintenanceLogs(String assetId);

  @insert
  Future<void> insertMaintenanceLog(AssetMaintenanceLog log);


  // ── System Logs ───────────────────────────────────────────────────────────
  @Query('SELECT * FROM system_activity_logs ORDER BY timestamp DESC LIMIT 100')
  Future<List<SystemLog>> getRecentLogs();

  @insert
  Future<void> logActivity(SystemLog log);


  // ── Substitutions ──────────────────────────────────────────────────────────
  @Query('SELECT * FROM substitutions WHERE substitute_teacher_id = :teacherId AND date = :date')
  Future<List<Substitution>> findActiveSubstitutions(String teacherId, int date);

  @Query('SELECT * FROM substitutions WHERE date = :date')
  Future<List<Substitution>> findAllSubstitutionsByDate(int date);

  @insert
  Future<void> insertSubstitution(Substitution substitution);

  @delete
  Future<void> deleteSubstitution(Substitution substitution);

  // ── Staff Attendance ──────────────────────────────────────────────────────
  @Query('SELECT * FROM staff_attendance WHERE staff_id = :staffId AND date = :date')
  Future<StaffAttendance?> findStaffAttendance(String staffId, int date);

  @insert
  Future<void> clockIn(StaffAttendance attendance);

  @update
  Future<void> clockOut(StaffAttendance attendance);

  @Query('SELECT * FROM staff_attendance WHERE date = :date')
  Future<List<StaffAttendance>> findAllStaffAttendance(int date);
}


