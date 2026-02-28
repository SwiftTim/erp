// lib/features/departments/department_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_database.dart';
import '../../data/models/department_model.dart';
import '../../data/models/user_model.dart';
import '../../features/auth/auth_provider.dart';

final departmentServiceProvider = Provider((ref) => DepartmentService(ref));

class DepartmentService {
  final Ref _ref;

  DepartmentService(this._ref);

  Future<List<DepartmentModel>> getMyDepartments(String teacherId) async {
    final db = await _ref.read(databaseProvider.future);
    final memberships = await db.departmentDao.getDepartmentsByTeacher(teacherId);
    final List<DepartmentModel> depts = [];
    for (var m in memberships) {
      final d = await db.departmentDao.getDepartmentById(m.departmentId);
      if (d != null) depts.add(d);
    }
    return depts;
  }

  Future<String?> getRoleInDepartment(String teacherId, String deptId) async {
    final db = await _ref.read(databaseProvider.future);
    final memberships = await db.departmentDao.getMembersByDepartment(deptId);
    final member = memberships.where((m) => m.teacherId == teacherId).firstOrNull;
    return member?.role;
  }

  Future<void> submitTermResults({
    required String classId,
    required String subjectId,
    required int term,
    required String year,
    required String teacherId,
  }) async {
    final db = await _ref.read(databaseProvider.future);
    final id = '${classId}_${subjectId}_${term}_$year';
    
    final approval = SubjectTermApprovalModel(
      id: id,
      classId: classId,
      subjectId: subjectId,
      term: term,
      year: year,
      status: 'submitted_by_teacher',
      teacherId: teacherId,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );

    await db.departmentDao.insertTermApproval(approval);

    await db.departmentDao.insertLog(ApprovalLogModel(
      entityType: 'term_approval',
      entityId: id,
      action: 'SUBMITTED',
      performedBy: teacherId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<void> approveTermResults({
    required String approvalId,
    required String hodId,
    String? comments,
  }) async {
    final db = await _ref.read(databaseProvider.future);
    final existing = await db.departmentDao.getTermApprovalById(approvalId);
    if (existing == null) return;

    final updated = SubjectTermApprovalModel(
      id: existing.id,
      classId: existing.classId,
      subjectId: existing.subjectId,
      term: existing.term,
      year: existing.year,
      status: 'approved_by_hod',
      teacherId: existing.teacherId,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );

    await db.departmentDao.updateTermApproval(updated);

    await db.departmentDao.insertLog(ApprovalLogModel(
      entityType: 'term_approval',
      entityId: approvalId,
      action: 'APPROVED',
      performedBy: hodId,
      comments: comments,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<void> rejectTermResults({
    required String approvalId,
    required String hodId,
    required String comments,
  }) async {
    final db = await _ref.read(databaseProvider.future);
    final existing = await db.departmentDao.getTermApprovalById(approvalId);
    if (existing == null) return;

    final updated = SubjectTermApprovalModel(
      id: existing.id,
      classId: existing.classId,
      subjectId: existing.subjectId,
      term: existing.term,
      year: existing.year,
      status: 'returned_to_teacher',
      teacherId: existing.teacherId,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );

    await db.departmentDao.updateTermApproval(updated);

    await db.departmentDao.insertLog(ApprovalLogModel(
      entityType: 'term_approval',
      entityId: approvalId,
      action: 'REJECTED',
      performedBy: hodId,
      comments: comments,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<double> calculateDepartmentHealth(String deptId) async {
    // Basic deterministic mock for visuals
    return (deptId.hashCode % 40) + 60.0; 
  }

  // ── 🔥 NEW ENHANCED GOVERNANCE LOGIC ───────────────────────────────────────

  Future<void> assignHOD(String teacherId, String deptId) async {
    final db = await _ref.read(databaseProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Clear current HOD for this department
    await db.departmentDao.clearHOD(deptId);

    // 2. Add as HOD to department_members
    await db.departmentDao.insertMember(DepartmentMemberModel(
      departmentId: deptId,
      teacherId: teacherId,
      role: 'hod',
      assignedAt: now,
    ));

    // 3. Update UserModel for legacy/navigation support
    final teacher = await db.userDao.findById(teacherId);
    if (teacher != null) {
      final updated = teacher.copyWith(
        departmentId: deptId,
        roleFlags: _addFlag(teacher.roleFlags, 'HOD'),
      );
      await db.userDao.updateUser(updated);
    }
  }

  Future<void> addMember(String teacherId, String deptId) async {
    final db = await _ref.read(databaseProvider.future);
    await db.departmentDao.insertMember(DepartmentMemberModel(
      departmentId: deptId,
      teacherId: teacherId,
      role: 'member',
      assignedAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<void> removeMember(String teacherId, String deptId) async {
    final db = await _ref.read(databaseProvider.future);
    await db.departmentDao.removeMemberFromDept(teacherId, deptId);
  }

  Future<void> autoAllocateAllTeachers() async {
    final db = await _ref.read(databaseProvider.future);
    final teachers = await db.userDao.findAll();
    
    for (var teacher in teachers) {
      if (teacher.roleLevel > 3) continue; // Only teachers

      final assignments = await db.enterpriseDao.findAssignmentsByTeacher(teacher.id);
      final myAssignment = assignments.firstOrNull;

      if (myAssignment != null) {
        final area = await db.curriculumDao.findAllLearningAreas().then((list) => list.where((a) => a.id == myAssignment.subjectId).firstOrNull);
        if (area != null && area.departmentId != null) {
          final existing = await db.departmentDao.getDepartmentsByTeacher(teacher.id);
          if (existing.isEmpty) {
            await addMember(teacher.id, area.departmentId!);
          }
        }
      }
    }
  }

  String _addFlag(String? current, String flag) {
    if (current == null || current.isEmpty) return '["$flag"]';
    if (current.contains(flag)) return current;
    // Basic JSON insertion
    return current.replaceFirst(']', ',"$flag"]');
  }
}
