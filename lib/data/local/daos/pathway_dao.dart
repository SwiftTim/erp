// lib/data/local/daos/pathway_dao.dart

import 'package:floor/floor.dart';
import '../../models/pathway_model.dart';

@dao
abstract class PathwayDao {
  @Query('SELECT * FROM pathway_recommendations WHERE student_id = :studentId')
  Future<PathwayRecommendationModel?> findForStudent(String studentId);

  @insert
  Future<void> insertRecommendation(PathwayRecommendationModel p);

  @update
  Future<void> updateRecommendation(PathwayRecommendationModel p);

  @Query('SELECT * FROM pathway_recommendations ORDER BY timestamp DESC')
  Future<List<PathwayRecommendationModel>> findAll();
}
