// lib/data/local/daos/chat_dao.dart

import 'package:floor/floor.dart';
import '../../models/messaging_models.dart';

@dao
abstract class ChatDao {
  // ── Direct Messages ─────────────────────────────────────────────────────────
  @Query('''
    SELECT * FROM chat_messages 
    WHERE is_deleted = 0 
      AND ((sender_id = :userA AND receiver_id = :userB) 
        OR (sender_id = :userB AND receiver_id = :userA))
    ORDER BY timestamp ASC
    LIMIT :limit OFFSET :offset
  ''')
  Future<List<ChatMessage>> findDirectMessages(
      String userA, String userB, int limit, int offset);

  @Query('''
    SELECT * FROM chat_messages 
    WHERE is_deleted = 0 AND group_id = :groupId 
    ORDER BY timestamp ASC
    LIMIT :limit OFFSET :offset
  ''')
  Future<List<ChatMessage>> findGroupMessages(
      String groupId, int limit, int offset);

  @insert
  Future<void> insertMessage(ChatMessage message);

  @Query('UPDATE chat_messages SET status = :status WHERE id = :id')
  Future<void> updateMessageStatus(String id, String status);

  @Query('UPDATE chat_messages SET is_deleted = 1 WHERE id = :id')
  Future<void> deleteMessage(String id);

  // ── Unread count for direct message ─────────────────────────────────────────
  @Query('''
    SELECT COUNT(*) FROM chat_messages 
    WHERE receiver_id = :userId AND status != "read" AND is_deleted = 0 AND group_id IS NULL
  ''')
  Future<int?> countUnreadDirect(String userId);

  // ── Last message in a conversation ──────────────────────────────────────────
  @Query('''
    SELECT * FROM chat_messages 
    WHERE is_deleted = 0 
      AND ((sender_id = :userA AND receiver_id = :userB) 
        OR (sender_id = :userB AND receiver_id = :userA))
    ORDER BY timestamp DESC LIMIT 1
  ''')
  Future<ChatMessage?> getLastDirectMessage(String userA, String userB);

  @Query('''
    SELECT * FROM chat_messages 
    WHERE is_deleted = 0 AND group_id = :groupId 
    ORDER BY timestamp DESC LIMIT 1
  ''')
  Future<ChatMessage?> getLastGroupMessage(String groupId);

  @Query('''
    SELECT * FROM chat_messages 
    WHERE is_deleted = 0 
      AND (sender_id = :userId OR receiver_id = :userId)
      AND group_id IS NULL
    GROUP BY CASE 
      WHEN sender_id = :userId THEN receiver_id 
      ELSE sender_id END
    ORDER BY timestamp DESC
  ''')
  Future<List<ChatMessage>> getRecentDirectConversations(String userId);

  @Query('''
    SELECT COUNT(*) FROM chat_messages 
    WHERE is_deleted = 0 AND receiver_id = :userId AND sender_id = :otherUserId AND status != 'read'
  ''')
  Future<int?> countUnreadFromUser(String userId, String otherUserId);

  // ── Groups ───────────────────────────────────────────────────────────────────
  @insert
  Future<void> insertGroup(ChatGroup group);

  @Query('SELECT * FROM chat_groups ORDER BY name ASC')
  Future<List<ChatGroup>> getAllGroups();

  @Query('SELECT * FROM chat_groups WHERE id = :id')
  Future<ChatGroup?> getGroupById(String id);

  @insert
  Future<void> insertGroupMember(ChatGroupMember member);

  @Query('SELECT * FROM chat_group_members WHERE group_id = :groupId')
  Future<List<ChatGroupMember>> getGroupMembers(String groupId);

  @Query('SELECT * FROM chat_group_members WHERE user_id = :userId')
  Future<List<ChatGroupMember>> getGroupsForUser(String userId);

  @Query('SELECT COUNT(*) FROM chat_group_members WHERE group_id = :groupId AND user_id = :userId')
  Future<int?> isMemberOfGroup(String groupId, String userId);

  // ── Read receipts ─────────────────────────────────────────────────────────
  @insert
  Future<void> insertReadReceipt(ChatReadReceipt receipt);

  @Query('SELECT COUNT(*) FROM chat_read_receipts WHERE message_id = :messageId AND user_id = :userId')
  Future<int?> hasReadMessage(String messageId, String userId);
}
