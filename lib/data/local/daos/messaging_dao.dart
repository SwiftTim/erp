// lib/data/local/daos/messaging_dao.dart

import 'package:floor/floor.dart';
import '../../models/attendance_model.dart'; // MessageModel is co-located here

@dao
abstract class MessagingDao {
  @Query('SELECT * FROM messages WHERE recipient_id = :userId OR sender_id = :userId OR recipient_id IS NULL ORDER BY sent_at DESC')
  Future<List<MessageModel>> findAllUserMessages(String userId);

  @Query('SELECT * FROM messages WHERE recipient_id = :userId OR recipient_id IS NULL ORDER BY sent_at DESC')
  Future<List<MessageModel>> findInbox(String userId);

  @Query('SELECT * FROM messages WHERE sender_id = :userId ORDER BY sent_at DESC')
  Future<List<MessageModel>> findSent(String userId);

  @Query('SELECT * FROM messages WHERE message_type = "Broadcast" ORDER BY sent_at DESC')
  Future<List<MessageModel>> findOfficialMemos();

  @insert
  Future<void> insertMessage(MessageModel message);

  @Query('UPDATE messages SET read_at = :readAt WHERE id = :id')
  Future<void> markRead(String id, int readAt);

  @Query('SELECT COUNT(*) FROM messages WHERE recipient_id = :userId AND read_at IS NULL')
  Future<int?> countUnread(String userId);
}
