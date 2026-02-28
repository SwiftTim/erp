// lib/data/models/curriculum_models.dart

import 'package:floor/floor.dart';

// ── Learning Area ─────────────────────────────────────────────────────────────
@Entity(tableName: 'learning_areas')
class LearningAreaModel {
  @PrimaryKey()
  final String id;
  final String name;           // e.g. Mathematics, Integrated Science
  @ColumnInfo(name: 'grade_band')
  final String gradeBand;      // Pre-Primary | Lower Primary | Upper Primary | Junior School
  final String category;       // Core | Elective
  @ColumnInfo(name: 'department_id')
  final String? departmentId;

  const LearningAreaModel({
    required this.id,
    required this.name,
    required this.gradeBand,
    required this.category,
    this.departmentId,
  });
}

// ── Strand ────────────────────────────────────────────────────────────────────
@Entity(tableName: 'strands')
class StrandModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'learning_area_id')
  final String learningAreaId;
  @ColumnInfo(name: 'strand_name')
  final String strandName;     // e.g. Numbers, Environmental Conservation

  const StrandModel({
    required this.id,
    required this.learningAreaId,
    required this.strandName,
  });
}

// ── Sub-Strand ────────────────────────────────────────────────────────────────
@Entity(tableName: 'sub_strands')
class SubStrandModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'strand_id')
  final String strandId;
  @ColumnInfo(name: 'sub_strand_name')
  final String subStrandName;  // e.g. Addition of Integers
  @ColumnInfo(name: 'assessment_rubric')
  final String? assessmentRubric;

  const SubStrandModel({
    required this.id,
    required this.strandId,
    required this.subStrandName,
    this.assessmentRubric,
  });
}

// ── School Class ──────────────────────────────────────────────────────────────
@Entity(tableName: 'school_classes')
class SchoolClassModel {
  @PrimaryKey()
  final String id;
  final String name;           // e.g. Grade 4 Sunflower
  final String grade;          // e.g. Grade 4
  @ColumnInfo(name: 'teacher_id')
  final String? teacherId;
  @ColumnInfo(name: 'academic_year')
  final String academicYear;

  const SchoolClassModel({
    required this.id,
    required this.name,
    required this.grade,
    this.teacherId,
    required this.academicYear,
  });
}

// ── Strand Coverage Tracker ───────────────────────────────────────────────────
@Entity(tableName: 'strand_coverage')
class StrandCoverage {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'class_id')
  final String classId;
  @ColumnInfo(name: 'strand_id')
  final String strandId;
  @ColumnInfo(name: 'teacher_id')
  final String teacherId;
  @ColumnInfo(name: 'completion_date')
  final int completionDate;

  const StrandCoverage({
    required this.id,
    required this.classId,
    required this.strandId,
    required this.teacherId,
    required this.completionDate,
  });
}

