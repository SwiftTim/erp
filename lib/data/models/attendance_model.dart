// lib/data/models/attendance_model.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'attendance')
class AttendanceModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'student_id')
  final String studentId;
  @ColumnInfo(name: 'class_id')
  final String classId;
  final String date;           // YYYY-MM-DD
  final String status;         // Present | Absent | Late
  @ColumnInfo(name: 'recorded_by')
  final String recordedBy;
  final int synced;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    required this.recordedBy,
    this.synced = 0,
  });

  AttendanceModel copyWith({
    String? id,
    String? status,
    int? synced,
  }) =>
      AttendanceModel(
        id: id ?? this.id,
        studentId: studentId,
        classId: classId,
        date: date,
        status: status ?? this.status,
        recordedBy: recordedBy,
        synced: synced ?? this.synced,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'studentId': studentId,
        'classId': classId,
        'date': date,
        'status': status,
        'recordedBy': recordedBy,
      };
}

// ── Messaging ─────────────────────────────────────────────────────────────────
@Entity(tableName: 'messages')
class MessageModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'sender_id')
  final String senderId;
  @ColumnInfo(name: 'recipient_id')
  final String? recipientId;   // null = broadcast
  @ColumnInfo(name: 'message_type')
  final String messageType;    // Direct | Broadcast
  final String? subject;
  final String body;
  @ColumnInfo(name: 'sent_at')
  final int sentAt;
  @ColumnInfo(name: 'read_at')
  final int? readAt;
  final int synced;

  const MessageModel({
    required this.id,
    required this.senderId,
    this.recipientId,
    required this.messageType,
    this.subject,
    required this.body,
    required this.sentAt,
    this.readAt,
    this.synced = 0,
  });

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'senderId': senderId,
        'recipientId': recipientId,
        'messageType': messageType,
        'subject': subject,
        'body': body,
        'sentAt': sentAt,
        'readAt': readAt,
      };
}

// ── Read Receipts ─────────────────────────────────────────────────────────────
@Entity(tableName: 'memo_read_receipts')
class MemoReadReceipt {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'memo_id')
  final String memoId;
  @ColumnInfo(name: 'user_id')
  final String userId;
  @ColumnInfo(name: 'read_at')
  final int readAt;

  const MemoReadReceipt({
    required this.id,
    required this.memoId,
    required this.userId,
    required this.readAt,
  });
}

