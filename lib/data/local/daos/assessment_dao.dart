// lib/data/local/daos/assessment_dao.dart

import 'package:floor/floor.dart';
import '../../models/assessment_model.dart';

@dao
abstract class AssessmentDao {
  // ── Assessments ─────────────────────────────────────────────────────────────
  @Query('''
    SELECT * FROM assessments
    WHERE student_id = :studentId AND term = :term AND academic_year = :year
    ORDER BY date_recorded DESC
  ''')
  Future<List<AssessmentModel>> findForStudent(String studentId, int term, String year);

  @Query('''
    SELECT * FROM assessments
    WHERE student_id = :studentId AND sub_strand_id = :subStrandId
    ORDER BY date_recorded DESC LIMIT 1
  ''')
  Future<AssessmentModel?> findLatestForSubStrand(String studentId, String subStrandId);

  @Query('''
    SELECT * FROM assessments
    WHERE teacher_id = :teacherId AND term = :term AND academic_year = :year
    ORDER BY date_recorded DESC
  ''')
  Future<List<AssessmentModel>> findByTeacher(String teacherId, int term, String year);

  @Query('SELECT * FROM assessments WHERE synced = 0')
  Future<List<AssessmentModel>> findUnsynced();

  @Query('''
    SELECT AVG(score) FROM assessments
    WHERE student_id = :studentId AND academic_year = :year AND term = :term
  ''')
  Future<double?> avgScoreForStudent(String studentId, String year, int term);

  @insert
  Future<void> insertAssessment(AssessmentModel assessment);

  @update
  Future<void> updateAssessment(AssessmentModel assessment);

  @Query('UPDATE assessments SET synced = 1 WHERE id = :id')
  Future<void> markSynced(String id);

  @Query('''
    SELECT a.* FROM assessments a
    JOIN users u ON a.teacher_id = u.id
    WHERE u.department_id = :deptId AND a.is_moderated = 1
  ''')
  Future<List<AssessmentModel>> findPendingModerationByDept(String deptId);

  @Query('UPDATE assessments SET is_moderated = 2, moderated_by = :hodId WHERE id = :id')
  Future<void> moderate(String id, String hodId);

  @Query('UPDATE assessments SET is_moderated = 3, moderated_by = :hodId, teacher_remarks = teacher_remarks || " [HOD Feedback: " || :reason || "]" WHERE id = :id')
  Future<void> reject(String id, String hodId, String reason);

  @Query('UPDATE assessments SET is_moderated = 2, moderated_by = :hodId WHERE teacher_id = :teacherId AND is_moderated = 1')
  Future<void> moderateAllForTeacher(String teacherId, String hodId);

  @Query('UPDATE assessments SET is_moderated = 1 WHERE teacher_id = :teacherId AND is_moderated = 0')
  Future<void> submitAllForTeacher(String teacherId);

  @Query('SELECT COUNT(*) FROM assessments WHERE teacher_id = :teacherId AND is_moderated = 0')
  Future<int?> countDraftsForTeacher(String teacherId);

  @Query('SELECT * FROM assessments WHERE teacher_id = :teacherId AND is_moderated = 1')
  Future<List<AssessmentModel>> findSubmittedForTeacher(String teacherId);

  // ── Core Competencies ───────────────────────────────────────────────────────
  @Query('''
    SELECT * FROM core_competencies
    WHERE student_id = :studentId AND term = :term AND academic_year = :year
  ''')
  Future<List<CoreCompetencyModel>> findCompetenciesForStudent(
      String studentId, int term, String year);

  @Query('SELECT * FROM core_competencies WHERE synced = 0')
  Future<List<CoreCompetencyModel>> findUnsyncedCompetencies();

  @insert
  Future<void> insertCompetency(CoreCompetencyModel competency);

  @update
  Future<void> updateCompetency(CoreCompetencyModel competency);

  // ── Evidence ────────────────────────────────────────────────────────────────
  @Query('SELECT * FROM evidence_items WHERE student_id = :studentId ORDER BY taken_at DESC')
  Future<List<EvidenceItemModel>> findEvidenceForStudent(String studentId);

  @Query('SELECT * FROM evidence_items WHERE uploaded = 0')
  Future<List<EvidenceItemModel>> findPendingUploads();

  @insert
  Future<void> insertEvidence(EvidenceItemModel item);

  @update
  Future<void> updateEvidence(EvidenceItemModel item);
}
