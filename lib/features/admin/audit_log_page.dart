// lib/features/admin/audit_log_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/enterprise_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';

class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  List<SystemLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final db = await ref.read(databaseProvider.future);
    final logs = await db.enterpriseDao.getRecentLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Institutional Audit Trail',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLogs,
              child: _logs.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final log = _logs[i];
                        return _LogEntry(log: log);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.policy_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No system activities logged yet.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final SystemLog log;
  const _LogEntry({required this.log});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
    final timeStr = "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    final dateStr = "${date.day}/${date.month}/${date.year}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getActionColor(log.action).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getActionIcon(log.action), size: 16, color: _getActionColor(log.action)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("$dateStr • $timeStr", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 2),
                Text("${log.module} • by ${log.userId}", style: TextStyle(fontSize: 11, color: AppTheme.primary.withOpacity(0.8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(log.details, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('CREATE')) return Colors.green;
    if (action.contains('UPDATE')) return Colors.blue;
    if (action.contains('DELETE')) return Colors.red;
    if (action.contains('REJECT')) return Colors.orange;
    if (action.contains('PROCURE')) return Colors.teal;
    return Colors.grey;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('CREATE')) return Icons.add_circle_outline;
    if (action.contains('UPDATE')) return Icons.edit_outlined;
    if (action.contains('DELETE')) return Icons.delete_outline;
    if (action.contains('LOGIN')) return Icons.login;
    if (action.contains('PROCURE')) return Icons.shopping_cart_outlined;
    return Icons.info_outline;
  }
}
