import 'package:floor/floor.dart';

@Entity(tableName: 'duty_roster')
class DutyRosterModel {
  @primaryKey
  final String id;
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  @ColumnInfo(name: 'week_number')
  final int weekNumber;
  @ColumnInfo(name: 'start_date')
  final int startDate; // Changed from String to int (epoch millis) to match common conventions, or keep String if requested. Let's use int for dates as in other models.
  @ColumnInfo(name: 'end_date')
  final int endDate;

  DutyRosterModel({
    required this.id,
    required this.teacherId,
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
  });
}

@Entity(tableName: 'tod_records')
class TodRecordModel {
  @primaryKey
  final String id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  final String offence;
  final String punishment;
  final String? remarks;
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  final int date; // Epoch millis
  final String status; // 'pending', 'resolved', etc.

  TodRecordModel({
    required this.id,
    required this.studentId,
    required this.offence,
    required this.punishment,
    this.remarks,
    required this.teacherId,
    required this.date,
    required this.status,
  });
}

@Entity(tableName: 'student_behavior')
class StudentBehaviorModel {
  @primaryKey
  @ColumnInfo(name: 'student_id')
  final String studentId;
  @ColumnInfo(name: 'weekly_offences')
  final int weeklyOffences;
  final String status; // 'normal', 'amber', 'red'
  
  StudentBehaviorModel({
    required this.studentId,
    required this.weeklyOffences,
    required this.status,
  });
}
