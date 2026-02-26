// lib/data/models/catering_model.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'meal_plans')
class MealPlanModel {
  @PrimaryKey()
  final String id;
  final String dayOfWeek;           // Monday, Tuesday, etc.
  final String mealType;            // Breakfast, Lunch, Snack
  final String menu;                // e.g. Githeri & Cabbage
  @ColumnInfo(name: 'academic_year')
  final String academicYear;
  final int term;

  const MealPlanModel({
    required this.id,
    required this.dayOfWeek,
    required this.mealType,
    required this.menu,
    required this.academicYear,
    required this.term,
  });
}
