// lib/data/local/daos/security_dao.dart

import 'package:floor/floor.dart';
import '../../models/security_model.dart';

@dao
abstract class SecurityDao {
  @Query('SELECT * FROM visitor_logs WHERE check_out_time IS NULL ORDER BY check_in_time DESC')
  Future<List<VisitorLogModel>> findActiveVisitors();

  @Query('SELECT * FROM visitor_logs ORDER BY check_in_time DESC LIMIT 100')
  Future<List<VisitorLogModel>> findAllLogs();

  @insert
  Future<void> insertLog(VisitorLogModel log);

  @update
  Future<void> updateLog(VisitorLogModel log);

  @Query('UPDATE visitor_logs SET check_out_time = :timestamp WHERE id = :id')
  Future<void> checkOut(String id, int timestamp);
}
