// lib/features/messaging/messaging_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/app_database.dart';
import '../../data/models/attendance_model.dart';
import '../auth/auth_provider.dart';

final messagingProvider = StateNotifierProvider<MessagingNotifier, MessagingState>((ref) {
  return MessagingNotifier(ref);
});

class MessagingState {
  final List<MessageModel> messages;
  final List<MessageModel> memos;
  final bool loading;
  final int unreadCount;

  MessagingState({
    this.messages = const [],
    this.memos = const [],
    this.loading = true,
    this.unreadCount = 0,
  });

  MessagingState copyWith({
    List<MessageModel>? messages,
    List<MessageModel>? memos,
    bool? loading,
    int? unreadCount,
  }) {
    return MessagingState(
      messages: messages ?? this.messages,
      memos: memos ?? this.memos,
      loading: loading ?? this.loading,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class MessagingNotifier extends StateNotifier<MessagingState> {
  final Ref _ref;
  MessagingNotifier(this._ref) : super(MessagingState()) {
    _init();
  }

  Future<void> _init() async {
    await loadMessages();
  }

  Future<void> loadMessages() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final db = await _ref.read(databaseProvider.future);
    final msgs = await db.messagingDao.findAllUserMessages(user.id);
    final memos = await db.messagingDao.findOfficialMemos();
    final unread = await db.messagingDao.countUnread(user.id) ?? 0;

    state = state.copyWith(
      messages: msgs,
      memos: memos,
      unreadCount: unread,
      loading: false,
    );
  }

  Future<void> sendMessage({
    required String? recipientId,
    required String messageType,
    String? subject,
    required String body,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final db = await _ref.read(databaseProvider.future);
    final msg = MessageModel(
      id: const Uuid().v4(),
      senderId: user.id,
      recipientId: recipientId,
      messageType: messageType,
      subject: subject,
      body: body,
      sentAt: DateTime.now().millisecondsSinceEpoch,
    );

    await db.messagingDao.insertMessage(msg);
    await loadMessages();
  }

  Future<void> markRead(String messageId) async {
    final db = await _ref.read(databaseProvider.future);
    await db.messagingDao.markRead(messageId, DateTime.now().millisecondsSinceEpoch);
    await loadMessages();
  }
}
