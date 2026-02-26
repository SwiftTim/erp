// lib/data/models/assessment_model.dart

import 'package:floor/floor.dart';

// ── Assessment ────────────────────────────────────────────────────────────────
@Entity(tableName: 'assessments')
class AssessmentModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  @ColumnInfo(name: 'sub_strand_id')
  final String subStrandId;
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  final int score;             // 1=BE, 2=AE, 3=ME, 4=EE
  @ColumnInfo(name: 'teacher_remarks')
  final String? teacherRemarks;
  @ColumnInfo(name: 'evidence_path')
  final String? evidencePath;  // local path or Cloud Storage URL
  final int term;              // 1, 2, or 3
  @ColumnInfo(name: 'academic_year')
  final String academicYear;
  @ColumnInfo(name: 'date_recorded')
  final int dateRecorded;      // Unix epoch ms
  @ColumnInfo(name: 'is_moderated')
  final int isModerated;       // 0=pending, 1=moderated/locked
  @ColumnInfo(name: 'moderated_by')
  final String? moderatedBy;
  final int synced;            // 0=local, 1=synced

  const AssessmentModel({
    required this.id,
    required this.studentId,
    required this.subStrandId,
    required this.teacherId,
    required this.score,
    this.teacherRemarks,
    this.evidencePath,
    required this.term,
    required this.academicYear,
    required this.dateRecorded,
    this.isModerated = 0,
    this.moderatedBy,
    this.synced = 0,
  });

  AssessmentModel copyWith({
    int? score,
    String? teacherRemarks,
    String? evidencePath,
    int? isModerated,
    String? moderatedBy,
    int? synced,
  }) {
    return AssessmentModel(
      id: id,
      studentId: studentId,
      subStrandId: subStrandId,
      teacherId: teacherId,
      score: score ?? this.score,
      teacherRemarks: teacherRemarks ?? this.teacherRemarks,
      evidencePath: evidencePath ?? this.evidencePath,
      term: term,
      academicYear: academicYear,
      dateRecorded: dateRecorded,
      isModerated: isModerated ?? this.isModerated,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'studentId': studentId,
        'subStrandId': subStrandId,
        'teacherId': teacherId,
        'score': score,
        'teacherRemarks': teacherRemarks,
        'evidencePath': evidencePath,
        'term': term,
        'academicYear': academicYear,
        'dateRecorded': dateRecorded,
        'isModerated': isModerated,
        'moderatedBy': moderatedBy,
      };
}

// ── Core Competency ───────────────────────────────────────────────────────────
@Entity(tableName: 'core_competencies')
class CoreCompetencyModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  final String competency;    // one of the 7 competency names
  final int score;            // 1-4
  final int term;
  @ColumnInfo(name: 'academic_year')
  final String academicYear;
  final String? remarks;
  final int synced;

  const CoreCompetencyModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.competency,
    required this.score,
    required this.term,
    required this.academicYear,
    this.remarks,
    this.synced = 0,
  });

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'studentId': studentId,
        'teacherId': teacherId,
        'competency': competency,
        'score': score,
        'term': term,
        'academicYear': academicYear,
        'remarks': remarks,
      };
}

// ── Evidence Item ─────────────────────────────────────────────────────────────
@Entity(tableName: 'evidence_items')
class EvidenceItemModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  @ColumnInfo(name: 'assessment_id')
  final String? assessmentId;
  @ColumnInfo(name: 'sub_strand_id')
  final String? subStrandId;
  @ColumnInfo(name: 'local_path')
  final String localPath;
  @ColumnInfo(name: 'cloud_url')
  final String? cloudUrl;
  final String? caption;
  @ColumnInfo(name: 'media_type')
  final String mediaType;    // photo | video
  @ColumnInfo(name: 'taken_at')
  final int takenAt;
  final int uploaded;        // 0=local, 1=uploaded

  const EvidenceItemModel({
    required this.id,
    required this.studentId,
    this.assessmentId,
    this.subStrandId,
    required this.localPath,
    this.cloudUrl,
    this.caption,
    required this.mediaType,
    required this.takenAt,
    this.uploaded = 0,
  });

  EvidenceItemModel copyWith({
    String? cloudUrl,
    int? uploaded,
  }) =>
      EvidenceItemModel(
        id: id,
        studentId: studentId,
        assessmentId: assessmentId,
        subStrandId: subStrandId,
        localPath: localPath,
        cloudUrl: cloudUrl ?? this.cloudUrl,
        caption: caption,
        mediaType: mediaType,
        takenAt: takenAt,
        uploaded: uploaded ?? this.uploaded,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'studentId': studentId,
        'assessmentId': assessmentId,
        'subStrandId': subStrandId,
        'cloudUrl': cloudUrl,
        'caption': caption,
        'mediaType': mediaType,
        'takenAt': takenAt,
      };
}
