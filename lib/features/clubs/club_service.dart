// lib/features/clubs/club_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../auth/auth_provider.dart';
import '../../data/local/app_database.dart';
import '../../data/models/club_model.dart';
import '../../data/models/student_model.dart';

final clubServiceProvider = Provider((ref) => ClubService(ref));

class ClubService {
  final Ref _ref;
  ClubService(this._ref);

  Future<List<ClubModel>> getMyClubs(String teacherId) async {
    final db = await _ref.read(databaseProvider.future);
    return db.clubDao.getClubsByPatron(teacherId);
  }

  Future<String> seedDefaultClubs() async {
    final db = await _ref.read(databaseProvider.future);
    final existing = await db.clubDao.getAllClubs();
    if (existing.isNotEmpty) return 'Initialization skipped: Clubs already exist.';

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final List<Map<String, String>> defaultClubs = [
        {'name': 'Mathematics Club', 'category': 'Academic', 'desc': 'Enhancing numerical capability and problem solving.'},
        {'name': 'Science Congress', 'category': 'Academic', 'desc': 'Research and innovation in science and technology.'},
        {'name': 'ICT / Coding Club', 'category': 'Academic', 'desc': 'Digital literacy and software development skills.'},
        {'name': 'Journalism Club', 'category': 'Academic', 'desc': 'School news, media literacy, and reporting.'},
        {'name': 'Debate Club', 'category': 'Academic', 'desc': 'Public speaking and critical thinking.'},
        {'name': 'Wildlife Club', 'category': 'Academic', 'desc': 'Environmental conservation and wildlife awareness.'},
        {'name': '4K Club', 'category': 'Academic', 'desc': 'Agriculture and food security projects.'},
        {'name': 'Drama Club', 'category': 'Arts', 'desc': 'Acting, script writing, and performance.'},
        {'name': 'Music Club', 'category': 'Arts', 'desc': 'Choir, instrumental music, and vocals.'},
        {'name': 'Football Club', 'category': 'Sports', 'desc': 'School football team development.'},
        {'name': 'Chess Club', 'category': 'Sports', 'desc': 'Strategic thinking through chess.'},
        {'name': 'Student Council', 'category': 'Leadership', 'desc': 'Student leadership and school governance.'},
        {'name': 'Red Cross', 'category': 'Leadership', 'desc': 'First aid and humanitarian service.'},
        {'name': 'Scouts / Girl Guides', 'category': 'Leadership', 'desc': 'Character development and outdoor skills.'},
        {'name': 'Christian Union', 'category': 'Leadership', 'desc': 'Spiritual growth and fellowship.'},
      ];

      for (var c in defaultClubs) {
        await db.clubDao.insertClub(ClubModel(
          id: Uuid().v4(),
          name: c['name']!,
          category: c['category']!,
          description: c['desc']!,
          createdAt: now,
        ));
      }
      return 'Successfully initialized ${defaultClubs.length} clubs.';
    } catch (e) {
      return 'Error: Failed to seed clubs. $e';
    }
  }

  Future<void> updateClubPatron(String clubId, String? teacherId) async {
    final db = await _ref.read(databaseProvider.future);
    final club = await db.clubDao.getClubById(clubId);
    if (club != null) {
      await db.clubDao.updateClub(club.copyWith(patronId: teacherId));
    }
  }

  Future<String?> addMember(String clubId, String studentId, String teacherId) async {
    final db = await _ref.read(databaseProvider.future);
    
    // 1. Check if student already in this club
    final existing = await db.clubDao.getMembership(studentId, clubId);
    if (existing != null) return 'Student is already a member of this club.';

    // 2. Check student's total club count (Max 2)
    final count = await db.clubDao.getStudentClubCount(studentId) ?? 0;
    if (count >= 2) return 'Student has reached the maximum limit of 2 clubs.';

    // 3. Check club capacity
    final club = await db.clubDao.getClubById(clubId);
    if (club == null) return 'Club not found.';
    final currentMembers = await db.clubDao.getMembersByClub(clubId);
    if (currentMembers.length >= club.capacityLimit) return 'Club has reached its maximum capacity of ${club.capacityLimit}.';

    // 4. Successful Add
    await db.clubDao.insertMember(ClubMemberModel(
      clubId: clubId,
      studentId: studentId,
      joinedAt: DateTime.now().millisecondsSinceEpoch,
      joinedBy: teacherId,
    ));
    
    return null; // Success
  }

  Future<void> removeMember(String clubId, String studentId) async {
    final db = await _ref.read(databaseProvider.future);
    await db.clubDao.removeStudentFromClub(studentId, clubId);
  }

  Future<double> calculateClubHealth(String clubId) async {
    final db = await _ref.read(databaseProvider.future);
    
    // Simple logic for visuals
    final club = await db.clubDao.getClubById(clubId);
    if (club == null) return 0;
    
    final members = await db.clubDao.getMembersByClub(clubId);
    final activities = await db.clubDao.getActivitiesByClub(clubId);
    
    double score = 0;
    // 1. Membership (30%) - Healthy if > 20 members
    score += (members.length / 20).clamp(0, 1) * 30;
    
    // 2. Activity Frequency (40%) - Healthy if > 4 activities this year
    score += (activities.length / 4).clamp(0, 1) * 40;
    
    // 3. Diversity (30%) - Just a mock for now
    score += 30;

    return score.clamp(0, 100);
  }
}
