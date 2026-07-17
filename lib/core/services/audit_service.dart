// lib/core/services/audit_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/enterprise_models.dart';
import '../../features/auth/auth_provider.dart';

final auditServiceProvider = Provider((ref) => AuditService(ref));

class AuditService {
  final Ref _ref;
  AuditService(this._ref);

  Future<void> log(String action, String module, String details) async {
    try {
      final db = await _ref.read(databaseProvider.future);
      final user = _ref.read(currentUserProvider);
      
      final entry = SystemLog(
        userId: user?.id ?? 'SYSTEM',
        action: action,
        module: module,
        details: details,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ipAddress: 'local-desktop',
      );

      await db.enterpriseDao.logActivity(entry);
    } catch (e) {
      print('Audit logging failed: $e');
    }
  }
}
