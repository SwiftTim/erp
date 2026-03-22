// lib/features/messaging/chat_window_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/messaging_models.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';
import 'messaging_hub_provider.dart';

class ChatWindowPage extends ConsumerStatefulWidget {
  final UserModel? otherUser;
  final ChatGroup? group;
  final String currentUserId;

  const ChatWindowPage({
    super.key,
    this.otherUser,
    this.group,
    required this.currentUserId,
  });

  @override
  ConsumerState<ChatWindowPage> createState() => _ChatWindowPageState();
}

class _ChatWindowPageState extends ConsumerState<ChatWindowPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _refreshTimer;
  ChatMessage? _replyTo;

  late ConversationKey _key;

  @override
  void initState() {
    super.initState();
    _key = ConversationKey(
      otherUserId: widget.otherUser?.id,
      groupId: widget.group?.id,
    );
    // Poll every 3 seconds for new messages (simple real-time simulation)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      ref.read(chatMessagesProvider(_key).notifier).refresh();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  String get _title {
    if (widget.group != null) return widget.group!.name;
    return widget.otherUser?.name ?? 'Chat';
  }

  String get _subtitle {
    if (widget.group != null) return _groupTypeLabel(widget.group!.type);
    return AppConstants.roleNames[widget.otherUser?.roleLevel ?? 5] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final convState = ref.watch(chatMessagesProvider(_key));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                Text(_subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(chatMessagesProvider(_key).notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: convState.loading && convState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : convState.messages.isEmpty
                    ? _buildEmptyChat()
                    : _buildMessagesList(convState.messages),
          ),
          // Reply preview
          if (_replyTo != null) _buildReplyPreview(),
          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.group != null) {
      return CircleAvatar(
        backgroundColor: AppTheme.primary.withOpacity(0.12),
        child: Icon(Icons.group_outlined, color: AppTheme.primary, size: 20),
      );
    }
    final name = widget.otherUser?.name ?? '';
    final initials = name
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
    return CircleAvatar(
      backgroundColor: AppTheme.primary.withOpacity(0.12),
      child: Text(initials,
          style: TextStyle(
              color: AppTheme.primary, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('No messages yet',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Start the conversation!',
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final isMine = msg.senderId == widget.currentUserId;
        final showDate =
            i == 0 || !_sameDay(messages[i - 1].timestamp, msg.timestamp);

        return Column(
          children: [
            if (showDate) _buildDateDivider(msg.timestamp),
            _ChatBubble(
              message: msg,
              isMine: isMine,
              onReply: () => setState(() => _replyTo = msg),
              replyTo: msg.replyToId != null
                  ? messages
                      .where((m) => m.id == msg.replyToId)
                      .firstOrNull
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    String label;
    if (_sameDay(timestamp, now.millisecondsSinceEpoch)) {
      label = 'Today';
    } else if (_sameDay(timestamp,
        now.subtract(const Duration(days: 1)).millisecondsSinceEpoch)) {
      label = 'Yesterday';
    } else {
      label = DateFormat('EEEE, dd MMMM').format(dt);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade200)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200)),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            color: AppTheme.primary,
            margin: const EdgeInsets.only(right: 10),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Replying to message…',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
                Text(
                  _replyTo!.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => setState(() => _replyTo = null),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.paddingOf(context).bottom + 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          FloatingActionButton.small(
            onPressed: _send,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            child: const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ref.read(chatMessagesProvider(_key).notifier).send(
          message: text,
          replyToId: _replyTo?.id,
        );
    setState(() => _replyTo = null);
  }

  bool _sameDay(int a, int b) {
    final da = DateTime.fromMillisecondsSinceEpoch(a);
    final db = DateTime.fromMillisecondsSinceEpoch(b);
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  String _groupTypeLabel(String type) {
    switch (type) {
      case 'all_staff':
        return 'All School Staff';
      case 'administration':
        return 'Administration';
      case 'department':
        return 'Department Group';
      default:
        return 'Group Chat';
    }
  }
}

// ── Chat Bubble ───────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final VoidCallback onReply;
  final ChatMessage? replyTo;

  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.onReply,
    this.replyTo,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onReply,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Reply preview inside bubble
              if (replyTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                          color: isMine ? Colors.white54 : AppTheme.primary,
                          width: 3),
                    ),
                  ),
                  child: Text(
                    replyTo!.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: isMine
                            ? Colors.white.withOpacity(0.75)
                            : Colors.grey.shade600),
                  ),
                ),
              // Main bubble
              Container(
                margin: EdgeInsets.only(
                    bottom: 4,
                    left: isMine ? 48 : 0,
                    right: isMine ? 0 : 48),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine
                      ? AppTheme.primary
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message text
                    if (message.isDeleted == 1)
                      Text(
                        'This message was deleted',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: isMine
                                ? Colors.white60
                                : Colors.grey.shade400,
                            fontSize: 13),
                      )
                    else
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isMine ? Colors.white : Colors.black87,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    // File attachment
                    if (message.fileName != null && message.isDeleted == 0)
                      _buildFileAttachment(isMine),
                    // Timestamp + status
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  message.timestamp)),
                          style: TextStyle(
                              fontSize: 10,
                              color: isMine
                                  ? Colors.white60
                                  : Colors.grey.shade400),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileAttachment(bool isMine) {
    final icon = _fileIcon(message.fileType ?? '');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withOpacity(0.15)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 20,
              color: isMine ? Colors.white : AppTheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.fileName ?? 'Attachment',
              style: TextStyle(
                  fontSize: 12,
                  color: isMine ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case 'read':
        return const Icon(Icons.done_all_rounded,
            size: 14, color: Colors.lightBlueAccent);
      case 'delivered':
        return Icon(Icons.done_all_rounded,
            size: 14, color: Colors.white.withOpacity(0.6));
      default:
        return Icon(Icons.done_rounded,
            size: 14, color: Colors.white.withOpacity(0.6));
    }
  }

  IconData _fileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'image':
      case 'png':
      case 'jpg':
        return Icons.image_outlined;
      case 'docx':
      case 'doc':
        return Icons.article_outlined;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.present_to_all_outlined;
      default:
        return Icons.attach_file_outlined;
    }
  }
}
