// lib/data/models/department_activity_model.dart
// Extended models for full-scale department management

import 'package:floor/floor.dart';
import 'department_model.dart';

// ── Department Document (uploads for schemes, reports, etc.) ─────────────────
@Entity(
  tableName: 'dept_documents',
  foreignKeys: [
    ForeignKey(
      childColumns: ['department_id'],
      parentColumns: ['id'],
      entity: DepartmentModel,
    ),
  ],
)
class DeptDocument {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'department_id')
  final String departmentId;
  final String title;
  final String category; // 'scheme', 'report', 'moderation', 'safety', 'plan', 'minutes'
  @ColumnInfo(name: 'file_path')
  final String? filePath; // local path or URL
  @ColumnInfo(name: 'file_name')
  final String fileName;
  final String? description;
  @ColumnInfo(name: 'uploaded_by')
  final String uploadedBy;
  @ColumnInfo(name: 'uploaded_at')
  final int uploadedAt;
  final String status; // 'pending', 'approved', 'rejected'

  DeptDocument({
    required this.id,
    required this.departmentId,
    required this.title,
    required this.category,
    this.filePath,
    required this.fileName,
    this.description,
    required this.uploadedBy,
    required this.uploadedAt,
    this.status = 'pending',
  });
}

// ── Department Meeting ────────────────────────────────────────────────────────
@Entity(
  tableName: 'dept_meetings',
  foreignKeys: [
    ForeignKey(
      childColumns: ['department_id'],
      parentColumns: ['id'],
      entity: DepartmentModel,
    ),
  ],
)
class DeptMeeting {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'department_id')
  final String departmentId;
  final String title;
  final String agenda;
  @ColumnInfo(name: 'scheduled_at')
  final int scheduledAt;
  final String venue;
  final String? minutes; // recorded minutes post-meeting
  @ColumnInfo(name: 'organized_by')
  final String organizedBy;
  final String status; // 'scheduled', 'completed', 'cancelled'

  DeptMeeting({
    required this.id,
    required this.departmentId,
    required this.title,
    required this.agenda,
    required this.scheduledAt,
    required this.venue,
    this.minutes,
    required this.organizedBy,
    this.status = 'scheduled',
  });
}

// ── Department Activity / Module Entry ────────────────────────────────────────
// Generic key-value activity log for all department module events
@Entity(
  tableName: 'dept_activities',
  foreignKeys: [
    ForeignKey(
      childColumns: ['department_id'],
      parentColumns: ['id'],
      entity: DepartmentModel,
    ),
  ],
)
class DeptActivity {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  @ColumnInfo(name: 'department_id')
  final String departmentId;
  @ColumnInfo(name: 'module_type')
  final String moduleType; 
  // e.g. 'reading_fluency', 'oral_assessment', 'lab_booking', 'equipment',
  //      'fieldwork', 'strand_assessment', 'safety_incident', 'skill_cert',
  //      'iep', 'case_mgmt', 'device_inventory', 'exam_builder'
  final String title;
  final String? data; // JSON blob for module-specific fields
  @ColumnInfo(name: 'recorded_by')
  final String recordedBy;
  @ColumnInfo(name: 'recorded_at')
  final int recordedAt;
  final String status; // 'open', 'in_progress', 'completed', 'flagged'
  final String? grade; // optional grade filter
  final String? subject; // optional subject filter

  DeptActivity({
    this.id,
    required this.departmentId,
    required this.moduleType,
    required this.title,
    this.data,
    required this.recordedBy,
    required this.recordedAt,
    this.status = 'open',
    this.grade,
    this.subject,
  });
}

// ── HOD Compliance Checklist Item ─────────────────────────────────────────────
@Entity(
  tableName: 'dept_compliance',
  foreignKeys: [
    ForeignKey(
      childColumns: ['department_id'],
      parentColumns: ['id'],
      entity: DepartmentModel,
    ),
  ],
)
class DeptCompliance {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  @ColumnInfo(name: 'department_id')
  final String departmentId;
  final String item; // e.g. "Schemes of Work submitted", "Safety checklist done"
  @ColumnInfo(name: 'is_done')
  final int isDone; // 0 or 1
  @ColumnInfo(name: 'due_date')
  final int? dueDate;
  @ColumnInfo(name: 'completed_by')
  final String? completedBy;
  @ColumnInfo(name: 'completed_at')
  final int? completedAt;
  final String term; // '1', '2', '3'
  final String year;

  DeptCompliance({
    this.id,
    required this.departmentId,
    required this.item,
    this.isDone = 0,
    this.dueDate,
    this.completedBy,
    this.completedAt,
    required this.term,
    required this.year,
  });

  DeptCompliance copyWith({int? isDone, String? completedBy, int? completedAt}) =>
      DeptCompliance(
        id: id,
        departmentId: departmentId,
        item: item,
        isDone: isDone ?? this.isDone,
        dueDate: dueDate,
        completedBy: completedBy ?? this.completedBy,
        completedAt: completedAt ?? this.completedAt,
        term: term,
        year: year,
      );
}
