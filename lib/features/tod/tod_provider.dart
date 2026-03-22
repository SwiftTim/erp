import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/tod_service.dart';
import '../auth/auth_provider.dart';
import '../../data/models/tod_model.dart';

final todServiceProvider = Provider<TodService>((ref) {
  final db = ref.watch(databaseProvider).maybeWhen(
    data: (db) => db,
    orElse: () => throw Exception('Database not initialized'),
  );
  return TodService(db);
});

final dutyRosterProvider = FutureProvider<List<DutyRosterModel>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.todDao.getAllDutyRosters();
});

final todRecordsProvider = FutureProvider<List<TodRecordModel>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.todDao.getAllTodRecords();
});

final studentBehaviorProvider = FutureProvider<List<StudentBehaviorModel>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.todDao.getAllStudentBehaviors();
});

// Helper to check if current user is on duty
final isOnDutyProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  
  final db = await ref.watch(databaseProvider.future);
  final now = DateTime.now().millisecondsSinceEpoch;
  final rosters = await db.todDao.getDutyRosterForDate(now);
  
  return rosters.any((r) => r.teacherId == user.id);
});
