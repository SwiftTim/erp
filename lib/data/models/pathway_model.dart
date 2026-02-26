// lib/data/models/pathway_model.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'pathway_recommendations')
class PathwayRecommendationModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  final String recommendedPathway;  // STEM | Social Sciences | Arts & Sports
  @ColumnInfo(name: 'performance_score')
  final double performanceScore;    // Avg assessment score
  final String rationale;           // AI/Teacher generated explanation
  final int timestamp;

  const PathwayRecommendationModel({
    required this.id,
    required this.studentId,
    required this.recommendedPathway,
    required this.performanceScore,
    required this.rationale,
    required this.timestamp,
  });
}
