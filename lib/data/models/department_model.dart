// lib/data/models/department_model.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'departments')
class DepartmentModel {
  @PrimaryKey()
  final String id;
  final String name;
  final String description;
  @ColumnInfo(name: 'created_by')
  final String createdBy;
  @ColumnInfo(name: 'created_at')
  final int createdAt;
  final String status; // 'active', 'inactive'

  DepartmentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.status = 'active',
  });
}

@Entity(
  tableName: 'department_members',
  foreignKeys: [
    ForeignKey(
      childColumns: ['department_id'],
      parentColumns: ['id'],
      entity: DepartmentModel,
    ),
  ],
)
class DepartmentMemberModel {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  @ColumnInfo(name: 'department_id')
  final String departmentId;
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  final String role; // 'member', 'hod', 'assistant_hod'
  @ColumnInfo(name: 'assigned_at')
  final int assignedAt;

  DepartmentMemberModel({
    this.id,
    required this.departmentId,
    required this.teacherId,
    required this.role,
    required this.assignedAt,
  });
}

@Entity(tableName: 'subject_term_approvals')
class SubjectTermApprovalModel {
  @PrimaryKey()
  final String id; // format: classId_subjectId_term_year
  @ColumnInfo(name: 'class_id')
  final String classId;
  @ColumnInfo(name: 'subject_id')
  final String subjectId;
  final int term;
  final String year;
  final String status; // 'draft', 'submitted_by_teacher', 'approved_by_hod', 'locked'
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  @ColumnInfo(name: 'last_updated')
  final int lastUpdated;

  SubjectTermApprovalModel({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.term,
    required this.year,
    required this.status,
    required this.teacherId,
    required this.lastUpdated,
  });
}

@Entity(tableName: 'approval_logs')
class ApprovalLogModel {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  @ColumnInfo(name: 'entity_type')
  final String entityType; // e.g., 'term_approval', 'assessment'
  @ColumnInfo(name: 'entity_id')
  final String entityId;
  final String action; // 'SUBMITTED', 'APPROVED', 'REJECTED', 'RETURNED'
  @ColumnInfo(name: 'performed_by')
  final String performedBy;
  final String? comments;
  final int timestamp;

  ApprovalLogModel({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.performedBy,
    this.comments,
    required this.timestamp,
  });
}
