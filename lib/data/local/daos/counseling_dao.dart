// lib/data/local/daos/counseling_dao.dart

import 'package:floor/floor.dart';
import '../../models/counseling_model.dart';

@dao
abstract class CounselingDao {
  @Query('SELECT * FROM counseling_logs WHERE student_id = :studentId ORDER BY timestamp DESC')
  Future<List<CounselingLogModel>> findForStudent(String studentId);

  @Query('SELECT * FROM counseling_logs ORDER BY timestamp DESC')
  Future<List<CounselingLogModel>> findAll();

  @insert
  Future<void> insertLog(CounselingLogModel log);

  @update
  Future<void> updateLog(CounselingLogModel log);

  @delete
  Future<void> deleteLog(CounselingLogModel log);
}
