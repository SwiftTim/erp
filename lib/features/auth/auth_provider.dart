// lib/features/auth/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../data/models/user_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/assessment_model.dart';
import '../../data/local/app_database.dart';
import '../../core/data/curriculum_seed.dart';
import '../../data/models/medical_model.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/curriculum_models.dart';
import '../../data/models/finance_model.dart';
import '../../core/data/finance_erp_seed.dart';
import 'package:uuid/uuid.dart';

// ── Database Provider ─────────────────────────────────────────────────────────
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await AppDatabase.create();

  // 1. Seed Curriculum
  await seedCurriculum(db);

  // 2. Seed Default Accounts if empty
  final userCount = await db.userDao.countAll();
  if (userCount == 0) {
    const uuid = Uuid();
    final bytes = utf8.encode('admin123' 'cbc_salt_2026');
    final hash = sha256.convert(bytes).toString();

    // ── ROLE-BASED TEST ACCOUNTS ──────────────────────────────────────────────
    final rolesToSeed = [
      {'email': 'director@cbc.ke', 'name': 'Director Maina', 'role': AppConstants.roleDirector},
      {'email': 'admin@cbc.ke', 'name': 'Headteacher Sarah', 'role': AppConstants.roleHeadteacher},
      {'email': 'deputy@cbc.ke', 'name': 'Deputy Mwangi', 'role': AppConstants.roleDeputy},
      {
        'email': 'senior@cbc.ke', 
        'name': 'Senior Teacher Rose', 
        'role': AppConstants.roleSeniorTeacher, 
        'dept': 'Mathematics',
        'flags': '["HOD"]'
      },
      {'email': 'teacher@cbc.ke', 'name': 'Teacher Otieno', 'role': AppConstants.roleTeacher, 'dept': 'Mathematics'},
      {'email': 'bursar@cbc.ke', 'name': 'Accountant Jane', 'role': AppConstants.roleAccountant},
      {'email': 'admissions@cbc.ke', 'name': 'Registrar Peter', 'role': AppConstants.roleAdmissions},
      {'email': 'nurse@cbc.ke', 'name': 'Nurse Alice', 'role': AppConstants.roleNurse},
      {'email': 'catering@cbc.ke', 'name': 'Chef John', 'role': AppConstants.roleCatering},
      {'email': 'security@cbc.ke', 'name': 'Officer Juma', 'role': AppConstants.roleSecurity},
      {'email': 'parent@cbc.ke', 'name': 'Mr. Kamau (Parent)', 'role': AppConstants.roleParent},
    ];

    for (final r in rolesToSeed) {
      final existing = await db.userDao.findByEmail(r['email'] as String);
      if (existing == null) {
        await db.userDao.insertUser(UserModel(
          id: uuid.v4(),
          name: r['name'] as String,
          email: r['email'] as String,
          passwordHash: hash,
          roleLevel: r['role'] as int,
          roleFlags: r['flags'] as String?,
          departmentId: r['dept'] as String?,
          isActive: 1,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    }

    // ── SAMPLE CONTENT SEEDING ────────────────────────────────────────────────
    
    // Seed Student 1 & Link to Parent
    final student1Id = uuid.v4();
    await db.studentDao.insertStudent(StudentModel(
      id: student1Id,
      upi: 'ABC123456',
      fullName: 'Johnstone Kamau',
      gender: 'Male',
      dob: '2016-05-12',
      grade: 'Grade 4',
      classId: 'G4-A',
      parentId: 'parent@cbc.ke',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    // Seed Medical Record for Student 1
    await db.medicalDao.insertRecord(MedicalRecordModel(
      studentId: student1Id,
      allergies: '["Peanuts", "Dust"]',
      chronicConditions: 'Mild Asthma',
      bloodGroup: 'O+',
    ));

    // Seed Finance Data
    await db.financeDao.insertFeeStructure(FeeStructureModel(
      id: uuid.v4(),
      grade: 'Grade 4',
      term: 1,
      academicYear: '2026',
      amount: 15000,
      description: 'Term 1 Fees',
      createdBy: 'system-seed',
    ));

    await db.financeDao.insertTransaction(FeeTransactionModel(
      id: uuid.v4(),
      studentId: student1Id,
      amountPaid: 8500,
      paymentMode: 'M-Pesa',
      referenceNo: 'RAY829JK2S',
      transactionDate: DateTime.now().millisecondsSinceEpoch,
      recordedBy: 'bursar-seed',
    ));

    // More Students for Analytics
    final stG6Id = uuid.v4();
    await db.studentDao.insertStudent(StudentModel(
      id: stG6Id,
      upi: 'G6-777',
      fullName: 'Mercy Aoko',
      gender: 'Female',
      dob: '2014-03-30',
      grade: 'Grade 6',
      classId: 'G6-B',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    await db.assessmentDao.insertAssessment(AssessmentModel(
      id: uuid.v4(),
      studentId: stG6Id,
      subStrandId: 'MATH-001',
      teacherId: 'teacher@cbc.ke',
      score: 4, // EE
      assessmentType: 'Diagnostic',
      term: 1,
      academicYear: '2026',
      dateRecorded: DateTime.now().millisecondsSinceEpoch,
    ));

    // ── SEED ERP FINANCE ──
    await seedFinanceErp(db);
  }

  // 3. Ensure Classes are seeded for Timetable Engine
  final classCount = (await db.curriculumDao.findAllClasses()).length;
  if (classCount == 0) {
    print('🏫 Seeding default classes...');
    final classesToSeed = [
      {'id': 'pp1-red', 'name': 'PP1 Red', 'grade': 'PP1'},
      {'id': 'g1-blue', 'name': 'Grade 1 Blue', 'grade': 'Grade 1'},
      {'id': 'g4-alpha', 'name': 'Grade 4 Alpha', 'grade': 'Grade 4'},
      {'id': 'g7-west', 'name': 'Grade 7 West', 'grade': 'Grade 7'},
    ];

    for (final c in classesToSeed) {
      await db.curriculumDao.insertClass(SchoolClassModel(
        id: c['id'] as String,
        name: c['name'] as String,
        grade: c['grade'] as String,
        academicYear: '2026',
      ));
    }
  }

  return db;
});

// ── Auth State ─────────────────────────────────────────────────────────
final authStateProvider = StateProvider<UserModel?>((ref) => null);

// ── Current User Shortcut ─────────────────────────────────────────────────────
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider);
});

// ── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async => null;

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final db = await ref.read(databaseProvider.future);
      final user = await db.userDao.findByEmail(email.trim().toLowerCase());
      if (user == null || user.isActive == 0) {
        state = const AsyncData(null);
        return false;
      }
      final hash = _hashPassword(password);
      if (hash != user.passwordHash) {
        state = const AsyncData(null);
        return false;
      }
      state = AsyncData(user);
      ref.read(authStateProvider.notifier).state = user;
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<UserModel?> register(UserModel user) async {
    final db = await ref.read(databaseProvider.future);
    await db.userDao.insertUser(user);
    return user;
  }

  void logout() {
    state = const AsyncData(null);
    ref.read(authStateProvider.notifier).state = null;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'cbc_salt_2026');
    return sha256.convert(bytes).toString();
  }

  String hashPassword(String password) => _hashPassword(password);
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);
