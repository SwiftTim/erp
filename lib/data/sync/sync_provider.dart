// lib/data/sync/sync_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/app_database.dart';
import '../sync/sync_service.dart';
import '../../features/auth/auth_provider.dart';

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final db = ref.watch(databaseProvider).maybeWhen(
        data: (db) => db,
        orElse: () => null,
      );
  return SyncNotifier(db);
});

enum SyncStatus { idle, syncing, error, success }

class SyncState {
  final SyncStatus status;
  final String? lastError;
  final DateTime? lastSyncTime;

  SyncState({
    this.status = SyncStatus.idle,
    this.lastError,
    this.lastSyncTime,
  });

  SyncState copyWith({SyncStatus? status, String? lastError, DateTime? lastSyncTime}) {
    return SyncState(
      status: status ?? this.status,
      lastError: lastError,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final AppDatabase? _db;
  SyncNotifier(this._db) : super(SyncState());

  Future<void> runSync() async {
    if (_db == null || state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing);
    
    try {
      final service = SyncService(_db);
      await service.syncAll();
      state = state.copyWith(status: SyncStatus.success, lastSyncTime: DateTime.now());
      
      // Reset to idle after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) state = state.copyWith(status: SyncStatus.idle);
      });
    } catch (e) {
      state = state.copyWith(status: SyncStatus.error, lastError: e.toString());
    }
  }
}
