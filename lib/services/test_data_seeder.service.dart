import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/user_model.dart';
import '../data/models/curriculum_models.dart';
import '../data/models/student_model.dart';
import '../data/models/timetable_models.dart';
import '../features/auth/auth_provider.dart';
import '../core/constants/app_constants.dart';

final testDataSeederProvider = Provider((ref) => TestDataSeeder(ref));

class TestDataSeeder {
  final Ref _ref;
  final _uuid = const Uuid();
  final _random = Random();

  TestDataSeeder(this._ref);

  Future<void> seedAll() async {
    final db = await _ref.read(databaseProvider.future);

    // 2. Seed Learning Areas (Subjects) as per MoE
    await _seedSubjects(db);

    // 3. Seed Teachers (20 teachers)
    final teachers = await _seedTeachers(db);

    // 4. Seed Classes (PP1 to Grade 9)
    final classes = await _seedClasses(db, teachers);

    // 5. Seed Students (20 per class)
    await _seedStudents(db, classes);

    // 6. Seed Timetable Constraints (Propagate Business Logic)
    await _seedTimetableConstraints(db, teachers, classes);
  }

  Future<void> _seedSubjects(dynamic db) async {
    final List<LearningAreaModel> subjects = [];

    // Pre-Primary
    final ppSubjects = ['Language Activities', 'Mathematical Activities', 'Environmental Activities', 'Psychomotor and Creative', 'Religious Education'];
    for (var name in ppSubjects) {
      subjects.add(LearningAreaModel(id: 'SUB_PP_${name.split(' ')[0]}', name: name, gradeBand: 'Pre-Primary', category: 'Core'));
    }

    // Lower Primary (G1-G3)
    final lpSubjects = ['Literacy', 'Kiswahili', 'English Language', 'Mathematics', 'Environmental Activities', 'Hygiene and Nutrition', 'Religious Education', 'Creative Arts', 'Movement Activities'];
    for (var name in lpSubjects) {
      subjects.add(LearningAreaModel(id: 'SUB_LP_${name.split(' ')[0]}', name: name, gradeBand: 'Lower Primary', category: 'Core'));
    }

    // Upper Primary (G4-G6)
    final upSubjects = ['English', 'Kiswahili', 'Mathematics', 'Science and Technology', 'Social Studies', 'Agriculture and Nutrition', 'Creative Arts and Sports', 'Religious Education'];
    for (var name in upSubjects) {
      subjects.add(LearningAreaModel(id: 'SUB_UP_${name.split(' ')[0]}', name: name, gradeBand: 'Upper Primary', category: 'Core'));
    }

    // Junior School (G7-G9)
    final jsSubjects = ['English', 'Kiswahili', 'Mathematics', 'Pre-Technical Studies', 'Integrated Science', 'Social Studies', 'Agriculture and Nutrition', 'Creative Arts and Sports', 'Religious Education'];
    for (var name in jsSubjects) {
      subjects.add(LearningAreaModel(id: 'SUB_JS_${name.split(' ')[0]}', name: name, gradeBand: 'Junior School', category: 'Core'));
    }

    for (var s in subjects) {
      await db.curriculumDao.insertArea(s);
    }
  }

  Future<List<UserModel>> _seedTeachers(dynamic db) async {
    final List<UserModel> teachers = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    final bytes = utf8.encode('admin123' + 'cbc_salt_2026');
    final adminHash = sha256.convert(bytes).toString();

    // 1 Deputy
    teachers.add(UserModel(
      id: 'TCH_DEPUTY',
      name: 'Deputy Sarah Wanjiku',
      email: 'deputy@school.com',
      passwordHash: adminHash,
      roleLevel: AppConstants.roleDeputy,
      isActive: 1,
      createdAt: now,
    ));

    // 39 Regular Teachers
    final names = [
      'James Kamau', 'Mercy Achieng', 'Robert Otieno', 'Alice Mutua', 'David Kipkorir',
      'Fatuma Hassan', 'Kevin Odhiambo', 'Grace Maina', 'Peter Kariuki', 'Lydia Ochieng',
      'Samuel Ngugi', 'Phyllis Waweru', 'Isaac Kibet', 'Catherine Njeri', 'Paul Musyoka',
      'Beatrice Kwamboka', 'Simon Moraa', 'Faith Chepkirui', 'Noel Zawadi', 'Hassan Ali',
      'Mary Atieno', 'John Omondi', 'Lucy Wambui', 'George Njuguna', 'Esther Nyambura',
      'Francis Mutiso', 'Rose Chebet', 'Dennis Wamalwa', 'Zeynep Amina', 'Victor Koech',
      'Sarah Chelangat', 'Benard Onyango', 'Eunice Wanjiru', 'Daniel Mulu', 'Agnes Mutuku',
      'Timothy Kiprotich', 'Caroline Wangari', 'Moses Okello', 'Joyce Anyango'
    ];

    for (int i = 0; i < names.length; i++) {
      teachers.add(UserModel(
        id: 'TCH_${i + 1}',
        name: names[i],
        email: 'teacher${i + 1}@school.com',
        passwordHash: adminHash,
        roleLevel: AppConstants.roleTeacher,
        isActive: 1,
        createdAt: now,
      ));
    }

    for (var t in teachers) {
      await db.userDao.insertUser(t);
    }
    return teachers;
  }

  Future<List<SchoolClassModel>> _seedClasses(dynamic db, List<UserModel> teachers) async {
    final List<SchoolClassModel> classes = [];
    final grades = AppConstants.allGrades;

    for (int i = 0; i < grades.length; i++) {
        // TCH_1 to TCH_11 will be Class Teachers
        final teacher = teachers[i + 1]; 
        classes.add(SchoolClassModel(
          id: 'CLS_${grades[i].replaceAll(' ', '_')}',
          name: '${grades[i]} Alpha',
          grade: grades[i],
          teacherId: teacher.id,
          academicYear: '2026',
        ));
    }

    for (var c in classes) {
      await db.curriculumDao.insertClass(c);
    }
    return classes;
  }

  Future<void> _seedStudents(dynamic db, List<SchoolClassModel> classes) async {
    final firstNames = ['Otieno', 'Kamau', 'Mwangi', 'Juma', 'Mutua', 'Kipkorir', 'Hassan', 'Odhiambo', 'Maina', 'Kariuki', 'Ochieng', 'Ngugi', 'Waweru', 'Kibet', 'Achieng', 'Njeri', 'Wanjiru', 'Akinyi', 'Atieno', 'Fatuma', 'Amina', 'Musyoka', 'Wambui', 'Kwamboka', 'Moraa', 'Chepkirui'];
    final lastNames = ['Omondi', 'Njoroge', 'Githinji', 'Ali', 'Kilonzo', 'Cheruiyot', 'Mohammed', 'Okoth', 'Karanja', 'Mungai', 'Anyango', 'Wambua', 'Rotich', 'Nyambane', 'Khadija', 'Mboya'];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var c in classes) {
      for (int i = 1; i <= 20; i++) {
        final fName = firstNames[_random.nextInt(firstNames.length)];
        final lName = lastNames[_random.nextInt(lastNames.length)];
        final upi = 'UPI-${c.id}-${i.toString().padLeft(3, '0')}';
        final birthYear = 2026 - (classes.indexOf(c) + 5);

        await db.studentDao.insertStudent(StudentModel(
          id: _uuid.v4(),
          upi: upi,
          fullName: '$fName $lName',
          gender: _random.nextBool() ? 'Male' : 'Female',
          dob: '$birthYear-01-01',
          grade: c.grade,
          classId: c.id,
          createdAt: now,
          synced: 0,
        ));
      }
    }
  }

  Future<void> _seedTimetableConstraints(dynamic db, List<UserModel> teachers, List<SchoolClassModel> classes) async {
    final subjects = await db.curriculumDao.findAllLearningAreas();

    // Clear old constraints to avoid duplicates/conflicts
    await db.timetableDao.clearAllCapabilities();
    await db.timetableDao.clearAllRequirements();
    await db.timetableDao.clearAllTeacherProfiles();

    final regularTeachers = teachers.where((t) => t.roleLevel == AppConstants.roleTeacher).toList();
    final classTeacherIds = classes.map((c) => c.teacherId).toSet();

    // ── Step 1: Create profiles for ALL teachers ──────────────────────────────
    for (var t in teachers) {
      await db.timetableDao.insertTeacherProfile(TeacherTimetableProfile(
        id: t.id,
        teacherId: t.id,
        maxPeriodsPerDay: t.roleLevel == AppConstants.roleDeputy ? 4 : 8,
        maxPeriodsPerWeek: t.roleLevel == AppConstants.roleDeputy ? 20 : 40,
        isClassTeacher: classTeacherIds.contains(t.id),
      ));
    }

    // ── Step 2: Group subjects by grade band ─────────────────────────────────
    final ppSubjects  = subjects.where((s) => s.gradeBand == 'Pre-Primary').toList();
    final lpSubjects  = subjects.where((s) => s.gradeBand == 'Lower Primary').toList();
    final upSubjects  = subjects.where((s) => s.gradeBand == 'Upper Primary').toList();
    final jsSubjects  = subjects.where((s) => s.gradeBand == 'Junior School').toList();

    // ── Step 3: Fair Round-Robin Specialist Pool ──────────────────────────────
    // We split the 39 teachers into pools so every teacher qualifies for something.
    // Lower Primary: all 39 teachers rotate as potential class/assistant teachers
    // Upper & Junior Primary: all 39 teachers rotate as subject specialists

    // Round-robin counter so assignments spread evenly across ALL teachers
    int teacherCursor = 0;

    // Helper: pick N teachers starting from cursor, wrapping around
    List<UserModel> pickTeachers(int n) {
      final result = <UserModel>[];
      for (int k = 0; k < n; k++) {
        result.add(regularTeachers[teacherCursor % regularTeachers.length]);
        teacherCursor++;
      }
      return result;
    }

    // ── Step 4: Seed Pre-Primary classes ─────────────────────────────────────
    final ppClasses = classes.where((c) => AppConstants.gradeBand(c.grade) == 'Pre-Primary').toList();
    for (var c in ppClasses) {
      int totalPeriods = 0;
      for (var s in ppSubjects) {
        int pPerWeek = s.name.contains('Religious') ? 3 : 5;
        if (totalPeriods + pPerWeek > 30) pPerWeek = 30 - totalPeriods;
        if (pPerWeek <= 0) continue;
        totalPeriods += pPerWeek;

        // P1: the class teacher
        await db.timetableDao.insertTeacherCapability(TeacherSubjectCapability(
          id: 'CAP_PP_P1_${c.teacherId}_${s.id}',
          teacherId: c.teacherId!,
          subjectId: s.id,
          priorityLevel: 1,
        ));

        // P2-P5: 4 additional teachers from round-robin pool (ensures broad coverage)
        final pool = pickTeachers(4);
        for (int k = 0; k < pool.length; k++) {
          await db.timetableDao.insertTeacherCapability(TeacherSubjectCapability(
            id: 'CAP_PP_P${k + 2}_${pool[k].id}_${s.id}',
            teacherId: pool[k].id,
            subjectId: s.id,
            priorityLevel: k + 2,
          ));
        }

        await db.timetableDao.insertClassRequirement(ClassSubjectRequirement(
          id: 'REQ_${c.id}_${s.id}',
          classId: c.id,
          subjectId: s.id,
          periodsPerWeek: pPerWeek,
        ));
      }
    }

    // ── Step 5: Seed Lower Primary classes ───────────────────────────────────
    final lpClasses = classes.where((c) => AppConstants.gradeBand(c.grade) == 'Lower Primary').toList();
    for (var c in lpClasses) {
      int totalPeriods = 0;
      for (var s in lpSubjects) {
        int pPerWeek = (s.name.contains('Literacy') || s.name.contains('Math')) ? 5
            : s.name.contains('Religious') || s.name.contains('Hygiene') ? 3 : 4;
        if (totalPeriods + pPerWeek > 35) pPerWeek = 35 - totalPeriods;
        if (pPerWeek <= 0) continue;
        totalPeriods += pPerWeek;

        // P1: class teacher
        await db.timetableDao.insertTeacherCapability(TeacherSubjectCapability(
          id: 'CAP_LP_P1_${c.teacherId}_${s.id}',
          teacherId: c.teacherId!,
          subjectId: s.id,
          priorityLevel: 1,
        ));

        // P2-P5: round-robin pool (4 more teachers)
        final pool = pickTeachers(4);
        for (int k = 0; k < pool.length; k++) {
          await db.timetableDao.insertTeacherCapability(TeacherSubjectCapability(
            id: 'CAP_LP_P${k + 2}_${pool[k].id}_${s.id}',
            teacherId: pool[k].id,
            subjectId: s.id,
            priorityLevel: k + 2,
          ));
        }

        await db.timetableDao.insertClassRequirement(ClassSubjectRequirement(
          id: 'REQ_${c.id}_${s.id}',
          classId: c.id,
          subjectId: s.id,
          periodsPerWeek: pPerWeek,
        ));
      }
    }

    // ── Step 6: Seed Upper Primary classes ───────────────────────────────────
    final upClasses = classes.where((c) => AppConstants.gradeBand(c.grade) == 'Upper Primary').toList();
    for (var c in upClasses) {
      int totalPeriods = 0;
      for (var s in upSubjects) {
        int pPerWeek = (s.name.contains('English') || s.name.contains('Math')) ? 5 : 4;
        if (totalPeriods + pPerWeek > 35) pPerWeek = 35 - totalPeriods;
        if (pPerWeek <= 0) continue;
        totalPeriods += pPerWeek;

        // 5 teachers per subject from round-robin — guarantees every teacher gets turns
        final pool = pickTeachers(5);
        for (int k = 0; k < pool.length; k++) {
          await db.timetableDao.insertTeacherCapability(TeacherSubjectCapability(
            id: 'CAP_UP_P${k + 1}_${pool[k].id}_${s.id}_${c.id}',
            teacherId: pool[k].id,
            subjectId: s.id,
            priorityLevel: k + 1,
          ));
        }

        await db.timetableDao.insertClassRequirement(ClassSubjectRequirement(
          id: 'REQ_${c.id}_${s.id}',
          classId: c.id,
          subjectId: s.id,
          periodsPerWeek: pPerWeek,
        ));
      }
    }

    // ── Step 7: Seed Junior School classes ────────────────────────────────────
    final jsClasses = classes.where((c) => AppConstants.gradeBand(c.grade) == 'Junior School').toList();
    for (var c in jsClasses) {
      int totalPeriods = 0;
      for (var s in jsSubjects) {
        int pPerWeek = (s.name.contains('English') || s.name.contains('Math') || s.name.contains('Integrated')) ? 5 : 4;
        if (totalPeriods + pPerWeek > 35) pPerWeek = 35 - totalPeriods;
        if (pPerWeek <= 0) continue;
        totalPeriods += pPerWeek;

        // 5 teachers per subject from round-robin
        final pool = pickTeachers(5);
        for (int k = 0; k < pool.length; k++) {
          await db.timetableDao.insertTeacherCapability(TeacherSubjectCapability(
            id: 'CAP_JS_P${k + 1}_${pool[k].id}_${s.id}_${c.id}',
            teacherId: pool[k].id,
            subjectId: s.id,
            priorityLevel: k + 1,
          ));
        }

        await db.timetableDao.insertClassRequirement(ClassSubjectRequirement(
          id: 'REQ_${c.id}_${s.id}',
          classId: c.id,
          subjectId: s.id,
          periodsPerWeek: pPerWeek,
        ));
      }
    }
  }
}
