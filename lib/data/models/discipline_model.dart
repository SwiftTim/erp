// lib/data/models/discipline_model.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'discipline_records')
class DisciplineRecordModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  final String category;            // e.g. Lateness, Disruption, Bullying
  @ColumnInfo(name: 'incident_description')
  final String incidentDescription;
  @ColumnInfo(name: 'action_taken')
  final String actionTaken;
  final String status;              // Pending | Resolved | Escalated
  final int timestamp;              // Unix epoch ms
  @ColumnInfo(name: 'recorded_by')
  final String recordedBy;          // Teacher/Discipline Master ID

  const DisciplineRecordModel({
    required this.id,
    required this.studentId,
    required this.category,
    required this.incidentDescription,
    required this.actionTaken,
    this.status = 'Pending',
    required this.timestamp,
    required this.recordedBy,
  });
}
