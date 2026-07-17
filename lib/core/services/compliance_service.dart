// lib/core/services/compliance_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../../features/auth/auth_provider.dart';

final complianceServiceProvider = Provider((ref) => ComplianceService(ref));

class TransitionScore {
  final double sbaGrade6; // 20%
  final double sbaGrade7; // 10%
  final double sbaGrade8; // 10%
  final double examGrade9; // 60%
  final double finalTotal;
  
  TransitionScore({
    required this.sbaGrade6,
    required this.sbaGrade7,
    required this.sbaGrade8,
    required this.examGrade9,
    required this.finalTotal,
  });
}

class ComplianceService {
  final Ref _ref;
  ComplianceService(this._ref);

  /// Calculates the weighted transition score for Junior School to Senior School
  Future<TransitionScore> calculateTransitionScore(String studentId) async {
    final db = await _ref.read(databaseProvider.future);
    
    // In a real app, we'd fetch specific year-end averages. 
    // Here we simulate by looking at historical assessment averages.
    final g6Avg = await db.assessmentDao.avgScoreForStudent(studentId, '2023', 3) ?? 75.0; // Mock historical
    final g7Avg = await db.assessmentDao.avgScoreForStudent(studentId, '2024', 3) ?? 70.0;
    final g8Avg = await db.assessmentDao.avgScoreForStudent(studentId, '2025', 3) ?? 72.0;
    final g9Avg = await db.assessmentDao.avgScoreForStudent(studentId, '2026', 1) ?? 68.0;

    // Apply weights
    final weightedG6 = g6Avg * AppConstants.kpseaWeight;
    final weightedG7 = g7Avg * AppConstants.sba7Weight;
    final weightedG8 = g8Avg * AppConstants.sba8Weight;
    final weightedG9 = g9Avg * AppConstants.kjseaWeight;

    final total = weightedG6 + weightedG7 + weightedG8 + weightedG9;

    return TransitionScore(
      sbaGrade6: weightedG6,
      sbaGrade7: weightedG7,
      sbaGrade8: weightedG8,
      examGrade9: weightedG9,
      finalTotal: total,
    );
  }

  /// Recommends a Senior School pathway based on subject performance history
  Future<String> recommendPathway(String studentId) async {
    final db = await _ref.read(databaseProvider.future);
    final assessments = await db.assessmentDao.findForStudent(studentId, 1, '2026');
    
    // Group averages by subject category
    double stemScore = 0;
    double artsScore = 0;
    double socialScore = 0;

    for (final a in assessments) {
      final subject = a.subStrandId.toLowerCase();
      if (['math', 'science', 'computer', 'agri'].any((s) => subject.contains(s))) {
        stemScore += a.score;
      } else if (['art', 'music', 'pe', 'sports', 'home'].any((s) => subject.contains(s))) {
        artsScore += a.score;
      } else {
        socialScore += a.score;
      }
    }

    if (stemScore >= artsScore && stemScore >= socialScore) return AppConstants.seniorPathways[0];
    if (artsScore >= stemScore && artsScore >= socialScore) return AppConstants.seniorPathways[1];
    return AppConstants.seniorPathways[2];
  }

  /// Generates a CSV string for bulk KNEC upload
  Future<String> generateKnecExport(List<String> gradeList) async {
    final db = await _ref.read(databaseProvider.future);
    final buffer = StringBuffer();
    
    // KNEC Standard CSV Header (Simulation)
    buffer.writeln('INDEX_NO,UPI,FULL_NAME,GENDER,GRADE,OVERALL_SCORE,TRANSITION_STATUS');

    final students = await db.studentDao.findAll();
    final targetStudents = students.where((s) => gradeList.contains(s.grade)).toList();

    for (final s in targetStudents) {
      final score = await calculateTransitionScore(s.id);
      final status = score.finalTotal >= 50 ? 'TRANSITIONED' : 'RETAINED';
      
      buffer.writeln('${s.upi},${s.upi},${s.fullName},${s.gender},${s.grade},${score.finalTotal.toStringAsFixed(1)},$status');
    }

    return buffer.toString();
  }
}
