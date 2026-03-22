// lib/data/models/messaging_models.dart
// New models for the Messaging Hub module

import 'package:floor/floor.dart';

// ── Direct Chat Messages ──────────────────────────────────────────────────────
@Entity(tableName: 'chat_messages')
class ChatMessage {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'sender_id')
  final String senderId;
  @ColumnInfo(name: 'receiver_id')
  final String? receiverId;   // null = group message
  @ColumnInfo(name: 'group_id')
  final String? groupId;      // null = direct message
  final String message;
  @ColumnInfo(name: 'file_path')
  final String? filePath;
  @ColumnInfo(name: 'file_name')
  final String? fileName;
  @ColumnInfo(name: 'file_type')
  final String? fileType; // 'pdf', 'image', 'docx', 'xlsx', 'ppt'
  @ColumnInfo(name: 'reply_to_id')
  final String? replyToId;
  final String status; // 'sent', 'delivered', 'read'
  final int timestamp;
  @ColumnInfo(name: 'is_deleted')
  final int isDeleted; // 0=no, 1=yes

  const ChatMessage({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.groupId,
    required this.message,
    this.filePath,
    this.fileName,
    this.fileType,
    this.replyToId,
    this.status = 'sent',
    required this.timestamp,
    this.isDeleted = 0,
  });

  ChatMessage copyWith({String? status, int? isDeleted}) => ChatMessage(
        id: id,
        senderId: senderId,
        receiverId: receiverId,
        groupId: groupId,
        message: message,
        filePath: filePath,
        fileName: fileName,
        fileType: fileType,
        replyToId: replyToId,
        status: status ?? this.status,
        timestamp: timestamp,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}

// ── Group Chats ───────────────────────────────────────────────────────────────
@Entity(tableName: 'chat_groups')
class ChatGroup {
  @PrimaryKey()
  final String id;
  final String name;
  final String type; // 'all_staff','department','administration','custom'
  @ColumnInfo(name: 'dept_id')
  final String? deptId; // for department groups
  @ColumnInfo(name: 'created_by')
  final String createdBy;
  @ColumnInfo(name: 'created_at')
  final int createdAt;
  @ColumnInfo(name: 'icon_code')
  final int? iconCode; // IconData codePoint

  const ChatGroup({
    required this.id,
    required this.name,
    required this.type,
    this.deptId,
    required this.createdBy,
    required this.createdAt,
    this.iconCode,
  });
}

// ── Group Members ─────────────────────────────────────────────────────────────
@Entity(tableName: 'chat_group_members')
class ChatGroupMember {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  @ColumnInfo(name: 'group_id')
  final String groupId;
  @ColumnInfo(name: 'user_id')
  final String userId;
  @ColumnInfo(name: 'joined_at')
  final int joinedAt;

  const ChatGroupMember({
    this.id,
    required this.groupId,
    required this.userId,
    required this.joinedAt,
  });
}

// ── Message Read Receipts for Chat ────────────────────────────────────────────
@Entity(tableName: 'chat_read_receipts')
class ChatReadReceipt {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  @ColumnInfo(name: 'message_id')
  final String messageId;
  @ColumnInfo(name: 'user_id')
  final String userId;
  @ColumnInfo(name: 'read_at')
  final int readAt;

  const ChatReadReceipt({
    this.id,
    required this.messageId,
    required this.userId,
    required this.readAt,
  });
}

// ── Calendar Events ───────────────────────────────────────────────────────────
@Entity(tableName: 'calendar_events')
class CalendarEvent {
  @PrimaryKey()
  final String id;
  final String title;
  @ColumnInfo(name: 'event_type')
  final String eventType;
  // 'Term Opening','Midterm Break','Term Closing','Examination Period',
  // 'Sports Day','Academic Day','Competition Day','Staff Meeting',
  // 'CBC Assessment Week','Parents Meeting Day','Report Card Issuing Day',
  // 'National Exam Preparation','Club Activity Day','Teacher Professional Development'
  @ColumnInfo(name: 'start_date')
  final int startDate; // epoch ms
  @ColumnInfo(name: 'end_date')
  final int endDate;   // epoch ms
  final String? description;
  final String priority; // 'normal','important','urgent'
  @ColumnInfo(name: 'created_by')
  final String createdBy;
  @ColumnInfo(name: 'created_at')
  final int createdAt;
  @ColumnInfo(name: 'reminder_days')
  final int reminderDays; // how many days before to remind

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.eventType,
    required this.startDate,
    required this.endDate,
    this.description,
    this.priority = 'normal',
    required this.createdBy,
    required this.createdAt,
    this.reminderDays = 3,
  });
}

// ── App Notifications ─────────────────────────────────────────────────────────
@Entity(tableName: 'app_notifications')
class AppNotification {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  @ColumnInfo(name: 'user_id')
  final String userId;
  final String title;
  final String message;
  final String? link; // route
  @ColumnInfo(name: 'notif_type')
  final String notifType; // 'message','memo','calendar','discipline','incident'
  @ColumnInfo(name: 'reference_id')
  final String? referenceId;
  @ColumnInfo(name: 'is_read')
  final int isRead; // 0=unread, 1=read
  @ColumnInfo(name: 'created_at')
  final int createdAt;

  const AppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.link,
    required this.notifType,
    this.referenceId,
    this.isRead = 0,
    required this.createdAt,
  });

  AppNotification copyWithRead() => AppNotification(
        id: id,
        userId: userId,
        title: title,
        message: message,
        link: link,
        notifType: notifType,
        referenceId: referenceId,
        isRead: 1,
        createdAt: createdAt,
      );
}
