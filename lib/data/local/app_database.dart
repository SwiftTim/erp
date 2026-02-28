// lib/data/local/app_database.dart

import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

// Models
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/curriculum_models.dart';
import '../models/assessment_model.dart';
import '../models/finance_model.dart';
import '../models/attendance_model.dart';
import '../models/medical_model.dart';
import '../models/discipline_model.dart';
import '../models/catering_model.dart';
import '../models/pathway_model.dart';
import '../models/security_model.dart';
import '../models/counseling_model.dart';
import '../models/enterprise_models.dart';
import '../models/timetable_models.dart';
import '../models/department_model.dart';

// DAOs
import 'daos/user_dao.dart';
import 'daos/student_dao.dart';
import 'daos/medical_dao.dart';
import 'daos/discipline_dao.dart';
import 'daos/catering_dao.dart';
import 'daos/pathway_dao.dart';
import 'daos/security_dao.dart';
import 'daos/counseling_dao.dart';
import 'daos/assessment_dao.dart';
import 'daos/finance_dao.dart';
import 'daos/attendance_dao.dart';
import 'daos/curriculum_dao.dart';
import 'daos/enterprise_dao.dart';
import 'daos/timetable_dao.dart';
import 'daos/messaging_dao.dart';
import 'daos/department_dao.dart';

part 'app_database.g.dart';

final migration1to2 = Migration(1, 2, (database) async {
  await database.execute('ALTER TABLE users ADD COLUMN role_flags TEXT');
});

final migration2to3 = Migration(2, 3, (database) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `school_classes` (
      `id` TEXT NOT NULL, 
      `name` TEXT NOT NULL, 
      `grade` TEXT NOT NULL, 
      `teacher_id` TEXT, 
      `academic_year` TEXT NOT NULL, 
      PRIMARY KEY (`id`)
    )
  ''');
});

final migration3to4 = Migration(3, 4, (database) async {
  await database.execute('ALTER TABLE learning_areas ADD COLUMN department_id TEXT');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `departments` (
      `id` TEXT NOT NULL, 
      `name` TEXT NOT NULL, 
      `description` TEXT NOT NULL, 
      `created_by` TEXT NOT NULL, 
      `created_at` INTEGER NOT NULL, 
      `status` TEXT NOT NULL, 
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `department_members` (
      `id` INTEGER PRIMARY KEY AUTOINCREMENT, 
      `department_id` TEXT NOT NULL, 
      `teacher_id` TEXT NOT NULL, 
      `role` TEXT NOT NULL, 
      `assigned_at` INTEGER NOT NULL,
      FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `subject_term_approvals` (
      `id` TEXT NOT NULL, 
      `class_id` TEXT NOT NULL, 
      `subject_id` TEXT NOT NULL, 
      `term` INTEGER NOT NULL, 
      `year` TEXT NOT NULL, 
      `status` TEXT NOT NULL, 
      `teacher_id` TEXT NOT NULL, 
      `last_updated` INTEGER NOT NULL, 
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `approval_logs` (
      `id` INTEGER PRIMARY KEY AUTOINCREMENT, 
      `entity_type` TEXT NOT NULL, 
      `entity_id` TEXT NOT NULL, 
      `action` TEXT NOT NULL, 
      `performed_by` TEXT NOT NULL, 
      `comments` TEXT, 
      `timestamp` INTEGER NOT NULL
    )
  ''');
});

@Database(version: 4, entities: [
  UserModel,
  StudentModel,
  LearningAreaModel,
  StrandModel,
  SubStrandModel,
  SchoolClassModel,
  AssessmentModel,
  CoreCompetencyModel,
  EvidenceItemModel,
  FeeStructureModel,
  FeeTransactionModel,
  ExpenditureModel,
  AttendanceModel,
  MessageModel,
  MedicalRecordModel,
  ClinicVisitModel,
  DisciplineRecordModel,
  MealPlanModel,
  PathwayRecommendationModel,
  VisitorLogModel,
  CounselingLogModel,
  StrandCoverage,
  // Timetable
  TeacherTimetableProfile,
  TeacherSubjectCapability,
  ClassSubjectRequirement,
  TimetableModel,
  TimetableSlot,
  LessonExecutionModel,
  AttendanceSessionModel,
  TeacherClub,
  // Enterprise
  InventoryAsset,
  AssetMaintenanceLog,
  OfficialMemo,
  MemoReadRecord,
  Substitution,
  SystemLog,
  ClubModel,
  ClubMembership,
  StaffLeave,
  StaffAttendance,
  TeachingAssignment,
  DepartmentModel,
  DepartmentMemberModel,
  SubjectTermApprovalModel,
  ApprovalLogModel,
])
abstract class AppDatabase extends FloorDatabase {
  UserDao get userDao;
  StudentDao get studentDao;
  AssessmentDao get assessmentDao;
  FinanceDao get financeDao;
  AttendanceDao get attendanceDao;
  CurriculumDao get curriculumDao;
  MedicalDao get medicalDao;
  DisciplineDao get disciplineDao;
  CateringDao get cateringDao;
  PathwayDao get pathwayDao;
  SecurityDao get securityDao;
  CounselingDao get counselingDao;
  EnterpriseDao get enterpriseDao;
  TimetableDao get timetableDao;
  MessagingDao get messagingDao;
  DepartmentDao get departmentDao;

  static Future<AppDatabase> create() async {
    return await $FloorAppDatabase
        .databaseBuilder('cbc_school.db')
        .addMigrations([migration1to2, migration2to3, migration3to4])
        .build();
  }
}
