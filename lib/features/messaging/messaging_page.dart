// lib/features/messaging/messaging_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/enterprise_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'messaging_provider.dart';

class MessagingPage extends ConsumerStatefulWidget {
  const MessagingPage({super.key});

  @override
  ConsumerState<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends ConsumerState<MessagingPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showComposeDialog() {
    final user = ref.read(currentUserProvider)!;
    final isAdmin = user.roleLevel <= 2;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ComposeSheet(isAdmin: isAdmin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagingProvider);

    return AppShell(
      title: 'Communications',
      body: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            tabs: [
              Tab(child: _BadgeTab(text: 'Inbox', count: state.unreadCount)),
              const Tab(text: 'Sent'),
              const Tab(text: 'Memos'),
            ],
            labelColor: AppTheme.primary,
          ),
          Expanded(
            child: state.loading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _MessagesList(messages: state.messages.where((m) => m.recipientId == ref.read(currentUserProvider)?.id).toList()),
                    _MessagesList(messages: state.messages.where((m) => m.senderId == ref.read(currentUserProvider)?.id).toList(), isSent: true),
                    _MessagesList(messages: state.memos, isMemo: true),
                  ],
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showComposeDialog,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Compose'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _BadgeTab extends StatelessWidget {
  final String text;
  final int count;
  const _BadgeTab({required this.text, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }
}

class _MessagesList extends ConsumerWidget {
  final List<MessageModel> messages;
  final bool isSent;
  final bool isMemo;
  const _MessagesList({required this.messages, this.isSent = false, this.isMemo = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No messages found', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final m = messages[i];
        final isUnread = !isSent && m.readAt == null && !isMemo;

        return Card(
          elevation: isUnread ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isUnread ? AppTheme.primary.withOpacity(0.3) : Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isMemo ? Colors.orange : AppTheme.primary).withOpacity(0.1),
              child: Icon(isMemo ? Icons.campaign : Icons.person_outline, color: isMemo ? Colors.orange : AppTheme.primary),
            ),
            title: Text(m.subject ?? '(No Subject)', style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(m.body, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: isUnread ? const Icon(Icons.circle, color: AppTheme.primary, size: 10) : null,
            onTap: () async {
              if (isUnread) ref.read(messagingProvider.notifier).markRead(m.id);
              
              if (isMemo) {
                try {
                  final db = await ref.read(databaseProvider.future);
                  final user = ref.read(currentUserProvider)!;
                  await db.enterpriseDao.logMemoRead(MemoReadRecord(
                    memoId: m.id, 
                    userId: user.id, 
                    readAt: DateTime.now().millisecondsSinceEpoch
                  ));
                } catch (_) {} // Ignore duplicates or errors silently
              }
              
              _showMessageDetail(context, m, ref);
            },
          ),
        );
      },
    );
  }

  void _showMessageDetail(BuildContext context, MessageModel m, WidgetRef ref) async {
    final user = ref.read(currentUserProvider)!;
    int? readCount;
    
    if (isMemo && user.roleLevel <= 2) {
      final db = await ref.read(databaseProvider.future);
      readCount = await db.enterpriseDao.getMemoReadCount(m.id);
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(m.subject ?? '(No Subject)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From ID: ${m.senderId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 16),
            Text(m.body),
            if (readCount != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('$readCount staff members have viewed this memo.', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _ComposeSheet extends ConsumerStatefulWidget {
  final bool isAdmin;
  const _ComposeSheet({required this.isAdmin});

  @override
  ConsumerState<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<_ComposeSheet> {
  final _bodyCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  bool _isBroadcast = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text('New Message', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (widget.isAdmin)
            SwitchListTile(
              title: const Text('Institutional Memo'),
              subtitle: const Text('Broadcast to all school staff'),
              value: _isBroadcast,
              onChanged: (v) => setState(() => _isBroadcast = v),
              contentPadding: EdgeInsets.zero,
            ),
          if (!_isBroadcast)
            TextFormField(
              controller: _recipientCtrl,
              decoration: const InputDecoration(labelText: 'Recipient Email/ID', prefixIcon: Icon(Icons.person_add_alt)),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.subject)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bodyCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Message Body', alignLabelWithHint: true),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.send_rounded),
            label: Text(_isBroadcast ? 'Broadcast Memo' : 'Send Message'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            onPressed: _send,
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) return;

    String? recipientId;
    if (!_isBroadcast) {
      final db = await ref.read(databaseProvider.future);
      final rEmail = _recipientCtrl.text.trim().toLowerCase();
      final rUser = await db.userDao.findByEmail(rEmail);
      if (rUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipient not found.'), backgroundColor: Colors.red));
        return;
      }
      recipientId = rUser.id;
    }

    await ref.read(messagingProvider.notifier).sendMessage(
      recipientId: recipientId,
      messageType: _isBroadcast ? 'Broadcast' : 'Direct',
      subject: _subjectCtrl.text.trim(),
      body: body,
    );

    if (mounted) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent.'), backgroundColor: Colors.green));
  }
}
