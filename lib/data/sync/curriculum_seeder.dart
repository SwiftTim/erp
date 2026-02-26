// lib/data/sync/curriculum_seeder.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import '../local/app_database.dart';
import '../models/curriculum_models.dart';

class CurriculumSeeder {
  static Future<void> seedIfEmpty(AppDatabase db) async {
    final count = await db.curriculumDao.countAreas();
    if (count != null && count > 0) return;

    print('🌱 Seeding curriculum data...');

    try {
      final String jsonString = await rootBundle.loadString('assets/data/curriculum_seed.json');
      final data = json.decode(jsonString);

      final List<LearningAreaModel> areas = (data['learning_areas'] as List)
          .map((e) => LearningAreaModel(
                id: e['id'],
                name: e['name'],
                gradeBand: e['level'],
                category: e['category'],
              ))
          .toList();

      final List<StrandModel> strands = (data['strands'] as List)
          .map((e) => StrandModel(
                id: e['id'],
                learningAreaId: e['learning_area_id'],
                strandName: e['strand_name'],
              ))
          .toList();

      final List<SubStrandModel> subStrands = (data['sub_strands'] as List)
          .map((e) => SubStrandModel(
                id: e['id'],
                strandId: e['strand_id'],
                subStrandName: e['sub_strand_name'],
                assessmentRubric: e['assessment_rubric'],
              ))
          .toList();

      await db.curriculumDao.insertFullCurriculum(areas, strands, subStrands);
      print('✅ Curriculum seeding complete.');
    } catch (e) {
      print('❌ Error seeding curriculum: $e');
    }
  }
}
