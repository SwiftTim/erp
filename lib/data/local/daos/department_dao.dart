// lib/data/local/daos/department_dao.dart

import 'package:floor/floor.dart';
import '../../models/department_model.dart';
import '../../models/curriculum_models.dart';

@dao
abstract class DepartmentDao {
  @insert
  Future<void> insertDepartment(DepartmentModel department);

  @update
  Future<void> updateDepartment(DepartmentModel department);

  @Query("SELECT * FROM departments WHERE status = 'active'")
  Future<List<DepartmentModel>> getAllActiveDepartments();

  @Query('SELECT * FROM departments WHERE id = :id')
  Future<DepartmentModel?> getDepartmentById(String id);

  // Department Members
  @insert
  Future<void> insertMember(DepartmentMemberModel member);

  @delete
  Future<void> removeMember(DepartmentMemberModel member);

  @Query('SELECT * FROM department_members WHERE department_id = :deptId')
  Future<List<DepartmentMemberModel>> getMembersByDepartment(String deptId);

  @Query('SELECT * FROM department_members WHERE teacher_id = :teacherId')
  Future<List<DepartmentMemberModel>> getDepartmentsByTeacher(String teacherId);

  // Subjects in Department
  @Query('SELECT * FROM learning_areas WHERE department_id = :deptId')
  Future<List<LearningAreaModel>> getSubjectsByDepartment(String deptId);

  // Approval Flow
  @insert
  Future<void> insertTermApproval(SubjectTermApprovalModel approval);

  @update
  Future<void> updateTermApproval(SubjectTermApprovalModel approval);

  @Query('SELECT * FROM subject_term_approvals WHERE id = :id')
  Future<SubjectTermApprovalModel?> getTermApprovalById(String id);

  @Query('SELECT * FROM subject_term_approvals WHERE class_id = :classId AND subject_id = :subjectId AND term = :term AND year = :year')
  Future<SubjectTermApprovalModel?> getStatus(String classId, String subjectId, int term, String year);

  @Query('SELECT * FROM subject_term_approvals WHERE status = :status')
  Future<List<SubjectTermApprovalModel>> getApprovalsByStatus(String status);

  // Logs
  @insert
  Future<void> insertLog(ApprovalLogModel log);

  @Query('SELECT * FROM approval_logs WHERE entity_id = :entityId ORDER BY timestamp DESC')
  Future<List<ApprovalLogModel>> getLogsForEntity(String entityId);

  @Query("DELETE FROM department_members WHERE department_id = :deptId AND (role = 'hod' OR role = 'HOD')")
  Future<void> clearHOD(String deptId);

  @Query('SELECT * FROM departments')
  Future<List<DepartmentModel>> getAllDepartments();

  @Query('SELECT * FROM department_members')
  Future<List<DepartmentMemberModel>> getAllMembers();

  @Query('DELETE FROM department_members WHERE teacher_id = :teacherId AND department_id = :deptId')
  Future<void> removeMemberFromDept(String teacherId, String deptId);
}
