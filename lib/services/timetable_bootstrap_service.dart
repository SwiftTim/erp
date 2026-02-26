import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../data/models/timetable_models.dart';
import '../features/auth/auth_provider.dart';
import '../core/constants/app_constants.dart';

final timetableBootstrapServiceProvider = Provider((ref) => TimetableBootstrapService(ref));

class TimetableBootstrapService {
  final Ref _ref;


  TimetableBootstrapService(this._ref);

  /// Automatically populates Teacher Capacities and Class Demands with sample data for testing.
  Future<void> bootstrapTestData() async {
    final db = await _ref.read(databaseProvider.future);
    
    // 1. Fetch foundation data
    final teachers = (await db.userDao.findAllActive()).where((u) => u.roleLevel <= AppConstants.roleTeacher).toList();
    final classes = await db.curriculumDao.findAllClasses();
    final subjects = await db.curriculumDao.findAllLearningAreas();

    if (teachers.isEmpty || classes.isEmpty || subjects.isEmpty) {
      throw Exception('Foundation data missing. Ensure teachers, classes, and curriculum are seeded first.');
    }

    // 2. Bootstrap Teacher Profiles & Capabilities
    // We'll distribute subjects among teachers
    for (int i = 0; i < teachers.length; i++) {
      final teacher = teachers[i];
      
      // Create Profile
      final profile = TeacherTimetableProfile(
        id: teacher.id,
        teacherId: teacher.id,
        maxPeriodsPerDay: 7,
        maxPeriodsPerWeek: 30,
        isClassTeacher: i < classes.length, // Assign some as class teachers
      );
      await db.timetableDao.insertTeacherProfile(profile);

      // Assign 2-3 subjects per teacher
      // We'll pick subjects that match their likely band if possible, or just cycle
      final teacherSubjects = [
        subjects[i % subjects.length],
        subjects[(i + 1) % subjects.length],
      ];

      for (int j = 0; j < teacherSubjects.length; j++) {
        final sub = teacherSubjects[j];
        final cap = TeacherSubjectCapability(
          id: '${teacher.id}_${sub.id}',
          teacherId: teacher.id,
          subjectId: sub.id,
          priorityLevel: j + 1, // 1=Primary, 2=Secondary
        );
        await db.timetableDao.insertTeacherCapability(cap);
      }
    }

    // 3. Bootstrap Class Demands
    // Each class needs all subjects relevant to its grade band
    for (final schoolClass in classes) {
      final band = AppConstants.gradeBand(schoolClass.grade);
      final relevantSubjects = subjects.where((s) => s.gradeBand == band).toList();
      
      // If no band-specific subjects found (fallback), use all subjects
      final targetSubjects = relevantSubjects.isNotEmpty ? relevantSubjects : subjects.take(5).toList();

      for (final sub in targetSubjects) {
        // Assign standard demand: 5 periods for core, 3 for others
        final demandValue = (sub.category == 'Core') ? 5 : 3;
        
        final req = ClassSubjectRequirement(
          id: '${schoolClass.id}_${sub.id}',
          classId: schoolClass.id,
          subjectId: sub.id,
          periodsPerWeek: demandValue,
        );
        await db.timetableDao.insertClassRequirement(req);
      }
    }
  }
}
