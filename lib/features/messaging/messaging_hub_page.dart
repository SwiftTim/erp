// lib/features/messaging/messaging_hub_page.dart
// Main Messaging Hub – replaces old messaging_page.dart route

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../../data/models/messaging_models.dart';
import '../../data/models/enterprise_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'messaging_hub_provider.dart';
import 'staff_directory_page.dart';
import 'chat_window_page.dart';
import 'memo_compose_page.dart';
import 'school_calendar_page.dart';

class MessagingHubPage extends ConsumerStatefulWidget {
  const MessagingHubPage({super.key});

  @override
  ConsumerState<MessagingHubPage> createState() => _MessagingHubPageState();
}

class _MessagingHubPageState extends ConsumerState<MessagingHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();
    final notifState = ref.watch(notificationsProvider);
    final memoState = ref.watch(memoHubProvider);
    final canSendMemo = user.roleLevel <= AppConstants.roleDeputy ||
        user.roleLevel == AppConstants.roleSeniorTeacher;

    return AppShell(
      title: 'Messaging Hub',
      actions: [
        // Notification bell
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => _showNotificationsPanel(context),
            ),
            if (notifState.unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Text(
                    '${notifState.unreadCount > 99 ? "99+" : notifState.unreadCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ],
      body: Column(
        children: [
          _buildHubHeader(user, canSendMemo),
          TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(icon: Icon(Icons.forum_outlined), text: 'Chats'),
              const Tab(icon: Icon(Icons.group_outlined), text: 'Groups'),
              Tab(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.campaign_outlined),
                    if (memoState.memos.isNotEmpty)
                      Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle),
                          )),
                  ],
                ),
                text: 'Memos',
              ),
              const Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Calendar'),
            ],
            labelColor: AppTheme.primary,
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _ChatsTab(user: user),
                _GroupsTab(user: user),
                _MemosTab(user: user, canSendMemo: canSendMemo),
                _CalendarTab(user: user),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, user, canSendMemo),
    );
  }

  Widget _buildHubHeader(UserModel user, bool canSendMemo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good ${_greeting()}, ${user.name.split(' ').first}!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(AppConstants.roleNames[user.roleLevel] ?? 'Staff',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 13)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const StaffDirectoryPage())),
            icon: const Icon(Icons.people_alt_outlined, size: 18),
            label: const Text('Directory'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFAB(
      BuildContext context, UserModel user, bool canSendMemo) {
    final tabIndex = _tab.index;
    if (tabIndex == 0) {
      // Chats tab → open staff directory to start new chat
      return FloatingActionButton.extended(
        heroTag: 'fab_chat',
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StaffDirectoryPage())),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New Chat'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      );
    } else if (tabIndex == 2 && canSendMemo) {
      return FloatingActionButton.extended(
        heroTag: 'fab_memo',
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemoComposePage())),
        icon: const Icon(Icons.send_outlined),
        label: const Text('Send Memo'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      );
    } else if (tabIndex == 3 &&
        user.roleLevel <= AppConstants.roleDeputy) {
      return FloatingActionButton.extended(
        heroTag: 'fab_event',
        onPressed: () => _showAddEventDialog(context),
        icon: const Icon(Icons.event_available_outlined),
        label: const Text('Add Event'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      );
    }
    return null;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _NotificationsSheet(),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _AddEventSheet(),
      ),
    );
  }
}

// ── Chats Tab ────────────────────────────────────────────────────────────────
class _ChatsTab extends ConsumerWidget {
  final UserModel user;
  const _ChatsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentChatsProvider);
    final pinned = ref.watch(pinnedChatsProvider);

    return recentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (messages) {
        if (messages.isEmpty) {
          return const _EmptyState(
            icon: Icons.forum_outlined,
            message: 'No active conversations',
            subtext: 'Tap "New Chat" to start messaging staff',
          );
        }
        
        // Sort: Pinned first, then by timestamp
        final sorted = List.of(messages)..sort((a, b) {
          final aOtherId = a.senderId == user.id ? a.receiverId! : a.senderId;
          final bOtherId = b.senderId == user.id ? b.receiverId! : b.senderId;
          final aPinned = pinned.contains(aOtherId) ? 1 : 0;
          final bPinned = pinned.contains(bOtherId) ? 1 : 0;
          
          if (aPinned != bPinned) return bPinned.compareTo(aPinned);
          return b.timestamp.compareTo(a.timestamp);
        });

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recentChatsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, i) {
              final msg = sorted[i];
              final otherId = msg.senderId == user.id ? msg.receiverId! : msg.senderId;
              
              return _RecentConversationTile(
                lastMessage: msg,
                otherUserId: otherId,
                currentUserId: user.id,
                isPinned: pinned.contains(otherId),
              );
            },
          ),
        );
      },
    );
  }
}

class _RecentConversationTile extends ConsumerWidget {
  final ChatMessage lastMessage;
  final String otherUserId;
  final String currentUserId;
  final bool isPinned;

  const _RecentConversationTile({
    required this.lastMessage,
    required this.otherUserId,
    required this.currentUserId,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(allStaffProvider);
    final unreadAsync = ref.watch(unreadChatCountProvider(otherUserId));

    return staffAsync.when(
      loading: () => const ListTile(title: Text('Loading...')),
      error: (_, __) => const SizedBox(),
      data: (staffList) {
        final staff = staffList.where((s) => s.id == otherUserId).firstOrNull;
        if (staff == null) return const SizedBox();

        final isMine = lastMessage.senderId == currentUserId;
        final unreadCount = unreadAsync.asData?.value ?? 0;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              _StaffAvatar(name: staff.name, roleLevel: staff.roleLevel),
              if (isPinned)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.push_pin, size: 14, color: AppTheme.primary),
                  ),
                ),
            ],
          ),
          title: Text(staff.name, style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600)),
          subtitle: Row(
            children: [
              if (isMine) ...[
                _buildStatusIcon(lastMessage.status),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  lastMessage.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade500,
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeAgo(DateTime.fromMillisecondsSinceEpoch(lastMessage.timestamp)),
                style: TextStyle(
                  fontSize: 11,
                  color: unreadCount > 0 ? AppTheme.primary : Colors.grey.shade500,
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              ] else
                const SizedBox(height: 18),
            ],
          ),
          onLongPress: () {
            ref.read(pinnedChatsProvider.notifier).togglePin(otherUserId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isPinned ? 'Chat unpinned' : 'Chat pinned'), duration: const Duration(seconds: 1)),
            );
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatWindowPage(otherUser: staff, currentUserId: currentUserId)),
            ).then((_) {
              // Refresh when returning
              ref.invalidate(recentChatsProvider);
              ref.invalidate(unreadChatCountProvider(otherUserId));
            });
          },
        );
      },
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'read':
        return const Icon(Icons.done_all_rounded, size: 14, color: Colors.lightBlueAccent);
      case 'delivered':
        return const Icon(Icons.done_all_rounded, size: 14, color: Colors.grey);
      default:
        return const Icon(Icons.done_rounded, size: 14, color: Colors.grey);
    }
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Yesterday';
      return DateFormat('dd/MM').format(dt);
    }
    if (diff.inHours > 0) return DateFormat('HH:mm').format(dt);
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}


// ── Groups Tab ────────────────────────────────────────────────────────────────
class _GroupsTab extends ConsumerWidget {
  final UserModel user;
  const _GroupsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(chatGroupsProvider);
    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (groups) {
        if (groups.isEmpty) {
          return _EmptyState(
            icon: Icons.group_outlined,
            message: 'No group chats yet',
            subtext:
                'System groups are created automatically based on departments',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: groups.length,
          itemBuilder: (context, i) {
            final group = groups[i];
            return _GroupTile(
              group: group,
              currentUserId: user.id,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatWindowPage(
                      group: group, currentUserId: user.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GroupTile extends ConsumerWidget {
  final ChatGroup group;
  final String currentUserId;
  final VoidCallback onTap;
  const _GroupTile(
      {required this.group,
      required this.currentUserId,
      required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMsgFuture = ref.watch(_lastGroupMsgProvider(group.id));
    final color = _groupColor(group.type);
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        radius: 24,
        child: Icon(_groupIcon(group.type), color: color, size: 22),
      ),
      title:
          Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: lastMsgFuture.when(
        loading: () =>
            Text(_groupTypeLabel(group.type),
                style: TextStyle(color: Colors.grey.shade500)),
        error: (_, __) => Text(_groupTypeLabel(group.type)),
        data: (msg) => msg != null
            ? Text(msg.message,
                maxLines: 1, overflow: TextOverflow.ellipsis)
            : Text(_groupTypeLabel(group.type),
                style: TextStyle(color: Colors.grey.shade500)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Color _groupColor(String type) {
    switch (type) {
      case 'all_staff':
        return AppTheme.primary;
      case 'administration':
        return Colors.purple;
      case 'department':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  IconData _groupIcon(String type) {
    switch (type) {
      case 'all_staff':
        return Icons.groups_outlined;
      case 'administration':
        return Icons.admin_panel_settings_outlined;
      case 'department':
        return Icons.business_outlined;
      default:
        return Icons.group_outlined;
    }
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
        return 'Group';
    }
  }
}

final _lastGroupMsgProvider =
    FutureProvider.family<ChatMessage?, String>((ref, groupId) async {
  final db = await ref.read(databaseProvider.future);
  return db.chatDao.getLastGroupMessage(groupId);
});

// ── Memos Tab ─────────────────────────────────────────────────────────────────
class _MemosTab extends ConsumerWidget {
  final UserModel user;
  final bool canSendMemo;
  const _MemosTab({required this.user, required this.canSendMemo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoState = ref.watch(memoHubProvider);
    if (memoState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (memoState.memos.isEmpty) {
      return _EmptyState(
        icon: Icons.campaign_outlined,
        message: 'No memos yet',
        subtext: canSendMemo
            ? 'Tap the Send Memo button to broadcast to staff'
            : 'Memos from leadership will appear here',
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(memoHubProvider.notifier).reload(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: memoState.memos.length,
        itemBuilder: (context, i) {
          final memo = memoState.memos[i];
          return _MemoCard(memo: memo, currentUser: user);
        },
      ),
    );
  }
}

class _MemoCard extends ConsumerWidget {
  final OfficialMemo memo;
  final UserModel currentUser;
  const _MemoCard({required this.memo, required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = currentUser.roleLevel <= AppConstants.roleDeputy;
    final priorityColor = _priorityColor(memo.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showMemoDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      memo.priority,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      memo.targetGroup,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM, HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(memo.createdAt)),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(memo.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Text(
                memo.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _ReadTrackingRow(memoId: memo.id),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
        return Colors.orange;
      case 'EMERGENCY':
        return Colors.red;
      default:
        return AppTheme.primary;
    }
  }

  void _showMemoDetail(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _priorityColor(memo.priority).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.campaign_outlined,
                  color: _priorityColor(memo.priority)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(memo.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, dd MMMM yyyy – HH:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(memo.createdAt)),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
              Text(memo.content, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 16),
              Chip(
                label: Text('Target: ${memo.targetGroup}'),
                backgroundColor: Colors.grey.shade100,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

class _ReadTrackingRow extends StatelessWidget {
  final String memoId;
  const _ReadTrackingRow({required this.memoId});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final countFuture = ref.watch(_memoReadCountProvider(memoId));
      return countFuture.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (count) => Row(
          children: [
            const Icon(Icons.done_all_rounded, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text('$count staff read',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      );
    });
  }
}

final _memoReadCountProvider =
    FutureProvider.family<int, String>((ref, memoId) async {
  final db = await ref.read(databaseProvider.future);
  return await db.enterpriseDao.getMemoReadCount(memoId) ?? 0;
});

// ── Calendar Tab ──────────────────────────────────────────────────────────────
class _CalendarTab extends ConsumerWidget {
  final UserModel user;
  const _CalendarTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SchoolCalendarEmbeddedView(user: user);
  }
}

// ── Notifications Sheet ───────────────────────────────────────────────────────
class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Notifications',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (state.unreadCount > 0)
                  TextButton.icon(
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark all read'),
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).markAllRead(),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('All caught up!',
                                style: TextStyle(
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.notifications.length,
                        itemBuilder: (ctx, i) {
                          final n = state.notifications[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _notifColor(n.notifType)
                                  .withOpacity(0.1),
                              child: Icon(
                                  _notifIcon(n.notifType),
                                  color: _notifColor(n.notifType),
                                  size: 20),
                            ),
                            title: Text(n.title,
                                style: TextStyle(
                                    fontWeight: n.isRead == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14)),
                            subtitle: Text(n.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                            trailing: n.isRead == 0
                                ? const Icon(Icons.circle,
                                    color: AppTheme.primary, size: 8)
                                : null,
                            onTap: () {
                              if (n.id != null) {
                                ref
                                    .read(notificationsProvider.notifier)
                                    .markRead(n.id!);
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _notifColor(String type) {
    switch (type) {
      case 'memo':
        return Colors.orange;
      case 'calendar':
        return AppTheme.primary;
      case 'message':
        return Colors.blue;
      case 'discipline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'memo':
        return Icons.campaign_outlined;
      case 'calendar':
        return Icons.event_outlined;
      case 'message':
        return Icons.chat_outlined;
      case 'discipline':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}

// ── Add Event Sheet ───────────────────────────────────────────────────────────
class _AddEventSheet extends ConsumerStatefulWidget {
  const _AddEventSheet();
  @override
  ConsumerState<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<_AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _eventType = 'Staff Meeting';
  String _priority = 'normal';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _saving = false;

  static const _eventTypes = [
    'Term Opening', 'Midterm Break', 'Term Closing', 'Examination Period',
    'Sports Day', 'Academic Day', 'Competition Day', 'Staff Meeting',
    'CBC Assessment Week', 'Parents Meeting Day', 'Report Card Issuing Day',
    'National Exam Preparation', 'Club Activity Day',
    'Teacher Professional Development',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Add Calendar Event',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Event Title',
                  prefixIcon: Icon(Icons.event_outlined)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _eventType,
              decoration: const InputDecoration(
                  labelText: 'Event Type',
                  prefixIcon: Icon(Icons.category_outlined)),
              items: _eventTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _eventType = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.priority_high_outlined)),
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'important', child: Text('Important')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
              ],
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _DateField(
                        label: 'Start Date',
                        date: _startDate,
                        onPick: (d) => setState(() => _startDate = d))),
                const SizedBox(width: 12),
                Expanded(
                    child: _DateField(
                        label: 'End Date',
                        date: _endDate,
                        onPick: (d) => setState(() => _endDate = d))),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              label: const Text('Add Event'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final user = ref.read(currentUserProvider)!;
    final db = await ref.read(databaseProvider.future);
    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      eventType: _eventType,
      startDate: _startDate.millisecondsSinceEpoch,
      endDate: _endDate.millisecondsSinceEpoch,
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      priority: _priority,
      createdBy: user.id,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Notify all staff
    final allStaff = await db.userDao.findAll();
    final staffIds = allStaff
        .where((u) => u.isActive == 1 && u.roleLevel <= 10)
        .map((u) => u.id)
        .toList();

    await ref.read(calendarNotifier.notifier).addEvent(event,
        notifyUserIds: staffIds);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Event added and staff notified!'),
            backgroundColor: AppTheme.primary),
      );
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;
  const _DateField(
      {required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
        child: Text(DateFormat('dd MMM yyyy').format(date),
            style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

// ── Empty State Widget ────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtext;
  const _EmptyState(
      {required this.icon, required this.message, required this.subtext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text(subtext,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Staff Avatar Widget ───────────────────────────────────────────────────────
class _StaffAvatar extends StatelessWidget {
  final String name;
  final int roleLevel;
  const _StaffAvatar({required this.name, required this.roleLevel});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
    final color = _roleColor(roleLevel);
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.15),
      radius: 24,
      child: Text(initials,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Color _roleColor(int level) {
    if (level <= 3) return Colors.purple;
    if (level <= 5) return AppTheme.primary;
    return Colors.teal;
  }
}
