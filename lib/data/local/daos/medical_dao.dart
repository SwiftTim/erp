// lib/data/local/daos/medical_dao.dart

import 'package:floor/floor.dart';
import '../../models/medical_model.dart';

@dao
abstract class MedicalDao {
  @Query('SELECT * FROM medical_records WHERE student_id = :studentId')
  Future<MedicalRecordModel?> findForStudent(String studentId);

  @insert
  Future<void> insertRecord(MedicalRecordModel record);

  @update
  Future<void> updateRecord(MedicalRecordModel record);

  @Query('SELECT * FROM clinic_visits WHERE student_id = :studentId ORDER BY timestamp DESC')
  Future<List<ClinicVisitModel>> findVisitsForStudent(String studentId);

  @Query('SELECT * FROM clinic_visits ORDER BY timestamp DESC LIMIT 50')
  Future<List<ClinicVisitModel>> findRecentVisits();

  @insert
  Future<void> insertVisit(ClinicVisitModel visit);
}
