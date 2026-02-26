// lib/data/models/counseling_model.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'counseling_logs')
class CounselingLogModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  final String issue;               // e.g. "Grief", "Peer Pressure", "Academic Stress"
  final String summary;             // High-level summary
  final String notes;               // Detailed confidential notes
  @ColumnInfo(name: 'follow_up_required')
  final int followUpRequired;       // 0=No, 1=Yes
  final int timestamp;
  @ColumnInfo(name: 'counselor_id')
  final String counselorId;

  const CounselingLogModel({
    required this.id,
    required this.studentId,
    required this.issue,
    required this.summary,
    required this.notes,
    this.followUpRequired = 0,
    required this.timestamp,
    required this.counselorId,
  });
}
