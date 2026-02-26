// lib/data/local/daos/discipline_dao.dart

import 'package:floor/floor.dart';
import '../../models/discipline_model.dart';

@dao
abstract class DisciplineDao {
  @Query('SELECT * FROM discipline_records WHERE student_id = :studentId ORDER BY timestamp DESC')
  Future<List<DisciplineRecordModel>> findForStudent(String studentId);

  @Query('SELECT * FROM discipline_records ORDER BY timestamp DESC')
  Future<List<DisciplineRecordModel>> findAll();

  @insert
  Future<void> insertRecord(DisciplineRecordModel record);

  @update
  Future<void> updateRecord(DisciplineRecordModel record);

  @delete
  Future<void> deleteRecord(DisciplineRecordModel record);
}
