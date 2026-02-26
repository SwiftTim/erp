// lib/data/sync/sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import '../local/app_database.dart';
import '../../core/utils/connectivity_service.dart';

class SyncService {
  final AppDatabase db;
  
  SyncService(this.db);

  /// Checks if Firebase is initialized before proceeding
  bool _isFirebaseReady() {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Main sync loop: runs all individual sync tasks
  Future<void> syncAll() async {
    if (!_isFirebaseReady()) {
      print('⚠️ Sync skipped: Firebase not initialized. Enable backend tomorrow.');
      return;
    }

    final hasConnection = await ConnectivityService.isConnected();
    if (!hasConnection) return;

    print('🔄 Starting background sync...');
    
    await _syncAssessments();
    await _syncStudents();
    await _syncAttendance();
    await _syncEvidence();
    
    print('✅ Sync loop complete.');
  }

  Future<void> _syncAssessments() async {
    final unsynced = await db.assessmentDao.findUnsynced();
    for (final assessment in unsynced) {
      try {
        await FirebaseFirestore.instance
            .collection('assessments')
            .doc(assessment.id)
            .set(assessment.toFirestore());
        await db.assessmentDao.markSynced(assessment.id);
      } catch (e) {
        print('Error syncing assessment ${assessment.id}: $e');
      }
    }
  }

  Future<void> _syncStudents() async {
    final unsynced = await db.studentDao.findUnsynced();
    for (final student in unsynced) {
      try {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(student.id)
            .set(student.toFirestore());
        await db.studentDao.markSynced(student.id);
      } catch (e) {
        print('Error syncing student ${student.id}: $e');
      }
    }
  }

  Future<void> _syncAttendance() async {
    final unsynced = await db.attendanceDao.findUnsynced();
    for (final record in unsynced) {
      try {
        await FirebaseFirestore.instance
            .collection('attendance')
            .doc(record.id)
            .set(record.toFirestore());
        await db.attendanceDao.markSynced(record.id);
      } catch (e) {
        print('Error syncing attendance ${record.id}: $e');
      }
    }
  }

  Future<void> _syncEvidence() async {
    final pending = await db.assessmentDao.findPendingUploads();
    for (final item in pending) {
      try {
        final file = File(item.localPath);
        if (!await file.exists()) continue;

        final ref = FirebaseStorage.instance.ref().child('evidence/${item.studentId}/${item.id}');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();

        await db.assessmentDao.updateEvidence(item.copyWith(
          cloudUrl: url,
          uploaded: 1,
        ));
      } catch (e) {
        print('Error uploading evidence ${item.id}: $e');
      }
    }
  }
}
