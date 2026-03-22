// lib/features/messaging/memo_compose_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'messaging_hub_provider.dart';

class MemoComposePage extends ConsumerStatefulWidget {
  const MemoComposePage({super.key});

  @override
  ConsumerState<MemoComposePage> createState() => _MemoComposePageState();
}

class _MemoComposePageState extends ConsumerState<MemoComposePage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _targetGroup = 'ALL';
  String _priority = 'NORMAL';
  bool _sending = false;

  static const _targetOptions = [
    _TargetOption(value: 'ALL', label: 'All Staff', icon: Icons.groups_outlined),
    _TargetOption(
        value: 'TEACHERS',
        label: 'All Teachers Only',
        icon: Icons.school_outlined),
    _TargetOption(
        value: 'ADMINISTRATION',
        label: 'Administration Only',
        icon: Icons.admin_panel_settings_outlined),
    _TargetOption(
        value: 'DEPARTMENT',
        label: 'My Department',
        icon: Icons.business_outlined),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canSend = user != null &&
        (user.roleLevel <= AppConstants.roleDeputy ||
            user.roleLevel == AppConstants.roleSeniorTeacher);

    if (!canSend) {
      return Scaffold(
        appBar: AppBar(title: const Text('Send Memo')),
        body: const Center(
            child: Text('You do not have permission to send memos.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Memo'),
        centerTitle: false,
        actions: [
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority selector
            Text('Priority',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                _PriorityChip(
                    label: 'Normal',
                    color: AppTheme.primary,
                    selected: _priority == 'NORMAL',
                    onTap: () => setState(() => _priority = 'NORMAL')),
                const SizedBox(width: 8),
                _PriorityChip(
                    label: 'Urgent',
                    color: Colors.orange,
                    selected: _priority == 'URGENT',
                    onTap: () => setState(() => _priority = 'URGENT')),
                const SizedBox(width: 8),
                _PriorityChip(
                    label: 'Emergency',
                    color: Colors.red,
                    selected: _priority == 'EMERGENCY',
                    onTap: () => setState(() => _priority = 'EMERGENCY')),
              ],
            ),
            const SizedBox(height: 20),

            // Target audience
            Text('Target Audience',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 13)),
            const SizedBox(height: 10),
            ..._targetOptions.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TargetTile(
                    option: opt,
                    selected: _targetGroup == opt.value,
                    onTap: () => setState(() => _targetGroup = opt.value),
                  ),
                )),

            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Memo Title *',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            TextFormField(
              controller: _contentCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Message Body *',
                alignLabelWithHint: true,
                helperText:
                    'Be clear and concise. This memo will be sent to all selected staff.',
              ),
            ),

            // Priority warning
            if (_priority == 'EMERGENCY')
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'EMERGENCY memos will interrupt all users with a fullscreen alert that cannot be dismissed until acknowledged.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in title and message body.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      // Get target user IDs
      final db = await ref.read(databaseProvider.future);
      final allStaff = await db.userDao.findAll();
      List<String> notifyIds;

      switch (_targetGroup) {
        case 'TEACHERS':
          notifyIds = allStaff
              .where((u) =>
                  u.isActive == 1 &&
                  (u.roleLevel == AppConstants.roleTeacher ||
                      u.roleLevel == AppConstants.roleSeniorTeacher))
              .map((u) => u.id)
              .toList();
          break;
        case 'ADMINISTRATION':
          notifyIds = allStaff
              .where((u) =>
                  u.isActive == 1 && u.roleLevel <= AppConstants.roleDeputy)
              .map((u) => u.id)
              .toList();
          break;
        default:
          notifyIds = allStaff
              .where((u) => u.isActive == 1 && u.roleLevel <= 10)
              .map((u) => u.id)
              .toList();
      }

      await ref.read(memoHubProvider.notifier).sendMemo(
            title: title,
            content: content,
            targetGroup: _targetGroup,
            priority: _priority,
            notifyUserIds: notifyIds,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Memo sent to ${notifyIds.length} staff member(s)'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send memo: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _TargetOption {
  final String value, label;
  final IconData icon;
  const _TargetOption(
      {required this.value, required this.label, required this.icon});
}

class _TargetTile extends StatelessWidget {
  final _TargetOption option;
  final bool selected;
  final VoidCallback onTap;
  const _TargetTile(
      {required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected ? AppTheme.primary : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(option.icon,
                size: 20,
                color: selected ? AppTheme.primary : Colors.grey),
            const SizedBox(width: 12),
            Text(option.label,
                style: TextStyle(
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color:
                        selected ? AppTheme.primary : Colors.black87)),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PriorityChip(
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}
