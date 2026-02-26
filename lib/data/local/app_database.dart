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

@Database(version: 3, entities: [
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

  static Future<AppDatabase> create() async {
    return await $FloorAppDatabase
        .databaseBuilder('cbc_school.db')
        .addMigrations([migration1to2, migration2to3])
        .build();
  }
}
