// lib/data/local/daos/curriculum_dao.dart

import 'package:floor/floor.dart';
import '../../models/curriculum_models.dart';

@dao
abstract class CurriculumDao {
  @Query('SELECT * FROM learning_areas WHERE grade_band = :gradeBand ORDER BY name ASC')
  Future<List<LearningAreaModel>> findAreasByLevel(String gradeBand);

  @Query('SELECT * FROM learning_areas ORDER BY name ASC')
  Future<List<LearningAreaModel>> findAllLearningAreas();

  @Query('SELECT * FROM strands WHERE learning_area_id = :areaId ORDER BY strand_name ASC')
  Future<List<StrandModel>> findStrandsByArea(String areaId);

  @Query('SELECT * FROM sub_strands WHERE strand_id = :strandId ORDER BY sub_strand_name ASC')
  Future<List<SubStrandModel>> findSubStrandsByStrand(String strandId);

  @Query('SELECT * FROM school_classes ORDER BY name ASC')
  Future<List<SchoolClassModel>> findAllClasses();

  @Query('SELECT * FROM school_classes WHERE id = :id')
  Future<SchoolClassModel?> findClassById(String id);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertArea(LearningAreaModel area);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertStrand(StrandModel strand);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSubStrand(SubStrandModel subStrand);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertClass(SchoolClassModel schoolClass);

  @transaction
  Future<void> insertFullCurriculum(
    List<LearningAreaModel> areas,
    List<StrandModel> strands,
    List<SubStrandModel> subStrands,
  ) async {
    for (final a in areas) await insertArea(a);
    for (final s in strands) await insertStrand(s);
    for (final ss in subStrands) await insertSubStrand(ss);
  }

  @Query('SELECT COUNT(*) FROM learning_areas')
  Future<int?> countAreas();

  @Query("DELETE FROM learning_areas WHERE id LIKE 'SUB_%'")
  Future<void> clearTestSubjects();

  // ── Coverage ────────────────────────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCoverage(StrandCoverage coverage);

  @Query('DELETE FROM strand_coverage WHERE class_id = :classId AND strand_id = :strandId')
  Future<void> removeCoverage(String classId, String strandId);

  @Query('SELECT * FROM strand_coverage WHERE class_id = :classId')
  Future<List<StrandCoverage>> findCoverageForClass(String classId);
}

