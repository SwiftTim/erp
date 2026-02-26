// lib/features/dashboard/widgets/sync_badge.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../data/sync/sync_provider.dart';

class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    
    return StreamBuilder(
      stream: ConnectivityService.onConnectivityChanged,
      builder: (context, snapshot) {
        final isOnline = snapshot.data != null && 
                         snapshot.data!.any((r) => r.name != 'none');
        
        final status = syncState.status;
        final color = _getStatusColor(status, isOnline);
        final icon = _getStatusIcon(status, isOnline);
        final label = _getStatusLabel(status, isOnline);

        return GestureDetector(
          onTap: isOnline ? () => ref.read(syncProvider.notifier).runSync() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == SyncStatus.syncing)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, 
                        color: color,
                      ),
                    ),
                  )
                else
                  Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(SyncStatus status, bool isOnline) {
    if (!isOnline) return Colors.orange;
    switch (status) {
      case SyncStatus.syncing: return Colors.blue;
      case SyncStatus.error: return Colors.red;
      case SyncStatus.success: return Colors.green;
      case SyncStatus.idle: return Colors.green;
    }
  }

  IconData _getStatusIcon(SyncStatus status, bool isOnline) {
    if (!isOnline) return Icons.cloud_off_outlined;
    switch (status) {
      case SyncStatus.syncing: return Icons.sync;
      case SyncStatus.error: return Icons.error_outline;
      case SyncStatus.success: return Icons.check_circle_outline;
      case SyncStatus.idle: return Icons.cloud_done_outlined;
    }
  }

  String _getStatusLabel(SyncStatus status, bool isOnline) {
    if (!isOnline) return 'Offline';
    switch (status) {
      case SyncStatus.syncing: return 'Syncing...';
      case SyncStatus.error: return 'Sync Error';
      case SyncStatus.success: return 'Updated';
      case SyncStatus.idle: return 'Synced';
    }
  }
}
