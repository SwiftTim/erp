// lib/data/models/enterprise_models.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'teaching_assignments')
class TeachingAssignment {
  @PrimaryKey()
  final String id;
  final String teacherId;
  final String classId;
  final String subjectId;
  final int academicYear;

  TeachingAssignment({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.subjectId,
    required this.academicYear,
  });
}

// ── Timetable Engine Specific Models moved to timetable_models.dart ────


@Entity(tableName: 'official_memos')
class OfficialMemo {
  @PrimaryKey()
  final String id;
  final String senderId;
  final String title;
  final String content;
  final String targetGroup; // "ALL", "TEACHERS", "PARENTS", "DEPARTMENT:Math"
  final int createdAt;
  final String priority; // "NORMAL", "URGENT", "EMERGENCY"

  OfficialMemo({
    required this.id,
    required this.senderId,
    required this.title,
    required this.content,
    required this.targetGroup,
    required this.createdAt,
    this.priority = 'NORMAL',
  });
}

@Entity(tableName: 'memo_reads')
class MemoReadRecord {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String memoId;
  final String userId;
  final int readAt;

  MemoReadRecord({
    this.id,
    required this.memoId,
    required this.userId,
    required this.readAt,
  });
}

@Entity(tableName: 'clubs')
class ClubModel {
  @PrimaryKey()
  final String id;
  final String name;
  final String description;
  final String advisorId; // Teacher ID
  final String category; // "Sports", "Academic", "Art"

  ClubModel({
    required this.id,
    required this.name,
    required this.description,
    required this.advisorId,
    required this.category,
  });
}

@Entity(tableName: 'club_memberships')
class ClubMembership {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String clubId;
  final String studentId;
  final int joinedAt;

  ClubMembership({
    this.id,
    required this.clubId,
    required this.studentId,
    required this.joinedAt,
  });
}

@Entity(tableName: 'staff_leaves')
class StaffLeave {
  @PrimaryKey()
  final String id;
  final String staffId;
  final String leaveType; // "SICK", "ANNUAL", "STUDY"
  final int startDate;
  final int endDate;
  final String reason;
  final String status; // "PENDING", "APPROVED", "REJECTED"
  final String? approvedBy;

  StaffLeave({
    required this.id,
    required this.staffId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = 'PENDING',
    this.approvedBy,
  });
}

@Entity(tableName: 'inventory_assets')
class InventoryAsset {
  @PrimaryKey()
  final String id;
  final String name;
  final String category; // "Books", "ICT", "Furniture"
  final String location;
  final int quantity;
  final String condition; // "New", "Good", "Damaged"
  @ColumnInfo(name: 'unit_cost') final double? unitCost;
  @ColumnInfo(name: 'purchase_date') final int? purchaseDate;
  @ColumnInfo(name: 'assigned_to') final String? assignedTo;

  InventoryAsset({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.quantity,
    required this.condition,
    this.unitCost,
    this.purchaseDate,
    this.assignedTo,
  });
}

@Entity(tableName: 'asset_maintenance_logs')
class AssetMaintenanceLog {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'asset_id')
  final String assetId;
  final String description; // "Replaced spark plugs", "Screen repair"
  final double cost;
  @ColumnInfo(name: 'serviced_at')
  final int servicedAt;
  @ColumnInfo(name: 'recorded_by')
  final String recordedBy;

  AssetMaintenanceLog({
    required this.id,
    required this.assetId,
    required this.description,
    required this.cost,
    required this.servicedAt,
    required this.recordedBy,
  });
}



@Entity(tableName: 'system_activity_logs')
class SystemLog {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String userId;
  final String action; // "EDIT_SCORE", "LOGIN", "DELETE_STUDENT"
  final String module;
  final String details;
  final int timestamp;
  final String ipAddress;

  SystemLog({
    this.id,
    required this.userId,
    required this.action,
    required this.module,
    required this.details,
    required this.timestamp,
    this.ipAddress = 'local',
  });
}


@Entity(tableName: 'substitutions')
class Substitution {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'original_teacher_id')
  final String originalTeacherId;
  @ColumnInfo(name: 'substitute_teacher_id')
  final String substituteTeacherId;
  @ColumnInfo(name: 'class_id')
  final String classId;
  @ColumnInfo(name: 'subject_id')
  final String subjectId;
  final int date; // Unix epoch ms (day of substitution)
  @ColumnInfo(name: 'period_number')
  final int periodNumber;
  @ColumnInfo(name: 'created_at')
  final int createdAt;

  Substitution({
    required this.id,
    required this.originalTeacherId,
    required this.substituteTeacherId,
    required this.classId,
    required this.subjectId,
    required this.date,
    required this.periodNumber,
    required this.createdAt,
  });
}

@Entity(tableName: 'staff_attendance')
class StaffAttendance {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'staff_id')
  final String staffId;
  final int date; // YYYYMMDD
  @ColumnInfo(name: 'clock_in')
  final int clockIn;
  @ColumnInfo(name: 'clock_out')
  final int? clockOut;
  final String? notes;

  StaffAttendance({
    required this.id,
    required this.staffId,
    required this.date,
    required this.clockIn,
    this.clockOut,
    this.notes,
  });
}


