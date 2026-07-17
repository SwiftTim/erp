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
import '../data/models/department_model.dart';

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

    // 7. Seed Departments
    await _seedDepartments(db, teachers);

    // 8. Seed Operational Staff accounts
    await _seedOperationalStaff(db);
  }

  /// Seeds one login account per operational role for testing purposes.
  /// All accounts share the password: admin123
  Future<void> _seedOperationalStaff(dynamic db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final bytes = utf8.encode('admin123' + 'cbc_salt_2026');
    final hash = sha256.convert(bytes).toString();

    final operationalUsers = [
      UserModel(id: 'OPS_FLEET',       name: 'Fleet Manager',      email: 'fleet@school.com',        passwordHash: hash, roleLevel: AppConstants.roleFleetManager,   isActive: 1, createdAt: now),
      UserModel(id: 'OPS_SECURITY',    name: 'Security Officer',   email: 'security@school.com',     passwordHash: hash, roleLevel: AppConstants.roleSecurity,       isActive: 1, createdAt: now),
      UserModel(id: 'OPS_NURSE',       name: 'School Nurse',       email: 'nurse@school.com',        passwordHash: hash, roleLevel: AppConstants.roleNurse,          isActive: 1, createdAt: now),
      UserModel(id: 'OPS_CATERING',    name: 'Cateress',           email: 'catering@school.com',     passwordHash: hash, roleLevel: AppConstants.roleCatering,       isActive: 1, createdAt: now),
      UserModel(id: 'OPS_BOARDING',    name: 'Boarding Master',    email: 'boarding@school.com',     passwordHash: hash, roleLevel: AppConstants.roleBoardingMaster,  isActive: 1, createdAt: now),
      UserModel(id: 'OPS_RECEPTION',   name: 'Receptionist',       email: 'reception@school.com',    passwordHash: hash, roleLevel: AppConstants.roleReceptionist,   isActive: 1, createdAt: now),
      UserModel(id: 'OPS_LIBRARIAN',   name: 'Librarian',          email: 'library@school.com',      passwordHash: hash, roleLevel: AppConstants.roleLibrarian,      isActive: 1, createdAt: now),
      UserModel(id: 'OPS_STORE',       name: 'Store Keeper',       email: 'store@school.com',        passwordHash: hash, roleLevel: AppConstants.roleStoreKeeper,    isActive: 1, createdAt: now),
      UserModel(id: 'OPS_HR',          name: 'HR Officer',         email: 'hr@school.com',           passwordHash: hash, roleLevel: AppConstants.roleHR,             isActive: 1, createdAt: now),
      UserModel(id: 'OPS_ACCOUNTANT',  name: 'School Bursar',      email: 'bursar@school.com',       passwordHash: hash, roleLevel: AppConstants.roleAccountant,     isActive: 1, createdAt: now),
      UserModel(id: 'OPS_ADMISSIONS',  name: 'Admissions Officer', email: 'admissions@school.com',   passwordHash: hash, roleLevel: AppConstants.roleAdmissions,     isActive: 1, createdAt: now),
      UserModel(id: 'OPS_DIRECTOR',    name: 'School Director',    email: 'director@school.com',     passwordHash: hash, roleLevel: AppConstants.roleDirector,      isActive: 1, createdAt: now),
      UserModel(id: 'OPS_HEAD',        name: 'Head Teacher',       email: 'headteacher@school.com',  passwordHash: hash, roleLevel: AppConstants.roleHeadteacher,   isActive: 1, createdAt: now),
    ];

    for (final user in operationalUsers) {
      final existing = await db.userDao.findById(user.id);
      if (existing == null) {
        await db.userDao.insertUser(user);
      }
    }
  }

  Future<void> _seedSubjects(dynamic db) async {
    // 1. Clean up old test-only subjects that were breaking strand population
    await db.curriculumDao.clearTestSubjects();
    
    // We fetch the already-seeded subjects from curriculum_seed.dart
    // This ensures strands and sub-strands are correctly linked.
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

    // 17 Regular Teachers (Worst Case Test Scenario: 18 Total Staff)
    final names = [
      'James Kamau', 'Mercy Achieng', 'Robert Otieno', 'Alice Mutua', 'David Kipkorir',
      'Fatuma Hassan', 'Kevin Odhiambo', 'Grace Maina', 'Peter Kariuki', 'Lydia Ochieng',
      'Samuel Ngugi', 'Phyllis Waweru', 'Isaac Kibet', 'Catherine Njeri', 'Paul Musyoka',
      'Beatrice Kwamboka', 'Simon Moraa'
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
      final existing = await db.userDao.findById(t.id);
      if (existing == null) {
        await db.userDao.insertUser(t);
      }
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
      final existing = await db.curriculumDao.findClassById(c.id);
      if (existing == null) {
        await db.curriculumDao.insertClass(c);
      }
    }
    return classes;
  }

  Future<void> _seedStudents(dynamic db, List<SchoolClassModel> classes) async {
    final firstNames = ['Otieno', 'Kamau', 'Mwangi', 'Juma', 'Mutua', 'Kipkorir', 'Hassan', 'Odhiambo', 'Maina', 'Kariuki', 'Ochieng', 'Ngugi', 'Waweru', 'Kibet', 'Achieng', 'Njeri', 'Wanjiru', 'Akinyi', 'Atieno', 'Fatuma', 'Amina', 'Musyoka', 'Wambui', 'Kwamboka', 'Moraa', 'Chepkirui'];
    final lastNames = ['Omondi', 'Njoroge', 'Githinji', 'Ali', 'Kilonzo', 'Cheruiyot', 'Mohammed', 'Okoth', 'Karanja', 'Mungai', 'Anyango', 'Wambua', 'Rotich', 'Nyambane', 'Khadija', 'Mboya'];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var c in classes) {
      final studentCount = await db.studentDao.countByClass(c.id);
      if (studentCount != null && studentCount >= 20) continue; 

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
    final ppSubjects  = subjects.where((s) => s.gradeBand == 'PP1-PP2').toList();
    final lpSubjects  = subjects.where((s) => s.gradeBand == 'Grade 1-3').toList();
    final upSubjects  = subjects.where((s) => s.gradeBand == 'Grade 4-6').toList();
    final jsSubjects  = subjects.where((s) => s.gradeBand == 'Grade 7-9').toList();

    // ── Step 3: Fair Round-Robin Specialist Pool ──────────────────────────────
    // We split the 39 teachers into pools so every teacher qualifies for something.
    // Lower Primary: all 39 teachers rotate as potential class/assistant teachers
    // Upper & Junior Primary: all 39 teachers rotate as subject specialists

    // Round-robin counter so assignments spread evenly across ALL 17 teachers
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
    final ppClasses = classes.where((c) => AppConstants.gradeBand(c.grade) == 'PP1-PP2').toList();
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

        // P2-P3: 2 additional teachers from round-robin pool (Reduced for 18-teacher case)
        final pool = pickTeachers(2);
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
    final lpClasses = classes.where((c) => AppConstants.gradeBand(c.grade) == 'Grade 1-3').toList();
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

        // P2-P3: round-robin pool (2 more teachers)
        final pool = pickTeachers(2);
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
    final upClasses = classes.where((c) => AppConstants.gradeBand(c.grade) == 'Grade 4-6').toList();
    for (var c in upClasses) {
      int totalPeriods = 0;
      for (var s in upSubjects) {
        int pPerWeek = (s.name.contains('English') || s.name.contains('Math')) ? 5 : 4;
        if (totalPeriods + pPerWeek > 35) pPerWeek = 35 - totalPeriods;
        if (pPerWeek <= 0) continue;
        totalPeriods += pPerWeek;

        // 3 teachers per subject (Reduced for 18-teacher case)
        final pool = pickTeachers(3);
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
    final jsClasses = classes.where((c) => AppConstants.gradeBand(c.grade) == 'Grade 7-9').toList();
    for (var c in jsClasses) {
      int totalPeriods = 0;
      for (var s in jsSubjects) {
        int pPerWeek = (s.name.contains('English') || s.name.contains('Math') || s.name.contains('Integrated')) ? 5 : 4;
        if (totalPeriods + pPerWeek > 35) pPerWeek = 35 - totalPeriods;
        if (pPerWeek <= 0) continue;
        totalPeriods += pPerWeek;

        // 3 teachers per subject (Reduced for 18-teacher case)
        final pool = pickTeachers(3);
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

  Future<void> _seedDepartments(dynamic db, List<UserModel> teachers) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final academicDepts = [
      {'id': 'DEPT_LANGUAGES', 'name': 'Languages Department'},
      {'id': 'DEPT_MATHEMATICS', 'name': 'Mathematics Department'},
      {'id': 'DEPT_SCIENCE', 'name': 'Science & Technology Department'},
      {'id': 'DEPT_HUMANITIES', 'name': 'Humanities / Social Studies Department'},
      {'id': 'DEPT_CREATIVE_ARTS', 'name': 'Creative Arts Department'},
      {'id': 'DEPT_TECHNICAL', 'name': 'Technical & Applied Sciences Department'},
      {'id': 'DEPT_RELIGIOUS', 'name': 'Religious Education Department'},
    ];

    final adminDepts = [
      {'id': 'DEPT_EXAMS', 'name': 'Examinations Department'},
      {'id': 'DEPT_GUIDANCE', 'name': 'Guidance & Counseling'},
      {'id': 'DEPT_ICT', 'name': 'ICT Department'},
      {'id': 'DEPT_DISCIPLINE', 'name': 'Discipline Department'},
      {'id': 'DEPT_COCURRICULAR', 'name': 'Co-Curricular Department'},
      {'id': 'DEPT_SNE', 'name': 'Special Needs Education'},
    ];

    final allDepts = [...academicDepts, ...adminDepts];

    for (var d in allDepts) {
      final existing = await db.departmentDao.getDepartmentById(d['id']!);
      if (existing == null) {
        await db.departmentDao.insertDepartment(DepartmentModel(
          id: d['id']!,
          name: d['name']!,
          description: 'Standard school department for ${d['name']}',
          createdBy: 'SYS_ADMIN',
          createdAt: now,
        ));
      }
    }

    // Assign HODs (Round-robin from teachers)
    for (int i = 0; i < allDepts.length; i++) {
      final teacher = teachers[i % teachers.length];
      await db.departmentDao.insertMember(DepartmentMemberModel(
        departmentId: allDepts[i]['id']!,
        teacherId: teacher.id,
        role: 'hod',
        assignedAt: now,
      ));
    }

    // Assign others as members
    for (var teacher in teachers) {
      final deptIndex = teachers.indexOf(teacher) % academicDepts.length;
      await db.departmentDao.insertMember(DepartmentMemberModel(
        departmentId: academicDepts[deptIndex]['id']!,
        teacherId: teacher.id,
        role: 'member',
        assignedAt: now,
      ));
    }

    // Link subjects to departments
    final subjects = await db.curriculumDao.findAllLearningAreas();
    for (var s in subjects) {
      String? deptId;
      final name = s.name.toLowerCase();
      if (name.contains('language') || name.contains('english') || name.contains('literacy') || name.contains('kiswahili')) {
        deptId = 'DEPT_LANGUAGES';
      } else if (name.contains('math')) {
        deptId = 'DEPT_MATHEMATICS';
      } else if (name.contains('science') || name.contains('environmental') || name.contains('hygiene') || name.contains('integrated')) {
        deptId = 'DEPT_SCIENCE';
      } else if (name.contains('social')) {
        deptId = 'DEPT_HUMANITIES';
      } else if (name.contains('creative') || name.contains('art')) {
        deptId = 'DEPT_CREATIVE_ARTS';
      } else if (name.contains('ict')) {
        deptId = 'DEPT_ICT';
      } else if (name.contains('technical')) {
        deptId = 'DEPT_TECHNICAL';
      } else if (name.contains('religious')) {
        deptId = 'DEPT_RELIGIOUS';
      }

      if (deptId != null) {
        await db.curriculumDao.insertArea(LearningAreaModel(
          id: s.id,
          name: s.name,
          gradeBand: s.gradeBand,
          category: s.category,
          departmentId: deptId,
        ));
      }
    }
  }
}
