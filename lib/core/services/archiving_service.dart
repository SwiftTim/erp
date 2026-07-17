// lib/core/services/archiving_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/student_model.dart';
import '../../features/auth/auth_provider.dart';
import 'audit_service.dart';

final archivingServiceProvider = Provider((ref) => ArchivingService(ref));

class ArchivingService {
  final Ref _ref;
  ArchivingService(this._ref);

  /// Executes the core 'Promote All' End-of-Year workflow.
  /// 
  /// This bumps every active student to their next progressive CBC grade.
  /// Grade 9 students are transitioned into alumni/graduated state.
  /// All class assignments are cleared, requiring fresh enrollment for the new academic year.
  Future<void> promoteAllStudents(String executorId) async {
    final db = await _ref.read(databaseProvider.future);
    final audit = _ref.read(auditServiceProvider);
    
    final allStudents = await db.studentDao.findAll();
    
    int promotedCount = 0;
    int graduatedCount = 0;

    for (final student in allStudents) {
      if (student.grade == 'Alumni') continue;

      final nextGrade = AppConstants.getNextGrade(student.grade);
      
      StudentModel updated;
      if (nextGrade != null) {
        updated = student.copyWith(
          grade: nextGrade,
          classId: 'UNASSIGNED', // Reset class pairing for the new year
        );
        promotedCount++;
      } else {
        // Grade 9 -> Alumni
        updated = student.copyWith(
          grade: 'Alumni',
          classId: 'GRADUATED',
        );
        graduatedCount++;
      }
      
      await db.studentDao.updateStudent(updated);
    }
    
    audit.log(
      'SYSTEM_ARCHIVE_PROMOTION',
      'Administration',
      'System-wide End-Of-Year promotion executed. $promotedCount promoted, $graduatedCount graduated.',
    );
  }
}
