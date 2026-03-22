// lib/data/local/daos/notification_dao.dart

import 'package:floor/floor.dart';
import '../../models/messaging_models.dart';

@dao
abstract class NotificationDao {
  @Query('SELECT * FROM app_notifications WHERE user_id = :userId ORDER BY created_at DESC LIMIT 50')
  Future<List<AppNotification>> getNotificationsForUser(String userId);

  @Query('SELECT COUNT(*) FROM app_notifications WHERE user_id = :userId AND is_read = 0')
  Future<int?> countUnread(String userId);

  @insert
  Future<void> insertNotification(AppNotification notification);

  @Query('UPDATE app_notifications SET is_read = 1 WHERE id = :id')
  Future<void> markRead(int id);

  @Query('UPDATE app_notifications SET is_read = 1 WHERE user_id = :userId')
  Future<void> markAllRead(String userId);

  @Query('DELETE FROM app_notifications WHERE created_at < :olderThanMs')
  Future<void> pruneOldNotifications(int olderThanMs);
}
