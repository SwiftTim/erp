// lib/core/services/cbc_aggregation_service.dart

import '../../data/local/app_database.dart';
import '../constants/app_constants.dart';

class CBCScore {
  final double average;
  final String band; // EE, ME, AE, BE
  final String label;

  CBCScore({
    required this.average,
    required this.band,
    required this.label,
  });

  factory CBCScore.fromAverage(double avg) {
    final band = AppConstants.getCompetencyBand(avg);
    final label = AppConstants.getCompetencyLabel(avg);
    return CBCScore(average: avg, band: band, label: label);
  }
}

class CBCAggregationService {
  final AppDatabase db;

  CBCAggregationService(this.db);

  /// Aggregates all assessments for a specific sub-strand.
  Future<CBCScore?> getSubStrandScore(String studentId, String subStrandId, int term, String year) async {
    final assessments = await db.assessmentDao.findForStudent(studentId, term, year);
    final filtered = assessments.where((a) => a.subStrandId == subStrandId).toList();
    
    if (filtered.isEmpty) return null;
    
    final avg = filtered.map((e) => e.score).reduce((a, b) => a + b) / filtered.length;
    return CBCScore.fromAverage(avg);
  }

  /// Aggregates scores for a Strand by averaging its Sub-strands.
  Future<CBCScore?> getStrandScore(String studentId, String strandId, int term, String year) async {
    final subStrands = await db.curriculumDao.findSubStrandsByStrand(strandId);
    if (subStrands.isEmpty) return null;

    double sum = 0;
    int count = 0;

    for (final ss in subStrands) {
      final score = await getSubStrandScore(studentId, ss.id, term, year);
      if (score != null) {
        sum += score.average;
        count++;
      }
    }

    if (count == 0) return null;
    return CBCScore.fromAverage(sum / count);
  }

  /// Aggregates scores for a Learning Area (Subject) by averaging its Strands.
  Future<CBCScore?> getSubjectScore(String studentId, String areaId, int term, String year) async {
    final strands = await db.curriculumDao.findStrandsByArea(areaId);
    if (strands.isEmpty) return null;

    double sum = 0;
    int count = 0;

    for (final s in strands) {
      final score = await getStrandScore(studentId, s.id, term, year);
      if (score != null) {
        sum += score.average;
        count++;
      }
    }

    if (count == 0) return null;
    return CBCScore.fromAverage(sum / count);
  }

  /// Aggregates overall performance for the term across all subjects.
  Future<CBCScore?> getOverallTermScore(String studentId, int term, String year) async {
    final student = await db.studentDao.findById(studentId);
    if (student == null) return null;

    final areas = await db.curriculumDao.findAreasByLevel(AppConstants.gradeBand(student.grade));
    if (areas.isEmpty) return null;

    double sum = 0;
    int count = 0;

    for (final area in areas) {
      final score = await getSubjectScore(studentId, area.id, term, year);
      if (score != null) {
        sum += score.average;
        count++;
      }
    }

    if (count == 0) return null;
    return CBCScore.fromAverage(sum / count);
  }
}
