// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  UserDao? _userDaoInstance;

  StudentDao? _studentDaoInstance;

  AssessmentDao? _assessmentDaoInstance;

  FinanceDao? _financeDaoInstance;

  AttendanceDao? _attendanceDaoInstance;

  CurriculumDao? _curriculumDaoInstance;

  MedicalDao? _medicalDaoInstance;

  DisciplineDao? _disciplineDaoInstance;

  CateringDao? _cateringDaoInstance;

  PathwayDao? _pathwayDaoInstance;

  SecurityDao? _securityDaoInstance;

  CounselingDao? _counselingDaoInstance;

  EnterpriseDao? _enterpriseDaoInstance;

  TimetableDao? _timetableDaoInstance;

  MessagingDao? _messagingDaoInstance;

  ChatDao? _chatDaoInstance;

  CalendarDao? _calendarDaoInstance;

  NotificationDao? _notificationDaoInstance;

  DepartmentDao? _departmentDaoInstance;

  DeptActivityDao? _deptActivityDaoInstance;

  ClubDao? _clubDaoInstance;

  TodDao? _todDaoInstance;

  FinanceErpDao? _financeErpDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 16,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `users` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `email` TEXT NOT NULL, `password_hash` TEXT NOT NULL, `role_level` INTEGER NOT NULL, `role_flags` TEXT, `assigned_class_id` TEXT, `department_id` TEXT, `is_active` INTEGER NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `students` (`id` TEXT NOT NULL, `upi` TEXT NOT NULL, `full_name` TEXT NOT NULL, `gender` TEXT NOT NULL, `dob` TEXT NOT NULL, `grade` TEXT NOT NULL, `class_id` TEXT NOT NULL, `parent_id` TEXT, `photo_url` TEXT, `created_at` INTEGER NOT NULL, `synced` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `learning_areas` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `grade_band` TEXT NOT NULL, `category` TEXT NOT NULL, `department_id` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `strands` (`id` TEXT NOT NULL, `learning_area_id` TEXT NOT NULL, `strand_name` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `sub_strands` (`id` TEXT NOT NULL, `strand_id` TEXT NOT NULL, `sub_strand_name` TEXT NOT NULL, `assessment_rubric` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `school_classes` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `grade` TEXT NOT NULL, `teacher_id` TEXT, `academic_year` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `assessments` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `sub_strand_id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `score` INTEGER NOT NULL, `teacher_remarks` TEXT, `evidence_path` TEXT, `term` INTEGER NOT NULL, `academic_year` TEXT NOT NULL, `date_recorded` INTEGER NOT NULL, `is_moderated` INTEGER NOT NULL, `moderated_by` TEXT, `assessment_type` TEXT NOT NULL, `synced` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `core_competencies` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `competency` TEXT NOT NULL, `score` INTEGER NOT NULL, `term` INTEGER NOT NULL, `academic_year` TEXT NOT NULL, `remarks` TEXT, `synced` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `evidence_items` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `assessment_id` TEXT, `sub_strand_id` TEXT, `local_path` TEXT NOT NULL, `cloud_url` TEXT, `caption` TEXT, `media_type` TEXT NOT NULL, `taken_at` INTEGER NOT NULL, `uploaded` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `fee_structures` (`id` TEXT NOT NULL, `grade` TEXT NOT NULL, `term` INTEGER NOT NULL, `academic_year` TEXT NOT NULL, `amount` REAL NOT NULL, `description` TEXT, `created_by` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `fee_transactions` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `amount_paid` REAL NOT NULL, `payment_mode` TEXT NOT NULL, `reference_no` TEXT NOT NULL, `balance_before` REAL, `balance_after` REAL, `recorded_by` TEXT NOT NULL, `transaction_date` INTEGER NOT NULL, `receipt_url` TEXT, `synced` INTEGER NOT NULL, `is_voided` INTEGER NOT NULL, `voided_by` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `expenditures` (`id` TEXT NOT NULL, `category` TEXT NOT NULL, `amount` REAL NOT NULL, `description` TEXT NOT NULL, `recorded_by` TEXT NOT NULL, `expense_date` INTEGER NOT NULL, `synced` INTEGER NOT NULL, `is_voided` INTEGER NOT NULL, `voided_by` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `attendance` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `class_id` TEXT NOT NULL, `date` TEXT NOT NULL, `status` TEXT NOT NULL, `recorded_by` TEXT NOT NULL, `synced` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `messages` (`id` TEXT NOT NULL, `sender_id` TEXT NOT NULL, `recipient_id` TEXT, `message_type` TEXT NOT NULL, `subject` TEXT, `body` TEXT NOT NULL, `sent_at` INTEGER NOT NULL, `read_at` INTEGER, `synced` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `medical_records` (`student_id` TEXT NOT NULL, `allergies` TEXT, `chronic_conditions` TEXT, `blood_group` TEXT, `emergency_contacts` TEXT, PRIMARY KEY (`student_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `clinic_visits` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `symptoms` TEXT NOT NULL, `action_taken` TEXT NOT NULL, `medication_given` TEXT, `timestamp` INTEGER NOT NULL, `recorded_by` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `discipline_records` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `category` TEXT NOT NULL, `incident_description` TEXT NOT NULL, `action_taken` TEXT NOT NULL, `status` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `recorded_by` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `meal_plans` (`id` TEXT NOT NULL, `dayOfWeek` TEXT NOT NULL, `mealType` TEXT NOT NULL, `menu` TEXT NOT NULL, `academic_year` TEXT NOT NULL, `term` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `pathway_recommendations` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `recommendedPathway` TEXT NOT NULL, `performance_score` REAL NOT NULL, `rationale` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `visitor_logs` (`id` TEXT NOT NULL, `visitor_name` TEXT NOT NULL, `id_number` TEXT NOT NULL, `purpose` TEXT NOT NULL, `whom_to_see` TEXT NOT NULL, `check_in_time` INTEGER NOT NULL, `check_out_time` INTEGER, `vehicle_reg` TEXT, `recorded_by` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `counseling_logs` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `issue` TEXT NOT NULL, `summary` TEXT NOT NULL, `notes` TEXT NOT NULL, `follow_up_required` INTEGER NOT NULL, `timestamp` INTEGER NOT NULL, `counselor_id` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `strand_coverage` (`id` TEXT NOT NULL, `class_id` TEXT NOT NULL, `strand_id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `completion_date` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `teacher_timetable_profiles` (`id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `max_periods_per_day` INTEGER NOT NULL, `max_periods_per_week` INTEGER NOT NULL, `is_class_teacher` INTEGER NOT NULL, `special_role` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `teacher_subject_capabilities` (`id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `subject_id` TEXT NOT NULL, `priority_level` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `class_subject_requirements` (`id` TEXT NOT NULL, `class_id` TEXT NOT NULL, `subject_id` TEXT NOT NULL, `periods_per_week` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `timetables` (`id` TEXT NOT NULL, `academic_year` TEXT NOT NULL, `term` TEXT NOT NULL, `is_active` INTEGER NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `timetable_slots` (`id` TEXT NOT NULL, `timetable_id` TEXT NOT NULL, `day_of_week` INTEGER NOT NULL, `period_number` INTEGER NOT NULL, `class_id` TEXT NOT NULL, `subject_id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `teacher_id_2` TEXT, `is_locked` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `lesson_executions` (`id` TEXT NOT NULL, `slot_id` TEXT NOT NULL, `attendance_session_id` TEXT NOT NULL, `status` TEXT NOT NULL, `coverage_weight` REAL NOT NULL, `notes` TEXT, `evidence_paths` TEXT, `timestamp` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `attendance_sessions` (`id` TEXT NOT NULL, `slot_id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `class_id` TEXT NOT NULL, `subject_id` TEXT NOT NULL, `period` INTEGER NOT NULL, `date` TEXT NOT NULL, `is_substitute` INTEGER NOT NULL, `timestamp` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `inventory_assets` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `category` TEXT NOT NULL, `location` TEXT NOT NULL, `quantity` INTEGER NOT NULL, `condition` TEXT NOT NULL, `unit_cost` REAL, `purchase_date` INTEGER, `assigned_to` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `asset_maintenance_logs` (`id` TEXT NOT NULL, `asset_id` TEXT NOT NULL, `description` TEXT NOT NULL, `cost` REAL NOT NULL, `serviced_at` INTEGER NOT NULL, `recorded_by` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `official_memos` (`id` TEXT NOT NULL, `senderId` TEXT NOT NULL, `title` TEXT NOT NULL, `content` TEXT NOT NULL, `targetGroup` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `priority` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `memo_reads` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `memoId` TEXT NOT NULL, `userId` TEXT NOT NULL, `readAt` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `substitutions` (`id` TEXT NOT NULL, `original_teacher_id` TEXT NOT NULL, `substitute_teacher_id` TEXT NOT NULL, `class_id` TEXT NOT NULL, `subject_id` TEXT NOT NULL, `date` INTEGER NOT NULL, `period_number` INTEGER NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `system_activity_logs` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `userId` TEXT NOT NULL, `action` TEXT NOT NULL, `module` TEXT NOT NULL, `details` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `ipAddress` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `staff_leaves` (`id` TEXT NOT NULL, `staffId` TEXT NOT NULL, `leaveType` TEXT NOT NULL, `startDate` INTEGER NOT NULL, `endDate` INTEGER NOT NULL, `reason` TEXT NOT NULL, `status` TEXT NOT NULL, `approvedBy` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `staff_attendance` (`id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `date` INTEGER NOT NULL, `clock_in` INTEGER NOT NULL, `clock_out` INTEGER, `notes` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `teaching_assignments` (`id` TEXT NOT NULL, `teacherId` TEXT NOT NULL, `classId` TEXT NOT NULL, `subjectId` TEXT NOT NULL, `academicYear` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `clubs` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `category` TEXT NOT NULL, `description` TEXT NOT NULL, `patron_id` TEXT, `assistant_patron_id` TEXT, `meeting_day` TEXT, `meeting_time` TEXT, `status` TEXT NOT NULL, `capacity_limit` INTEGER NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `club_members` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `club_id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `role` TEXT NOT NULL, `joined_at` INTEGER NOT NULL, `joined_by` TEXT NOT NULL, `consent_form_signed` INTEGER NOT NULL, `parent_contact_verified` INTEGER NOT NULL, FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `club_activities` (`id` TEXT NOT NULL, `club_id` TEXT NOT NULL, `title` TEXT NOT NULL, `description` TEXT NOT NULL, `type` TEXT NOT NULL, `scheduled_at` INTEGER NOT NULL, `venue` TEXT NOT NULL, `status` TEXT NOT NULL, `recorded_at` INTEGER NOT NULL, FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `club_attendance` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `activity_id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `status` TEXT NOT NULL, `remarks` TEXT, FOREIGN KEY (`activity_id`) REFERENCES `club_activities` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `club_reports` (`id` TEXT NOT NULL, `club_id` TEXT NOT NULL, `term` INTEGER NOT NULL, `year` TEXT NOT NULL, `content` TEXT NOT NULL, `submitted_at` INTEGER NOT NULL, `patron_id` TEXT NOT NULL, `status` TEXT NOT NULL, FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `departments` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `description` TEXT NOT NULL, `created_by` TEXT NOT NULL, `created_at` INTEGER NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `department_members` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `department_id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `role` TEXT NOT NULL, `assigned_at` INTEGER NOT NULL, FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `subject_term_approvals` (`id` TEXT NOT NULL, `class_id` TEXT NOT NULL, `subject_id` TEXT NOT NULL, `term` INTEGER NOT NULL, `year` TEXT NOT NULL, `status` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `last_updated` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `approval_logs` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `entity_type` TEXT NOT NULL, `entity_id` TEXT NOT NULL, `action` TEXT NOT NULL, `performed_by` TEXT NOT NULL, `comments` TEXT, `timestamp` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `dept_documents` (`id` TEXT NOT NULL, `department_id` TEXT NOT NULL, `title` TEXT NOT NULL, `category` TEXT NOT NULL, `file_path` TEXT, `file_name` TEXT NOT NULL, `description` TEXT, `uploaded_by` TEXT NOT NULL, `uploaded_at` INTEGER NOT NULL, `status` TEXT NOT NULL, FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `dept_meetings` (`id` TEXT NOT NULL, `department_id` TEXT NOT NULL, `title` TEXT NOT NULL, `agenda` TEXT NOT NULL, `scheduled_at` INTEGER NOT NULL, `venue` TEXT NOT NULL, `minutes` TEXT, `organized_by` TEXT NOT NULL, `status` TEXT NOT NULL, FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `dept_activities` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `department_id` TEXT NOT NULL, `module_type` TEXT NOT NULL, `title` TEXT NOT NULL, `data` TEXT, `recorded_by` TEXT NOT NULL, `recorded_at` INTEGER NOT NULL, `status` TEXT NOT NULL, `grade` TEXT, `subject` TEXT, FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `dept_compliance` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `department_id` TEXT NOT NULL, `item` TEXT NOT NULL, `is_done` INTEGER NOT NULL, `due_date` INTEGER, `completed_by` TEXT, `completed_at` INTEGER, `term` TEXT NOT NULL, `year` TEXT NOT NULL, FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `duty_roster` (`id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `week_number` INTEGER NOT NULL, `start_date` INTEGER NOT NULL, `end_date` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `tod_records` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `offence` TEXT NOT NULL, `punishment` TEXT NOT NULL, `remarks` TEXT, `teacher_id` TEXT NOT NULL, `date` INTEGER NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `student_behavior` (`student_id` TEXT NOT NULL, `weekly_offences` INTEGER NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`student_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `chat_messages` (`id` TEXT NOT NULL, `sender_id` TEXT NOT NULL, `receiver_id` TEXT, `group_id` TEXT, `message` TEXT NOT NULL, `file_path` TEXT, `file_name` TEXT, `file_type` TEXT, `reply_to_id` TEXT, `status` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `is_deleted` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `chat_groups` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `type` TEXT NOT NULL, `dept_id` TEXT, `created_by` TEXT NOT NULL, `created_at` INTEGER NOT NULL, `icon_code` INTEGER, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `chat_group_members` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `group_id` TEXT NOT NULL, `user_id` TEXT NOT NULL, `joined_at` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `chat_read_receipts` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `message_id` TEXT NOT NULL, `user_id` TEXT NOT NULL, `read_at` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `calendar_events` (`id` TEXT NOT NULL, `title` TEXT NOT NULL, `event_type` TEXT NOT NULL, `start_date` INTEGER NOT NULL, `end_date` INTEGER NOT NULL, `description` TEXT, `priority` TEXT NOT NULL, `created_by` TEXT NOT NULL, `created_at` INTEGER NOT NULL, `reminder_days` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `app_notifications` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `user_id` TEXT NOT NULL, `title` TEXT NOT NULL, `message` TEXT NOT NULL, `link` TEXT, `notif_type` TEXT NOT NULL, `reference_id` TEXT, `is_read` INTEGER NOT NULL, `created_at` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `staff` (`staff_id` TEXT NOT NULL, `name` TEXT NOT NULL, `role` TEXT NOT NULL, `department` TEXT NOT NULL, `employment_type` TEXT NOT NULL, `bank_name` TEXT NOT NULL, `account_no` TEXT NOT NULL, `bank_branch` TEXT NOT NULL, `date_hired` INTEGER NOT NULL, PRIMARY KEY (`staff_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `fee_structure` (`fee_id` TEXT NOT NULL, `fee_name` TEXT NOT NULL, `amount` REAL NOT NULL, `term` INTEGER NOT NULL, `is_optional` INTEGER NOT NULL, PRIMARY KEY (`fee_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `student_billing` (`billing_id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `term` INTEGER NOT NULL, `tuition` REAL NOT NULL, `transport` REAL NOT NULL, `meals` REAL NOT NULL, `swimming` REAL NOT NULL, `other_charges` REAL NOT NULL, `total_amount` REAL NOT NULL, `balance` REAL NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`billing_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `fee_payments` (`payment_id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `amount_paid` REAL NOT NULL, `payment_method` TEXT NOT NULL, `transaction_code` TEXT NOT NULL, `date_paid` INTEGER NOT NULL, `received_by` TEXT NOT NULL, PRIMARY KEY (`payment_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `amenities` (`amenity_id` TEXT NOT NULL, `amenity_name` TEXT NOT NULL, `fee_amount` REAL NOT NULL, `billing_type` TEXT NOT NULL, PRIMARY KEY (`amenity_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `student_amenities` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `amenity_id` TEXT NOT NULL, `term` INTEGER NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `payroll` (`payroll_id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `month` TEXT NOT NULL, `basic_salary` REAL NOT NULL, `allowances` REAL NOT NULL, `deductions` REAL NOT NULL, `nssf` REAL NOT NULL, `shif` REAL NOT NULL, `housing_levy` REAL NOT NULL, `paye` REAL NOT NULL, `loan_deduction` REAL NOT NULL, `net_salary` REAL NOT NULL, `status` TEXT NOT NULL, `processed_by` TEXT NOT NULL, `date_processed` INTEGER NOT NULL, PRIMARY KEY (`payroll_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `staff_loans` (`loan_id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `loan_amount` REAL NOT NULL, `interest_rate` REAL NOT NULL, `repayment_period` INTEGER NOT NULL, `monthly_deduction` REAL NOT NULL, `total_repayment` REAL NOT NULL, `remaining_balance` REAL NOT NULL, `status` TEXT NOT NULL, `approved_by` TEXT, `issue_date` INTEGER NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`loan_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `loan_repayments` (`repayment_id` TEXT NOT NULL, `loan_id` TEXT NOT NULL, `payroll_id` TEXT, `amount` REAL NOT NULL, `payment_date` INTEGER NOT NULL, `deducted_from_payroll` INTEGER NOT NULL, PRIMARY KEY (`repayment_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `expenses` (`expense_id` TEXT NOT NULL, `category` TEXT NOT NULL, `description` TEXT NOT NULL, `amount` REAL NOT NULL, `payment_method` TEXT NOT NULL, `date` INTEGER NOT NULL, `approved_by` TEXT NOT NULL, PRIMARY KEY (`expense_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `assets` (`asset_id` TEXT NOT NULL, `asset_name` TEXT NOT NULL, `category` TEXT NOT NULL, `purchase_date` INTEGER NOT NULL, `purchase_value` REAL NOT NULL, `condition` TEXT NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`asset_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `repairs` (`repair_id` TEXT NOT NULL, `asset_id` TEXT NOT NULL, `description` TEXT NOT NULL, `repair_cost` REAL NOT NULL, `repair_date` INTEGER NOT NULL, `technician` TEXT NOT NULL, PRIMARY KEY (`repair_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `resource_requests` (`request_id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `purpose` TEXT NOT NULL, `status` TEXT NOT NULL, `total_budget` REAL NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`request_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `resource_request_items` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `request_id` TEXT NOT NULL, `item_name` TEXT NOT NULL, `quantity` INTEGER NOT NULL, `price` REAL NOT NULL, `total` REAL NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `budget_approvals` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `request_id` TEXT NOT NULL, `approved_by` TEXT NOT NULL, `decision` TEXT NOT NULL, `comments` TEXT NOT NULL, `date` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `salary_components` (`component_id` TEXT NOT NULL, `name` TEXT NOT NULL, `type` TEXT NOT NULL, `description` TEXT, `is_statutory` INTEGER NOT NULL, `is_tax_applicable` INTEGER NOT NULL, `is_attendance_linked` INTEGER NOT NULL, `default_amount` REAL NOT NULL, PRIMARY KEY (`component_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `salary_structures` (`structure_id` TEXT NOT NULL, `name` TEXT NOT NULL, `company` TEXT NOT NULL, `is_active` INTEGER NOT NULL, `total_earnings` REAL NOT NULL, `total_deductions` REAL NOT NULL, PRIMARY KEY (`structure_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `salary_structure_assignments` (`assignment_id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `structure_id` TEXT NOT NULL, `from_date` INTEGER NOT NULL, `base_salary` REAL NOT NULL, PRIMARY KEY (`assignment_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `payroll_entries` (`payroll_entry_id` TEXT NOT NULL, `month` TEXT NOT NULL, `structure_id` TEXT NOT NULL, `status` TEXT NOT NULL, `posting_date` INTEGER NOT NULL, `count_processed` INTEGER NOT NULL, PRIMARY KEY (`payroll_entry_id`))');
        await database.execute(
            'CREATE UNIQUE INDEX `index_teacher_subject_capabilities_teacher_id_subject_id` ON `teacher_subject_capabilities` (`teacher_id`, `subject_id`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_class_subject_requirements_class_id_subject_id` ON `class_subject_requirements` (`class_id`, `subject_id`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_timetable_slots_timetable_id_day_of_week_period_number_class_id` ON `timetable_slots` (`timetable_id`, `day_of_week`, `period_number`, `class_id`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_timetable_slots_timetable_id_day_of_week_period_number_teacher_id` ON `timetable_slots` (`timetable_id`, `day_of_week`, `period_number`, `teacher_id`)');
        await database.execute(
            'CREATE INDEX `index_timetable_slots_timetable_id_day_of_week_period_number_teacher_id_2` ON `timetable_slots` (`timetable_id`, `day_of_week`, `period_number`, `teacher_id_2`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  UserDao get userDao {
    return _userDaoInstance ??= _$UserDao(database, changeListener);
  }

  @override
  StudentDao get studentDao {
    return _studentDaoInstance ??= _$StudentDao(database, changeListener);
  }

  @override
  AssessmentDao get assessmentDao {
    return _assessmentDaoInstance ??= _$AssessmentDao(database, changeListener);
  }

  @override
  FinanceDao get financeDao {
    return _financeDaoInstance ??= _$FinanceDao(database, changeListener);
  }

  @override
  AttendanceDao get attendanceDao {
    return _attendanceDaoInstance ??= _$AttendanceDao(database, changeListener);
  }

  @override
  CurriculumDao get curriculumDao {
    return _curriculumDaoInstance ??= _$CurriculumDao(database, changeListener);
  }

  @override
  MedicalDao get medicalDao {
    return _medicalDaoInstance ??= _$MedicalDao(database, changeListener);
  }

  @override
  DisciplineDao get disciplineDao {
    return _disciplineDaoInstance ??= _$DisciplineDao(database, changeListener);
  }

  @override
  CateringDao get cateringDao {
    return _cateringDaoInstance ??= _$CateringDao(database, changeListener);
  }

  @override
  PathwayDao get pathwayDao {
    return _pathwayDaoInstance ??= _$PathwayDao(database, changeListener);
  }

  @override
  SecurityDao get securityDao {
    return _securityDaoInstance ??= _$SecurityDao(database, changeListener);
  }

  @override
  CounselingDao get counselingDao {
    return _counselingDaoInstance ??= _$CounselingDao(database, changeListener);
  }

  @override
  EnterpriseDao get enterpriseDao {
    return _enterpriseDaoInstance ??= _$EnterpriseDao(database, changeListener);
  }

  @override
  TimetableDao get timetableDao {
    return _timetableDaoInstance ??= _$TimetableDao(database, changeListener);
  }

  @override
  MessagingDao get messagingDao {
    return _messagingDaoInstance ??= _$MessagingDao(database, changeListener);
  }

  @override
  ChatDao get chatDao {
    return _chatDaoInstance ??= _$ChatDao(database, changeListener);
  }

  @override
  CalendarDao get calendarDao {
    return _calendarDaoInstance ??= _$CalendarDao(database, changeListener);
  }

  @override
  NotificationDao get notificationDao {
    return _notificationDaoInstance ??=
        _$NotificationDao(database, changeListener);
  }

  @override
  DepartmentDao get departmentDao {
    return _departmentDaoInstance ??= _$DepartmentDao(database, changeListener);
  }

  @override
  DeptActivityDao get deptActivityDao {
    return _deptActivityDaoInstance ??=
        _$DeptActivityDao(database, changeListener);
  }

  @override
  ClubDao get clubDao {
    return _clubDaoInstance ??= _$ClubDao(database, changeListener);
  }

  @override
  TodDao get todDao {
    return _todDaoInstance ??= _$TodDao(database, changeListener);
  }

  @override
  FinanceErpDao get financeErpDao {
    return _financeErpDaoInstance ??= _$FinanceErpDao(database, changeListener);
  }
}

class _$UserDao extends UserDao {
  _$UserDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _userModelInsertionAdapter = InsertionAdapter(
            database,
            'users',
            (UserModel item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'email': item.email,
                  'password_hash': item.passwordHash,
                  'role_level': item.roleLevel,
                  'role_flags': item.roleFlags,
                  'assigned_class_id': item.assignedClassId,
                  'department_id': item.departmentId,
                  'is_active': item.isActive,
                  'created_at': item.createdAt
                }),
        _userModelUpdateAdapter = UpdateAdapter(
            database,
            'users',
            ['id'],
            (UserModel item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'email': item.email,
                  'password_hash': item.passwordHash,
                  'role_level': item.roleLevel,
                  'role_flags': item.roleFlags,
                  'assigned_class_id': item.assignedClassId,
                  'department_id': item.departmentId,
                  'is_active': item.isActive,
                  'created_at': item.createdAt
                }),
        _userModelDeletionAdapter = DeletionAdapter(
            database,
            'users',
            ['id'],
            (UserModel item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'email': item.email,
                  'password_hash': item.passwordHash,
                  'role_level': item.roleLevel,
                  'role_flags': item.roleFlags,
                  'assigned_class_id': item.assignedClassId,
                  'department_id': item.departmentId,
                  'is_active': item.isActive,
                  'created_at': item.createdAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<UserModel> _userModelInsertionAdapter;

  final UpdateAdapter<UserModel> _userModelUpdateAdapter;

  final DeletionAdapter<UserModel> _userModelDeletionAdapter;

  @override
  Future<UserModel?> findById(String id) async {
    return _queryAdapter.query('SELECT * FROM users WHERE id = ?1',
        mapper: (Map<String, Object?> row) => UserModel(
            id: row['id'] as String,
            name: row['name'] as String,
            email: row['email'] as String,
            passwordHash: row['password_hash'] as String,
            roleLevel: row['role_level'] as int,
            roleFlags: row['role_flags'] as String?,
            assignedClassId: row['assigned_class_id'] as String?,
            departmentId: row['department_id'] as String?,
            isActive: row['is_active'] as int,
            createdAt: row['created_at'] as int),
        arguments: [id]);
  }

  @override
  Future<UserModel?> findByEmail(String email) async {
    return _queryAdapter.query('SELECT * FROM users WHERE email = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => UserModel(
            id: row['id'] as String,
            name: row['name'] as String,
            email: row['email'] as String,
            passwordHash: row['password_hash'] as String,
            roleLevel: row['role_level'] as int,
            roleFlags: row['role_flags'] as String?,
            assignedClassId: row['assigned_class_id'] as String?,
            departmentId: row['department_id'] as String?,
            isActive: row['is_active'] as int,
            createdAt: row['created_at'] as int),
        arguments: [email]);
  }

  @override
  Future<List<UserModel>> findAllActive() async {
    return _queryAdapter.queryList(
        'SELECT * FROM users WHERE is_active = 1 ORDER BY role_level, name',
        mapper: (Map<String, Object?> row) => UserModel(
            id: row['id'] as String,
            name: row['name'] as String,
            email: row['email'] as String,
            passwordHash: row['password_hash'] as String,
            roleLevel: row['role_level'] as int,
            roleFlags: row['role_flags'] as String?,
            assignedClassId: row['assigned_class_id'] as String?,
            departmentId: row['department_id'] as String?,
            isActive: row['is_active'] as int,
            createdAt: row['created_at'] as int));
  }

  @override
  Future<List<UserModel>> findAll() async {
    return _queryAdapter.queryList('SELECT * FROM users',
        mapper: (Map<String, Object?> row) => UserModel(
            id: row['id'] as String,
            name: row['name'] as String,
            email: row['email'] as String,
            passwordHash: row['password_hash'] as String,
            roleLevel: row['role_level'] as int,
            roleFlags: row['role_flags'] as String?,
            assignedClassId: row['assigned_class_id'] as String?,
            departmentId: row['department_id'] as String?,
            isActive: row['is_active'] as int,
            createdAt: row['created_at'] as int));
  }

  @override
  Future<int?> countAll() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM users',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<List<UserModel>> findByRole(int roleLevel) async {
    return _queryAdapter.queryList(
        'SELECT * FROM users WHERE role_level = ?1 AND is_active = 1',
        mapper: (Map<String, Object?> row) => UserModel(
            id: row['id'] as String,
            name: row['name'] as String,
            email: row['email'] as String,
            passwordHash: row['password_hash'] as String,
            roleLevel: row['role_level'] as int,
            roleFlags: row['role_flags'] as String?,
            assignedClassId: row['assigned_class_id'] as String?,
            departmentId: row['department_id'] as String?,
            isActive: row['is_active'] as int,
            createdAt: row['created_at'] as int),
        arguments: [roleLevel]);
  }

  @override
  Future<void> setActive(
    String id,
    int active,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE users SET is_active = ?2 WHERE id = ?1',
        arguments: [id, active]);
  }

  @override
  Future<void> insertUser(UserModel user) async {
    await _userModelInsertionAdapter.insert(user, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _userModelUpdateAdapter.update(user, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteUser(UserModel user) async {
    await _userModelDeletionAdapter.delete(user);
  }
}

class _$StudentDao extends StudentDao {
  _$StudentDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _studentModelInsertionAdapter = InsertionAdapter(
            database,
            'students',
            (StudentModel item) => <String, Object?>{
                  'id': item.id,
                  'upi': item.upi,
                  'full_name': item.fullName,
                  'gender': item.gender,
                  'dob': item.dob,
                  'grade': item.grade,
                  'class_id': item.classId,
                  'parent_id': item.parentId,
                  'photo_url': item.photoUrl,
                  'created_at': item.createdAt,
                  'synced': item.synced
                }),
        _studentModelUpdateAdapter = UpdateAdapter(
            database,
            'students',
            ['id'],
            (StudentModel item) => <String, Object?>{
                  'id': item.id,
                  'upi': item.upi,
                  'full_name': item.fullName,
                  'gender': item.gender,
                  'dob': item.dob,
                  'grade': item.grade,
                  'class_id': item.classId,
                  'parent_id': item.parentId,
                  'photo_url': item.photoUrl,
                  'created_at': item.createdAt,
                  'synced': item.synced
                }),
        _studentModelDeletionAdapter = DeletionAdapter(
            database,
            'students',
            ['id'],
            (StudentModel item) => <String, Object?>{
                  'id': item.id,
                  'upi': item.upi,
                  'full_name': item.fullName,
                  'gender': item.gender,
                  'dob': item.dob,
                  'grade': item.grade,
                  'class_id': item.classId,
                  'parent_id': item.parentId,
                  'photo_url': item.photoUrl,
                  'created_at': item.createdAt,
                  'synced': item.synced
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<StudentModel> _studentModelInsertionAdapter;

  final UpdateAdapter<StudentModel> _studentModelUpdateAdapter;

  final DeletionAdapter<StudentModel> _studentModelDeletionAdapter;

  @override
  Future<StudentModel?> findById(String id) async {
    return _queryAdapter.query('SELECT * FROM students WHERE id = ?1',
        mapper: (Map<String, Object?> row) => StudentModel(
            id: row['id'] as String,
            upi: row['upi'] as String,
            fullName: row['full_name'] as String,
            gender: row['gender'] as String,
            dob: row['dob'] as String,
            grade: row['grade'] as String,
            classId: row['class_id'] as String,
            parentId: row['parent_id'] as String?,
            photoUrl: row['photo_url'] as String?,
            createdAt: row['created_at'] as int,
            synced: row['synced'] as int),
        arguments: [id]);
  }

  @override
  Future<StudentModel?> findByUpi(String upi) async {
    return _queryAdapter.query('SELECT * FROM students WHERE upi = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => StudentModel(
            id: row['id'] as String,
            upi: row['upi'] as String,
            fullName: row['full_name'] as String,
            gender: row['gender'] as String,
            dob: row['dob'] as String,
            grade: row['grade'] as String,
            classId: row['class_id'] as String,
            parentId: row['parent_id'] as String?,
            photoUrl: row['photo_url'] as String?,
            createdAt: row['created_at'] as int,
            synced: row['synced'] as int),
        arguments: [upi]);
  }

  @override
  Future<List<StudentModel>> findByClass(String classId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM students WHERE class_id = ?1 ORDER BY full_name',
        mapper: (Map<String, Object?> row) => StudentModel(
            id: row['id'] as String,
            upi: row['upi'] as String,
            fullName: row['full_name'] as String,
            gender: row['gender'] as String,
            dob: row['dob'] as String,
            grade: row['grade'] as String,
            classId: row['class_id'] as String,
            parentId: row['parent_id'] as String?,
            photoUrl: row['photo_url'] as String?,
            createdAt: row['created_at'] as int,
            synced: row['synced'] as int),
        arguments: [classId]);
  }

  @override
  Future<List<StudentModel>> findByClasses(List<String> classIds) async {
    const offset = 1;
    final _sqliteVariablesForClassIds =
        Iterable<String>.generate(classIds.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * FROM students WHERE class_id IN (' +
            _sqliteVariablesForClassIds +
            ') ORDER BY full_name',
        mapper: (Map<String, Object?> row) => StudentModel(
            id: row['id'] as String,
            upi: row['upi'] as String,
            fullName: row['full_name'] as String,
            gender: row['gender'] as String,
            dob: row['dob'] as String,
            grade: row['grade'] as String,
            classId: row['class_id'] as String,
            parentId: row['parent_id'] as String?,
            photoUrl: row['photo_url'] as String?,
            createdAt: row['created_at'] as int,
            synced: row['synced'] as int),
        arguments: [...classIds]);
  }

  @override
  Future<List<StudentModel>> findByGrade(String grade) async {
    return _queryAdapter.queryList(
        'SELECT * FROM students WHERE grade = ?1 ORDER BY full_name',
        mapper: (Map<String, Object?> row) => StudentModel(
            id: row['id'] as String,
            upi: row['upi'] as String,
            fullName: row['full_name'] as String,
            gender: row['gender'] as String,
            dob: row['dob'] as String,
            grade: row['grade'] as String,
            classId: row['class_id'] as String,
            parentId: row['parent_id'] as String?,
            photoUrl: row['photo_url'] as String?,
            createdAt: row['created_at'] as int,
            synced: row['synced'] as int),
        arguments: [grade]);
  }

  @override
  Future<List<StudentModel>> findByParent(String parentId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM students WHERE parent_id = ?1 ORDER BY full_name',
        mapper: (Map<String, Object?> row) => StudentModel(
            id: row['id'] as String,
            upi: row['upi'] as String,
            fullName: row['full_name'] as String,
            gender: row['gender'] as String,
            dob: row['dob'] as String,
            grade: row['grade'] as String,
            classId: row['class_id'] as String,
            parentId: row['parent_id'] as String?,
            photoUrl: row['photo_url'] as String?,
            createdAt: row['created_at'] as int,
            synced: row['synced'] as int),
        arguments: [parentId]);
  }

  @override
  Future<List<StudentModel>> searchByName(String query) async {
    return _queryAdapter.queryList(
        'SELECT * FROM students WHERE full_name LIKE \'%\' || ?1 || \'%\' ORDER BY full_name',
        mapper: (Map<String, Object?> row) => StudentModel(id: row['id'] as String, upi: row['upi'] as String, fullName: row['full_name'] as String, gender: row['gender'] as String, dob: row['dob'] as String, grade: row['grade'] as String, classId: row['class_id'] as String, parentId: row['parent_id'] as String?, photoUrl: row['photo_url'] as String?, createdAt: row['created_at'] as int, synced: row['synced'] as int),
        arguments: [query]);
  }

  @override
  Future<int?> countAll() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM students',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int?> countByClass(String classId) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM students WHERE class_id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classId]);
  }

  @override
  Future<List<StudentModel>> findAll() async {
    return _queryAdapter.queryList('SELECT * FROM students ORDER BY full_name',
        mapper: (Map<String, Object?> row) => StudentModel(
            id: row['id'] as String,
            upi: row['upi'] as String,
            fullName: row['full_name'] as String,
            gender: row['gender'] as String,
            dob: row['dob'] as String,
            grade: row['grade'] as String,
            classId: row['class_id'] as String,
            parentId: row['parent_id'] as String?,
            photoUrl: row['photo_url'] as String?,
            createdAt: row['created_at'] as int,
            synced: row['synced'] as int));
  }

  @override
  Future<List<StudentModel>> findUnsynced() async {
    return _queryAdapter.queryList('SELECT * FROM students WHERE synced = 0',
        mapper: (Map<String, Object?> row) => StudentModel(
            id: row['id'] as String,
            upi: row['upi'] as String,
            fullName: row['full_name'] as String,
            gender: row['gender'] as String,
            dob: row['dob'] as String,
            grade: row['grade'] as String,
            classId: row['class_id'] as String,
            parentId: row['parent_id'] as String?,
            photoUrl: row['photo_url'] as String?,
            createdAt: row['created_at'] as int,
            synced: row['synced'] as int));
  }

  @override
  Future<void> markSynced(String id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE students SET synced = 1 WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<void> insertStudent(StudentModel student) async {
    await _studentModelInsertionAdapter.insert(
        student, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    await _studentModelUpdateAdapter.update(student, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteStudent(StudentModel student) async {
    await _studentModelDeletionAdapter.delete(student);
  }
}

class _$AssessmentDao extends AssessmentDao {
  _$AssessmentDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _assessmentModelInsertionAdapter = InsertionAdapter(
            database,
            'assessments',
            (AssessmentModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'sub_strand_id': item.subStrandId,
                  'teacher_id': item.teacherId,
                  'score': item.score,
                  'teacher_remarks': item.teacherRemarks,
                  'evidence_path': item.evidencePath,
                  'term': item.term,
                  'academic_year': item.academicYear,
                  'date_recorded': item.dateRecorded,
                  'is_moderated': item.isModerated,
                  'moderated_by': item.moderatedBy,
                  'assessment_type': item.assessmentType,
                  'synced': item.synced
                }),
        _coreCompetencyModelInsertionAdapter = InsertionAdapter(
            database,
            'core_competencies',
            (CoreCompetencyModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'teacher_id': item.teacherId,
                  'competency': item.competency,
                  'score': item.score,
                  'term': item.term,
                  'academic_year': item.academicYear,
                  'remarks': item.remarks,
                  'synced': item.synced
                }),
        _evidenceItemModelInsertionAdapter = InsertionAdapter(
            database,
            'evidence_items',
            (EvidenceItemModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'assessment_id': item.assessmentId,
                  'sub_strand_id': item.subStrandId,
                  'local_path': item.localPath,
                  'cloud_url': item.cloudUrl,
                  'caption': item.caption,
                  'media_type': item.mediaType,
                  'taken_at': item.takenAt,
                  'uploaded': item.uploaded
                }),
        _assessmentModelUpdateAdapter = UpdateAdapter(
            database,
            'assessments',
            ['id'],
            (AssessmentModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'sub_strand_id': item.subStrandId,
                  'teacher_id': item.teacherId,
                  'score': item.score,
                  'teacher_remarks': item.teacherRemarks,
                  'evidence_path': item.evidencePath,
                  'term': item.term,
                  'academic_year': item.academicYear,
                  'date_recorded': item.dateRecorded,
                  'is_moderated': item.isModerated,
                  'moderated_by': item.moderatedBy,
                  'assessment_type': item.assessmentType,
                  'synced': item.synced
                }),
        _coreCompetencyModelUpdateAdapter = UpdateAdapter(
            database,
            'core_competencies',
            ['id'],
            (CoreCompetencyModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'teacher_id': item.teacherId,
                  'competency': item.competency,
                  'score': item.score,
                  'term': item.term,
                  'academic_year': item.academicYear,
                  'remarks': item.remarks,
                  'synced': item.synced
                }),
        _evidenceItemModelUpdateAdapter = UpdateAdapter(
            database,
            'evidence_items',
            ['id'],
            (EvidenceItemModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'assessment_id': item.assessmentId,
                  'sub_strand_id': item.subStrandId,
                  'local_path': item.localPath,
                  'cloud_url': item.cloudUrl,
                  'caption': item.caption,
                  'media_type': item.mediaType,
                  'taken_at': item.takenAt,
                  'uploaded': item.uploaded
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<AssessmentModel> _assessmentModelInsertionAdapter;

  final InsertionAdapter<CoreCompetencyModel>
      _coreCompetencyModelInsertionAdapter;

  final InsertionAdapter<EvidenceItemModel> _evidenceItemModelInsertionAdapter;

  final UpdateAdapter<AssessmentModel> _assessmentModelUpdateAdapter;

  final UpdateAdapter<CoreCompetencyModel> _coreCompetencyModelUpdateAdapter;

  final UpdateAdapter<EvidenceItemModel> _evidenceItemModelUpdateAdapter;

  @override
  Future<List<AssessmentModel>> findForStudent(
    String studentId,
    int term,
    String year,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM assessments     WHERE student_id = ?1 AND term = ?2 AND academic_year = ?3     ORDER BY date_recorded DESC',
        mapper: (Map<String, Object?> row) => AssessmentModel(id: row['id'] as String, studentId: row['student_id'] as String, subStrandId: row['sub_strand_id'] as String, teacherId: row['teacher_id'] as String, score: row['score'] as int, assessmentType: row['assessment_type'] as String, teacherRemarks: row['teacher_remarks'] as String?, evidencePath: row['evidence_path'] as String?, term: row['term'] as int, academicYear: row['academic_year'] as String, dateRecorded: row['date_recorded'] as int, isModerated: row['is_moderated'] as int, moderatedBy: row['moderated_by'] as String?, synced: row['synced'] as int),
        arguments: [studentId, term, year]);
  }

  @override
  Future<AssessmentModel?> findLatestForSubStrand(
    String studentId,
    String subStrandId,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM assessments     WHERE student_id = ?1 AND sub_strand_id = ?2     ORDER BY date_recorded DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => AssessmentModel(id: row['id'] as String, studentId: row['student_id'] as String, subStrandId: row['sub_strand_id'] as String, teacherId: row['teacher_id'] as String, score: row['score'] as int, assessmentType: row['assessment_type'] as String, teacherRemarks: row['teacher_remarks'] as String?, evidencePath: row['evidence_path'] as String?, term: row['term'] as int, academicYear: row['academic_year'] as String, dateRecorded: row['date_recorded'] as int, isModerated: row['is_moderated'] as int, moderatedBy: row['moderated_by'] as String?, synced: row['synced'] as int),
        arguments: [studentId, subStrandId]);
  }

  @override
  Future<List<AssessmentModel>> findByTeacher(
    String teacherId,
    int term,
    String year,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM assessments     WHERE teacher_id = ?1 AND term = ?2 AND academic_year = ?3     ORDER BY date_recorded DESC',
        mapper: (Map<String, Object?> row) => AssessmentModel(id: row['id'] as String, studentId: row['student_id'] as String, subStrandId: row['sub_strand_id'] as String, teacherId: row['teacher_id'] as String, score: row['score'] as int, assessmentType: row['assessment_type'] as String, teacherRemarks: row['teacher_remarks'] as String?, evidencePath: row['evidence_path'] as String?, term: row['term'] as int, academicYear: row['academic_year'] as String, dateRecorded: row['date_recorded'] as int, isModerated: row['is_moderated'] as int, moderatedBy: row['moderated_by'] as String?, synced: row['synced'] as int),
        arguments: [teacherId, term, year]);
  }

  @override
  Future<List<AssessmentModel>> findUnsynced() async {
    return _queryAdapter.queryList('SELECT * FROM assessments WHERE synced = 0',
        mapper: (Map<String, Object?> row) => AssessmentModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            subStrandId: row['sub_strand_id'] as String,
            teacherId: row['teacher_id'] as String,
            score: row['score'] as int,
            assessmentType: row['assessment_type'] as String,
            teacherRemarks: row['teacher_remarks'] as String?,
            evidencePath: row['evidence_path'] as String?,
            term: row['term'] as int,
            academicYear: row['academic_year'] as String,
            dateRecorded: row['date_recorded'] as int,
            isModerated: row['is_moderated'] as int,
            moderatedBy: row['moderated_by'] as String?,
            synced: row['synced'] as int));
  }

  @override
  Future<double?> avgScoreForStudent(
    String studentId,
    String year,
    int term,
  ) async {
    return _queryAdapter.query(
        'SELECT AVG(score) FROM assessments     WHERE student_id = ?1 AND academic_year = ?2 AND term = ?3',
        mapper: (Map<String, Object?> row) => row.values.first as double,
        arguments: [studentId, year, term]);
  }

  @override
  Future<void> markSynced(String id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE assessments SET synced = 1 WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<List<AssessmentModel>> findPendingModerationByDept(
      String deptId) async {
    return _queryAdapter.queryList(
        'SELECT a.* FROM assessments a     JOIN users u ON a.teacher_id = u.id     WHERE u.department_id = ?1 AND a.is_moderated = 1',
        mapper: (Map<String, Object?> row) => AssessmentModel(id: row['id'] as String, studentId: row['student_id'] as String, subStrandId: row['sub_strand_id'] as String, teacherId: row['teacher_id'] as String, score: row['score'] as int, assessmentType: row['assessment_type'] as String, teacherRemarks: row['teacher_remarks'] as String?, evidencePath: row['evidence_path'] as String?, term: row['term'] as int, academicYear: row['academic_year'] as String, dateRecorded: row['date_recorded'] as int, isModerated: row['is_moderated'] as int, moderatedBy: row['moderated_by'] as String?, synced: row['synced'] as int),
        arguments: [deptId]);
  }

  @override
  Future<void> moderate(
    String id,
    String hodId,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE assessments SET is_moderated = 2, moderated_by = ?2 WHERE id = ?1',
        arguments: [id, hodId]);
  }

  @override
  Future<void> reject(
    String id,
    String hodId,
    String reason,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE assessments SET is_moderated = 3, moderated_by = ?2, teacher_remarks = teacher_remarks || \" [HOD Feedback: \" || ?3 || \"]\" WHERE id = ?1',
        arguments: [id, hodId, reason]);
  }

  @override
  Future<void> moderateAllForTeacher(
    String teacherId,
    String hodId,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE assessments SET is_moderated = 2, moderated_by = ?2 WHERE teacher_id = ?1 AND is_moderated = 1',
        arguments: [teacherId, hodId]);
  }

  @override
  Future<void> submitAllForTeacher(String teacherId) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE assessments SET is_moderated = 1 WHERE teacher_id = ?1 AND is_moderated = 0',
        arguments: [teacherId]);
  }

  @override
  Future<int?> countDraftsForTeacher(String teacherId) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM assessments WHERE teacher_id = ?1 AND is_moderated = 0',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [teacherId]);
  }

  @override
  Future<List<AssessmentModel>> findSubmittedForTeacher(
      String teacherId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM assessments WHERE teacher_id = ?1 AND is_moderated = 1',
        mapper: (Map<String, Object?> row) => AssessmentModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            subStrandId: row['sub_strand_id'] as String,
            teacherId: row['teacher_id'] as String,
            score: row['score'] as int,
            assessmentType: row['assessment_type'] as String,
            teacherRemarks: row['teacher_remarks'] as String?,
            evidencePath: row['evidence_path'] as String?,
            term: row['term'] as int,
            academicYear: row['academic_year'] as String,
            dateRecorded: row['date_recorded'] as int,
            isModerated: row['is_moderated'] as int,
            moderatedBy: row['moderated_by'] as String?,
            synced: row['synced'] as int),
        arguments: [teacherId]);
  }

  @override
  Future<List<CoreCompetencyModel>> findCompetenciesForStudent(
    String studentId,
    int term,
    String year,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM core_competencies     WHERE student_id = ?1 AND term = ?2 AND academic_year = ?3',
        mapper: (Map<String, Object?> row) => CoreCompetencyModel(id: row['id'] as String, studentId: row['student_id'] as String, teacherId: row['teacher_id'] as String, competency: row['competency'] as String, score: row['score'] as int, term: row['term'] as int, academicYear: row['academic_year'] as String, remarks: row['remarks'] as String?, synced: row['synced'] as int),
        arguments: [studentId, term, year]);
  }

  @override
  Future<List<CoreCompetencyModel>> findUnsyncedCompetencies() async {
    return _queryAdapter.queryList(
        'SELECT * FROM core_competencies WHERE synced = 0',
        mapper: (Map<String, Object?> row) => CoreCompetencyModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            teacherId: row['teacher_id'] as String,
            competency: row['competency'] as String,
            score: row['score'] as int,
            term: row['term'] as int,
            academicYear: row['academic_year'] as String,
            remarks: row['remarks'] as String?,
            synced: row['synced'] as int));
  }

  @override
  Future<List<EvidenceItemModel>> findEvidenceForStudent(
      String studentId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM evidence_items WHERE student_id = ?1 ORDER BY taken_at DESC',
        mapper: (Map<String, Object?> row) => EvidenceItemModel(id: row['id'] as String, studentId: row['student_id'] as String, assessmentId: row['assessment_id'] as String?, subStrandId: row['sub_strand_id'] as String?, localPath: row['local_path'] as String, cloudUrl: row['cloud_url'] as String?, caption: row['caption'] as String?, mediaType: row['media_type'] as String, takenAt: row['taken_at'] as int, uploaded: row['uploaded'] as int),
        arguments: [studentId]);
  }

  @override
  Future<List<EvidenceItemModel>> findPendingUploads() async {
    return _queryAdapter.queryList(
        'SELECT * FROM evidence_items WHERE uploaded = 0',
        mapper: (Map<String, Object?> row) => EvidenceItemModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            assessmentId: row['assessment_id'] as String?,
            subStrandId: row['sub_strand_id'] as String?,
            localPath: row['local_path'] as String,
            cloudUrl: row['cloud_url'] as String?,
            caption: row['caption'] as String?,
            mediaType: row['media_type'] as String,
            takenAt: row['taken_at'] as int,
            uploaded: row['uploaded'] as int));
  }

  @override
  Future<void> insertAssessment(AssessmentModel assessment) async {
    await _assessmentModelInsertionAdapter.insert(
        assessment, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertCompetency(CoreCompetencyModel competency) async {
    await _coreCompetencyModelInsertionAdapter.insert(
        competency, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertEvidence(EvidenceItemModel item) async {
    await _evidenceItemModelInsertionAdapter.insert(
        item, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateAssessment(AssessmentModel assessment) async {
    await _assessmentModelUpdateAdapter.update(
        assessment, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateCompetency(CoreCompetencyModel competency) async {
    await _coreCompetencyModelUpdateAdapter.update(
        competency, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateEvidence(EvidenceItemModel item) async {
    await _evidenceItemModelUpdateAdapter.update(
        item, OnConflictStrategy.abort);
  }
}

class _$FinanceDao extends FinanceDao {
  _$FinanceDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _feeStructureModelInsertionAdapter = InsertionAdapter(
            database,
            'fee_structures',
            (FeeStructureModel item) => <String, Object?>{
                  'id': item.id,
                  'grade': item.grade,
                  'term': item.term,
                  'academic_year': item.academicYear,
                  'amount': item.amount,
                  'description': item.description,
                  'created_by': item.createdBy
                }),
        _feeTransactionModelInsertionAdapter = InsertionAdapter(
            database,
            'fee_transactions',
            (FeeTransactionModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'amount_paid': item.amountPaid,
                  'payment_mode': item.paymentMode,
                  'reference_no': item.referenceNo,
                  'balance_before': item.balanceBefore,
                  'balance_after': item.balanceAfter,
                  'recorded_by': item.recordedBy,
                  'transaction_date': item.transactionDate,
                  'receipt_url': item.receiptUrl,
                  'synced': item.synced,
                  'is_voided': item.isVoided,
                  'voided_by': item.voidedBy
                }),
        _expenditureModelInsertionAdapter = InsertionAdapter(
            database,
            'expenditures',
            (ExpenditureModel item) => <String, Object?>{
                  'id': item.id,
                  'category': item.category,
                  'amount': item.amount,
                  'description': item.description,
                  'recorded_by': item.recordedBy,
                  'expense_date': item.expenseDate,
                  'synced': item.synced,
                  'is_voided': item.isVoided,
                  'voided_by': item.voidedBy
                }),
        _feeStructureModelUpdateAdapter = UpdateAdapter(
            database,
            'fee_structures',
            ['id'],
            (FeeStructureModel item) => <String, Object?>{
                  'id': item.id,
                  'grade': item.grade,
                  'term': item.term,
                  'academic_year': item.academicYear,
                  'amount': item.amount,
                  'description': item.description,
                  'created_by': item.createdBy
                }),
        _feeTransactionModelUpdateAdapter = UpdateAdapter(
            database,
            'fee_transactions',
            ['id'],
            (FeeTransactionModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'amount_paid': item.amountPaid,
                  'payment_mode': item.paymentMode,
                  'reference_no': item.referenceNo,
                  'balance_before': item.balanceBefore,
                  'balance_after': item.balanceAfter,
                  'recorded_by': item.recordedBy,
                  'transaction_date': item.transactionDate,
                  'receipt_url': item.receiptUrl,
                  'synced': item.synced,
                  'is_voided': item.isVoided,
                  'voided_by': item.voidedBy
                }),
        _expenditureModelUpdateAdapter = UpdateAdapter(
            database,
            'expenditures',
            ['id'],
            (ExpenditureModel item) => <String, Object?>{
                  'id': item.id,
                  'category': item.category,
                  'amount': item.amount,
                  'description': item.description,
                  'recorded_by': item.recordedBy,
                  'expense_date': item.expenseDate,
                  'synced': item.synced,
                  'is_voided': item.isVoided,
                  'voided_by': item.voidedBy
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<FeeStructureModel> _feeStructureModelInsertionAdapter;

  final InsertionAdapter<FeeTransactionModel>
      _feeTransactionModelInsertionAdapter;

  final InsertionAdapter<ExpenditureModel> _expenditureModelInsertionAdapter;

  final UpdateAdapter<FeeStructureModel> _feeStructureModelUpdateAdapter;

  final UpdateAdapter<FeeTransactionModel> _feeTransactionModelUpdateAdapter;

  final UpdateAdapter<ExpenditureModel> _expenditureModelUpdateAdapter;

  @override
  Future<FeeStructureModel?> findFeeStructure(
    String grade,
    int term,
    String year,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM fee_structures WHERE grade = ?1 AND term = ?2 AND academic_year = ?3 LIMIT 1',
        mapper: (Map<String, Object?> row) => FeeStructureModel(id: row['id'] as String, grade: row['grade'] as String, term: row['term'] as int, academicYear: row['academic_year'] as String, amount: row['amount'] as double, description: row['description'] as String?, createdBy: row['created_by'] as String),
        arguments: [grade, term, year]);
  }

  @override
  Future<List<FeeStructureModel>> findAllForYear(String year) async {
    return _queryAdapter.queryList(
        'SELECT * FROM fee_structures WHERE academic_year = ?1 ORDER BY grade, term',
        mapper: (Map<String, Object?> row) => FeeStructureModel(id: row['id'] as String, grade: row['grade'] as String, term: row['term'] as int, academicYear: row['academic_year'] as String, amount: row['amount'] as double, description: row['description'] as String?, createdBy: row['created_by'] as String),
        arguments: [year]);
  }

  @override
  Future<List<FeeTransactionModel>> findTransactionsForStudent(
      String studentId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM fee_transactions     WHERE student_id = ?1 AND is_voided = 0     ORDER BY transaction_date DESC',
        mapper: (Map<String, Object?> row) => FeeTransactionModel(id: row['id'] as String, studentId: row['student_id'] as String, amountPaid: row['amount_paid'] as double, paymentMode: row['payment_mode'] as String, referenceNo: row['reference_no'] as String, balanceBefore: row['balance_before'] as double?, balanceAfter: row['balance_after'] as double?, recordedBy: row['recorded_by'] as String, transactionDate: row['transaction_date'] as int, receiptUrl: row['receipt_url'] as String?, synced: row['synced'] as int, isVoided: row['is_voided'] as int, voidedBy: row['voided_by'] as String?),
        arguments: [studentId]);
  }

  @override
  Future<double?> totalPaid(String studentId) async {
    return _queryAdapter.query(
        'SELECT SUM(amount_paid) FROM fee_transactions WHERE student_id = ?1 AND is_voided = 0',
        mapper: (Map<String, Object?> row) => row.values.first as double,
        arguments: [studentId]);
  }

  @override
  Future<FeeTransactionModel?> findTransactionById(String id) async {
    return _queryAdapter.query('SELECT * FROM fee_transactions WHERE id = ?1',
        mapper: (Map<String, Object?> row) => FeeTransactionModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            amountPaid: row['amount_paid'] as double,
            paymentMode: row['payment_mode'] as String,
            referenceNo: row['reference_no'] as String,
            balanceBefore: row['balance_before'] as double?,
            balanceAfter: row['balance_after'] as double?,
            recordedBy: row['recorded_by'] as String,
            transactionDate: row['transaction_date'] as int,
            receiptUrl: row['receipt_url'] as String?,
            synced: row['synced'] as int,
            isVoided: row['is_voided'] as int,
            voidedBy: row['voided_by'] as String?),
        arguments: [id]);
  }

  @override
  Future<List<FeeTransactionModel>> findTransactionsInRange(
    int fromDate,
    int toDate,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM fee_transactions     WHERE transaction_date >= ?1 AND transaction_date <= ?2     ORDER BY transaction_date DESC',
        mapper: (Map<String, Object?> row) => FeeTransactionModel(id: row['id'] as String, studentId: row['student_id'] as String, amountPaid: row['amount_paid'] as double, paymentMode: row['payment_mode'] as String, referenceNo: row['reference_no'] as String, balanceBefore: row['balance_before'] as double?, balanceAfter: row['balance_after'] as double?, recordedBy: row['recorded_by'] as String, transactionDate: row['transaction_date'] as int, receiptUrl: row['receipt_url'] as String?, synced: row['synced'] as int, isVoided: row['is_voided'] as int, voidedBy: row['voided_by'] as String?),
        arguments: [fromDate, toDate]);
  }

  @override
  Future<List<FeeTransactionModel>> findUnsynced() async {
    return _queryAdapter.queryList(
        'SELECT * FROM fee_transactions WHERE synced = 0',
        mapper: (Map<String, Object?> row) => FeeTransactionModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            amountPaid: row['amount_paid'] as double,
            paymentMode: row['payment_mode'] as String,
            referenceNo: row['reference_no'] as String,
            balanceBefore: row['balance_before'] as double?,
            balanceAfter: row['balance_after'] as double?,
            recordedBy: row['recorded_by'] as String,
            transactionDate: row['transaction_date'] as int,
            receiptUrl: row['receipt_url'] as String?,
            synced: row['synced'] as int,
            isVoided: row['is_voided'] as int,
            voidedBy: row['voided_by'] as String?));
  }

  @override
  Future<void> markSynced(String id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE fee_transactions SET synced = 1 WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<List<ExpenditureModel>> findAllExpenditures() async {
    return _queryAdapter.queryList(
        'SELECT * FROM expenditures WHERE is_voided = 0 ORDER BY expense_date DESC',
        mapper: (Map<String, Object?> row) => ExpenditureModel(
            id: row['id'] as String,
            category: row['category'] as String,
            amount: row['amount'] as double,
            description: row['description'] as String,
            recordedBy: row['recorded_by'] as String,
            expenseDate: row['expense_date'] as int,
            synced: row['synced'] as int,
            isVoided: row['is_voided'] as int,
            voidedBy: row['voided_by'] as String?));
  }

  @override
  Future<double?> totalExpenditureInRange(
    int fromDate,
    int toDate,
  ) async {
    return _queryAdapter.query(
        'SELECT SUM(amount) FROM expenditures WHERE expense_date >= ?1 AND expense_date <= ?2 AND is_voided = 0',
        mapper: (Map<String, Object?> row) => row.values.first as double,
        arguments: [fromDate, toDate]);
  }

  @override
  Future<ExpenditureModel?> findExpenditureById(String id) async {
    return _queryAdapter.query('SELECT * FROM expenditures WHERE id = ?1',
        mapper: (Map<String, Object?> row) => ExpenditureModel(
            id: row['id'] as String,
            category: row['category'] as String,
            amount: row['amount'] as double,
            description: row['description'] as String,
            recordedBy: row['recorded_by'] as String,
            expenseDate: row['expense_date'] as int,
            synced: row['synced'] as int,
            isVoided: row['is_voided'] as int,
            voidedBy: row['voided_by'] as String?),
        arguments: [id]);
  }

  @override
  Future<void> insertFeeStructure(FeeStructureModel fs) async {
    await _feeStructureModelInsertionAdapter.insert(
        fs, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertTransaction(FeeTransactionModel txn) async {
    await _feeTransactionModelInsertionAdapter.insert(
        txn, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertExpenditure(ExpenditureModel expenditure) async {
    await _expenditureModelInsertionAdapter.insert(
        expenditure, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateFeeStructure(FeeStructureModel fs) async {
    await _feeStructureModelUpdateAdapter.update(fs, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateTransaction(FeeTransactionModel txn) async {
    await _feeTransactionModelUpdateAdapter.update(
        txn, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateExpenditure(ExpenditureModel exp) async {
    await _expenditureModelUpdateAdapter.update(exp, OnConflictStrategy.abort);
  }
}

class _$AttendanceDao extends AttendanceDao {
  _$AttendanceDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _attendanceModelInsertionAdapter = InsertionAdapter(
            database,
            'attendance',
            (AttendanceModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'class_id': item.classId,
                  'date': item.date,
                  'status': item.status,
                  'recorded_by': item.recordedBy,
                  'synced': item.synced
                }),
        _messageModelInsertionAdapter = InsertionAdapter(
            database,
            'messages',
            (MessageModel item) => <String, Object?>{
                  'id': item.id,
                  'sender_id': item.senderId,
                  'recipient_id': item.recipientId,
                  'message_type': item.messageType,
                  'subject': item.subject,
                  'body': item.body,
                  'sent_at': item.sentAt,
                  'read_at': item.readAt,
                  'synced': item.synced
                }),
        _attendanceModelUpdateAdapter = UpdateAdapter(
            database,
            'attendance',
            ['id'],
            (AttendanceModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'class_id': item.classId,
                  'date': item.date,
                  'status': item.status,
                  'recorded_by': item.recordedBy,
                  'synced': item.synced
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<AttendanceModel> _attendanceModelInsertionAdapter;

  final InsertionAdapter<MessageModel> _messageModelInsertionAdapter;

  final UpdateAdapter<AttendanceModel> _attendanceModelUpdateAdapter;

  @override
  Future<List<AttendanceModel>> findForClassByDate(
    String classId,
    String date,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM attendance     WHERE class_id = ?1 AND date = ?2     ORDER BY student_id',
        mapper: (Map<String, Object?> row) => AttendanceModel(id: row['id'] as String, studentId: row['student_id'] as String, classId: row['class_id'] as String, date: row['date'] as String, status: row['status'] as String, recordedBy: row['recorded_by'] as String, synced: row['synced'] as int),
        arguments: [classId, date]);
  }

  @override
  Future<List<AttendanceModel>> findForStudent(String studentId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM attendance     WHERE student_id = ?1     ORDER BY date DESC',
        mapper: (Map<String, Object?> row) => AttendanceModel(id: row['id'] as String, studentId: row['student_id'] as String, classId: row['class_id'] as String, date: row['date'] as String, status: row['status'] as String, recordedBy: row['recorded_by'] as String, synced: row['synced'] as int),
        arguments: [studentId]);
  }

  @override
  Future<int?> countAbsences(
    String studentId,
    String fromDate,
    String toDate,
  ) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM attendance     WHERE student_id = ?1 AND status = \'Absent\'     AND date >= ?2 AND date <= ?3',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [studentId, fromDate, toDate]);
  }

  @override
  Future<List<AttendanceModel>> findUnsynced() async {
    return _queryAdapter.queryList('SELECT * FROM attendance WHERE synced = 0',
        mapper: (Map<String, Object?> row) => AttendanceModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            classId: row['class_id'] as String,
            date: row['date'] as String,
            status: row['status'] as String,
            recordedBy: row['recorded_by'] as String,
            synced: row['synced'] as int));
  }

  @override
  Future<void> markSynced(String id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE attendance SET synced = 1 WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<List<MessageModel>> findMessagesForUser(String userId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM messages     WHERE recipient_id = ?1 OR message_type = \'Broadcast\'     ORDER BY sent_at DESC',
        mapper: (Map<String, Object?> row) => MessageModel(id: row['id'] as String, senderId: row['sender_id'] as String, recipientId: row['recipient_id'] as String?, messageType: row['message_type'] as String, subject: row['subject'] as String?, body: row['body'] as String, sentAt: row['sent_at'] as int, readAt: row['read_at'] as int?, synced: row['synced'] as int),
        arguments: [userId]);
  }

  @override
  Future<List<MessageModel>> findSentMessages(String senderId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM messages     WHERE sender_id = ?1     ORDER BY sent_at DESC',
        mapper: (Map<String, Object?> row) => MessageModel(id: row['id'] as String, senderId: row['sender_id'] as String, recipientId: row['recipient_id'] as String?, messageType: row['message_type'] as String, subject: row['subject'] as String?, body: row['body'] as String, sentAt: row['sent_at'] as int, readAt: row['read_at'] as int?, synced: row['synced'] as int),
        arguments: [senderId]);
  }

  @override
  Future<void> markRead(
    String id,
    int readAt,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE messages SET read_at = ?2 WHERE id = ?1',
        arguments: [id, readAt]);
  }

  @override
  Future<void> insertAttendance(AttendanceModel record) async {
    await _attendanceModelInsertionAdapter.insert(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertMessage(MessageModel message) async {
    await _messageModelInsertionAdapter.insert(
        message, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateAttendance(AttendanceModel record) async {
    await _attendanceModelUpdateAdapter.update(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<void> upsertAttendance(AttendanceModel record) async {
    if (database is sqflite.Transaction) {
      await super.upsertAttendance(record);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.attendanceDao.upsertAttendance(record);
      });
    }
  }
}

class _$CurriculumDao extends CurriculumDao {
  _$CurriculumDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _learningAreaModelInsertionAdapter = InsertionAdapter(
            database,
            'learning_areas',
            (LearningAreaModel item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'grade_band': item.gradeBand,
                  'category': item.category,
                  'department_id': item.departmentId
                }),
        _strandModelInsertionAdapter = InsertionAdapter(
            database,
            'strands',
            (StrandModel item) => <String, Object?>{
                  'id': item.id,
                  'learning_area_id': item.learningAreaId,
                  'strand_name': item.strandName
                }),
        _subStrandModelInsertionAdapter = InsertionAdapter(
            database,
            'sub_strands',
            (SubStrandModel item) => <String, Object?>{
                  'id': item.id,
                  'strand_id': item.strandId,
                  'sub_strand_name': item.subStrandName,
                  'assessment_rubric': item.assessmentRubric
                }),
        _schoolClassModelInsertionAdapter = InsertionAdapter(
            database,
            'school_classes',
            (SchoolClassModel item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'grade': item.grade,
                  'teacher_id': item.teacherId,
                  'academic_year': item.academicYear
                }),
        _strandCoverageInsertionAdapter = InsertionAdapter(
            database,
            'strand_coverage',
            (StrandCoverage item) => <String, Object?>{
                  'id': item.id,
                  'class_id': item.classId,
                  'strand_id': item.strandId,
                  'teacher_id': item.teacherId,
                  'completion_date': item.completionDate
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<LearningAreaModel> _learningAreaModelInsertionAdapter;

  final InsertionAdapter<StrandModel> _strandModelInsertionAdapter;

  final InsertionAdapter<SubStrandModel> _subStrandModelInsertionAdapter;

  final InsertionAdapter<SchoolClassModel> _schoolClassModelInsertionAdapter;

  final InsertionAdapter<StrandCoverage> _strandCoverageInsertionAdapter;

  @override
  Future<List<LearningAreaModel>> findAreasByLevel(String gradeBand) async {
    return _queryAdapter.queryList(
        'SELECT * FROM learning_areas WHERE grade_band = ?1 ORDER BY name ASC',
        mapper: (Map<String, Object?> row) => LearningAreaModel(
            id: row['id'] as String,
            name: row['name'] as String,
            gradeBand: row['grade_band'] as String,
            category: row['category'] as String,
            departmentId: row['department_id'] as String?),
        arguments: [gradeBand]);
  }

  @override
  Future<List<LearningAreaModel>> findAllLearningAreas() async {
    return _queryAdapter.queryList(
        'SELECT * FROM learning_areas ORDER BY name ASC',
        mapper: (Map<String, Object?> row) => LearningAreaModel(
            id: row['id'] as String,
            name: row['name'] as String,
            gradeBand: row['grade_band'] as String,
            category: row['category'] as String,
            departmentId: row['department_id'] as String?));
  }

  @override
  Future<List<StrandModel>> findStrandsByArea(String areaId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM strands WHERE learning_area_id = ?1 ORDER BY strand_name ASC',
        mapper: (Map<String, Object?> row) => StrandModel(id: row['id'] as String, learningAreaId: row['learning_area_id'] as String, strandName: row['strand_name'] as String),
        arguments: [areaId]);
  }

  @override
  Future<List<SubStrandModel>> findSubStrandsByStrand(String strandId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM sub_strands WHERE strand_id = ?1 ORDER BY sub_strand_name ASC',
        mapper: (Map<String, Object?> row) => SubStrandModel(id: row['id'] as String, strandId: row['strand_id'] as String, subStrandName: row['sub_strand_name'] as String, assessmentRubric: row['assessment_rubric'] as String?),
        arguments: [strandId]);
  }

  @override
  Future<List<SchoolClassModel>> findAllClasses() async {
    return _queryAdapter.queryList(
        'SELECT * FROM school_classes ORDER BY name ASC',
        mapper: (Map<String, Object?> row) => SchoolClassModel(
            id: row['id'] as String,
            name: row['name'] as String,
            grade: row['grade'] as String,
            teacherId: row['teacher_id'] as String?,
            academicYear: row['academic_year'] as String));
  }

  @override
  Future<SchoolClassModel?> findClassById(String id) async {
    return _queryAdapter.query('SELECT * FROM school_classes WHERE id = ?1',
        mapper: (Map<String, Object?> row) => SchoolClassModel(
            id: row['id'] as String,
            name: row['name'] as String,
            grade: row['grade'] as String,
            teacherId: row['teacher_id'] as String?,
            academicYear: row['academic_year'] as String),
        arguments: [id]);
  }

  @override
  Future<int?> countAreas() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM learning_areas',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> clearTestSubjects() async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM learning_areas WHERE id LIKE \'SUB_%\'');
  }

  @override
  Future<void> removeCoverage(
    String classId,
    String strandId,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM strand_coverage WHERE class_id = ?1 AND strand_id = ?2',
        arguments: [classId, strandId]);
  }

  @override
  Future<List<StrandCoverage>> findCoverageForClass(String classId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM strand_coverage WHERE class_id = ?1',
        mapper: (Map<String, Object?> row) => StrandCoverage(
            id: row['id'] as String,
            classId: row['class_id'] as String,
            strandId: row['strand_id'] as String,
            teacherId: row['teacher_id'] as String,
            completionDate: row['completion_date'] as int),
        arguments: [classId]);
  }

  @override
  Future<void> insertArea(LearningAreaModel area) async {
    await _learningAreaModelInsertionAdapter.insert(
        area, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertStrand(StrandModel strand) async {
    await _strandModelInsertionAdapter.insert(
        strand, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSubStrand(SubStrandModel subStrand) async {
    await _subStrandModelInsertionAdapter.insert(
        subStrand, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertClass(SchoolClassModel schoolClass) async {
    await _schoolClassModelInsertionAdapter.insert(
        schoolClass, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertCoverage(StrandCoverage coverage) async {
    await _strandCoverageInsertionAdapter.insert(
        coverage, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertFullCurriculum(
    List<LearningAreaModel> areas,
    List<StrandModel> strands,
    List<SubStrandModel> subStrands,
  ) async {
    if (database is sqflite.Transaction) {
      await super.insertFullCurriculum(areas, strands, subStrands);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.curriculumDao
            .insertFullCurriculum(areas, strands, subStrands);
      });
    }
  }
}

class _$MedicalDao extends MedicalDao {
  _$MedicalDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _medicalRecordModelInsertionAdapter = InsertionAdapter(
            database,
            'medical_records',
            (MedicalRecordModel item) => <String, Object?>{
                  'student_id': item.studentId,
                  'allergies': item.allergies,
                  'chronic_conditions': item.chronicConditions,
                  'blood_group': item.bloodGroup,
                  'emergency_contacts': item.emergencyContacts
                }),
        _clinicVisitModelInsertionAdapter = InsertionAdapter(
            database,
            'clinic_visits',
            (ClinicVisitModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'symptoms': item.symptoms,
                  'action_taken': item.actionTaken,
                  'medication_given': item.medicationGiven,
                  'timestamp': item.timestamp,
                  'recorded_by': item.recordedBy
                }),
        _medicalRecordModelUpdateAdapter = UpdateAdapter(
            database,
            'medical_records',
            ['student_id'],
            (MedicalRecordModel item) => <String, Object?>{
                  'student_id': item.studentId,
                  'allergies': item.allergies,
                  'chronic_conditions': item.chronicConditions,
                  'blood_group': item.bloodGroup,
                  'emergency_contacts': item.emergencyContacts
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<MedicalRecordModel>
      _medicalRecordModelInsertionAdapter;

  final InsertionAdapter<ClinicVisitModel> _clinicVisitModelInsertionAdapter;

  final UpdateAdapter<MedicalRecordModel> _medicalRecordModelUpdateAdapter;

  @override
  Future<MedicalRecordModel?> findForStudent(String studentId) async {
    return _queryAdapter.query(
        'SELECT * FROM medical_records WHERE student_id = ?1',
        mapper: (Map<String, Object?> row) => MedicalRecordModel(
            studentId: row['student_id'] as String,
            allergies: row['allergies'] as String?,
            chronicConditions: row['chronic_conditions'] as String?,
            bloodGroup: row['blood_group'] as String?,
            emergencyContacts: row['emergency_contacts'] as String?),
        arguments: [studentId]);
  }

  @override
  Future<List<ClinicVisitModel>> findVisitsForStudent(String studentId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM clinic_visits WHERE student_id = ?1 ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => ClinicVisitModel(id: row['id'] as String, studentId: row['student_id'] as String, symptoms: row['symptoms'] as String, actionTaken: row['action_taken'] as String, medicationGiven: row['medication_given'] as String?, timestamp: row['timestamp'] as int, recordedBy: row['recorded_by'] as String),
        arguments: [studentId]);
  }

  @override
  Future<List<ClinicVisitModel>> findRecentVisits() async {
    return _queryAdapter.queryList(
        'SELECT * FROM clinic_visits ORDER BY timestamp DESC LIMIT 50',
        mapper: (Map<String, Object?> row) => ClinicVisitModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            symptoms: row['symptoms'] as String,
            actionTaken: row['action_taken'] as String,
            medicationGiven: row['medication_given'] as String?,
            timestamp: row['timestamp'] as int,
            recordedBy: row['recorded_by'] as String));
  }

  @override
  Future<void> insertRecord(MedicalRecordModel record) async {
    await _medicalRecordModelInsertionAdapter.insert(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertVisit(ClinicVisitModel visit) async {
    await _clinicVisitModelInsertionAdapter.insert(
        visit, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateRecord(MedicalRecordModel record) async {
    await _medicalRecordModelUpdateAdapter.update(
        record, OnConflictStrategy.abort);
  }
}

class _$DisciplineDao extends DisciplineDao {
  _$DisciplineDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _disciplineRecordModelInsertionAdapter = InsertionAdapter(
            database,
            'discipline_records',
            (DisciplineRecordModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'category': item.category,
                  'incident_description': item.incidentDescription,
                  'action_taken': item.actionTaken,
                  'status': item.status,
                  'timestamp': item.timestamp,
                  'recorded_by': item.recordedBy
                }),
        _disciplineRecordModelUpdateAdapter = UpdateAdapter(
            database,
            'discipline_records',
            ['id'],
            (DisciplineRecordModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'category': item.category,
                  'incident_description': item.incidentDescription,
                  'action_taken': item.actionTaken,
                  'status': item.status,
                  'timestamp': item.timestamp,
                  'recorded_by': item.recordedBy
                }),
        _disciplineRecordModelDeletionAdapter = DeletionAdapter(
            database,
            'discipline_records',
            ['id'],
            (DisciplineRecordModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'category': item.category,
                  'incident_description': item.incidentDescription,
                  'action_taken': item.actionTaken,
                  'status': item.status,
                  'timestamp': item.timestamp,
                  'recorded_by': item.recordedBy
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DisciplineRecordModel>
      _disciplineRecordModelInsertionAdapter;

  final UpdateAdapter<DisciplineRecordModel>
      _disciplineRecordModelUpdateAdapter;

  final DeletionAdapter<DisciplineRecordModel>
      _disciplineRecordModelDeletionAdapter;

  @override
  Future<List<DisciplineRecordModel>> findForStudent(String studentId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM discipline_records WHERE student_id = ?1 ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => DisciplineRecordModel(id: row['id'] as String, studentId: row['student_id'] as String, category: row['category'] as String, incidentDescription: row['incident_description'] as String, actionTaken: row['action_taken'] as String, status: row['status'] as String, timestamp: row['timestamp'] as int, recordedBy: row['recorded_by'] as String),
        arguments: [studentId]);
  }

  @override
  Future<List<DisciplineRecordModel>> findAll() async {
    return _queryAdapter.queryList(
        'SELECT * FROM discipline_records ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => DisciplineRecordModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            category: row['category'] as String,
            incidentDescription: row['incident_description'] as String,
            actionTaken: row['action_taken'] as String,
            status: row['status'] as String,
            timestamp: row['timestamp'] as int,
            recordedBy: row['recorded_by'] as String));
  }

  @override
  Future<void> insertRecord(DisciplineRecordModel record) async {
    await _disciplineRecordModelInsertionAdapter.insert(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateRecord(DisciplineRecordModel record) async {
    await _disciplineRecordModelUpdateAdapter.update(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteRecord(DisciplineRecordModel record) async {
    await _disciplineRecordModelDeletionAdapter.delete(record);
  }
}

class _$CateringDao extends CateringDao {
  _$CateringDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _mealPlanModelInsertionAdapter = InsertionAdapter(
            database,
            'meal_plans',
            (MealPlanModel item) => <String, Object?>{
                  'id': item.id,
                  'dayOfWeek': item.dayOfWeek,
                  'mealType': item.mealType,
                  'menu': item.menu,
                  'academic_year': item.academicYear,
                  'term': item.term
                }),
        _mealPlanModelUpdateAdapter = UpdateAdapter(
            database,
            'meal_plans',
            ['id'],
            (MealPlanModel item) => <String, Object?>{
                  'id': item.id,
                  'dayOfWeek': item.dayOfWeek,
                  'mealType': item.mealType,
                  'menu': item.menu,
                  'academic_year': item.academicYear,
                  'term': item.term
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<MealPlanModel> _mealPlanModelInsertionAdapter;

  final UpdateAdapter<MealPlanModel> _mealPlanModelUpdateAdapter;

  @override
  Future<List<MealPlanModel>> findForTerm(
    int term,
    String year,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM meal_plans WHERE term = ?1 AND academic_year = ?2 ORDER BY dayOfWeek',
        mapper: (Map<String, Object?> row) => MealPlanModel(id: row['id'] as String, dayOfWeek: row['dayOfWeek'] as String, mealType: row['mealType'] as String, menu: row['menu'] as String, academicYear: row['academic_year'] as String, term: row['term'] as int),
        arguments: [term, year]);
  }

  @override
  Future<void> deleteMeal(String id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM meal_plans WHERE id = ?1', arguments: [id]);
  }

  @override
  Future<void> insertMeal(MealPlanModel meal) async {
    await _mealPlanModelInsertionAdapter.insert(meal, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateMeal(MealPlanModel meal) async {
    await _mealPlanModelUpdateAdapter.update(meal, OnConflictStrategy.abort);
  }
}

class _$PathwayDao extends PathwayDao {
  _$PathwayDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _pathwayRecommendationModelInsertionAdapter = InsertionAdapter(
            database,
            'pathway_recommendations',
            (PathwayRecommendationModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'recommendedPathway': item.recommendedPathway,
                  'performance_score': item.performanceScore,
                  'rationale': item.rationale,
                  'timestamp': item.timestamp
                }),
        _pathwayRecommendationModelUpdateAdapter = UpdateAdapter(
            database,
            'pathway_recommendations',
            ['id'],
            (PathwayRecommendationModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'recommendedPathway': item.recommendedPathway,
                  'performance_score': item.performanceScore,
                  'rationale': item.rationale,
                  'timestamp': item.timestamp
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<PathwayRecommendationModel>
      _pathwayRecommendationModelInsertionAdapter;

  final UpdateAdapter<PathwayRecommendationModel>
      _pathwayRecommendationModelUpdateAdapter;

  @override
  Future<PathwayRecommendationModel?> findForStudent(String studentId) async {
    return _queryAdapter.query(
        'SELECT * FROM pathway_recommendations WHERE student_id = ?1',
        mapper: (Map<String, Object?> row) => PathwayRecommendationModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            recommendedPathway: row['recommendedPathway'] as String,
            performanceScore: row['performance_score'] as double,
            rationale: row['rationale'] as String,
            timestamp: row['timestamp'] as int),
        arguments: [studentId]);
  }

  @override
  Future<List<PathwayRecommendationModel>> findAll() async {
    return _queryAdapter.queryList(
        'SELECT * FROM pathway_recommendations ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => PathwayRecommendationModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            recommendedPathway: row['recommendedPathway'] as String,
            performanceScore: row['performance_score'] as double,
            rationale: row['rationale'] as String,
            timestamp: row['timestamp'] as int));
  }

  @override
  Future<void> insertRecommendation(PathwayRecommendationModel p) async {
    await _pathwayRecommendationModelInsertionAdapter.insert(
        p, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateRecommendation(PathwayRecommendationModel p) async {
    await _pathwayRecommendationModelUpdateAdapter.update(
        p, OnConflictStrategy.abort);
  }
}

class _$SecurityDao extends SecurityDao {
  _$SecurityDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _visitorLogModelInsertionAdapter = InsertionAdapter(
            database,
            'visitor_logs',
            (VisitorLogModel item) => <String, Object?>{
                  'id': item.id,
                  'visitor_name': item.visitorName,
                  'id_number': item.idNumber,
                  'purpose': item.purpose,
                  'whom_to_see': item.whomToSee,
                  'check_in_time': item.checkInTime,
                  'check_out_time': item.checkOutTime,
                  'vehicle_reg': item.vehicleReg,
                  'recorded_by': item.recordedBy
                }),
        _visitorLogModelUpdateAdapter = UpdateAdapter(
            database,
            'visitor_logs',
            ['id'],
            (VisitorLogModel item) => <String, Object?>{
                  'id': item.id,
                  'visitor_name': item.visitorName,
                  'id_number': item.idNumber,
                  'purpose': item.purpose,
                  'whom_to_see': item.whomToSee,
                  'check_in_time': item.checkInTime,
                  'check_out_time': item.checkOutTime,
                  'vehicle_reg': item.vehicleReg,
                  'recorded_by': item.recordedBy
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<VisitorLogModel> _visitorLogModelInsertionAdapter;

  final UpdateAdapter<VisitorLogModel> _visitorLogModelUpdateAdapter;

  @override
  Future<List<VisitorLogModel>> findActiveVisitors() async {
    return _queryAdapter.queryList(
        'SELECT * FROM visitor_logs WHERE check_out_time IS NULL ORDER BY check_in_time DESC',
        mapper: (Map<String, Object?> row) => VisitorLogModel(
            id: row['id'] as String,
            visitorName: row['visitor_name'] as String,
            idNumber: row['id_number'] as String,
            purpose: row['purpose'] as String,
            whomToSee: row['whom_to_see'] as String,
            checkInTime: row['check_in_time'] as int,
            checkOutTime: row['check_out_time'] as int?,
            vehicleReg: row['vehicle_reg'] as String?,
            recordedBy: row['recorded_by'] as String));
  }

  @override
  Future<List<VisitorLogModel>> findAllLogs() async {
    return _queryAdapter.queryList(
        'SELECT * FROM visitor_logs ORDER BY check_in_time DESC LIMIT 100',
        mapper: (Map<String, Object?> row) => VisitorLogModel(
            id: row['id'] as String,
            visitorName: row['visitor_name'] as String,
            idNumber: row['id_number'] as String,
            purpose: row['purpose'] as String,
            whomToSee: row['whom_to_see'] as String,
            checkInTime: row['check_in_time'] as int,
            checkOutTime: row['check_out_time'] as int?,
            vehicleReg: row['vehicle_reg'] as String?,
            recordedBy: row['recorded_by'] as String));
  }

  @override
  Future<void> checkOut(
    String id,
    int timestamp,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE visitor_logs SET check_out_time = ?2 WHERE id = ?1',
        arguments: [id, timestamp]);
  }

  @override
  Future<void> insertLog(VisitorLogModel log) async {
    await _visitorLogModelInsertionAdapter.insert(
        log, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateLog(VisitorLogModel log) async {
    await _visitorLogModelUpdateAdapter.update(log, OnConflictStrategy.abort);
  }
}

class _$CounselingDao extends CounselingDao {
  _$CounselingDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _counselingLogModelInsertionAdapter = InsertionAdapter(
            database,
            'counseling_logs',
            (CounselingLogModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'issue': item.issue,
                  'summary': item.summary,
                  'notes': item.notes,
                  'follow_up_required': item.followUpRequired,
                  'timestamp': item.timestamp,
                  'counselor_id': item.counselorId
                }),
        _counselingLogModelUpdateAdapter = UpdateAdapter(
            database,
            'counseling_logs',
            ['id'],
            (CounselingLogModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'issue': item.issue,
                  'summary': item.summary,
                  'notes': item.notes,
                  'follow_up_required': item.followUpRequired,
                  'timestamp': item.timestamp,
                  'counselor_id': item.counselorId
                }),
        _counselingLogModelDeletionAdapter = DeletionAdapter(
            database,
            'counseling_logs',
            ['id'],
            (CounselingLogModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'issue': item.issue,
                  'summary': item.summary,
                  'notes': item.notes,
                  'follow_up_required': item.followUpRequired,
                  'timestamp': item.timestamp,
                  'counselor_id': item.counselorId
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CounselingLogModel>
      _counselingLogModelInsertionAdapter;

  final UpdateAdapter<CounselingLogModel> _counselingLogModelUpdateAdapter;

  final DeletionAdapter<CounselingLogModel> _counselingLogModelDeletionAdapter;

  @override
  Future<List<CounselingLogModel>> findForStudent(String studentId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM counseling_logs WHERE student_id = ?1 ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => CounselingLogModel(id: row['id'] as String, studentId: row['student_id'] as String, issue: row['issue'] as String, summary: row['summary'] as String, notes: row['notes'] as String, followUpRequired: row['follow_up_required'] as int, timestamp: row['timestamp'] as int, counselorId: row['counselor_id'] as String),
        arguments: [studentId]);
  }

  @override
  Future<List<CounselingLogModel>> findAll() async {
    return _queryAdapter.queryList(
        'SELECT * FROM counseling_logs ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => CounselingLogModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            issue: row['issue'] as String,
            summary: row['summary'] as String,
            notes: row['notes'] as String,
            followUpRequired: row['follow_up_required'] as int,
            timestamp: row['timestamp'] as int,
            counselorId: row['counselor_id'] as String));
  }

  @override
  Future<void> insertLog(CounselingLogModel log) async {
    await _counselingLogModelInsertionAdapter.insert(
        log, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateLog(CounselingLogModel log) async {
    await _counselingLogModelUpdateAdapter.update(
        log, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteLog(CounselingLogModel log) async {
    await _counselingLogModelDeletionAdapter.delete(log);
  }
}

class _$EnterpriseDao extends EnterpriseDao {
  _$EnterpriseDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _teachingAssignmentInsertionAdapter = InsertionAdapter(
            database,
            'teaching_assignments',
            (TeachingAssignment item) => <String, Object?>{
                  'id': item.id,
                  'teacherId': item.teacherId,
                  'classId': item.classId,
                  'subjectId': item.subjectId,
                  'academicYear': item.academicYear
                }),
        _officialMemoInsertionAdapter = InsertionAdapter(
            database,
            'official_memos',
            (OfficialMemo item) => <String, Object?>{
                  'id': item.id,
                  'senderId': item.senderId,
                  'title': item.title,
                  'content': item.content,
                  'targetGroup': item.targetGroup,
                  'createdAt': item.createdAt,
                  'priority': item.priority
                }),
        _memoReadRecordInsertionAdapter = InsertionAdapter(
            database,
            'memo_reads',
            (MemoReadRecord item) => <String, Object?>{
                  'id': item.id,
                  'memoId': item.memoId,
                  'userId': item.userId,
                  'readAt': item.readAt
                }),
        _staffLeaveInsertionAdapter = InsertionAdapter(
            database,
            'staff_leaves',
            (StaffLeave item) => <String, Object?>{
                  'id': item.id,
                  'staffId': item.staffId,
                  'leaveType': item.leaveType,
                  'startDate': item.startDate,
                  'endDate': item.endDate,
                  'reason': item.reason,
                  'status': item.status,
                  'approvedBy': item.approvedBy
                }),
        _inventoryAssetInsertionAdapter = InsertionAdapter(
            database,
            'inventory_assets',
            (InventoryAsset item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'category': item.category,
                  'location': item.location,
                  'quantity': item.quantity,
                  'condition': item.condition,
                  'unit_cost': item.unitCost,
                  'purchase_date': item.purchaseDate,
                  'assigned_to': item.assignedTo
                }),
        _assetMaintenanceLogInsertionAdapter = InsertionAdapter(
            database,
            'asset_maintenance_logs',
            (AssetMaintenanceLog item) => <String, Object?>{
                  'id': item.id,
                  'asset_id': item.assetId,
                  'description': item.description,
                  'cost': item.cost,
                  'serviced_at': item.servicedAt,
                  'recorded_by': item.recordedBy
                }),
        _systemLogInsertionAdapter = InsertionAdapter(
            database,
            'system_activity_logs',
            (SystemLog item) => <String, Object?>{
                  'id': item.id,
                  'userId': item.userId,
                  'action': item.action,
                  'module': item.module,
                  'details': item.details,
                  'timestamp': item.timestamp,
                  'ipAddress': item.ipAddress
                }),
        _substitutionInsertionAdapter = InsertionAdapter(
            database,
            'substitutions',
            (Substitution item) => <String, Object?>{
                  'id': item.id,
                  'original_teacher_id': item.originalTeacherId,
                  'substitute_teacher_id': item.substituteTeacherId,
                  'class_id': item.classId,
                  'subject_id': item.subjectId,
                  'date': item.date,
                  'period_number': item.periodNumber,
                  'created_at': item.createdAt
                }),
        _staffAttendanceInsertionAdapter = InsertionAdapter(
            database,
            'staff_attendance',
            (StaffAttendance item) => <String, Object?>{
                  'id': item.id,
                  'staff_id': item.staffId,
                  'date': item.date,
                  'clock_in': item.clockIn,
                  'clock_out': item.clockOut,
                  'notes': item.notes
                }),
        _staffLeaveUpdateAdapter = UpdateAdapter(
            database,
            'staff_leaves',
            ['id'],
            (StaffLeave item) => <String, Object?>{
                  'id': item.id,
                  'staffId': item.staffId,
                  'leaveType': item.leaveType,
                  'startDate': item.startDate,
                  'endDate': item.endDate,
                  'reason': item.reason,
                  'status': item.status,
                  'approvedBy': item.approvedBy
                }),
        _staffAttendanceUpdateAdapter = UpdateAdapter(
            database,
            'staff_attendance',
            ['id'],
            (StaffAttendance item) => <String, Object?>{
                  'id': item.id,
                  'staff_id': item.staffId,
                  'date': item.date,
                  'clock_in': item.clockIn,
                  'clock_out': item.clockOut,
                  'notes': item.notes
                }),
        _substitutionDeletionAdapter = DeletionAdapter(
            database,
            'substitutions',
            ['id'],
            (Substitution item) => <String, Object?>{
                  'id': item.id,
                  'original_teacher_id': item.originalTeacherId,
                  'substitute_teacher_id': item.substituteTeacherId,
                  'class_id': item.classId,
                  'subject_id': item.subjectId,
                  'date': item.date,
                  'period_number': item.periodNumber,
                  'created_at': item.createdAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<TeachingAssignment>
      _teachingAssignmentInsertionAdapter;

  final InsertionAdapter<OfficialMemo> _officialMemoInsertionAdapter;

  final InsertionAdapter<MemoReadRecord> _memoReadRecordInsertionAdapter;

  final InsertionAdapter<StaffLeave> _staffLeaveInsertionAdapter;

  final InsertionAdapter<InventoryAsset> _inventoryAssetInsertionAdapter;

  final InsertionAdapter<AssetMaintenanceLog>
      _assetMaintenanceLogInsertionAdapter;

  final InsertionAdapter<SystemLog> _systemLogInsertionAdapter;

  final InsertionAdapter<Substitution> _substitutionInsertionAdapter;

  final InsertionAdapter<StaffAttendance> _staffAttendanceInsertionAdapter;

  final UpdateAdapter<StaffLeave> _staffLeaveUpdateAdapter;

  final UpdateAdapter<StaffAttendance> _staffAttendanceUpdateAdapter;

  final DeletionAdapter<Substitution> _substitutionDeletionAdapter;

  @override
  Future<List<TeachingAssignment>> findAssignmentsByTeacher(
      String teacherId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM teaching_assignments WHERE teacherId = ?1',
        mapper: (Map<String, Object?> row) => TeachingAssignment(
            id: row['id'] as String,
            teacherId: row['teacherId'] as String,
            classId: row['classId'] as String,
            subjectId: row['subjectId'] as String,
            academicYear: row['academicYear'] as int),
        arguments: [teacherId]);
  }

  @override
  Future<List<TeachingAssignment>> findAssignmentsByClass(
      String classId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM teaching_assignments WHERE classId = ?1',
        mapper: (Map<String, Object?> row) => TeachingAssignment(
            id: row['id'] as String,
            teacherId: row['teacherId'] as String,
            classId: row['classId'] as String,
            subjectId: row['subjectId'] as String,
            academicYear: row['academicYear'] as int),
        arguments: [classId]);
  }

  @override
  Future<List<OfficialMemo>> findAllMemos() async {
    return _queryAdapter.queryList(
        'SELECT * FROM official_memos ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => OfficialMemo(
            id: row['id'] as String,
            senderId: row['senderId'] as String,
            title: row['title'] as String,
            content: row['content'] as String,
            targetGroup: row['targetGroup'] as String,
            createdAt: row['createdAt'] as int,
            priority: row['priority'] as String));
  }

  @override
  Future<List<OfficialMemo>> findMemosForGroup(String group) async {
    return _queryAdapter.queryList(
        'SELECT * FROM official_memos WHERE targetGroup = ?1 OR targetGroup = \"ALL\" ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => OfficialMemo(id: row['id'] as String, senderId: row['senderId'] as String, title: row['title'] as String, content: row['content'] as String, targetGroup: row['targetGroup'] as String, createdAt: row['createdAt'] as int, priority: row['priority'] as String),
        arguments: [group]);
  }

  @override
  Future<int?> getMemoReadCount(String memoId) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM memo_reads WHERE memoId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [memoId]);
  }

  @override
  Future<List<StaffLeave>> findAllLeaves() async {
    return _queryAdapter.queryList(
        'SELECT * FROM staff_leaves ORDER BY startDate DESC',
        mapper: (Map<String, Object?> row) => StaffLeave(
            id: row['id'] as String,
            staffId: row['staffId'] as String,
            leaveType: row['leaveType'] as String,
            startDate: row['startDate'] as int,
            endDate: row['endDate'] as int,
            reason: row['reason'] as String,
            status: row['status'] as String,
            approvedBy: row['approvedBy'] as String?));
  }

  @override
  Future<List<StaffLeave>> findLeavesByStaff(String staffId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM staff_leaves WHERE staffId = ?1 ORDER BY startDate DESC',
        mapper: (Map<String, Object?> row) => StaffLeave(
            id: row['id'] as String,
            staffId: row['staffId'] as String,
            leaveType: row['leaveType'] as String,
            startDate: row['startDate'] as int,
            endDate: row['endDate'] as int,
            reason: row['reason'] as String,
            status: row['status'] as String,
            approvedBy: row['approvedBy'] as String?),
        arguments: [staffId]);
  }

  @override
  Future<List<StaffLeave>> findPendingLeaves() async {
    return _queryAdapter.queryList(
        'SELECT * FROM staff_leaves WHERE status = \"PENDING\"',
        mapper: (Map<String, Object?> row) => StaffLeave(
            id: row['id'] as String,
            staffId: row['staffId'] as String,
            leaveType: row['leaveType'] as String,
            startDate: row['startDate'] as int,
            endDate: row['endDate'] as int,
            reason: row['reason'] as String,
            status: row['status'] as String,
            approvedBy: row['approvedBy'] as String?));
  }

  @override
  Future<List<InventoryAsset>> findAllAssets() async {
    return _queryAdapter.queryList('SELECT * FROM inventory_assets',
        mapper: (Map<String, Object?> row) => InventoryAsset(
            id: row['id'] as String,
            name: row['name'] as String,
            category: row['category'] as String,
            location: row['location'] as String,
            quantity: row['quantity'] as int,
            condition: row['condition'] as String,
            unitCost: row['unit_cost'] as double?,
            purchaseDate: row['purchase_date'] as int?,
            assignedTo: row['assigned_to'] as String?));
  }

  @override
  Future<List<AssetMaintenanceLog>> findMaintenanceLogs(String assetId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM asset_maintenance_logs WHERE asset_id = ?1 ORDER BY serviced_at DESC',
        mapper: (Map<String, Object?> row) => AssetMaintenanceLog(id: row['id'] as String, assetId: row['asset_id'] as String, description: row['description'] as String, cost: row['cost'] as double, servicedAt: row['serviced_at'] as int, recordedBy: row['recorded_by'] as String),
        arguments: [assetId]);
  }

  @override
  Future<List<SystemLog>> getRecentLogs() async {
    return _queryAdapter.queryList(
        'SELECT * FROM system_activity_logs ORDER BY timestamp DESC LIMIT 100',
        mapper: (Map<String, Object?> row) => SystemLog(
            id: row['id'] as int?,
            userId: row['userId'] as String,
            action: row['action'] as String,
            module: row['module'] as String,
            details: row['details'] as String,
            timestamp: row['timestamp'] as int,
            ipAddress: row['ipAddress'] as String));
  }

  @override
  Future<List<Substitution>> findActiveSubstitutions(
    String teacherId,
    int date,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM substitutions WHERE substitute_teacher_id = ?1 AND date = ?2',
        mapper: (Map<String, Object?> row) => Substitution(id: row['id'] as String, originalTeacherId: row['original_teacher_id'] as String, substituteTeacherId: row['substitute_teacher_id'] as String, classId: row['class_id'] as String, subjectId: row['subject_id'] as String, date: row['date'] as int, periodNumber: row['period_number'] as int, createdAt: row['created_at'] as int),
        arguments: [teacherId, date]);
  }

  @override
  Future<List<Substitution>> findAllSubstitutionsByDate(int date) async {
    return _queryAdapter.queryList(
        'SELECT * FROM substitutions WHERE date = ?1',
        mapper: (Map<String, Object?> row) => Substitution(
            id: row['id'] as String,
            originalTeacherId: row['original_teacher_id'] as String,
            substituteTeacherId: row['substitute_teacher_id'] as String,
            classId: row['class_id'] as String,
            subjectId: row['subject_id'] as String,
            date: row['date'] as int,
            periodNumber: row['period_number'] as int,
            createdAt: row['created_at'] as int),
        arguments: [date]);
  }

  @override
  Future<StaffAttendance?> findStaffAttendance(
    String staffId,
    int date,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM staff_attendance WHERE staff_id = ?1 AND date = ?2',
        mapper: (Map<String, Object?> row) => StaffAttendance(
            id: row['id'] as String,
            staffId: row['staff_id'] as String,
            date: row['date'] as int,
            clockIn: row['clock_in'] as int,
            clockOut: row['clock_out'] as int?,
            notes: row['notes'] as String?),
        arguments: [staffId, date]);
  }

  @override
  Future<List<StaffAttendance>> findAllStaffAttendance(int date) async {
    return _queryAdapter.queryList(
        'SELECT * FROM staff_attendance WHERE date = ?1',
        mapper: (Map<String, Object?> row) => StaffAttendance(
            id: row['id'] as String,
            staffId: row['staff_id'] as String,
            date: row['date'] as int,
            clockIn: row['clock_in'] as int,
            clockOut: row['clock_out'] as int?,
            notes: row['notes'] as String?),
        arguments: [date]);
  }

  @override
  Future<void> insertAssignment(TeachingAssignment assignment) async {
    await _teachingAssignmentInsertionAdapter.insert(
        assignment, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertMemo(OfficialMemo memo) async {
    await _officialMemoInsertionAdapter.insert(memo, OnConflictStrategy.abort);
  }

  @override
  Future<void> logMemoRead(MemoReadRecord record) async {
    await _memoReadRecordInsertionAdapter.insert(
        record, OnConflictStrategy.abort);
  }

  @override
  Future<void> requestLeave(StaffLeave leave) async {
    await _staffLeaveInsertionAdapter.insert(leave, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertAsset(InventoryAsset asset) async {
    await _inventoryAssetInsertionAdapter.insert(
        asset, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertMaintenanceLog(AssetMaintenanceLog log) async {
    await _assetMaintenanceLogInsertionAdapter.insert(
        log, OnConflictStrategy.abort);
  }

  @override
  Future<void> logActivity(SystemLog log) async {
    await _systemLogInsertionAdapter.insert(log, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertSubstitution(Substitution substitution) async {
    await _substitutionInsertionAdapter.insert(
        substitution, OnConflictStrategy.abort);
  }

  @override
  Future<void> clockIn(StaffAttendance attendance) async {
    await _staffAttendanceInsertionAdapter.insert(
        attendance, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateLeave(StaffLeave leave) async {
    await _staffLeaveUpdateAdapter.update(leave, OnConflictStrategy.abort);
  }

  @override
  Future<void> clockOut(StaffAttendance attendance) async {
    await _staffAttendanceUpdateAdapter.update(
        attendance, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteSubstitution(Substitution substitution) async {
    await _substitutionDeletionAdapter.delete(substitution);
  }
}

class _$TimetableDao extends TimetableDao {
  _$TimetableDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _teacherTimetableProfileInsertionAdapter = InsertionAdapter(
            database,
            'teacher_timetable_profiles',
            (TeacherTimetableProfile item) => <String, Object?>{
                  'id': item.id,
                  'teacher_id': item.teacherId,
                  'max_periods_per_day': item.maxPeriodsPerDay,
                  'max_periods_per_week': item.maxPeriodsPerWeek,
                  'is_class_teacher': item.isClassTeacher ? 1 : 0,
                  'special_role': item.specialRole
                }),
        _teacherSubjectCapabilityInsertionAdapter = InsertionAdapter(
            database,
            'teacher_subject_capabilities',
            (TeacherSubjectCapability item) => <String, Object?>{
                  'id': item.id,
                  'teacher_id': item.teacherId,
                  'subject_id': item.subjectId,
                  'priority_level': item.priorityLevel
                }),
        _classSubjectRequirementInsertionAdapter = InsertionAdapter(
            database,
            'class_subject_requirements',
            (ClassSubjectRequirement item) => <String, Object?>{
                  'id': item.id,
                  'class_id': item.classId,
                  'subject_id': item.subjectId,
                  'periods_per_week': item.periodsPerWeek
                }),
        _timetableModelInsertionAdapter = InsertionAdapter(
            database,
            'timetables',
            (TimetableModel item) => <String, Object?>{
                  'id': item.id,
                  'academic_year': item.academicYear,
                  'term': item.term,
                  'is_active': item.isActive ? 1 : 0,
                  'created_at': item.createdAt
                }),
        _timetableSlotInsertionAdapter = InsertionAdapter(
            database,
            'timetable_slots',
            (TimetableSlot item) => <String, Object?>{
                  'id': item.id,
                  'timetable_id': item.timetableId,
                  'day_of_week': item.dayOfWeek,
                  'period_number': item.periodNumber,
                  'class_id': item.classId,
                  'subject_id': item.subjectId,
                  'teacher_id': item.teacherId,
                  'teacher_id_2': item.teacherId2,
                  'is_locked': item.isLocked ? 1 : 0
                }),
        _attendanceSessionModelInsertionAdapter = InsertionAdapter(
            database,
            'attendance_sessions',
            (AttendanceSessionModel item) => <String, Object?>{
                  'id': item.id,
                  'slot_id': item.slotId,
                  'teacher_id': item.teacherId,
                  'class_id': item.classId,
                  'subject_id': item.subjectId,
                  'period': item.period,
                  'date': item.date,
                  'is_substitute': item.isSubstitute ? 1 : 0,
                  'timestamp': item.timestamp
                }),
        _lessonExecutionModelInsertionAdapter = InsertionAdapter(
            database,
            'lesson_executions',
            (LessonExecutionModel item) => <String, Object?>{
                  'id': item.id,
                  'slot_id': item.slotId,
                  'attendance_session_id': item.attendanceSessionId,
                  'status': item.status,
                  'coverage_weight': item.coverageWeight,
                  'notes': item.notes,
                  'evidence_paths': item.evidencePaths,
                  'timestamp': item.timestamp
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<TeacherTimetableProfile>
      _teacherTimetableProfileInsertionAdapter;

  final InsertionAdapter<TeacherSubjectCapability>
      _teacherSubjectCapabilityInsertionAdapter;

  final InsertionAdapter<ClassSubjectRequirement>
      _classSubjectRequirementInsertionAdapter;

  final InsertionAdapter<TimetableModel> _timetableModelInsertionAdapter;

  final InsertionAdapter<TimetableSlot> _timetableSlotInsertionAdapter;

  final InsertionAdapter<AttendanceSessionModel>
      _attendanceSessionModelInsertionAdapter;

  final InsertionAdapter<LessonExecutionModel>
      _lessonExecutionModelInsertionAdapter;

  @override
  Future<List<TeacherTimetableProfile>> findAllTeacherProfiles() async {
    return _queryAdapter.queryList('SELECT * FROM teacher_timetable_profiles',
        mapper: (Map<String, Object?> row) => TeacherTimetableProfile(
            id: row['id'] as String,
            teacherId: row['teacher_id'] as String,
            maxPeriodsPerDay: row['max_periods_per_day'] as int,
            maxPeriodsPerWeek: row['max_periods_per_week'] as int,
            isClassTeacher: (row['is_class_teacher'] as int) != 0,
            specialRole: row['special_role'] as String?));
  }

  @override
  Future<TeacherTimetableProfile?> findTeacherProfileById(
      String teacherId) async {
    return _queryAdapter.query(
        'SELECT * FROM teacher_timetable_profiles WHERE teacher_id = ?1',
        mapper: (Map<String, Object?> row) => TeacherTimetableProfile(
            id: row['id'] as String,
            teacherId: row['teacher_id'] as String,
            maxPeriodsPerDay: row['max_periods_per_day'] as int,
            maxPeriodsPerWeek: row['max_periods_per_week'] as int,
            isClassTeacher: (row['is_class_teacher'] as int) != 0,
            specialRole: row['special_role'] as String?),
        arguments: [teacherId]);
  }

  @override
  Future<List<TeacherSubjectCapability>> findCapabilitiesByTeacher(
      String teacherId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM teacher_subject_capabilities WHERE teacher_id = ?1',
        mapper: (Map<String, Object?> row) => TeacherSubjectCapability(
            id: row['id'] as String,
            teacherId: row['teacher_id'] as String,
            subjectId: row['subject_id'] as String,
            priorityLevel: row['priority_level'] as int),
        arguments: [teacherId]);
  }

  @override
  Future<List<TeacherSubjectCapability>> findAllCapabilities() async {
    return _queryAdapter.queryList('SELECT * FROM teacher_subject_capabilities',
        mapper: (Map<String, Object?> row) => TeacherSubjectCapability(
            id: row['id'] as String,
            teacherId: row['teacher_id'] as String,
            subjectId: row['subject_id'] as String,
            priorityLevel: row['priority_level'] as int));
  }

  @override
  Future<List<ClassSubjectRequirement>> findAllClassRequirements() async {
    return _queryAdapter.queryList('SELECT * FROM class_subject_requirements',
        mapper: (Map<String, Object?> row) => ClassSubjectRequirement(
            id: row['id'] as String,
            classId: row['class_id'] as String,
            subjectId: row['subject_id'] as String,
            periodsPerWeek: row['periods_per_week'] as int));
  }

  @override
  Future<List<ClassSubjectRequirement>> findRequirementsByClass(
      String classId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM class_subject_requirements WHERE class_id = ?1',
        mapper: (Map<String, Object?> row) => ClassSubjectRequirement(
            id: row['id'] as String,
            classId: row['class_id'] as String,
            subjectId: row['subject_id'] as String,
            periodsPerWeek: row['periods_per_week'] as int),
        arguments: [classId]);
  }

  @override
  Future<TimetableModel?> getActiveTimetable() async {
    return _queryAdapter.query(
        'SELECT * FROM timetables WHERE is_active = 1 ORDER BY created_at DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => TimetableModel(
            id: row['id'] as String,
            academicYear: row['academic_year'] as String,
            term: row['term'] as String,
            isActive: (row['is_active'] as int) != 0,
            createdAt: row['created_at'] as int));
  }

  @override
  Future<void> deactivateAllTimetables() async {
    await _queryAdapter.queryNoReturn('UPDATE timetables SET is_active = 0');
  }

  @override
  Future<void> clearAllTimetables() async {
    await _queryAdapter.queryNoReturn('DELETE FROM timetables');
  }

  @override
  Future<TimetableSlot?> findSlotById(String id) async {
    return _queryAdapter.query('SELECT * FROM timetable_slots WHERE id = ?1',
        mapper: (Map<String, Object?> row) => TimetableSlot(
            id: row['id'] as String,
            timetableId: row['timetable_id'] as String,
            dayOfWeek: row['day_of_week'] as int,
            periodNumber: row['period_number'] as int,
            classId: row['class_id'] as String,
            subjectId: row['subject_id'] as String,
            teacherId: row['teacher_id'] as String,
            teacherId2: row['teacher_id_2'] as String?,
            isLocked: (row['is_locked'] as int) != 0),
        arguments: [id]);
  }

  @override
  Future<List<TimetableSlot>> getSlotsForTimetable(String timetableId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM timetable_slots WHERE timetable_id = ?1',
        mapper: (Map<String, Object?> row) => TimetableSlot(
            id: row['id'] as String,
            timetableId: row['timetable_id'] as String,
            dayOfWeek: row['day_of_week'] as int,
            periodNumber: row['period_number'] as int,
            classId: row['class_id'] as String,
            subjectId: row['subject_id'] as String,
            teacherId: row['teacher_id'] as String,
            teacherId2: row['teacher_id_2'] as String?,
            isLocked: (row['is_locked'] as int) != 0),
        arguments: [timetableId]);
  }

  @override
  Future<List<TimetableSlot>> getSlotsForClass(
    String timetableId,
    String classId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM timetable_slots WHERE timetable_id = ?1 AND class_id = ?2',
        mapper: (Map<String, Object?> row) => TimetableSlot(id: row['id'] as String, timetableId: row['timetable_id'] as String, dayOfWeek: row['day_of_week'] as int, periodNumber: row['period_number'] as int, classId: row['class_id'] as String, subjectId: row['subject_id'] as String, teacherId: row['teacher_id'] as String, teacherId2: row['teacher_id_2'] as String?, isLocked: (row['is_locked'] as int) != 0),
        arguments: [timetableId, classId]);
  }

  @override
  Future<List<TimetableSlot>> getSlotsForTeacher(
    String timetableId,
    String teacherId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM timetable_slots WHERE timetable_id = ?1 AND (teacher_id = ?2 OR teacher_id_2 = ?2)',
        mapper: (Map<String, Object?> row) => TimetableSlot(id: row['id'] as String, timetableId: row['timetable_id'] as String, dayOfWeek: row['day_of_week'] as int, periodNumber: row['period_number'] as int, classId: row['class_id'] as String, subjectId: row['subject_id'] as String, teacherId: row['teacher_id'] as String, teacherId2: row['teacher_id_2'] as String?, isLocked: (row['is_locked'] as int) != 0),
        arguments: [timetableId, teacherId]);
  }

  @override
  Future<void> clearSlotsForTimetable(String timetableId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM timetable_slots WHERE timetable_id = ?1',
        arguments: [timetableId]);
  }

  @override
  Future<void> clearAllTeacherProfiles() async {
    await _queryAdapter.queryNoReturn('DELETE FROM teacher_timetable_profiles');
  }

  @override
  Future<void> clearAllCapabilities() async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM teacher_subject_capabilities');
  }

  @override
  Future<void> clearAllRequirements() async {
    await _queryAdapter.queryNoReturn('DELETE FROM class_subject_requirements');
  }

  @override
  Future<AttendanceSessionModel?> findSessionBySlotAndDate(
    String slotId,
    String date,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM attendance_sessions WHERE slot_id = ?1 AND date = ?2',
        mapper: (Map<String, Object?> row) => AttendanceSessionModel(
            id: row['id'] as String,
            slotId: row['slot_id'] as String,
            teacherId: row['teacher_id'] as String,
            classId: row['class_id'] as String,
            subjectId: row['subject_id'] as String,
            period: row['period'] as int,
            date: row['date'] as String,
            isSubstitute: (row['is_substitute'] as int) != 0,
            timestamp: row['timestamp'] as int),
        arguments: [slotId, date]);
  }

  @override
  Future<LessonExecutionModel?> findExecutionBySession(String sessionId) async {
    return _queryAdapter.query(
        'SELECT * FROM lesson_executions WHERE attendance_session_id = ?1',
        mapper: (Map<String, Object?> row) => LessonExecutionModel(
            id: row['id'] as String,
            slotId: row['slot_id'] as String,
            attendanceSessionId: row['attendance_session_id'] as String,
            status: row['status'] as String,
            coverageWeight: row['coverage_weight'] as double,
            notes: row['notes'] as String?,
            evidencePaths: row['evidence_paths'] as String?,
            timestamp: row['timestamp'] as int),
        arguments: [sessionId]);
  }

  @override
  Future<int?> getCompletedLessonsCount(
    String classId,
    String subjectId,
  ) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM lesson_executions le     JOIN attendance_sessions asess ON le.attendance_session_id = asess.id     WHERE asess.class_id = ?1      AND asess.subject_id = ?2      AND le.status = \'Completed\'',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [classId, subjectId]);
  }

  @override
  Future<void> insertTeacherProfile(TeacherTimetableProfile profile) async {
    await _teacherTimetableProfileInsertionAdapter.insert(
        profile, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertTeacherCapability(
      TeacherSubjectCapability capability) async {
    await _teacherSubjectCapabilityInsertionAdapter.insert(
        capability, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertClassRequirement(
      ClassSubjectRequirement requirement) async {
    await _classSubjectRequirementInsertionAdapter.insert(
        requirement, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertTimetable(TimetableModel timetable) async {
    await _timetableModelInsertionAdapter.insert(
        timetable, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertTimetableSlots(List<TimetableSlot> slots) async {
    await _timetableSlotInsertionAdapter.insertList(
        slots, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertAttendanceSession(AttendanceSessionModel session) async {
    await _attendanceSessionModelInsertionAdapter.insert(
        session, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertLessonExecution(LessonExecutionModel execution) async {
    await _lessonExecutionModelInsertionAdapter.insert(
        execution, OnConflictStrategy.replace);
  }
}

class _$MessagingDao extends MessagingDao {
  _$MessagingDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _messageModelInsertionAdapter = InsertionAdapter(
            database,
            'messages',
            (MessageModel item) => <String, Object?>{
                  'id': item.id,
                  'sender_id': item.senderId,
                  'recipient_id': item.recipientId,
                  'message_type': item.messageType,
                  'subject': item.subject,
                  'body': item.body,
                  'sent_at': item.sentAt,
                  'read_at': item.readAt,
                  'synced': item.synced
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<MessageModel> _messageModelInsertionAdapter;

  @override
  Future<List<MessageModel>> findAllUserMessages(String userId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM messages WHERE recipient_id = ?1 OR sender_id = ?1 OR recipient_id IS NULL ORDER BY sent_at DESC',
        mapper: (Map<String, Object?> row) => MessageModel(id: row['id'] as String, senderId: row['sender_id'] as String, recipientId: row['recipient_id'] as String?, messageType: row['message_type'] as String, subject: row['subject'] as String?, body: row['body'] as String, sentAt: row['sent_at'] as int, readAt: row['read_at'] as int?, synced: row['synced'] as int),
        arguments: [userId]);
  }

  @override
  Future<List<MessageModel>> findInbox(String userId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM messages WHERE recipient_id = ?1 OR recipient_id IS NULL ORDER BY sent_at DESC',
        mapper: (Map<String, Object?> row) => MessageModel(id: row['id'] as String, senderId: row['sender_id'] as String, recipientId: row['recipient_id'] as String?, messageType: row['message_type'] as String, subject: row['subject'] as String?, body: row['body'] as String, sentAt: row['sent_at'] as int, readAt: row['read_at'] as int?, synced: row['synced'] as int),
        arguments: [userId]);
  }

  @override
  Future<List<MessageModel>> findSent(String userId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM messages WHERE sender_id = ?1 ORDER BY sent_at DESC',
        mapper: (Map<String, Object?> row) => MessageModel(
            id: row['id'] as String,
            senderId: row['sender_id'] as String,
            recipientId: row['recipient_id'] as String?,
            messageType: row['message_type'] as String,
            subject: row['subject'] as String?,
            body: row['body'] as String,
            sentAt: row['sent_at'] as int,
            readAt: row['read_at'] as int?,
            synced: row['synced'] as int),
        arguments: [userId]);
  }

  @override
  Future<List<MessageModel>> findOfficialMemos() async {
    return _queryAdapter.queryList(
        'SELECT * FROM messages WHERE message_type = \"Broadcast\" ORDER BY sent_at DESC',
        mapper: (Map<String, Object?> row) => MessageModel(
            id: row['id'] as String,
            senderId: row['sender_id'] as String,
            recipientId: row['recipient_id'] as String?,
            messageType: row['message_type'] as String,
            subject: row['subject'] as String?,
            body: row['body'] as String,
            sentAt: row['sent_at'] as int,
            readAt: row['read_at'] as int?,
            synced: row['synced'] as int));
  }

  @override
  Future<void> markRead(
    String id,
    int readAt,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE messages SET read_at = ?2 WHERE id = ?1',
        arguments: [id, readAt]);
  }

  @override
  Future<int?> countUnread(String userId) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM messages WHERE recipient_id = ?1 AND read_at IS NULL',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [userId]);
  }

  @override
  Future<void> insertMessage(MessageModel message) async {
    await _messageModelInsertionAdapter.insert(
        message, OnConflictStrategy.abort);
  }
}

class _$ChatDao extends ChatDao {
  _$ChatDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _chatMessageInsertionAdapter = InsertionAdapter(
            database,
            'chat_messages',
            (ChatMessage item) => <String, Object?>{
                  'id': item.id,
                  'sender_id': item.senderId,
                  'receiver_id': item.receiverId,
                  'group_id': item.groupId,
                  'message': item.message,
                  'file_path': item.filePath,
                  'file_name': item.fileName,
                  'file_type': item.fileType,
                  'reply_to_id': item.replyToId,
                  'status': item.status,
                  'timestamp': item.timestamp,
                  'is_deleted': item.isDeleted
                }),
        _chatGroupInsertionAdapter = InsertionAdapter(
            database,
            'chat_groups',
            (ChatGroup item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'type': item.type,
                  'dept_id': item.deptId,
                  'created_by': item.createdBy,
                  'created_at': item.createdAt,
                  'icon_code': item.iconCode
                }),
        _chatGroupMemberInsertionAdapter = InsertionAdapter(
            database,
            'chat_group_members',
            (ChatGroupMember item) => <String, Object?>{
                  'id': item.id,
                  'group_id': item.groupId,
                  'user_id': item.userId,
                  'joined_at': item.joinedAt
                }),
        _chatReadReceiptInsertionAdapter = InsertionAdapter(
            database,
            'chat_read_receipts',
            (ChatReadReceipt item) => <String, Object?>{
                  'id': item.id,
                  'message_id': item.messageId,
                  'user_id': item.userId,
                  'read_at': item.readAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ChatMessage> _chatMessageInsertionAdapter;

  final InsertionAdapter<ChatGroup> _chatGroupInsertionAdapter;

  final InsertionAdapter<ChatGroupMember> _chatGroupMemberInsertionAdapter;

  final InsertionAdapter<ChatReadReceipt> _chatReadReceiptInsertionAdapter;

  @override
  Future<List<ChatMessage>> findDirectMessages(
    String userA,
    String userB,
    int limit,
    int offset,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM chat_messages      WHERE is_deleted = 0        AND ((sender_id = ?1 AND receiver_id = ?2)          OR (sender_id = ?2 AND receiver_id = ?1))     ORDER BY timestamp ASC     LIMIT ?3 OFFSET ?4',
        mapper: (Map<String, Object?> row) => ChatMessage(id: row['id'] as String, senderId: row['sender_id'] as String, receiverId: row['receiver_id'] as String?, groupId: row['group_id'] as String?, message: row['message'] as String, filePath: row['file_path'] as String?, fileName: row['file_name'] as String?, fileType: row['file_type'] as String?, replyToId: row['reply_to_id'] as String?, status: row['status'] as String, timestamp: row['timestamp'] as int, isDeleted: row['is_deleted'] as int),
        arguments: [userA, userB, limit, offset]);
  }

  @override
  Future<List<ChatMessage>> findGroupMessages(
    String groupId,
    int limit,
    int offset,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM chat_messages      WHERE is_deleted = 0 AND group_id = ?1      ORDER BY timestamp ASC     LIMIT ?2 OFFSET ?3',
        mapper: (Map<String, Object?> row) => ChatMessage(id: row['id'] as String, senderId: row['sender_id'] as String, receiverId: row['receiver_id'] as String?, groupId: row['group_id'] as String?, message: row['message'] as String, filePath: row['file_path'] as String?, fileName: row['file_name'] as String?, fileType: row['file_type'] as String?, replyToId: row['reply_to_id'] as String?, status: row['status'] as String, timestamp: row['timestamp'] as int, isDeleted: row['is_deleted'] as int),
        arguments: [groupId, limit, offset]);
  }

  @override
  Future<void> updateMessageStatus(
    String id,
    String status,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE chat_messages SET status = ?2 WHERE id = ?1',
        arguments: [id, status]);
  }

  @override
  Future<void> deleteMessage(String id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE chat_messages SET is_deleted = 1 WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<int?> countUnreadDirect(String userId) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM chat_messages      WHERE receiver_id = ?1 AND status != \"read\" AND is_deleted = 0 AND group_id IS NULL',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [userId]);
  }

  @override
  Future<ChatMessage?> getLastDirectMessage(
    String userA,
    String userB,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM chat_messages      WHERE is_deleted = 0        AND ((sender_id = ?1 AND receiver_id = ?2)          OR (sender_id = ?2 AND receiver_id = ?1))     ORDER BY timestamp DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => ChatMessage(id: row['id'] as String, senderId: row['sender_id'] as String, receiverId: row['receiver_id'] as String?, groupId: row['group_id'] as String?, message: row['message'] as String, filePath: row['file_path'] as String?, fileName: row['file_name'] as String?, fileType: row['file_type'] as String?, replyToId: row['reply_to_id'] as String?, status: row['status'] as String, timestamp: row['timestamp'] as int, isDeleted: row['is_deleted'] as int),
        arguments: [userA, userB]);
  }

  @override
  Future<ChatMessage?> getLastGroupMessage(String groupId) async {
    return _queryAdapter.query(
        'SELECT * FROM chat_messages      WHERE is_deleted = 0 AND group_id = ?1      ORDER BY timestamp DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => ChatMessage(id: row['id'] as String, senderId: row['sender_id'] as String, receiverId: row['receiver_id'] as String?, groupId: row['group_id'] as String?, message: row['message'] as String, filePath: row['file_path'] as String?, fileName: row['file_name'] as String?, fileType: row['file_type'] as String?, replyToId: row['reply_to_id'] as String?, status: row['status'] as String, timestamp: row['timestamp'] as int, isDeleted: row['is_deleted'] as int),
        arguments: [groupId]);
  }

  @override
  Future<List<ChatMessage>> getRecentDirectConversations(String userId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM chat_messages      WHERE is_deleted = 0        AND (sender_id = ?1 OR receiver_id = ?1)       AND group_id IS NULL     GROUP BY CASE        WHEN sender_id = ?1 THEN receiver_id        ELSE sender_id END     ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => ChatMessage(id: row['id'] as String, senderId: row['sender_id'] as String, receiverId: row['receiver_id'] as String?, groupId: row['group_id'] as String?, message: row['message'] as String, filePath: row['file_path'] as String?, fileName: row['file_name'] as String?, fileType: row['file_type'] as String?, replyToId: row['reply_to_id'] as String?, status: row['status'] as String, timestamp: row['timestamp'] as int, isDeleted: row['is_deleted'] as int),
        arguments: [userId]);
  }

  @override
  Future<int?> countUnreadFromUser(
    String userId,
    String otherUserId,
  ) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM chat_messages      WHERE is_deleted = 0 AND receiver_id = ?1 AND sender_id = ?2 AND status != \'read\'',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [userId, otherUserId]);
  }

  @override
  Future<List<ChatGroup>> getAllGroups() async {
    return _queryAdapter.queryList(
        'SELECT * FROM chat_groups ORDER BY name ASC',
        mapper: (Map<String, Object?> row) => ChatGroup(
            id: row['id'] as String,
            name: row['name'] as String,
            type: row['type'] as String,
            deptId: row['dept_id'] as String?,
            createdBy: row['created_by'] as String,
            createdAt: row['created_at'] as int,
            iconCode: row['icon_code'] as int?));
  }

  @override
  Future<ChatGroup?> getGroupById(String id) async {
    return _queryAdapter.query('SELECT * FROM chat_groups WHERE id = ?1',
        mapper: (Map<String, Object?> row) => ChatGroup(
            id: row['id'] as String,
            name: row['name'] as String,
            type: row['type'] as String,
            deptId: row['dept_id'] as String?,
            createdBy: row['created_by'] as String,
            createdAt: row['created_at'] as int,
            iconCode: row['icon_code'] as int?),
        arguments: [id]);
  }

  @override
  Future<List<ChatGroupMember>> getGroupMembers(String groupId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM chat_group_members WHERE group_id = ?1',
        mapper: (Map<String, Object?> row) => ChatGroupMember(
            id: row['id'] as int?,
            groupId: row['group_id'] as String,
            userId: row['user_id'] as String,
            joinedAt: row['joined_at'] as int),
        arguments: [groupId]);
  }

  @override
  Future<List<ChatGroupMember>> getGroupsForUser(String userId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM chat_group_members WHERE user_id = ?1',
        mapper: (Map<String, Object?> row) => ChatGroupMember(
            id: row['id'] as int?,
            groupId: row['group_id'] as String,
            userId: row['user_id'] as String,
            joinedAt: row['joined_at'] as int),
        arguments: [userId]);
  }

  @override
  Future<int?> isMemberOfGroup(
    String groupId,
    String userId,
  ) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM chat_group_members WHERE group_id = ?1 AND user_id = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [groupId, userId]);
  }

  @override
  Future<int?> hasReadMessage(
    String messageId,
    String userId,
  ) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM chat_read_receipts WHERE message_id = ?1 AND user_id = ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [messageId, userId]);
  }

  @override
  Future<void> insertMessage(ChatMessage message) async {
    await _chatMessageInsertionAdapter.insert(
        message, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertGroup(ChatGroup group) async {
    await _chatGroupInsertionAdapter.insert(group, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertGroupMember(ChatGroupMember member) async {
    await _chatGroupMemberInsertionAdapter.insert(
        member, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertReadReceipt(ChatReadReceipt receipt) async {
    await _chatReadReceiptInsertionAdapter.insert(
        receipt, OnConflictStrategy.abort);
  }
}

class _$CalendarDao extends CalendarDao {
  _$CalendarDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _calendarEventInsertionAdapter = InsertionAdapter(
            database,
            'calendar_events',
            (CalendarEvent item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'event_type': item.eventType,
                  'start_date': item.startDate,
                  'end_date': item.endDate,
                  'description': item.description,
                  'priority': item.priority,
                  'created_by': item.createdBy,
                  'created_at': item.createdAt,
                  'reminder_days': item.reminderDays
                }),
        _calendarEventUpdateAdapter = UpdateAdapter(
            database,
            'calendar_events',
            ['id'],
            (CalendarEvent item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'event_type': item.eventType,
                  'start_date': item.startDate,
                  'end_date': item.endDate,
                  'description': item.description,
                  'priority': item.priority,
                  'created_by': item.createdBy,
                  'created_at': item.createdAt,
                  'reminder_days': item.reminderDays
                }),
        _calendarEventDeletionAdapter = DeletionAdapter(
            database,
            'calendar_events',
            ['id'],
            (CalendarEvent item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'event_type': item.eventType,
                  'start_date': item.startDate,
                  'end_date': item.endDate,
                  'description': item.description,
                  'priority': item.priority,
                  'created_by': item.createdBy,
                  'created_at': item.createdAt,
                  'reminder_days': item.reminderDays
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CalendarEvent> _calendarEventInsertionAdapter;

  final UpdateAdapter<CalendarEvent> _calendarEventUpdateAdapter;

  final DeletionAdapter<CalendarEvent> _calendarEventDeletionAdapter;

  @override
  Future<List<CalendarEvent>> getAllEvents() async {
    return _queryAdapter.queryList(
        'SELECT * FROM calendar_events ORDER BY start_date ASC',
        mapper: (Map<String, Object?> row) => CalendarEvent(
            id: row['id'] as String,
            title: row['title'] as String,
            eventType: row['event_type'] as String,
            startDate: row['start_date'] as int,
            endDate: row['end_date'] as int,
            description: row['description'] as String?,
            priority: row['priority'] as String,
            createdBy: row['created_by'] as String,
            createdAt: row['created_at'] as int,
            reminderDays: row['reminder_days'] as int));
  }

  @override
  Future<List<CalendarEvent>> getEventsInRange(
    int fromMs,
    int toMs,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM calendar_events      WHERE start_date >= ?1 AND start_date <= ?2      ORDER BY start_date ASC',
        mapper: (Map<String, Object?> row) => CalendarEvent(id: row['id'] as String, title: row['title'] as String, eventType: row['event_type'] as String, startDate: row['start_date'] as int, endDate: row['end_date'] as int, description: row['description'] as String?, priority: row['priority'] as String, createdBy: row['created_by'] as String, createdAt: row['created_at'] as int, reminderDays: row['reminder_days'] as int),
        arguments: [fromMs, toMs]);
  }

  @override
  Future<List<CalendarEvent>> getUpcomingEvents(int nowMs) async {
    return _queryAdapter.queryList(
        'SELECT * FROM calendar_events      WHERE start_date >= ?1      ORDER BY start_date ASC',
        mapper: (Map<String, Object?> row) => CalendarEvent(id: row['id'] as String, title: row['title'] as String, eventType: row['event_type'] as String, startDate: row['start_date'] as int, endDate: row['end_date'] as int, description: row['description'] as String?, priority: row['priority'] as String, createdBy: row['created_by'] as String, createdAt: row['created_at'] as int, reminderDays: row['reminder_days'] as int),
        arguments: [nowMs]);
  }

  @override
  Future<CalendarEvent?> getEventById(String id) async {
    return _queryAdapter.query('SELECT * FROM calendar_events WHERE id = ?1',
        mapper: (Map<String, Object?> row) => CalendarEvent(
            id: row['id'] as String,
            title: row['title'] as String,
            eventType: row['event_type'] as String,
            startDate: row['start_date'] as int,
            endDate: row['end_date'] as int,
            description: row['description'] as String?,
            priority: row['priority'] as String,
            createdBy: row['created_by'] as String,
            createdAt: row['created_at'] as int,
            reminderDays: row['reminder_days'] as int),
        arguments: [id]);
  }

  @override
  Future<List<CalendarEvent>> getEventsForMonth(
    int fromMs,
    int toMs,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM calendar_events      WHERE start_date BETWEEN ?1 AND ?2     ORDER BY start_date ASC',
        mapper: (Map<String, Object?> row) => CalendarEvent(id: row['id'] as String, title: row['title'] as String, eventType: row['event_type'] as String, startDate: row['start_date'] as int, endDate: row['end_date'] as int, description: row['description'] as String?, priority: row['priority'] as String, createdBy: row['created_by'] as String, createdAt: row['created_at'] as int, reminderDays: row['reminder_days'] as int),
        arguments: [fromMs, toMs]);
  }

  @override
  Future<void> insertEvent(CalendarEvent event) async {
    await _calendarEventInsertionAdapter.insert(
        event, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    await _calendarEventUpdateAdapter.update(event, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteEvent(CalendarEvent event) async {
    await _calendarEventDeletionAdapter.delete(event);
  }
}

class _$NotificationDao extends NotificationDao {
  _$NotificationDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _appNotificationInsertionAdapter = InsertionAdapter(
            database,
            'app_notifications',
            (AppNotification item) => <String, Object?>{
                  'id': item.id,
                  'user_id': item.userId,
                  'title': item.title,
                  'message': item.message,
                  'link': item.link,
                  'notif_type': item.notifType,
                  'reference_id': item.referenceId,
                  'is_read': item.isRead,
                  'created_at': item.createdAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<AppNotification> _appNotificationInsertionAdapter;

  @override
  Future<List<AppNotification>> getNotificationsForUser(String userId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM app_notifications WHERE user_id = ?1 ORDER BY created_at DESC LIMIT 50',
        mapper: (Map<String, Object?> row) => AppNotification(id: row['id'] as int?, userId: row['user_id'] as String, title: row['title'] as String, message: row['message'] as String, link: row['link'] as String?, notifType: row['notif_type'] as String, referenceId: row['reference_id'] as String?, isRead: row['is_read'] as int, createdAt: row['created_at'] as int),
        arguments: [userId]);
  }

  @override
  Future<int?> countUnread(String userId) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM app_notifications WHERE user_id = ?1 AND is_read = 0',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [userId]);
  }

  @override
  Future<void> markRead(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE app_notifications SET is_read = 1 WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<void> markAllRead(String userId) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE app_notifications SET is_read = 1 WHERE user_id = ?1',
        arguments: [userId]);
  }

  @override
  Future<void> pruneOldNotifications(int olderThanMs) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM app_notifications WHERE created_at < ?1',
        arguments: [olderThanMs]);
  }

  @override
  Future<void> insertNotification(AppNotification notification) async {
    await _appNotificationInsertionAdapter.insert(
        notification, OnConflictStrategy.abort);
  }
}

class _$DepartmentDao extends DepartmentDao {
  _$DepartmentDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _departmentModelInsertionAdapter = InsertionAdapter(
            database,
            'departments',
            (DepartmentModel item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'description': item.description,
                  'created_by': item.createdBy,
                  'created_at': item.createdAt,
                  'status': item.status
                }),
        _departmentMemberModelInsertionAdapter = InsertionAdapter(
            database,
            'department_members',
            (DepartmentMemberModel item) => <String, Object?>{
                  'id': item.id,
                  'department_id': item.departmentId,
                  'teacher_id': item.teacherId,
                  'role': item.role,
                  'assigned_at': item.assignedAt
                }),
        _subjectTermApprovalModelInsertionAdapter = InsertionAdapter(
            database,
            'subject_term_approvals',
            (SubjectTermApprovalModel item) => <String, Object?>{
                  'id': item.id,
                  'class_id': item.classId,
                  'subject_id': item.subjectId,
                  'term': item.term,
                  'year': item.year,
                  'status': item.status,
                  'teacher_id': item.teacherId,
                  'last_updated': item.lastUpdated
                }),
        _approvalLogModelInsertionAdapter = InsertionAdapter(
            database,
            'approval_logs',
            (ApprovalLogModel item) => <String, Object?>{
                  'id': item.id,
                  'entity_type': item.entityType,
                  'entity_id': item.entityId,
                  'action': item.action,
                  'performed_by': item.performedBy,
                  'comments': item.comments,
                  'timestamp': item.timestamp
                }),
        _departmentModelUpdateAdapter = UpdateAdapter(
            database,
            'departments',
            ['id'],
            (DepartmentModel item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'description': item.description,
                  'created_by': item.createdBy,
                  'created_at': item.createdAt,
                  'status': item.status
                }),
        _subjectTermApprovalModelUpdateAdapter = UpdateAdapter(
            database,
            'subject_term_approvals',
            ['id'],
            (SubjectTermApprovalModel item) => <String, Object?>{
                  'id': item.id,
                  'class_id': item.classId,
                  'subject_id': item.subjectId,
                  'term': item.term,
                  'year': item.year,
                  'status': item.status,
                  'teacher_id': item.teacherId,
                  'last_updated': item.lastUpdated
                }),
        _departmentMemberModelDeletionAdapter = DeletionAdapter(
            database,
            'department_members',
            ['id'],
            (DepartmentMemberModel item) => <String, Object?>{
                  'id': item.id,
                  'department_id': item.departmentId,
                  'teacher_id': item.teacherId,
                  'role': item.role,
                  'assigned_at': item.assignedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DepartmentModel> _departmentModelInsertionAdapter;

  final InsertionAdapter<DepartmentMemberModel>
      _departmentMemberModelInsertionAdapter;

  final InsertionAdapter<SubjectTermApprovalModel>
      _subjectTermApprovalModelInsertionAdapter;

  final InsertionAdapter<ApprovalLogModel> _approvalLogModelInsertionAdapter;

  final UpdateAdapter<DepartmentModel> _departmentModelUpdateAdapter;

  final UpdateAdapter<SubjectTermApprovalModel>
      _subjectTermApprovalModelUpdateAdapter;

  final DeletionAdapter<DepartmentMemberModel>
      _departmentMemberModelDeletionAdapter;

  @override
  Future<List<DepartmentModel>> getAllActiveDepartments() async {
    return _queryAdapter.queryList(
        'SELECT * FROM departments WHERE status = \'active\'',
        mapper: (Map<String, Object?> row) => DepartmentModel(
            id: row['id'] as String,
            name: row['name'] as String,
            description: row['description'] as String,
            createdBy: row['created_by'] as String,
            createdAt: row['created_at'] as int,
            status: row['status'] as String));
  }

  @override
  Future<DepartmentModel?> getDepartmentById(String id) async {
    return _queryAdapter.query('SELECT * FROM departments WHERE id = ?1',
        mapper: (Map<String, Object?> row) => DepartmentModel(
            id: row['id'] as String,
            name: row['name'] as String,
            description: row['description'] as String,
            createdBy: row['created_by'] as String,
            createdAt: row['created_at'] as int,
            status: row['status'] as String),
        arguments: [id]);
  }

  @override
  Future<List<DepartmentMemberModel>> getMembersByDepartment(
      String deptId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM department_members WHERE department_id = ?1',
        mapper: (Map<String, Object?> row) => DepartmentMemberModel(
            id: row['id'] as int?,
            departmentId: row['department_id'] as String,
            teacherId: row['teacher_id'] as String,
            role: row['role'] as String,
            assignedAt: row['assigned_at'] as int),
        arguments: [deptId]);
  }

  @override
  Future<List<DepartmentMemberModel>> getDepartmentsByTeacher(
      String teacherId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM department_members WHERE teacher_id = ?1',
        mapper: (Map<String, Object?> row) => DepartmentMemberModel(
            id: row['id'] as int?,
            departmentId: row['department_id'] as String,
            teacherId: row['teacher_id'] as String,
            role: row['role'] as String,
            assignedAt: row['assigned_at'] as int),
        arguments: [teacherId]);
  }

  @override
  Future<List<LearningAreaModel>> getSubjectsByDepartment(String deptId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM learning_areas WHERE department_id = ?1',
        mapper: (Map<String, Object?> row) => LearningAreaModel(
            id: row['id'] as String,
            name: row['name'] as String,
            gradeBand: row['grade_band'] as String,
            category: row['category'] as String,
            departmentId: row['department_id'] as String?),
        arguments: [deptId]);
  }

  @override
  Future<SubjectTermApprovalModel?> getTermApprovalById(String id) async {
    return _queryAdapter.query(
        'SELECT * FROM subject_term_approvals WHERE id = ?1',
        mapper: (Map<String, Object?> row) => SubjectTermApprovalModel(
            id: row['id'] as String,
            classId: row['class_id'] as String,
            subjectId: row['subject_id'] as String,
            term: row['term'] as int,
            year: row['year'] as String,
            status: row['status'] as String,
            teacherId: row['teacher_id'] as String,
            lastUpdated: row['last_updated'] as int),
        arguments: [id]);
  }

  @override
  Future<SubjectTermApprovalModel?> getStatus(
    String classId,
    String subjectId,
    int term,
    String year,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM subject_term_approvals WHERE class_id = ?1 AND subject_id = ?2 AND term = ?3 AND year = ?4',
        mapper: (Map<String, Object?> row) => SubjectTermApprovalModel(id: row['id'] as String, classId: row['class_id'] as String, subjectId: row['subject_id'] as String, term: row['term'] as int, year: row['year'] as String, status: row['status'] as String, teacherId: row['teacher_id'] as String, lastUpdated: row['last_updated'] as int),
        arguments: [classId, subjectId, term, year]);
  }

  @override
  Future<List<SubjectTermApprovalModel>> getApprovalsByStatus(
      String status) async {
    return _queryAdapter.queryList(
        'SELECT * FROM subject_term_approvals WHERE status = ?1',
        mapper: (Map<String, Object?> row) => SubjectTermApprovalModel(
            id: row['id'] as String,
            classId: row['class_id'] as String,
            subjectId: row['subject_id'] as String,
            term: row['term'] as int,
            year: row['year'] as String,
            status: row['status'] as String,
            teacherId: row['teacher_id'] as String,
            lastUpdated: row['last_updated'] as int),
        arguments: [status]);
  }

  @override
  Future<List<ApprovalLogModel>> getLogsForEntity(String entityId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM approval_logs WHERE entity_id = ?1 ORDER BY timestamp DESC',
        mapper: (Map<String, Object?> row) => ApprovalLogModel(id: row['id'] as int?, entityType: row['entity_type'] as String, entityId: row['entity_id'] as String, action: row['action'] as String, performedBy: row['performed_by'] as String, comments: row['comments'] as String?, timestamp: row['timestamp'] as int),
        arguments: [entityId]);
  }

  @override
  Future<void> clearHOD(String deptId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM department_members WHERE department_id = ?1 AND (role = \'hod\' OR role = \'HOD\')',
        arguments: [deptId]);
  }

  @override
  Future<List<DepartmentModel>> getAllDepartments() async {
    return _queryAdapter.queryList('SELECT * FROM departments',
        mapper: (Map<String, Object?> row) => DepartmentModel(
            id: row['id'] as String,
            name: row['name'] as String,
            description: row['description'] as String,
            createdBy: row['created_by'] as String,
            createdAt: row['created_at'] as int,
            status: row['status'] as String));
  }

  @override
  Future<List<DepartmentMemberModel>> getAllMembers() async {
    return _queryAdapter.queryList('SELECT * FROM department_members',
        mapper: (Map<String, Object?> row) => DepartmentMemberModel(
            id: row['id'] as int?,
            departmentId: row['department_id'] as String,
            teacherId: row['teacher_id'] as String,
            role: row['role'] as String,
            assignedAt: row['assigned_at'] as int));
  }

  @override
  Future<void> removeMemberFromDept(
    String teacherId,
    String deptId,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM department_members WHERE teacher_id = ?1 AND department_id = ?2',
        arguments: [teacherId, deptId]);
  }

  @override
  Future<void> insertDepartment(DepartmentModel department) async {
    await _departmentModelInsertionAdapter.insert(
        department, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertMember(DepartmentMemberModel member) async {
    await _departmentMemberModelInsertionAdapter.insert(
        member, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertTermApproval(SubjectTermApprovalModel approval) async {
    await _subjectTermApprovalModelInsertionAdapter.insert(
        approval, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertLog(ApprovalLogModel log) async {
    await _approvalLogModelInsertionAdapter.insert(
        log, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateDepartment(DepartmentModel department) async {
    await _departmentModelUpdateAdapter.update(
        department, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateTermApproval(SubjectTermApprovalModel approval) async {
    await _subjectTermApprovalModelUpdateAdapter.update(
        approval, OnConflictStrategy.abort);
  }

  @override
  Future<void> removeMember(DepartmentMemberModel member) async {
    await _departmentMemberModelDeletionAdapter.delete(member);
  }
}

class _$DeptActivityDao extends DeptActivityDao {
  _$DeptActivityDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _deptDocumentInsertionAdapter = InsertionAdapter(
            database,
            'dept_documents',
            (DeptDocument item) => <String, Object?>{
                  'id': item.id,
                  'department_id': item.departmentId,
                  'title': item.title,
                  'category': item.category,
                  'file_path': item.filePath,
                  'file_name': item.fileName,
                  'description': item.description,
                  'uploaded_by': item.uploadedBy,
                  'uploaded_at': item.uploadedAt,
                  'status': item.status
                }),
        _deptMeetingInsertionAdapter = InsertionAdapter(
            database,
            'dept_meetings',
            (DeptMeeting item) => <String, Object?>{
                  'id': item.id,
                  'department_id': item.departmentId,
                  'title': item.title,
                  'agenda': item.agenda,
                  'scheduled_at': item.scheduledAt,
                  'venue': item.venue,
                  'minutes': item.minutes,
                  'organized_by': item.organizedBy,
                  'status': item.status
                }),
        _deptActivityInsertionAdapter = InsertionAdapter(
            database,
            'dept_activities',
            (DeptActivity item) => <String, Object?>{
                  'id': item.id,
                  'department_id': item.departmentId,
                  'module_type': item.moduleType,
                  'title': item.title,
                  'data': item.data,
                  'recorded_by': item.recordedBy,
                  'recorded_at': item.recordedAt,
                  'status': item.status,
                  'grade': item.grade,
                  'subject': item.subject
                }),
        _deptComplianceInsertionAdapter = InsertionAdapter(
            database,
            'dept_compliance',
            (DeptCompliance item) => <String, Object?>{
                  'id': item.id,
                  'department_id': item.departmentId,
                  'item': item.item,
                  'is_done': item.isDone,
                  'due_date': item.dueDate,
                  'completed_by': item.completedBy,
                  'completed_at': item.completedAt,
                  'term': item.term,
                  'year': item.year
                }),
        _deptDocumentUpdateAdapter = UpdateAdapter(
            database,
            'dept_documents',
            ['id'],
            (DeptDocument item) => <String, Object?>{
                  'id': item.id,
                  'department_id': item.departmentId,
                  'title': item.title,
                  'category': item.category,
                  'file_path': item.filePath,
                  'file_name': item.fileName,
                  'description': item.description,
                  'uploaded_by': item.uploadedBy,
                  'uploaded_at': item.uploadedAt,
                  'status': item.status
                }),
        _deptMeetingUpdateAdapter = UpdateAdapter(
            database,
            'dept_meetings',
            ['id'],
            (DeptMeeting item) => <String, Object?>{
                  'id': item.id,
                  'department_id': item.departmentId,
                  'title': item.title,
                  'agenda': item.agenda,
                  'scheduled_at': item.scheduledAt,
                  'venue': item.venue,
                  'minutes': item.minutes,
                  'organized_by': item.organizedBy,
                  'status': item.status
                }),
        _deptActivityUpdateAdapter = UpdateAdapter(
            database,
            'dept_activities',
            ['id'],
            (DeptActivity item) => <String, Object?>{
                  'id': item.id,
                  'department_id': item.departmentId,
                  'module_type': item.moduleType,
                  'title': item.title,
                  'data': item.data,
                  'recorded_by': item.recordedBy,
                  'recorded_at': item.recordedAt,
                  'status': item.status,
                  'grade': item.grade,
                  'subject': item.subject
                }),
        _deptComplianceUpdateAdapter = UpdateAdapter(
            database,
            'dept_compliance',
            ['id'],
            (DeptCompliance item) => <String, Object?>{
                  'id': item.id,
                  'department_id': item.departmentId,
                  'item': item.item,
                  'is_done': item.isDone,
                  'due_date': item.dueDate,
                  'completed_by': item.completedBy,
                  'completed_at': item.completedAt,
                  'term': item.term,
                  'year': item.year
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DeptDocument> _deptDocumentInsertionAdapter;

  final InsertionAdapter<DeptMeeting> _deptMeetingInsertionAdapter;

  final InsertionAdapter<DeptActivity> _deptActivityInsertionAdapter;

  final InsertionAdapter<DeptCompliance> _deptComplianceInsertionAdapter;

  final UpdateAdapter<DeptDocument> _deptDocumentUpdateAdapter;

  final UpdateAdapter<DeptMeeting> _deptMeetingUpdateAdapter;

  final UpdateAdapter<DeptActivity> _deptActivityUpdateAdapter;

  final UpdateAdapter<DeptCompliance> _deptComplianceUpdateAdapter;

  @override
  Future<List<DeptDocument>> getDocsByDept(String deptId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM dept_documents WHERE department_id = ?1 ORDER BY uploaded_at DESC',
        mapper: (Map<String, Object?> row) => DeptDocument(id: row['id'] as String, departmentId: row['department_id'] as String, title: row['title'] as String, category: row['category'] as String, filePath: row['file_path'] as String?, fileName: row['file_name'] as String, description: row['description'] as String?, uploadedBy: row['uploaded_by'] as String, uploadedAt: row['uploaded_at'] as int, status: row['status'] as String),
        arguments: [deptId]);
  }

  @override
  Future<List<DeptDocument>> getDocsByCategory(
    String deptId,
    String category,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM dept_documents WHERE department_id = ?1 AND category = ?2 ORDER BY uploaded_at DESC',
        mapper: (Map<String, Object?> row) => DeptDocument(id: row['id'] as String, departmentId: row['department_id'] as String, title: row['title'] as String, category: row['category'] as String, filePath: row['file_path'] as String?, fileName: row['file_name'] as String, description: row['description'] as String?, uploadedBy: row['uploaded_by'] as String, uploadedAt: row['uploaded_at'] as int, status: row['status'] as String),
        arguments: [deptId, category]);
  }

  @override
  Future<void> deleteDocument(String id) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM dept_documents WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<List<DeptMeeting>> getMeetingsByDept(String deptId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM dept_meetings WHERE department_id = ?1 ORDER BY scheduled_at DESC',
        mapper: (Map<String, Object?> row) => DeptMeeting(id: row['id'] as String, departmentId: row['department_id'] as String, title: row['title'] as String, agenda: row['agenda'] as String, scheduledAt: row['scheduled_at'] as int, venue: row['venue'] as String, minutes: row['minutes'] as String?, organizedBy: row['organized_by'] as String, status: row['status'] as String),
        arguments: [deptId]);
  }

  @override
  Future<List<DeptMeeting>> getMeetingsByStatus(
    String deptId,
    String status,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM dept_meetings WHERE department_id = ?1 AND status = ?2 ORDER BY scheduled_at DESC',
        mapper: (Map<String, Object?> row) => DeptMeeting(id: row['id'] as String, departmentId: row['department_id'] as String, title: row['title'] as String, agenda: row['agenda'] as String, scheduledAt: row['scheduled_at'] as int, venue: row['venue'] as String, minutes: row['minutes'] as String?, organizedBy: row['organized_by'] as String, status: row['status'] as String),
        arguments: [deptId, status]);
  }

  @override
  Future<List<DeptActivity>> getActivitiesByDept(String deptId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM dept_activities WHERE department_id = ?1 ORDER BY recorded_at DESC',
        mapper: (Map<String, Object?> row) => DeptActivity(id: row['id'] as int?, departmentId: row['department_id'] as String, moduleType: row['module_type'] as String, title: row['title'] as String, data: row['data'] as String?, recordedBy: row['recorded_by'] as String, recordedAt: row['recorded_at'] as int, status: row['status'] as String, grade: row['grade'] as String?, subject: row['subject'] as String?),
        arguments: [deptId]);
  }

  @override
  Future<List<DeptActivity>> getActivitiesByModule(
    String deptId,
    String moduleType,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM dept_activities WHERE department_id = ?1 AND module_type = ?2 ORDER BY recorded_at DESC',
        mapper: (Map<String, Object?> row) => DeptActivity(id: row['id'] as int?, departmentId: row['department_id'] as String, moduleType: row['module_type'] as String, title: row['title'] as String, data: row['data'] as String?, recordedBy: row['recorded_by'] as String, recordedAt: row['recorded_at'] as int, status: row['status'] as String, grade: row['grade'] as String?, subject: row['subject'] as String?),
        arguments: [deptId, moduleType]);
  }

  @override
  Future<List<DeptActivity>> getActivitiesByStatus(
    String deptId,
    String status,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM dept_activities WHERE department_id = ?1 AND status = ?2 ORDER BY recorded_at DESC',
        mapper: (Map<String, Object?> row) => DeptActivity(id: row['id'] as int?, departmentId: row['department_id'] as String, moduleType: row['module_type'] as String, title: row['title'] as String, data: row['data'] as String?, recordedBy: row['recorded_by'] as String, recordedAt: row['recorded_at'] as int, status: row['status'] as String, grade: row['grade'] as String?, subject: row['subject'] as String?),
        arguments: [deptId, status]);
  }

  @override
  Future<List<DeptCompliance>> getComplianceItems(
    String deptId,
    String term,
    String year,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM dept_compliance WHERE department_id = ?1 AND term = ?2 AND year = ?3',
        mapper: (Map<String, Object?> row) => DeptCompliance(id: row['id'] as int?, departmentId: row['department_id'] as String, item: row['item'] as String, isDone: row['is_done'] as int, dueDate: row['due_date'] as int?, completedBy: row['completed_by'] as String?, completedAt: row['completed_at'] as int?, term: row['term'] as String, year: row['year'] as String),
        arguments: [deptId, term, year]);
  }

  @override
  Future<List<DeptCompliance>> getAllComplianceItems(String deptId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM dept_compliance WHERE department_id = ?1',
        mapper: (Map<String, Object?> row) => DeptCompliance(
            id: row['id'] as int?,
            departmentId: row['department_id'] as String,
            item: row['item'] as String,
            isDone: row['is_done'] as int,
            dueDate: row['due_date'] as int?,
            completedBy: row['completed_by'] as String?,
            completedAt: row['completed_at'] as int?,
            term: row['term'] as String,
            year: row['year'] as String),
        arguments: [deptId]);
  }

  @override
  Future<void> deleteCompliance(int id) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM dept_compliance WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<void> insertDocument(DeptDocument doc) async {
    await _deptDocumentInsertionAdapter.insert(doc, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertMeeting(DeptMeeting meeting) async {
    await _deptMeetingInsertionAdapter.insert(
        meeting, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertActivity(DeptActivity activity) async {
    await _deptActivityInsertionAdapter.insert(
        activity, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertCompliance(DeptCompliance item) async {
    await _deptComplianceInsertionAdapter.insert(
        item, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateDocument(DeptDocument doc) async {
    await _deptDocumentUpdateAdapter.update(doc, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateMeeting(DeptMeeting meeting) async {
    await _deptMeetingUpdateAdapter.update(meeting, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateActivity(DeptActivity activity) async {
    await _deptActivityUpdateAdapter.update(activity, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateCompliance(DeptCompliance item) async {
    await _deptComplianceUpdateAdapter.update(item, OnConflictStrategy.abort);
  }
}

class _$ClubDao extends ClubDao {
  _$ClubDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _clubModelInsertionAdapter = InsertionAdapter(
            database,
            'clubs',
            (ClubModel item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'category': item.category,
                  'description': item.description,
                  'patron_id': item.patronId,
                  'assistant_patron_id': item.assistantPatronId,
                  'meeting_day': item.meetingDay,
                  'meeting_time': item.meetingTime,
                  'status': item.status,
                  'capacity_limit': item.capacityLimit,
                  'created_at': item.createdAt
                }),
        _clubMemberModelInsertionAdapter = InsertionAdapter(
            database,
            'club_members',
            (ClubMemberModel item) => <String, Object?>{
                  'id': item.id,
                  'club_id': item.clubId,
                  'student_id': item.studentId,
                  'role': item.role,
                  'joined_at': item.joinedAt,
                  'joined_by': item.joinedBy,
                  'consent_form_signed': item.consentFormSigned ? 1 : 0,
                  'parent_contact_verified': item.parentContactVerified ? 1 : 0
                }),
        _clubActivityModelInsertionAdapter = InsertionAdapter(
            database,
            'club_activities',
            (ClubActivityModel item) => <String, Object?>{
                  'id': item.id,
                  'club_id': item.clubId,
                  'title': item.title,
                  'description': item.description,
                  'type': item.type,
                  'scheduled_at': item.scheduledAt,
                  'venue': item.venue,
                  'status': item.status,
                  'recorded_at': item.recordedAt
                }),
        _clubAttendanceModelInsertionAdapter = InsertionAdapter(
            database,
            'club_attendance',
            (ClubAttendanceModel item) => <String, Object?>{
                  'id': item.id,
                  'activity_id': item.activityId,
                  'student_id': item.studentId,
                  'status': item.status,
                  'remarks': item.remarks
                }),
        _clubReportModelInsertionAdapter = InsertionAdapter(
            database,
            'club_reports',
            (ClubReportModel item) => <String, Object?>{
                  'id': item.id,
                  'club_id': item.clubId,
                  'term': item.term,
                  'year': item.year,
                  'content': item.content,
                  'submitted_at': item.submittedAt,
                  'patron_id': item.patronId,
                  'status': item.status
                }),
        _clubModelUpdateAdapter = UpdateAdapter(
            database,
            'clubs',
            ['id'],
            (ClubModel item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'category': item.category,
                  'description': item.description,
                  'patron_id': item.patronId,
                  'assistant_patron_id': item.assistantPatronId,
                  'meeting_day': item.meetingDay,
                  'meeting_time': item.meetingTime,
                  'status': item.status,
                  'capacity_limit': item.capacityLimit,
                  'created_at': item.createdAt
                }),
        _clubActivityModelUpdateAdapter = UpdateAdapter(
            database,
            'club_activities',
            ['id'],
            (ClubActivityModel item) => <String, Object?>{
                  'id': item.id,
                  'club_id': item.clubId,
                  'title': item.title,
                  'description': item.description,
                  'type': item.type,
                  'scheduled_at': item.scheduledAt,
                  'venue': item.venue,
                  'status': item.status,
                  'recorded_at': item.recordedAt
                }),
        _clubMemberModelDeletionAdapter = DeletionAdapter(
            database,
            'club_members',
            ['id'],
            (ClubMemberModel item) => <String, Object?>{
                  'id': item.id,
                  'club_id': item.clubId,
                  'student_id': item.studentId,
                  'role': item.role,
                  'joined_at': item.joinedAt,
                  'joined_by': item.joinedBy,
                  'consent_form_signed': item.consentFormSigned ? 1 : 0,
                  'parent_contact_verified': item.parentContactVerified ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ClubModel> _clubModelInsertionAdapter;

  final InsertionAdapter<ClubMemberModel> _clubMemberModelInsertionAdapter;

  final InsertionAdapter<ClubActivityModel> _clubActivityModelInsertionAdapter;

  final InsertionAdapter<ClubAttendanceModel>
      _clubAttendanceModelInsertionAdapter;

  final InsertionAdapter<ClubReportModel> _clubReportModelInsertionAdapter;

  final UpdateAdapter<ClubModel> _clubModelUpdateAdapter;

  final UpdateAdapter<ClubActivityModel> _clubActivityModelUpdateAdapter;

  final DeletionAdapter<ClubMemberModel> _clubMemberModelDeletionAdapter;

  @override
  Future<List<ClubModel>> getAllActiveClubs() async {
    return _queryAdapter.queryList(
        'SELECT * FROM clubs WHERE status = \"active\"',
        mapper: (Map<String, Object?> row) => ClubModel(
            id: row['id'] as String,
            name: row['name'] as String,
            category: row['category'] as String,
            description: row['description'] as String,
            patronId: row['patron_id'] as String?,
            assistantPatronId: row['assistant_patron_id'] as String?,
            meetingDay: row['meeting_day'] as String?,
            meetingTime: row['meeting_time'] as String?,
            status: row['status'] as String,
            capacityLimit: row['capacity_limit'] as int,
            createdAt: row['created_at'] as int));
  }

  @override
  Future<ClubModel?> getClubById(String id) async {
    return _queryAdapter.query('SELECT * FROM clubs WHERE id = ?1',
        mapper: (Map<String, Object?> row) => ClubModel(
            id: row['id'] as String,
            name: row['name'] as String,
            category: row['category'] as String,
            description: row['description'] as String,
            patronId: row['patron_id'] as String?,
            assistantPatronId: row['assistant_patron_id'] as String?,
            meetingDay: row['meeting_day'] as String?,
            meetingTime: row['meeting_time'] as String?,
            status: row['status'] as String,
            capacityLimit: row['capacity_limit'] as int,
            createdAt: row['created_at'] as int),
        arguments: [id]);
  }

  @override
  Future<List<ClubModel>> getClubsByPatron(String patronId) async {
    return _queryAdapter.queryList('SELECT * FROM clubs WHERE patron_id = ?1',
        mapper: (Map<String, Object?> row) => ClubModel(
            id: row['id'] as String,
            name: row['name'] as String,
            category: row['category'] as String,
            description: row['description'] as String,
            patronId: row['patron_id'] as String?,
            assistantPatronId: row['assistant_patron_id'] as String?,
            meetingDay: row['meeting_day'] as String?,
            meetingTime: row['meeting_time'] as String?,
            status: row['status'] as String,
            capacityLimit: row['capacity_limit'] as int,
            createdAt: row['created_at'] as int),
        arguments: [patronId]);
  }

  @override
  Future<List<ClubMemberModel>> getMembersByClub(String clubId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM club_members WHERE club_id = ?1',
        mapper: (Map<String, Object?> row) => ClubMemberModel(
            id: row['id'] as int?,
            clubId: row['club_id'] as String,
            studentId: row['student_id'] as String,
            role: row['role'] as String,
            joinedAt: row['joined_at'] as int,
            joinedBy: row['joined_by'] as String,
            consentFormSigned: (row['consent_form_signed'] as int) != 0,
            parentContactVerified:
                (row['parent_contact_verified'] as int) != 0),
        arguments: [clubId]);
  }

  @override
  Future<int?> getStudentClubCount(String studentId) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM club_members WHERE student_id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [studentId]);
  }

  @override
  Future<ClubMemberModel?> getMembership(
    String studentId,
    String clubId,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM club_members WHERE student_id = ?1 AND club_id = ?2',
        mapper: (Map<String, Object?> row) => ClubMemberModel(
            id: row['id'] as int?,
            clubId: row['club_id'] as String,
            studentId: row['student_id'] as String,
            role: row['role'] as String,
            joinedAt: row['joined_at'] as int,
            joinedBy: row['joined_by'] as String,
            consentFormSigned: (row['consent_form_signed'] as int) != 0,
            parentContactVerified:
                (row['parent_contact_verified'] as int) != 0),
        arguments: [studentId, clubId]);
  }

  @override
  Future<void> removeStudentFromClub(
    String studentId,
    String clubId,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM club_members WHERE student_id = ?1 AND club_id = ?2',
        arguments: [studentId, clubId]);
  }

  @override
  Future<List<ClubActivityModel>> getActivitiesByClub(String clubId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM club_activities WHERE club_id = ?1 ORDER BY scheduled_at DESC',
        mapper: (Map<String, Object?> row) => ClubActivityModel(id: row['id'] as String, clubId: row['club_id'] as String, title: row['title'] as String, description: row['description'] as String, type: row['type'] as String, scheduledAt: row['scheduled_at'] as int, venue: row['venue'] as String, status: row['status'] as String, recordedAt: row['recorded_at'] as int),
        arguments: [clubId]);
  }

  @override
  Future<ClubActivityModel?> getActivityById(String id) async {
    return _queryAdapter.query('SELECT * FROM club_activities WHERE id = ?1',
        mapper: (Map<String, Object?> row) => ClubActivityModel(
            id: row['id'] as String,
            clubId: row['club_id'] as String,
            title: row['title'] as String,
            description: row['description'] as String,
            type: row['type'] as String,
            scheduledAt: row['scheduled_at'] as int,
            venue: row['venue'] as String,
            status: row['status'] as String,
            recordedAt: row['recorded_at'] as int),
        arguments: [id]);
  }

  @override
  Future<List<ClubAttendanceModel>> getAttendanceByActivity(
      String activityId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM club_attendance WHERE activity_id = ?1',
        mapper: (Map<String, Object?> row) => ClubAttendanceModel(
            id: row['id'] as int?,
            activityId: row['activity_id'] as String,
            studentId: row['student_id'] as String,
            status: row['status'] as String,
            remarks: row['remarks'] as String?),
        arguments: [activityId]);
  }

  @override
  Future<List<ClubReportModel>> getReportsByClub(String clubId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM club_reports WHERE club_id = ?1 ORDER BY submitted_at DESC',
        mapper: (Map<String, Object?> row) => ClubReportModel(id: row['id'] as String, clubId: row['club_id'] as String, term: row['term'] as int, year: row['year'] as String, content: row['content'] as String, submittedAt: row['submitted_at'] as int, patronId: row['patron_id'] as String, status: row['status'] as String),
        arguments: [clubId]);
  }

  @override
  Future<List<ClubModel>> getAllClubs() async {
    return _queryAdapter.queryList('SELECT * FROM clubs',
        mapper: (Map<String, Object?> row) => ClubModel(
            id: row['id'] as String,
            name: row['name'] as String,
            category: row['category'] as String,
            description: row['description'] as String,
            patronId: row['patron_id'] as String?,
            assistantPatronId: row['assistant_patron_id'] as String?,
            meetingDay: row['meeting_day'] as String?,
            meetingTime: row['meeting_time'] as String?,
            status: row['status'] as String,
            capacityLimit: row['capacity_limit'] as int,
            createdAt: row['created_at'] as int));
  }

  @override
  Future<List<StudentModel>> getEligibleStudentsForClub(String clubId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM students      WHERE CAST(SUBSTR(grade, 7) AS INTEGER) BETWEEN 4 AND 9      AND id NOT IN (SELECT student_id FROM club_members WHERE club_id = ?1)',
        mapper: (Map<String, Object?> row) => StudentModel(id: row['id'] as String, upi: row['upi'] as String, fullName: row['full_name'] as String, gender: row['gender'] as String, dob: row['dob'] as String, grade: row['grade'] as String, classId: row['class_id'] as String, parentId: row['parent_id'] as String?, photoUrl: row['photo_url'] as String?, createdAt: row['created_at'] as int, synced: row['synced'] as int),
        arguments: [clubId]);
  }

  @override
  Future<void> insertClub(ClubModel club) async {
    await _clubModelInsertionAdapter.insert(club, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertMember(ClubMemberModel member) async {
    await _clubMemberModelInsertionAdapter.insert(
        member, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertActivity(ClubActivityModel activity) async {
    await _clubActivityModelInsertionAdapter.insert(
        activity, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertAttendance(ClubAttendanceModel attendance) async {
    await _clubAttendanceModelInsertionAdapter.insert(
        attendance, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertReport(ClubReportModel report) async {
    await _clubReportModelInsertionAdapter.insert(
        report, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateClub(ClubModel club) async {
    await _clubModelUpdateAdapter.update(club, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateActivity(ClubActivityModel activity) async {
    await _clubActivityModelUpdateAdapter.update(
        activity, OnConflictStrategy.abort);
  }

  @override
  Future<void> removeMember(ClubMemberModel member) async {
    await _clubMemberModelDeletionAdapter.delete(member);
  }
}

class _$TodDao extends TodDao {
  _$TodDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _dutyRosterModelInsertionAdapter = InsertionAdapter(
            database,
            'duty_roster',
            (DutyRosterModel item) => <String, Object?>{
                  'id': item.id,
                  'teacher_id': item.teacherId,
                  'week_number': item.weekNumber,
                  'start_date': item.startDate,
                  'end_date': item.endDate
                }),
        _todRecordModelInsertionAdapter = InsertionAdapter(
            database,
            'tod_records',
            (TodRecordModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'offence': item.offence,
                  'punishment': item.punishment,
                  'remarks': item.remarks,
                  'teacher_id': item.teacherId,
                  'date': item.date,
                  'status': item.status
                }),
        _studentBehaviorModelInsertionAdapter = InsertionAdapter(
            database,
            'student_behavior',
            (StudentBehaviorModel item) => <String, Object?>{
                  'student_id': item.studentId,
                  'weekly_offences': item.weeklyOffences,
                  'status': item.status
                }),
        _todRecordModelUpdateAdapter = UpdateAdapter(
            database,
            'tod_records',
            ['id'],
            (TodRecordModel item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.studentId,
                  'offence': item.offence,
                  'punishment': item.punishment,
                  'remarks': item.remarks,
                  'teacher_id': item.teacherId,
                  'date': item.date,
                  'status': item.status
                }),
        _studentBehaviorModelUpdateAdapter = UpdateAdapter(
            database,
            'student_behavior',
            ['student_id'],
            (StudentBehaviorModel item) => <String, Object?>{
                  'student_id': item.studentId,
                  'weekly_offences': item.weeklyOffences,
                  'status': item.status
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DutyRosterModel> _dutyRosterModelInsertionAdapter;

  final InsertionAdapter<TodRecordModel> _todRecordModelInsertionAdapter;

  final InsertionAdapter<StudentBehaviorModel>
      _studentBehaviorModelInsertionAdapter;

  final UpdateAdapter<TodRecordModel> _todRecordModelUpdateAdapter;

  final UpdateAdapter<StudentBehaviorModel> _studentBehaviorModelUpdateAdapter;

  @override
  Future<List<DutyRosterModel>> getAllDutyRosters() async {
    return _queryAdapter.queryList('SELECT * FROM duty_roster',
        mapper: (Map<String, Object?> row) => DutyRosterModel(
            id: row['id'] as String,
            teacherId: row['teacher_id'] as String,
            weekNumber: row['week_number'] as int,
            startDate: row['start_date'] as int,
            endDate: row['end_date'] as int));
  }

  @override
  Future<List<DutyRosterModel>> getDutyRostersByWeek(int weekNumber) async {
    return _queryAdapter.queryList(
        'SELECT * FROM duty_roster WHERE week_number = ?1',
        mapper: (Map<String, Object?> row) => DutyRosterModel(
            id: row['id'] as String,
            teacherId: row['teacher_id'] as String,
            weekNumber: row['week_number'] as int,
            startDate: row['start_date'] as int,
            endDate: row['end_date'] as int),
        arguments: [weekNumber]);
  }

  @override
  Future<List<DutyRosterModel>> getDutyRostersByTeacher(
      String teacherId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM duty_roster WHERE teacher_id = ?1',
        mapper: (Map<String, Object?> row) => DutyRosterModel(
            id: row['id'] as String,
            teacherId: row['teacher_id'] as String,
            weekNumber: row['week_number'] as int,
            startDate: row['start_date'] as int,
            endDate: row['end_date'] as int),
        arguments: [teacherId]);
  }

  @override
  Future<List<DutyRosterModel>> getDutyRosterForDate(int date) async {
    return _queryAdapter.queryList(
        'SELECT * FROM duty_roster WHERE ?1 BETWEEN start_date AND end_date',
        mapper: (Map<String, Object?> row) => DutyRosterModel(
            id: row['id'] as String,
            teacherId: row['teacher_id'] as String,
            weekNumber: row['week_number'] as int,
            startDate: row['start_date'] as int,
            endDate: row['end_date'] as int),
        arguments: [date]);
  }

  @override
  Future<void> clearDutyRosters() async {
    await _queryAdapter.queryNoReturn('DELETE FROM duty_roster');
  }

  @override
  Future<void> clearDutyRostersByWeek(int weekNumber) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM duty_roster WHERE week_number = ?1',
        arguments: [weekNumber]);
  }

  @override
  Future<List<TodRecordModel>> getAllTodRecords() async {
    return _queryAdapter.queryList(
        'SELECT * FROM tod_records ORDER BY date DESC',
        mapper: (Map<String, Object?> row) => TodRecordModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            offence: row['offence'] as String,
            punishment: row['punishment'] as String,
            remarks: row['remarks'] as String?,
            teacherId: row['teacher_id'] as String,
            date: row['date'] as int,
            status: row['status'] as String));
  }

  @override
  Future<List<TodRecordModel>> getTodRecordsByTeacher(String teacherId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM tod_records WHERE teacher_id = ?1 ORDER BY date DESC',
        mapper: (Map<String, Object?> row) => TodRecordModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            offence: row['offence'] as String,
            punishment: row['punishment'] as String,
            remarks: row['remarks'] as String?,
            teacherId: row['teacher_id'] as String,
            date: row['date'] as int,
            status: row['status'] as String),
        arguments: [teacherId]);
  }

  @override
  Future<List<TodRecordModel>> getTodRecordsByStudent(String studentId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM tod_records WHERE student_id = ?1 ORDER BY date DESC',
        mapper: (Map<String, Object?> row) => TodRecordModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            offence: row['offence'] as String,
            punishment: row['punishment'] as String,
            remarks: row['remarks'] as String?,
            teacherId: row['teacher_id'] as String,
            date: row['date'] as int,
            status: row['status'] as String),
        arguments: [studentId]);
  }

  @override
  Future<List<TodRecordModel>> getTodRecordsByDateRange(
    int startOfDay,
    int endOfDay,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM tod_records WHERE date >= ?1 AND date <= ?2',
        mapper: (Map<String, Object?> row) => TodRecordModel(
            id: row['id'] as String,
            studentId: row['student_id'] as String,
            offence: row['offence'] as String,
            punishment: row['punishment'] as String,
            remarks: row['remarks'] as String?,
            teacherId: row['teacher_id'] as String,
            date: row['date'] as int,
            status: row['status'] as String),
        arguments: [startOfDay, endOfDay]);
  }

  @override
  Future<List<StudentBehaviorModel>> getAllStudentBehaviors() async {
    return _queryAdapter.queryList('SELECT * FROM student_behavior',
        mapper: (Map<String, Object?> row) => StudentBehaviorModel(
            studentId: row['student_id'] as String,
            weeklyOffences: row['weekly_offences'] as int,
            status: row['status'] as String));
  }

  @override
  Future<StudentBehaviorModel?> getStudentBehavior(String studentId) async {
    return _queryAdapter.query(
        'SELECT * FROM student_behavior WHERE student_id = ?1',
        mapper: (Map<String, Object?> row) => StudentBehaviorModel(
            studentId: row['student_id'] as String,
            weeklyOffences: row['weekly_offences'] as int,
            status: row['status'] as String),
        arguments: [studentId]);
  }

  @override
  Future<List<StudentBehaviorModel>> getStudentBehaviorsByStatus(
      String status) async {
    return _queryAdapter.queryList(
        'SELECT * FROM student_behavior WHERE status = ?1',
        mapper: (Map<String, Object?> row) => StudentBehaviorModel(
            studentId: row['student_id'] as String,
            weeklyOffences: row['weekly_offences'] as int,
            status: row['status'] as String),
        arguments: [status]);
  }

  @override
  Future<void> clearStudentBehaviors() async {
    await _queryAdapter.queryNoReturn('DELETE FROM student_behavior');
  }

  @override
  Future<void> insertDutyRoster(DutyRosterModel roster) async {
    await _dutyRosterModelInsertionAdapter.insert(
        roster, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertDutyRosters(List<DutyRosterModel> rosters) async {
    await _dutyRosterModelInsertionAdapter.insertList(
        rosters, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertTodRecord(TodRecordModel record) async {
    await _todRecordModelInsertionAdapter.insert(
        record, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertStudentBehavior(StudentBehaviorModel behavior) async {
    await _studentBehaviorModelInsertionAdapter.insert(
        behavior, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateTodRecord(TodRecordModel record) async {
    await _todRecordModelUpdateAdapter.update(
        record, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateStudentBehavior(StudentBehaviorModel behavior) async {
    await _studentBehaviorModelUpdateAdapter.update(
        behavior, OnConflictStrategy.replace);
  }
}

class _$FinanceErpDao extends FinanceErpDao {
  _$FinanceErpDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _financeStaffInsertionAdapter = InsertionAdapter(
            database,
            'staff',
            (FinanceStaff item) => <String, Object?>{
                  'staff_id': item.staff_id,
                  'name': item.name,
                  'role': item.role,
                  'department': item.department,
                  'employment_type': item.employment_type,
                  'bank_name': item.bank_name,
                  'account_no': item.account_no,
                  'bank_branch': item.bank_branch,
                  'date_hired': item.date_hired
                }),
        _erpFeeStructureInsertionAdapter = InsertionAdapter(
            database,
            'fee_structure',
            (ErpFeeStructure item) => <String, Object?>{
                  'fee_id': item.fee_id,
                  'fee_name': item.fee_name,
                  'amount': item.amount,
                  'term': item.term,
                  'is_optional': item.is_optional ? 1 : 0
                }),
        _studentBillingInsertionAdapter = InsertionAdapter(
            database,
            'student_billing',
            (StudentBilling item) => <String, Object?>{
                  'billing_id': item.billing_id,
                  'student_id': item.student_id,
                  'term': item.term,
                  'tuition': item.tuition,
                  'transport': item.transport,
                  'meals': item.meals,
                  'swimming': item.swimming,
                  'other_charges': item.other_charges,
                  'total_amount': item.total_amount,
                  'balance': item.balance,
                  'status': item.status
                }),
        _erpFeePaymentInsertionAdapter = InsertionAdapter(
            database,
            'fee_payments',
            (ErpFeePayment item) => <String, Object?>{
                  'payment_id': item.payment_id,
                  'student_id': item.student_id,
                  'amount_paid': item.amount_paid,
                  'payment_method': item.payment_method,
                  'transaction_code': item.transaction_code,
                  'date_paid': item.date_paid,
                  'received_by': item.received_by
                }),
        _erpAmenityInsertionAdapter = InsertionAdapter(
            database,
            'amenities',
            (ErpAmenity item) => <String, Object?>{
                  'amenity_id': item.amenity_id,
                  'amenity_name': item.amenity_name,
                  'fee_amount': item.fee_amount,
                  'billing_type': item.billing_type
                }),
        _studentAmenityInsertionAdapter = InsertionAdapter(
            database,
            'student_amenities',
            (StudentAmenity item) => <String, Object?>{
                  'id': item.id,
                  'student_id': item.student_id,
                  'amenity_id': item.amenity_id,
                  'term': item.term,
                  'status': item.status
                }),
        _payrollInsertionAdapter = InsertionAdapter(
            database,
            'payroll',
            (Payroll item) => <String, Object?>{
                  'payroll_id': item.payroll_id,
                  'staff_id': item.staff_id,
                  'month': item.month,
                  'basic_salary': item.basic_salary,
                  'allowances': item.allowances,
                  'deductions': item.deductions,
                  'nssf': item.nssf,
                  'shif': item.shif,
                  'housing_levy': item.housing_levy,
                  'paye': item.paye,
                  'loan_deduction': item.loan_deduction,
                  'net_salary': item.net_salary,
                  'status': item.status,
                  'processed_by': item.processed_by,
                  'date_processed': item.date_processed
                }),
        _staffLoanInsertionAdapter = InsertionAdapter(
            database,
            'staff_loans',
            (StaffLoan item) => <String, Object?>{
                  'loan_id': item.loan_id,
                  'staff_id': item.staff_id,
                  'loan_amount': item.loan_amount,
                  'interest_rate': item.interest_rate,
                  'repayment_period': item.repayment_period,
                  'monthly_deduction': item.monthly_deduction,
                  'total_repayment': item.total_repayment,
                  'remaining_balance': item.remaining_balance,
                  'status': item.status,
                  'approved_by': item.approved_by,
                  'issue_date': item.issue_date,
                  'created_at': item.created_at
                }),
        _loanRepaymentInsertionAdapter = InsertionAdapter(
            database,
            'loan_repayments',
            (LoanRepayment item) => <String, Object?>{
                  'repayment_id': item.repayment_id,
                  'loan_id': item.loan_id,
                  'payroll_id': item.payroll_id,
                  'amount': item.amount,
                  'payment_date': item.payment_date,
                  'deducted_from_payroll': item.deducted_from_payroll ? 1 : 0
                }),
        _erpExpenseInsertionAdapter = InsertionAdapter(
            database,
            'expenses',
            (ErpExpense item) => <String, Object?>{
                  'expense_id': item.expense_id,
                  'category': item.category,
                  'description': item.description,
                  'amount': item.amount,
                  'payment_method': item.payment_method,
                  'date': item.date,
                  'approved_by': item.approved_by
                }),
        _erpAssetInsertionAdapter = InsertionAdapter(
            database,
            'assets',
            (ErpAsset item) => <String, Object?>{
                  'asset_id': item.asset_id,
                  'asset_name': item.asset_name,
                  'category': item.category,
                  'purchase_date': item.purchase_date,
                  'purchase_value': item.purchase_value,
                  'condition': item.condition,
                  'status': item.status
                }),
        _erpRepairInsertionAdapter = InsertionAdapter(
            database,
            'repairs',
            (ErpRepair item) => <String, Object?>{
                  'repair_id': item.repair_id,
                  'asset_id': item.asset_id,
                  'description': item.description,
                  'repair_cost': item.repair_cost,
                  'repair_date': item.repair_date,
                  'technician': item.technician
                }),
        _resourceRequestInsertionAdapter = InsertionAdapter(
            database,
            'resource_requests',
            (ResourceRequest item) => <String, Object?>{
                  'request_id': item.request_id,
                  'teacher_id': item.teacher_id,
                  'purpose': item.purpose,
                  'status': item.status,
                  'total_budget': item.total_budget,
                  'created_at': item.created_at
                }),
        _resourceRequestItemInsertionAdapter = InsertionAdapter(
            database,
            'resource_request_items',
            (ResourceRequestItem item) => <String, Object?>{
                  'id': item.id,
                  'request_id': item.request_id,
                  'item_name': item.item_name,
                  'quantity': item.quantity,
                  'price': item.price,
                  'total': item.total
                }),
        _budgetApprovalInsertionAdapter = InsertionAdapter(
            database,
            'budget_approvals',
            (BudgetApproval item) => <String, Object?>{
                  'id': item.id,
                  'request_id': item.request_id,
                  'approved_by': item.approved_by,
                  'decision': item.decision,
                  'comments': item.comments,
                  'date': item.date
                }),
        _salaryComponentInsertionAdapter = InsertionAdapter(
            database,
            'salary_components',
            (SalaryComponent item) => <String, Object?>{
                  'component_id': item.component_id,
                  'name': item.name,
                  'type': item.type,
                  'description': item.description,
                  'is_statutory': item.is_statutory ? 1 : 0,
                  'is_tax_applicable': item.is_tax_applicable ? 1 : 0,
                  'is_attendance_linked': item.is_attendance_linked ? 1 : 0,
                  'default_amount': item.default_amount
                }),
        _salaryStructureInsertionAdapter = InsertionAdapter(
            database,
            'salary_structures',
            (SalaryStructure item) => <String, Object?>{
                  'structure_id': item.structure_id,
                  'name': item.name,
                  'company': item.company,
                  'is_active': item.is_active ? 1 : 0,
                  'total_earnings': item.total_earnings,
                  'total_deductions': item.total_deductions
                }),
        _salaryStructureAssignmentInsertionAdapter = InsertionAdapter(
            database,
            'salary_structure_assignments',
            (SalaryStructureAssignment item) => <String, Object?>{
                  'assignment_id': item.assignment_id,
                  'staff_id': item.staff_id,
                  'structure_id': item.structure_id,
                  'from_date': item.from_date,
                  'base_salary': item.base_salary
                }),
        _payrollEntryInsertionAdapter = InsertionAdapter(
            database,
            'payroll_entries',
            (PayrollEntry item) => <String, Object?>{
                  'payroll_entry_id': item.payroll_entry_id,
                  'month': item.month,
                  'structure_id': item.structure_id,
                  'status': item.status,
                  'posting_date': item.posting_date,
                  'count_processed': item.count_processed
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<FinanceStaff> _financeStaffInsertionAdapter;

  final InsertionAdapter<ErpFeeStructure> _erpFeeStructureInsertionAdapter;

  final InsertionAdapter<StudentBilling> _studentBillingInsertionAdapter;

  final InsertionAdapter<ErpFeePayment> _erpFeePaymentInsertionAdapter;

  final InsertionAdapter<ErpAmenity> _erpAmenityInsertionAdapter;

  final InsertionAdapter<StudentAmenity> _studentAmenityInsertionAdapter;

  final InsertionAdapter<Payroll> _payrollInsertionAdapter;

  final InsertionAdapter<StaffLoan> _staffLoanInsertionAdapter;

  final InsertionAdapter<LoanRepayment> _loanRepaymentInsertionAdapter;

  final InsertionAdapter<ErpExpense> _erpExpenseInsertionAdapter;

  final InsertionAdapter<ErpAsset> _erpAssetInsertionAdapter;

  final InsertionAdapter<ErpRepair> _erpRepairInsertionAdapter;

  final InsertionAdapter<ResourceRequest> _resourceRequestInsertionAdapter;

  final InsertionAdapter<ResourceRequestItem>
      _resourceRequestItemInsertionAdapter;

  final InsertionAdapter<BudgetApproval> _budgetApprovalInsertionAdapter;

  final InsertionAdapter<SalaryComponent> _salaryComponentInsertionAdapter;

  final InsertionAdapter<SalaryStructure> _salaryStructureInsertionAdapter;

  final InsertionAdapter<SalaryStructureAssignment>
      _salaryStructureAssignmentInsertionAdapter;

  final InsertionAdapter<PayrollEntry> _payrollEntryInsertionAdapter;

  @override
  Future<List<FinanceStaff>> getAllStaff() async {
    return _queryAdapter.queryList('SELECT * FROM staff',
        mapper: (Map<String, Object?> row) => FinanceStaff(
            staff_id: row['staff_id'] as String,
            name: row['name'] as String,
            role: row['role'] as String,
            department: row['department'] as String,
            employment_type: row['employment_type'] as String,
            bank_name: row['bank_name'] as String,
            account_no: row['account_no'] as String,
            bank_branch: row['bank_branch'] as String,
            date_hired: row['date_hired'] as int));
  }

  @override
  Future<void> clearStaff() async {
    await _queryAdapter.queryNoReturn('DELETE FROM staff');
  }

  @override
  Future<List<ErpFeeStructure>> getAllFeeStructures() async {
    return _queryAdapter.queryList('SELECT * FROM fee_structure',
        mapper: (Map<String, Object?> row) => ErpFeeStructure(
            fee_id: row['fee_id'] as String,
            fee_name: row['fee_name'] as String,
            amount: row['amount'] as double,
            term: row['term'] as int,
            is_optional: (row['is_optional'] as int) != 0));
  }

  @override
  Future<void> clearFeeStructure() async {
    await _queryAdapter.queryNoReturn('DELETE FROM fee_structure');
  }

  @override
  Future<List<StudentBilling>> getAllBillings() async {
    return _queryAdapter.queryList('SELECT * FROM student_billing',
        mapper: (Map<String, Object?> row) => StudentBilling(
            billing_id: row['billing_id'] as String,
            student_id: row['student_id'] as String,
            term: row['term'] as int,
            tuition: row['tuition'] as double,
            transport: row['transport'] as double,
            meals: row['meals'] as double,
            swimming: row['swimming'] as double,
            other_charges: row['other_charges'] as double,
            total_amount: row['total_amount'] as double,
            balance: row['balance'] as double,
            status: row['status'] as String));
  }

  @override
  Future<StudentBilling?> getBillingByStudent(String studentId) async {
    return _queryAdapter.query(
        'SELECT * FROM student_billing WHERE student_id = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => StudentBilling(
            billing_id: row['billing_id'] as String,
            student_id: row['student_id'] as String,
            term: row['term'] as int,
            tuition: row['tuition'] as double,
            transport: row['transport'] as double,
            meals: row['meals'] as double,
            swimming: row['swimming'] as double,
            other_charges: row['other_charges'] as double,
            total_amount: row['total_amount'] as double,
            balance: row['balance'] as double,
            status: row['status'] as String),
        arguments: [studentId]);
  }

  @override
  Future<void> clearBillings() async {
    await _queryAdapter.queryNoReturn('DELETE FROM student_billing');
  }

  @override
  Future<List<ErpFeePayment>> getAllPayments() async {
    return _queryAdapter.queryList('SELECT * FROM fee_payments',
        mapper: (Map<String, Object?> row) => ErpFeePayment(
            payment_id: row['payment_id'] as String,
            student_id: row['student_id'] as String,
            amount_paid: row['amount_paid'] as double,
            payment_method: row['payment_method'] as String,
            transaction_code: row['transaction_code'] as String,
            date_paid: row['date_paid'] as int,
            received_by: row['received_by'] as String));
  }

  @override
  Future<List<ErpFeePayment>> getPaymentsByStudent(String studentId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM fee_payments WHERE student_id = ?1',
        mapper: (Map<String, Object?> row) => ErpFeePayment(
            payment_id: row['payment_id'] as String,
            student_id: row['student_id'] as String,
            amount_paid: row['amount_paid'] as double,
            payment_method: row['payment_method'] as String,
            transaction_code: row['transaction_code'] as String,
            date_paid: row['date_paid'] as int,
            received_by: row['received_by'] as String),
        arguments: [studentId]);
  }

  @override
  Future<void> clearPayments() async {
    await _queryAdapter.queryNoReturn('DELETE FROM fee_payments');
  }

  @override
  Future<List<ErpAmenity>> getAllAmenities() async {
    return _queryAdapter.queryList('SELECT * FROM amenities',
        mapper: (Map<String, Object?> row) => ErpAmenity(
            amenity_id: row['amenity_id'] as String,
            amenity_name: row['amenity_name'] as String,
            fee_amount: row['fee_amount'] as double,
            billing_type: row['billing_type'] as String));
  }

  @override
  Future<void> clearAmenities() async {
    await _queryAdapter.queryNoReturn('DELETE FROM amenities');
  }

  @override
  Future<List<StudentAmenity>> getAllStudentAmenities() async {
    return _queryAdapter.queryList('SELECT * FROM student_amenities',
        mapper: (Map<String, Object?> row) => StudentAmenity(
            id: row['id'] as String,
            student_id: row['student_id'] as String,
            amenity_id: row['amenity_id'] as String,
            term: row['term'] as int,
            status: row['status'] as String));
  }

  @override
  Future<void> clearStudentAmenities() async {
    await _queryAdapter.queryNoReturn('DELETE FROM student_amenities');
  }

  @override
  Future<List<Payroll>> getAllPayrolls() async {
    return _queryAdapter.queryList('SELECT * FROM payroll',
        mapper: (Map<String, Object?> row) => Payroll(
            payroll_id: row['payroll_id'] as String,
            staff_id: row['staff_id'] as String,
            month: row['month'] as String,
            basic_salary: row['basic_salary'] as double,
            allowances: row['allowances'] as double,
            deductions: row['deductions'] as double,
            nssf: row['nssf'] as double,
            shif: row['shif'] as double,
            housing_levy: row['housing_levy'] as double,
            paye: row['paye'] as double,
            loan_deduction: row['loan_deduction'] as double,
            net_salary: row['net_salary'] as double,
            status: row['status'] as String,
            processed_by: row['processed_by'] as String,
            date_processed: row['date_processed'] as int));
  }

  @override
  Future<List<Payroll>> getPayrollByStaff(String staffId) async {
    return _queryAdapter.queryList('SELECT * FROM payroll WHERE staff_id = ?1',
        mapper: (Map<String, Object?> row) => Payroll(
            payroll_id: row['payroll_id'] as String,
            staff_id: row['staff_id'] as String,
            month: row['month'] as String,
            basic_salary: row['basic_salary'] as double,
            allowances: row['allowances'] as double,
            deductions: row['deductions'] as double,
            nssf: row['nssf'] as double,
            shif: row['shif'] as double,
            housing_levy: row['housing_levy'] as double,
            paye: row['paye'] as double,
            loan_deduction: row['loan_deduction'] as double,
            net_salary: row['net_salary'] as double,
            status: row['status'] as String,
            processed_by: row['processed_by'] as String,
            date_processed: row['date_processed'] as int),
        arguments: [staffId]);
  }

  @override
  Future<void> clearPayroll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM payroll');
  }

  @override
  Future<List<StaffLoan>> getAllLoans() async {
    return _queryAdapter.queryList('SELECT * FROM staff_loans',
        mapper: (Map<String, Object?> row) => StaffLoan(
            loan_id: row['loan_id'] as String,
            staff_id: row['staff_id'] as String,
            loan_amount: row['loan_amount'] as double,
            interest_rate: row['interest_rate'] as double,
            repayment_period: row['repayment_period'] as int,
            monthly_deduction: row['monthly_deduction'] as double,
            total_repayment: row['total_repayment'] as double,
            remaining_balance: row['remaining_balance'] as double,
            status: row['status'] as String,
            approved_by: row['approved_by'] as String?,
            issue_date: row['issue_date'] as int,
            created_at: row['created_at'] as int));
  }

  @override
  Future<List<StaffLoan>> getActiveLoansByStaff(String staffId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM staff_loans WHERE staff_id = ?1 AND status = \"Approved\"',
        mapper: (Map<String, Object?> row) => StaffLoan(loan_id: row['loan_id'] as String, staff_id: row['staff_id'] as String, loan_amount: row['loan_amount'] as double, interest_rate: row['interest_rate'] as double, repayment_period: row['repayment_period'] as int, monthly_deduction: row['monthly_deduction'] as double, total_repayment: row['total_repayment'] as double, remaining_balance: row['remaining_balance'] as double, status: row['status'] as String, approved_by: row['approved_by'] as String?, issue_date: row['issue_date'] as int, created_at: row['created_at'] as int),
        arguments: [staffId]);
  }

  @override
  Future<void> clearLoans() async {
    await _queryAdapter.queryNoReturn('DELETE FROM staff_loans');
  }

  @override
  Future<List<LoanRepayment>> getAllLoanRepayments() async {
    return _queryAdapter.queryList('SELECT * FROM loan_repayments',
        mapper: (Map<String, Object?> row) => LoanRepayment(
            repayment_id: row['repayment_id'] as String,
            loan_id: row['loan_id'] as String,
            payroll_id: row['payroll_id'] as String?,
            amount: row['amount'] as double,
            payment_date: row['payment_date'] as int,
            deducted_from_payroll: (row['deducted_from_payroll'] as int) != 0));
  }

  @override
  Future<void> clearLoanRepayments() async {
    await _queryAdapter.queryNoReturn('DELETE FROM loan_repayments');
  }

  @override
  Future<List<ErpExpense>> getAllExpenses() async {
    return _queryAdapter.queryList('SELECT * FROM expenses',
        mapper: (Map<String, Object?> row) => ErpExpense(
            expense_id: row['expense_id'] as String,
            category: row['category'] as String,
            description: row['description'] as String,
            amount: row['amount'] as double,
            payment_method: row['payment_method'] as String,
            date: row['date'] as int,
            approved_by: row['approved_by'] as String));
  }

  @override
  Future<void> clearExpenses() async {
    await _queryAdapter.queryNoReturn('DELETE FROM expenses');
  }

  @override
  Future<List<ErpAsset>> getAllAssets() async {
    return _queryAdapter.queryList('SELECT * FROM assets',
        mapper: (Map<String, Object?> row) => ErpAsset(
            asset_id: row['asset_id'] as String,
            asset_name: row['asset_name'] as String,
            category: row['category'] as String,
            purchase_date: row['purchase_date'] as int,
            purchase_value: row['purchase_value'] as double,
            condition: row['condition'] as String,
            status: row['status'] as String));
  }

  @override
  Future<void> clearAssets() async {
    await _queryAdapter.queryNoReturn('DELETE FROM assets');
  }

  @override
  Future<List<ErpRepair>> getAllRepairs() async {
    return _queryAdapter.queryList('SELECT * FROM repairs',
        mapper: (Map<String, Object?> row) => ErpRepair(
            repair_id: row['repair_id'] as String,
            asset_id: row['asset_id'] as String,
            description: row['description'] as String,
            repair_cost: row['repair_cost'] as double,
            repair_date: row['repair_date'] as int,
            technician: row['technician'] as String));
  }

  @override
  Future<void> clearRepairs() async {
    await _queryAdapter.queryNoReturn('DELETE FROM repairs');
  }

  @override
  Future<List<ResourceRequest>> getAllResourceRequests() async {
    return _queryAdapter.queryList('SELECT * FROM resource_requests',
        mapper: (Map<String, Object?> row) => ResourceRequest(
            request_id: row['request_id'] as String,
            teacher_id: row['teacher_id'] as String,
            purpose: row['purpose'] as String,
            status: row['status'] as String,
            total_budget: row['total_budget'] as double,
            created_at: row['created_at'] as int));
  }

  @override
  Future<List<ResourceRequest>> getResourceRequestsByTeacher(
      String teacherId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM resource_requests WHERE teacher_id = ?1',
        mapper: (Map<String, Object?> row) => ResourceRequest(
            request_id: row['request_id'] as String,
            teacher_id: row['teacher_id'] as String,
            purpose: row['purpose'] as String,
            status: row['status'] as String,
            total_budget: row['total_budget'] as double,
            created_at: row['created_at'] as int),
        arguments: [teacherId]);
  }

  @override
  Future<List<ResourceRequest>> getResourceRequestsByStatus(
      String status) async {
    return _queryAdapter.queryList(
        'SELECT * FROM resource_requests WHERE status = ?1',
        mapper: (Map<String, Object?> row) => ResourceRequest(
            request_id: row['request_id'] as String,
            teacher_id: row['teacher_id'] as String,
            purpose: row['purpose'] as String,
            status: row['status'] as String,
            total_budget: row['total_budget'] as double,
            created_at: row['created_at'] as int),
        arguments: [status]);
  }

  @override
  Future<void> deleteResourceRequest(String requestId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM resource_requests WHERE request_id = ?1',
        arguments: [requestId]);
  }

  @override
  Future<void> clearResourceRequests() async {
    await _queryAdapter.queryNoReturn('DELETE FROM resource_requests');
  }

  @override
  Future<void> clearRequestItems() async {
    await _queryAdapter.queryNoReturn('DELETE FROM resource_request_items');
  }

  @override
  Future<List<ResourceRequestItem>> getRequestItems(String requestId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM resource_request_items WHERE request_id = ?1',
        mapper: (Map<String, Object?> row) => ResourceRequestItem(
            id: row['id'] as int?,
            request_id: row['request_id'] as String,
            item_name: row['item_name'] as String,
            quantity: row['quantity'] as int,
            price: row['price'] as double,
            total: row['total'] as double),
        arguments: [requestId]);
  }

  @override
  Future<void> deleteRequestItems(String requestId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM resource_request_items WHERE request_id = ?1',
        arguments: [requestId]);
  }

  @override
  Future<List<BudgetApproval>> getApprovalsByRequest(String requestId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM budget_approvals WHERE request_id = ?1',
        mapper: (Map<String, Object?> row) => BudgetApproval(
            id: row['id'] as int?,
            request_id: row['request_id'] as String,
            approved_by: row['approved_by'] as String,
            decision: row['decision'] as String,
            comments: row['comments'] as String,
            date: row['date'] as int),
        arguments: [requestId]);
  }

  @override
  Future<void> clearBudgetApprovals() async {
    await _queryAdapter.queryNoReturn('DELETE FROM budget_approvals');
  }

  @override
  Future<void> clearSalaryComponents() async {
    await _queryAdapter.queryNoReturn('DELETE FROM salary_components');
  }

  @override
  Future<void> clearSalaryStructures() async {
    await _queryAdapter.queryNoReturn('DELETE FROM salary_structures');
  }

  @override
  Future<void> clearSalaryStructureAssignments() async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM salary_structure_assignments');
  }

  @override
  Future<void> clearPayrollEntries() async {
    await _queryAdapter.queryNoReturn('DELETE FROM payroll_entries');
  }

  @override
  Future<List<SalaryComponent>> getAllSalaryComponents() async {
    return _queryAdapter.queryList('SELECT * FROM salary_components',
        mapper: (Map<String, Object?> row) => SalaryComponent(
            component_id: row['component_id'] as String,
            name: row['name'] as String,
            type: row['type'] as String,
            description: row['description'] as String?,
            is_statutory: (row['is_statutory'] as int) != 0,
            is_tax_applicable: (row['is_tax_applicable'] as int) != 0,
            is_attendance_linked: (row['is_attendance_linked'] as int) != 0,
            default_amount: row['default_amount'] as double));
  }

  @override
  Future<List<SalaryStructure>> getAllSalaryStructures() async {
    return _queryAdapter.queryList('SELECT * FROM salary_structures',
        mapper: (Map<String, Object?> row) => SalaryStructure(
            structure_id: row['structure_id'] as String,
            name: row['name'] as String,
            company: row['company'] as String,
            is_active: (row['is_active'] as int) != 0,
            total_earnings: row['total_earnings'] as double,
            total_deductions: row['total_deductions'] as double));
  }

  @override
  Future<List<SalaryStructureAssignment>> getAllStructureAssignments() async {
    return _queryAdapter.queryList('SELECT * FROM salary_structure_assignments',
        mapper: (Map<String, Object?> row) => SalaryStructureAssignment(
            assignment_id: row['assignment_id'] as String,
            staff_id: row['staff_id'] as String,
            structure_id: row['structure_id'] as String,
            from_date: row['from_date'] as int,
            base_salary: row['base_salary'] as double));
  }

  @override
  Future<SalaryStructureAssignment?> getAssignmentByStaff(
      String staffId) async {
    return _queryAdapter.query(
        'SELECT * FROM salary_structure_assignments WHERE staff_id = ?1',
        mapper: (Map<String, Object?> row) => SalaryStructureAssignment(
            assignment_id: row['assignment_id'] as String,
            staff_id: row['staff_id'] as String,
            structure_id: row['structure_id'] as String,
            from_date: row['from_date'] as int,
            base_salary: row['base_salary'] as double),
        arguments: [staffId]);
  }

  @override
  Future<List<PayrollEntry>> getAllPayrollEntries() async {
    return _queryAdapter.queryList('SELECT * FROM payroll_entries',
        mapper: (Map<String, Object?> row) => PayrollEntry(
            payroll_entry_id: row['payroll_entry_id'] as String,
            month: row['month'] as String,
            structure_id: row['structure_id'] as String,
            status: row['status'] as String,
            posting_date: row['posting_date'] as int,
            count_processed: row['count_processed'] as int));
  }

  @override
  Future<void> insertStaff(FinanceStaff staff) async {
    await _financeStaffInsertionAdapter.insert(
        staff, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertFeeStructure(ErpFeeStructure fee) async {
    await _erpFeeStructureInsertionAdapter.insert(
        fee, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertBilling(StudentBilling billing) async {
    await _studentBillingInsertionAdapter.insert(
        billing, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertPayment(ErpFeePayment payment) async {
    await _erpFeePaymentInsertionAdapter.insert(
        payment, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertAmenity(ErpAmenity amenity) async {
    await _erpAmenityInsertionAdapter.insert(
        amenity, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertStudentAmenity(StudentAmenity sa) async {
    await _studentAmenityInsertionAdapter.insert(
        sa, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertPayroll(Payroll payroll) async {
    await _payrollInsertionAdapter.insert(payroll, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertLoan(StaffLoan loan) async {
    await _staffLoanInsertionAdapter.insert(loan, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertLoanRepayment(LoanRepayment lr) async {
    await _loanRepaymentInsertionAdapter.insert(lr, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertExpense(ErpExpense expense) async {
    await _erpExpenseInsertionAdapter.insert(
        expense, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertAsset(ErpAsset asset) async {
    await _erpAssetInsertionAdapter.insert(asset, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertRepair(ErpRepair repair) async {
    await _erpRepairInsertionAdapter.insert(repair, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertResourceRequest(ResourceRequest request) async {
    await _resourceRequestInsertionAdapter.insert(
        request, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertRequestItem(ResourceRequestItem item) async {
    await _resourceRequestItemInsertionAdapter.insert(
        item, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertBudgetApproval(BudgetApproval approval) async {
    await _budgetApprovalInsertionAdapter.insert(
        approval, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSalaryComponent(SalaryComponent component) async {
    await _salaryComponentInsertionAdapter.insert(
        component, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSalaryStructure(SalaryStructure structure) async {
    await _salaryStructureInsertionAdapter.insert(
        structure, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertStructureAssignment(
      SalaryStructureAssignment assignment) async {
    await _salaryStructureAssignmentInsertionAdapter.insert(
        assignment, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertPayrollEntry(PayrollEntry entry) async {
    await _payrollEntryInsertionAdapter.insert(
        entry, OnConflictStrategy.replace);
  }
}
