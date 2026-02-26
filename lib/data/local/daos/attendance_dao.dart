// lib/data/local/daos/attendance_dao.dart

import 'package:floor/floor.dart';
import '../../models/attendance_model.dart';

@dao
abstract class AttendanceDao {
  // ── Attendance ──────────────────────────────────────────────────────────────
  @Query('''
    SELECT * FROM attendance
    WHERE class_id = :classId AND date = :date
    ORDER BY student_id
  ''')
  Future<List<AttendanceModel>> findForClassByDate(String classId, String date);

  @Query('''
    SELECT * FROM attendance
    WHERE student_id = :studentId
    ORDER BY date DESC
  ''')
  Future<List<AttendanceModel>> findForStudent(String studentId);

  @Query('''
    SELECT COUNT(*) FROM attendance
    WHERE student_id = :studentId AND status = 'Absent'
    AND date >= :fromDate AND date <= :toDate
  ''')
  Future<int?> countAbsences(String studentId, String fromDate, String toDate);

  @Query('SELECT * FROM attendance WHERE synced = 0')
  Future<List<AttendanceModel>> findUnsynced();

  @insert
  Future<void> insertAttendance(AttendanceModel record);

  @update
  Future<void> updateAttendance(AttendanceModel record);

  @Query('UPDATE attendance SET synced = 1 WHERE id = :id')
  Future<void> markSynced(String id);

  @transaction
  Future<void> upsertAttendance(AttendanceModel record) async {
    final existing = await findForClassByDate(record.classId, record.date);
    final studentRecord = existing.where((r) => r.studentId == record.studentId).firstOrNull;
    if (studentRecord != null) {
      await updateAttendance(record.copyWith(id: studentRecord.id));
    } else {
      await insertAttendance(record);
    }
  }

  // ── Messaging ────────────────────────────────────────────────────────────────
  @Query('''
    SELECT * FROM messages
    WHERE recipient_id = :userId OR message_type = 'Broadcast'
    ORDER BY sent_at DESC
  ''')
  Future<List<MessageModel>> findMessagesForUser(String userId);

  @Query('''
    SELECT * FROM messages
    WHERE sender_id = :senderId
    ORDER BY sent_at DESC
  ''')
  Future<List<MessageModel>> findSentMessages(String senderId);

  @insert
  Future<void> insertMessage(MessageModel message);

  @Query('UPDATE messages SET read_at = :readAt WHERE id = :id')
  Future<void> markRead(String id, int readAt);
}
