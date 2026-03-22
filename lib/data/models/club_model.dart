// lib/data/models/club_model.dart

import 'package:floor/floor.dart';
import 'user_model.dart';
import 'department_model.dart'; // Clubs are under Co-Curricular Dept

@Entity(tableName: 'clubs')
class ClubModel {
  @PrimaryKey()
  final String id;
  final String name;
  final String category; // 'Academic', 'Arts', 'Sports', 'Leadership', 'Special Interest'
  final String description;
  @ColumnInfo(name: 'patron_id')
  final String? patronId;
  @ColumnInfo(name: 'assistant_patron_id')
  final String? assistantPatronId;
  @ColumnInfo(name: 'meeting_day')
  final String? meetingDay; // 'Wednesday', 'Friday', etc
  @ColumnInfo(name: 'meeting_time')
  final String? meetingTime;
  final String status; // 'active', 'inactive'
  @ColumnInfo(name: 'capacity_limit')
  final int capacityLimit;
  @ColumnInfo(name: 'created_at')
  final int createdAt;

  ClubModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.patronId,
    this.assistantPatronId,
    this.meetingDay,
    this.meetingTime,
    this.status = 'active',
    this.capacityLimit = 60,
    required this.createdAt,
  });

  ClubModel copyWith({
    String? patronId,
    String? assistantPatronId,
    String? meetingDay,
    String? meetingTime,
    String? status,
    int? capacityLimit,
  }) {
    return ClubModel(
      id: id,
      name: name,
      category: category,
      description: description,
      patronId: patronId ?? this.patronId,
      assistantPatronId: assistantPatronId ?? this.assistantPatronId,
      meetingDay: meetingDay ?? this.meetingDay,
      meetingTime: meetingTime ?? this.meetingTime,
      status: status ?? this.status,
      capacityLimit: capacityLimit ?? this.capacityLimit,
      createdAt: createdAt,
    );
  }
}

@Entity(
  tableName: 'club_members',
  foreignKeys: [
    ForeignKey(
      childColumns: ['club_id'],
      parentColumns: ['id'],
      entity: ClubModel,
      onDelete: ForeignKeyAction.cascade,
    ),
  ],
)
class ClubMemberModel {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  @ColumnInfo(name: 'club_id')
  final String clubId;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  final String role; // 'member', 'chairperson', 'secretary', 'treasurer'
  @ColumnInfo(name: 'joined_at')
  final int joinedAt;
  @ColumnInfo(name: 'joined_by')
  final String joinedBy; // teacher id
  @ColumnInfo(name: 'consent_form_signed')
  final bool consentFormSigned;
  @ColumnInfo(name: 'parent_contact_verified')
  final bool parentContactVerified;

  ClubMemberModel({
    this.id,
    required this.clubId,
    required this.studentId,
    this.role = 'member',
    required this.joinedAt,
    required this.joinedBy,
    this.consentFormSigned = false,
    this.parentContactVerified = false,
  });

  ClubMemberModel copyWith({
    String? role,
    bool? consentFormSigned,
    bool? parentContactVerified,
  }) {
    return ClubMemberModel(
      id: id,
      clubId: clubId,
      studentId: studentId,
      role: role ?? this.role,
      joinedAt: joinedAt,
      joinedBy: joinedBy,
      consentFormSigned: consentFormSigned ?? this.consentFormSigned,
      parentContactVerified: parentContactVerified ?? this.parentContactVerified,
    );
  }
}

@Entity(
  tableName: 'club_activities',
  foreignKeys: [
    ForeignKey(
      childColumns: ['club_id'],
      parentColumns: ['id'],
      entity: ClubModel,
    ),
  ],
)
class ClubActivityModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'club_id')
  final String clubId;
  final String title;
  final String description;
  final String type; // 'Meeting', 'Competition', 'Field Trip', 'Project'
  @ColumnInfo(name: 'scheduled_at')
  final int scheduledAt;
  final String venue;
  final String status; // 'planned', 'completed', 'cancelled'
  @ColumnInfo(name: 'recorded_at')
  final int recordedAt;

  ClubActivityModel({
    required this.id,
    required this.clubId,
    required this.title,
    required this.description,
    required this.type,
    required this.scheduledAt,
    required this.venue,
    this.status = 'planned',
    required this.recordedAt,
  });
}

@Entity(
  tableName: 'club_attendance',
  foreignKeys: [
    ForeignKey(
      childColumns: ['activity_id'],
      parentColumns: ['id'],
      entity: ClubActivityModel,
      onDelete: ForeignKeyAction.cascade,
    ),
  ],
)
class ClubAttendanceModel {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  @ColumnInfo(name: 'activity_id')
  final String activityId;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  final String status; // 'Present', 'Absent', 'Excused'
  final String? remarks;

  ClubAttendanceModel({
    this.id,
    required this.activityId,
    required this.studentId,
    required this.status,
    this.remarks,
  });
}

@Entity(
  tableName: 'club_reports',
  foreignKeys: [
    ForeignKey(
      childColumns: ['club_id'],
      parentColumns: ['id'],
      entity: ClubModel,
    ),
  ],
)
class ClubReportModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'club_id')
  final String clubId;
  final int term;
  final String year;
  final String content; // JSON summary of activities and achievements
  @ColumnInfo(name: 'submitted_at')
  final int submittedAt;
  @ColumnInfo(name: 'patron_id')
  final String patronId;
  final String status; // 'submitted', 'reviewed'

  ClubReportModel({
    required this.id,
    required this.clubId,
    required this.term,
    required this.year,
    required this.content,
    required this.submittedAt,
    required this.patronId,
    this.status = 'submitted',
  });
}
