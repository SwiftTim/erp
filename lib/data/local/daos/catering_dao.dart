// lib/data/local/daos/catering_dao.dart

import 'package:floor/floor.dart';
import '../../models/catering_model.dart';

@dao
abstract class CateringDao {
  @Query('SELECT * FROM meal_plans WHERE term = :term AND academic_year = :year ORDER BY dayOfWeek')
  Future<List<MealPlanModel>> findForTerm(int term, String year);

  @insert
  Future<void> insertMeal(MealPlanModel meal);

  @update
  Future<void> updateMeal(MealPlanModel meal);

  @Query('DELETE FROM meal_plans WHERE id = :id')
  Future<void> deleteMeal(String id);
}
