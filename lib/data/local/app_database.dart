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
import '../models/department_activity_model.dart';
import '../models/club_model.dart';
import '../models/tod_model.dart';
import '../models/messaging_models.dart';
import '../models/finance_erp_models.dart';
import '../models/operations_models.dart';
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
import 'daos/chat_dao.dart';
import 'daos/calendar_dao.dart';
import 'daos/notification_dao.dart';
import 'daos/department_dao.dart';
import 'daos/dept_activity_dao.dart';
import 'daos/club_dao.dart';
import 'daos/tod_dao.dart';
import 'daos/finance_erp_dao.dart';
import 'daos/operations_dao.dart';

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

final migration4to5 = Migration(4, 5, (database) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `dept_documents` (
      `id` TEXT NOT NULL,
      `department_id` TEXT NOT NULL,
      `title` TEXT NOT NULL,
      `category` TEXT NOT NULL,
      `file_path` TEXT,
      `file_name` TEXT NOT NULL,
      `description` TEXT,
      `uploaded_by` TEXT NOT NULL,
      `uploaded_at` INTEGER NOT NULL,
      `status` TEXT NOT NULL,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `dept_meetings` (
      `id` TEXT NOT NULL,
      `department_id` TEXT NOT NULL,
      `title` TEXT NOT NULL,
      `agenda` TEXT NOT NULL,
      `scheduled_at` INTEGER NOT NULL,
      `venue` TEXT NOT NULL,
      `minutes` TEXT,
      `organized_by` TEXT NOT NULL,
      `status` TEXT NOT NULL,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `dept_activities` (
      `id` INTEGER PRIMARY KEY AUTOINCREMENT,
      `department_id` TEXT NOT NULL,
      `module_type` TEXT NOT NULL,
      `title` TEXT NOT NULL,
      `data` TEXT,
      `recorded_by` TEXT NOT NULL,
      `recorded_at` INTEGER NOT NULL,
      `status` TEXT NOT NULL,
      `grade` TEXT,
      `subject` TEXT,
      FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `dept_compliance` (
      `id` INTEGER PRIMARY KEY AUTOINCREMENT,
      `department_id` TEXT NOT NULL,
      `item` TEXT NOT NULL,
      `is_done` INTEGER NOT NULL,
      `due_date` INTEGER,
      `completed_by` TEXT,
      `completed_at` INTEGER,
      `term` TEXT NOT NULL,
      `year` TEXT NOT NULL,
      FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`)
    )
  ''');
});

final migration5to6 = Migration(5, 6, (database) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `clubs` (
      `id` TEXT NOT NULL,
      `name` TEXT NOT NULL,
      `category` TEXT NOT NULL,
      `description` TEXT NOT NULL,
      `patron_id` TEXT,
      `assistant_patron_id` TEXT,
      `meeting_day` TEXT,
      `meeting_time` TEXT,
      `status` TEXT NOT NULL,
      `capacity_limit` INTEGER NOT NULL,
      `created_at` INTEGER NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `club_members` (
      `id` INTEGER PRIMARY KEY AUTOINCREMENT,
      `club_id` TEXT NOT NULL,
      `student_id` TEXT NOT NULL,
      `role` TEXT NOT NULL,
      `joined_at` INTEGER NOT NULL,
      `joined_by` TEXT NOT NULL,
      `consent_form_signed` INTEGER NOT NULL,
      `parent_contact_verified` INTEGER NOT NULL,
      FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `club_activities` (
      `id` TEXT NOT NULL,
      `club_id` TEXT NOT NULL,
      `title` TEXT NOT NULL,
      `description` TEXT NOT NULL,
      `type` TEXT NOT NULL,
      `scheduled_at` INTEGER NOT NULL,
      `venue` TEXT NOT NULL,
      `status` TEXT NOT NULL,
      `recorded_at` INTEGER NOT NULL,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `club_attendance` (
      `id` INTEGER PRIMARY KEY AUTOINCREMENT,
      `activity_id` TEXT NOT NULL,
      `student_id` TEXT NOT NULL,
      `status` TEXT NOT NULL,
      `remarks` TEXT,
      FOREIGN KEY (`activity_id`) REFERENCES `club_activities` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `club_reports` (
      `id` TEXT NOT NULL,
      `club_id` TEXT NOT NULL,
      `term` INTEGER NOT NULL,
      `year` TEXT NOT NULL,
      `content` TEXT NOT NULL,
      `submitted_at` INTEGER NOT NULL,
      `patron_id` TEXT NOT NULL,
      `status` TEXT NOT NULL,
      PRIMARY KEY (`id`),
      FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`)
    )
  ''');
});

final migration6to7 = Migration(6, 7, (database) async {
  // Ensure clubs table has all required columns for the 2026 schema
  await database.execute('DROP TABLE IF EXISTS `clubs`');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `clubs` (
      `id` TEXT NOT NULL,
      `name` TEXT NOT NULL,
      `category` TEXT NOT NULL,
      `description` TEXT NOT NULL,
      `patron_id` TEXT,
      `assistant_patron_id` TEXT,
      `meeting_day` TEXT,
      `meeting_time` TEXT,
      `status` TEXT NOT NULL,
      `capacity_limit` INTEGER NOT NULL,
      `created_at` INTEGER NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');
});

final migration9to10 = Migration(9, 10, (database) async {
  await database.execute('ALTER TABLE `app_notifications` ADD COLUMN `reference_id` TEXT');
});

final migration8to9 = Migration(8, 9, (database) async {
  // Chat messages (direct + group)
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `chat_messages` (
      `id` TEXT NOT NULL,
      `sender_id` TEXT NOT NULL,
      `receiver_id` TEXT,
      `group_id` TEXT,
      `message` TEXT NOT NULL,
      `file_path` TEXT,
      `file_name` TEXT,
      `file_type` TEXT,
      `reply_to_id` TEXT,
      `status` TEXT NOT NULL,
      `timestamp` INTEGER NOT NULL,
      `is_deleted` INTEGER NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `chat_groups` (
      `id` TEXT NOT NULL,
      `name` TEXT NOT NULL,
      `type` TEXT NOT NULL,
      `dept_id` TEXT,
      `created_by` TEXT NOT NULL,
      `created_at` INTEGER NOT NULL,
      `icon_code` INTEGER,
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `chat_group_members` (
      `id` INTEGER PRIMARY KEY AUTOINCREMENT,
      `group_id` TEXT NOT NULL,
      `user_id` TEXT NOT NULL,
      `joined_at` INTEGER NOT NULL
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `chat_read_receipts` (
      `id` INTEGER PRIMARY KEY AUTOINCREMENT,
      `message_id` TEXT NOT NULL,
      `user_id` TEXT NOT NULL,
      `read_at` INTEGER NOT NULL
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `calendar_events` (
      `id` TEXT NOT NULL,
      `title` TEXT NOT NULL,
      `event_type` TEXT NOT NULL,
      `start_date` INTEGER NOT NULL,
      `end_date` INTEGER NOT NULL,
      `description` TEXT,
      `priority` TEXT NOT NULL,
      `created_by` TEXT NOT NULL,
      `created_at` INTEGER NOT NULL,
      `reminder_days` INTEGER NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `app_notifications` (
      `id` INTEGER PRIMARY KEY AUTOINCREMENT,
      `user_id` TEXT NOT NULL,
      `title` TEXT NOT NULL,
      `message` TEXT NOT NULL,
      `link` TEXT,
      `notif_type` TEXT NOT NULL,
      `is_read` INTEGER NOT NULL,
      `created_at` INTEGER NOT NULL
    )
  ''');
});

final migration7to8 = Migration(7, 8, (database) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `duty_roster` (
      `id` TEXT NOT NULL,
      `teacher_id` TEXT NOT NULL,
      `week_number` INTEGER NOT NULL,
      `start_date` INTEGER NOT NULL,
      `end_date` INTEGER NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `tod_records` (
      `id` TEXT NOT NULL,
      `student_id` TEXT NOT NULL,
      `offence` TEXT NOT NULL,
      `punishment` TEXT NOT NULL,
      `remarks` TEXT,
      `teacher_id` TEXT NOT NULL,
      `date` INTEGER NOT NULL,
      `status` TEXT NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `student_behavior` (
      `student_id` TEXT NOT NULL,
      `weekly_offences` INTEGER NOT NULL,
      `status` TEXT NOT NULL,
      PRIMARY KEY (`student_id`)
    )
  ''');
});

final migration10to11 = Migration(10, 11, (database) async {
  await database.execute('CREATE TABLE IF NOT EXISTS `staff` (`staff_id` TEXT NOT NULL, `name` TEXT NOT NULL, `role` TEXT NOT NULL, `department` TEXT NOT NULL, `employment_type` TEXT NOT NULL, `date_hired` INTEGER NOT NULL, PRIMARY KEY (`staff_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `fee_structure` (`fee_id` TEXT NOT NULL, `fee_name` TEXT NOT NULL, `amount` REAL NOT NULL, `term` INTEGER NOT NULL, `is_optional` INTEGER NOT NULL, PRIMARY KEY (`fee_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `student_billing` (`billing_id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `term` INTEGER NOT NULL, `tuition` REAL NOT NULL, `transport` REAL NOT NULL, `meals` REAL NOT NULL, `swimming` REAL NOT NULL, `other_charges` REAL NOT NULL, `total_amount` REAL NOT NULL, `balance` REAL NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`billing_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `fee_payments` (`payment_id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `amount_paid` REAL NOT NULL, `payment_method` TEXT NOT NULL, `transaction_code` TEXT NOT NULL, `date_paid` INTEGER NOT NULL, `received_by` TEXT NOT NULL, PRIMARY KEY (`payment_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `amenities` (`amenity_id` TEXT NOT NULL, `amenity_name` TEXT NOT NULL, `fee_amount` REAL NOT NULL, `billing_type` TEXT NOT NULL, PRIMARY KEY (`amenity_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `student_amenities` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `amenity_id` TEXT NOT NULL, `term` INTEGER NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `payroll` (`payroll_id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `month` TEXT NOT NULL, `basic_salary` REAL NOT NULL, `allowances` REAL NOT NULL, `deductions` REAL NOT NULL, `loan_deduction` REAL NOT NULL, `net_salary` REAL NOT NULL, `processed_by` TEXT NOT NULL, `date_processed` INTEGER NOT NULL, PRIMARY KEY (`payroll_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `staff_loans` (`loan_id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `loan_amount` REAL NOT NULL, `interest_rate` REAL NOT NULL, `issue_date` INTEGER NOT NULL, `repayment_period` INTEGER NOT NULL, `balance` REAL NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`loan_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `loan_repayments` (`repayment_id` TEXT NOT NULL, `loan_id` TEXT NOT NULL, `amount` REAL NOT NULL, `payment_date` INTEGER NOT NULL, `deducted_from_payroll` INTEGER NOT NULL, PRIMARY KEY (`repayment_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `expenses` (`expense_id` TEXT NOT NULL, `category` TEXT NOT NULL, `description` TEXT NOT NULL, `amount` REAL NOT NULL, `payment_method` TEXT NOT NULL, `date` INTEGER NOT NULL, `approved_by` TEXT NOT NULL, PRIMARY KEY (`expense_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `assets` (`asset_id` TEXT NOT NULL, `asset_name` TEXT NOT NULL, `category` TEXT NOT NULL, `purchase_date` INTEGER NOT NULL, `purchase_value` REAL NOT NULL, `condition` TEXT NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`asset_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `repairs` (`repair_id` TEXT NOT NULL, `asset_id` TEXT NOT NULL, `description` TEXT NOT NULL, `repair_cost` REAL NOT NULL, `repair_date` INTEGER NOT NULL, `technician` TEXT NOT NULL, PRIMARY KEY (`repair_id`))');
});

final migration11to12 = Migration(11, 12, (database) async {
  await database.execute('ALTER TABLE payroll ADD COLUMN nssf REAL NOT NULL DEFAULT 0.0');
  await database.execute('ALTER TABLE payroll ADD COLUMN shif REAL NOT NULL DEFAULT 0.0');
  await database.execute('ALTER TABLE payroll ADD COLUMN housing_levy REAL NOT NULL DEFAULT 0.0');
  await database.execute('ALTER TABLE payroll ADD COLUMN paye REAL NOT NULL DEFAULT 0.0');
});

final migration12to13 = Migration(12, 13, (database) async {
  await database.execute('ALTER TABLE payroll ADD COLUMN status TEXT NOT NULL DEFAULT "Draft"');
  await database.execute('ALTER TABLE staff ADD COLUMN bank_name TEXT NOT NULL DEFAULT "Equity Bank"');
  await database.execute('ALTER TABLE staff ADD COLUMN account_no TEXT NOT NULL DEFAULT "0123456789012"');
  await database.execute('ALTER TABLE staff ADD COLUMN bank_branch TEXT NOT NULL DEFAULT "Corporate"');
});

final migration13to14 = Migration(13, 14, (database) async {
  // Update Staff Loans
  await database.execute('ALTER TABLE staff_loans ADD COLUMN monthly_deduction REAL NOT NULL DEFAULT 0.0');
  await database.execute('ALTER TABLE staff_loans ADD COLUMN total_repayment REAL NOT NULL DEFAULT 0.0');
  await database.execute('ALTER TABLE staff_loans ADD COLUMN approved_by TEXT');
  await database.execute('ALTER TABLE staff_loans ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0');
  // Rename balance to remaining_balance is not supported directly in sqlite ALTER but we can add it and data is demo mostly
  await database.execute('ALTER TABLE staff_loans ADD COLUMN remaining_balance REAL NOT NULL DEFAULT 0.0');
  
  // Update Loan Repayments
  await database.execute('ALTER TABLE loan_repayments ADD COLUMN payroll_id TEXT');
  
  // Create Resource Procurement Tables
  await database.execute('CREATE TABLE IF NOT EXISTS `resource_requests` (`request_id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `purpose` TEXT NOT NULL, `status` TEXT NOT NULL, `total_budget` REAL NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`request_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `resource_request_items` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `request_id` TEXT NOT NULL, `item_name` TEXT NOT NULL, `quantity` INTEGER NOT NULL, `price` REAL NOT NULL, `total` REAL NOT NULL)');
  await database.execute('CREATE TABLE IF NOT EXISTS `budget_approvals` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `request_id` TEXT NOT NULL, `approved_by` TEXT NOT NULL, `decision` TEXT NOT NULL, `comments` TEXT NOT NULL, `date` INTEGER NOT NULL)');
});

final migration14to15 = Migration(14, 15, (database) async {
  await database.execute('CREATE TABLE IF NOT EXISTS `salary_components` (`component_id` TEXT NOT NULL, `name` TEXT NOT NULL, `type` TEXT NOT NULL, `description` TEXT, `is_statutory` INTEGER NOT NULL, `is_tax_applicable` INTEGER NOT NULL, `is_attendance_linked` INTEGER NOT NULL, `default_amount` REAL NOT NULL, PRIMARY KEY (`component_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `salary_structures` (`structure_id` TEXT NOT NULL, `name` TEXT NOT NULL, `company` TEXT NOT NULL, `is_active` INTEGER NOT NULL, `total_earnings` REAL NOT NULL, `total_deductions` REAL NOT NULL, PRIMARY KEY (`structure_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `salary_structure_assignments` (`assignment_id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `structure_id` TEXT NOT NULL, `from_date` INTEGER NOT NULL, `base_salary` REAL NOT NULL, PRIMARY KEY (`assignment_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `payroll_entries` (`payroll_entry_id` TEXT NOT NULL, `month` TEXT NOT NULL, `structure_id` TEXT NOT NULL, `status` TEXT NOT NULL, `posting_date` INTEGER NOT NULL, `count_processed` INTEGER NOT NULL, PRIMARY KEY (`payroll_entry_id`))');
});

final migration16to17 = Migration(16, 17, (database) async {
  // Leave-Out Module
  await database.execute('CREATE TABLE IF NOT EXISTS `leave_out_requests` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `student_name` TEXT NOT NULL, `reason` TEXT NOT NULL, `reason_notes` TEXT NOT NULL, `requested_by` TEXT NOT NULL, `severity` TEXT NOT NULL, `status` TEXT NOT NULL, `created_by` TEXT NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `leave_out_events` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `leave_out_id` TEXT NOT NULL, `event_type` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `recorded_by` TEXT NOT NULL)');
  // Gate / Security Expanded
  await database.execute('CREATE TABLE IF NOT EXISTS `gate_logs` (`id` TEXT NOT NULL, `type` TEXT NOT NULL, `reg_number` TEXT, `contact` TEXT NOT NULL, `reason` TEXT NOT NULL, `student_id` TEXT, `destination_dept` TEXT, `entry_ts` INTEGER NOT NULL, `exit_ts` INTEGER, `recorded_by` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `visiting_schools` (`id` TEXT NOT NULL, `school_name` TEXT NOT NULL, `teacher_name` TEXT NOT NULL, `student_count` INTEGER NOT NULL, `reason` TEXT NOT NULL, `entry_ts` INTEGER NOT NULL, `exit_ts` INTEGER, `recorded_by` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `security_incidents` (`id` TEXT NOT NULL, `shift` TEXT NOT NULL, `description` TEXT NOT NULL, `photo_url` TEXT, `flagged_indiscipline` INTEGER NOT NULL, `escalated_to` TEXT, `created_at` INTEGER NOT NULL, `created_by` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `camera_feeds` (`id` TEXT NOT NULL, `label` TEXT NOT NULL, `ip_address` TEXT NOT NULL, `access_key_hash` TEXT NOT NULL, `zone` TEXT NOT NULL, `issued_by` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `duty_assignments` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `guard_id` TEXT NOT NULL, `guard_name` TEXT NOT NULL, `role` TEXT NOT NULL, `shift_date` INTEGER NOT NULL)');
  // Store Keeper
  await database.execute('CREATE TABLE IF NOT EXISTS `store_assets` (`id` TEXT NOT NULL, `category` TEXT NOT NULL, `name` TEXT NOT NULL, `tag_number` TEXT NOT NULL, `condition` TEXT NOT NULL, `status` TEXT NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `asset_assignments` (`id` TEXT NOT NULL, `asset_id` TEXT NOT NULL, `assigned_to_type` TEXT NOT NULL, `assigned_to_id` TEXT NOT NULL, `assign_condition` TEXT NOT NULL, `return_condition` TEXT, `assigned_at` INTEGER NOT NULL, `returned_at` INTEGER, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `stock_items` (`id` TEXT NOT NULL, `category` TEXT NOT NULL, `name` TEXT NOT NULL, `unit` TEXT NOT NULL, `quantity_on_hand` INTEGER NOT NULL, `reorder_level` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `procurement_requests` (`id` TEXT NOT NULL, `source_module` TEXT NOT NULL, `item` TEXT NOT NULL, `qty` INTEGER NOT NULL, `estimated_cost` REAL NOT NULL, `justification` TEXT NOT NULL, `requested_by` TEXT NOT NULL, `status` TEXT NOT NULL, `approval_log` TEXT, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  // Library
  await database.execute('CREATE TABLE IF NOT EXISTS `library_books` (`id` TEXT NOT NULL, `title` TEXT NOT NULL, `author` TEXT NOT NULL, `isbn` TEXT NOT NULL, `category` TEXT NOT NULL, `total_copies` INTEGER NOT NULL, `available_copies` INTEGER NOT NULL, `shelf_location` TEXT NOT NULL, `version` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `library_loans` (`id` TEXT NOT NULL, `book_id` TEXT NOT NULL, `borrower_id` TEXT NOT NULL, `borrower_name` TEXT NOT NULL, `borrower_type` TEXT NOT NULL, `borrowed_at` INTEGER NOT NULL, `due_at` INTEGER NOT NULL, `returned_at` INTEGER, `fine_amount` REAL NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `library_members` (`id` TEXT NOT NULL, `person_id` TEXT NOT NULL, `name` TEXT NOT NULL, `type` TEXT NOT NULL, `borrow_limit` INTEGER NOT NULL, `is_active` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  // Fleet
  await database.execute('CREATE TABLE IF NOT EXISTS `fleet_vehicles` (`id` TEXT NOT NULL, `plate_number` TEXT NOT NULL, `seats` INTEGER NOT NULL, `driver_id` TEXT NOT NULL, `driver_name` TEXT NOT NULL, `consumption_rate` REAL NOT NULL, `tank_capacity` REAL NOT NULL, `odometer_km` REAL NOT NULL, `fuel_level` REAL NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `transport_enrollments` (`id` TEXT NOT NULL, `student_id` TEXT NOT NULL, `student_name` TEXT NOT NULL, `guardian_contact` TEXT NOT NULL, `pickup_location` TEXT NOT NULL, `van_id` TEXT NOT NULL, `active` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `transport_events` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `student_id` TEXT NOT NULL, `van_id` TEXT NOT NULL, `event_type` TEXT NOT NULL, `timestamp` INTEGER NOT NULL)');
  await database.execute('CREATE TABLE IF NOT EXISTS `vehicle_maintenance_logs` (`id` TEXT NOT NULL, `vehicle_id` TEXT NOT NULL, `type` TEXT NOT NULL, `date` INTEGER NOT NULL, `cost` REAL NOT NULL, `notes` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `fleet_incidents` (`id` TEXT NOT NULL, `van_id` TEXT NOT NULL, `description` TEXT NOT NULL, `reported_at` INTEGER NOT NULL, `reported_by` TEXT NOT NULL, `notified_fleet_manager` INTEGER NOT NULL, `notified_receptionist` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  // Trips
  await database.execute('CREATE TABLE IF NOT EXISTS `school_trips` (`id` TEXT NOT NULL, `teacher_id` TEXT NOT NULL, `teacher_name` TEXT NOT NULL, `class_id` TEXT NOT NULL, `venue` TEXT NOT NULL, `purpose` TEXT NOT NULL, `student_ids` TEXT NOT NULL, `status` TEXT NOT NULL, `deputy_approved_by` TEXT, `amount` REAL NOT NULL, `headteacher_signature` TEXT, `fleet_alloc_ref` TEXT, `created_at` INTEGER NOT NULL, `trip_date` INTEGER, PRIMARY KEY (`id`))');
  // Casual Workers
  await database.execute('CREATE TABLE IF NOT EXISTS `casual_workers` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `national_id` TEXT NOT NULL, `job_description` TEXT NOT NULL, `agreed_rate_per_day` REAL NOT NULL, `registered_by` TEXT NOT NULL, `start_date` INTEGER NOT NULL, `end_date` INTEGER, `active` INTEGER NOT NULL, `blacklisted` INTEGER NOT NULL, `blacklist_reason` TEXT, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `casual_attendance` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `worker_id` TEXT NOT NULL, `in_ts` INTEGER NOT NULL, `out_ts` INTEGER, `recorded_by` TEXT NOT NULL)');
  // Reception
  await database.execute('CREATE TABLE IF NOT EXISTS `visitor_queue` (`id` TEXT NOT NULL, `visitor_name` TEXT NOT NULL, `contact` TEXT NOT NULL, `purpose` TEXT NOT NULL, `person_to_see` TEXT, `arrived_at` INTEGER NOT NULL, `attended_at` INTEGER, `status` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `bulk_message_jobs` (`id` TEXT NOT NULL, `source_module` TEXT NOT NULL, `message_template` TEXT NOT NULL, `recipient_list` TEXT NOT NULL, `sent_at` INTEGER, `status` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `appointments` (`id` TEXT NOT NULL, `requested_with` TEXT NOT NULL, `requester_name` TEXT NOT NULL, `requester_contact` TEXT NOT NULL, `purpose` TEXT NOT NULL, `datetime` INTEGER NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`id`))');
  // Boarding
  await database.execute('CREATE TABLE IF NOT EXISTS `dorm_blocks` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `type` TEXT NOT NULL, `floor_count` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `dorm_rooms` (`id` TEXT NOT NULL, `block_id` TEXT NOT NULL, `room_number` TEXT NOT NULL, `floor` INTEGER NOT NULL, `length_m` REAL NOT NULL, `width_m` REAL NOT NULL, `bed_count` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `bed_slots` (`id` TEXT NOT NULL, `room_id` TEXT NOT NULL, `bunk_position` TEXT NOT NULL, `student_id` TEXT, `student_name` TEXT, `student_class` TEXT, `reg_number` TEXT, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `dorm_facilities` (`id` TEXT NOT NULL, `room_or_block_id` TEXT NOT NULL, `type` TEXT NOT NULL, `last_serviced` INTEGER NOT NULL, `next_due` INTEGER NOT NULL, `status` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `inspection_reports` (`id` TEXT NOT NULL, `area_type` TEXT NOT NULL, `condition_notes` TEXT NOT NULL, `submitted_by` TEXT NOT NULL, `submitted_at` INTEGER NOT NULL, `severity` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `dining_tables` (`id` TEXT NOT NULL, `table_number` INTEGER NOT NULL, `grade_level` TEXT NOT NULL, `student_ids` TEXT NOT NULL, `leader_ids` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `boarding_staff` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `staff_id` TEXT NOT NULL, `staff_name` TEXT NOT NULL, `role` TEXT NOT NULL, `duties` TEXT NOT NULL)');
  // HR
  await database.execute('CREATE TABLE IF NOT EXISTS `job_vacancies` (`id` TEXT NOT NULL, `title` TEXT NOT NULL, `grade` TEXT NOT NULL, `department` TEXT NOT NULL, `status` TEXT NOT NULL, `budget_ref` TEXT, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `staff_documents` (`id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `doc_type` TEXT NOT NULL, `file_url` TEXT NOT NULL, `file_name` TEXT NOT NULL, `uploaded_at` INTEGER NOT NULL, `uploaded_by` TEXT NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `staff_statutory` (`staff_id` TEXT NOT NULL, `nssf_number` TEXT, `sha_number` TEXT, `tsc_number` TEXT, `national_id` TEXT, `email` TEXT, PRIMARY KEY (`staff_id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `workforce_incidents` (`id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `staff_name` TEXT NOT NULL, `type` TEXT NOT NULL, `description` TEXT NOT NULL, `reported_by` TEXT NOT NULL, `action_taken` TEXT, `status` TEXT NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `welfare_funds` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `balance` REAL NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`id`))');
  await database.execute('CREATE TABLE IF NOT EXISTS `welfare_contributions` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `fund_id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `staff_name` TEXT NOT NULL, `amount` REAL NOT NULL, `type` TEXT NOT NULL, `date` INTEGER NOT NULL)');
  await database.execute('CREATE TABLE IF NOT EXISTS `teacher_quarters` (`id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `staff_name` TEXT NOT NULL, `quarter_unit` TEXT NOT NULL, `assigned_date` INTEGER NOT NULL, `active` INTEGER NOT NULL, PRIMARY KEY (`id`))');
});

final migration15to16 = Migration(15, 16, (database) async {
  // Fix staff_loans table schema mismatch
  await database.execute('CREATE TABLE IF NOT EXISTS `staff_loans_backup` (`loan_id` TEXT NOT NULL, `staff_id` TEXT NOT NULL, `loan_amount` REAL NOT NULL, `interest_rate` REAL NOT NULL, `repayment_period` INTEGER NOT NULL, `monthly_deduction` REAL NOT NULL, `total_repayment` REAL NOT NULL, `remaining_balance` REAL NOT NULL, `status` TEXT NOT NULL, `approved_by` TEXT, `issue_date` INTEGER NOT NULL, `created_at` INTEGER NOT NULL, PRIMARY KEY (`loan_id`))');
  
  // Try to migrate data if columns exist, otherwise start fresh (seeding will handle it)
  try {
    await database.execute('''
      INSERT INTO `staff_loans_backup` (loan_id, staff_id, loan_amount, interest_rate, repayment_period, monthly_deduction, total_repayment, remaining_balance, status, approved_by, issue_date, created_at)
      SELECT loan_id, staff_id, loan_amount, interest_rate, repayment_period, monthly_deduction, total_repayment, remaining_balance, status, approved_by, issue_date, created_at FROM staff_loans
    ''');
  } catch (_) {
    // If migration fails due to missing columns in old table, we'll just have an empty table which the seeder will fill.
  }

  await database.execute('DROP TABLE `staff_loans`');
  await database.execute('ALTER TABLE `staff_loans_backup` RENAME TO `staff_loans`');
});

@Database(version: 17, entities: [
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
  InventoryAsset,
  AssetMaintenanceLog,
  OfficialMemo,
  MemoReadRecord,
  Substitution,
  SystemLog,
  StaffLeave,
  StaffAttendance,
  TeachingAssignment,
  ClubModel,
  ClubMemberModel,
  ClubActivityModel,
  ClubAttendanceModel,
  ClubReportModel,
  DepartmentModel,
  DepartmentMemberModel,
  SubjectTermApprovalModel,
  ApprovalLogModel,
  DeptDocument,
  DeptMeeting,
  DeptActivity,
  DeptCompliance,
  DutyRosterModel,
  TodRecordModel,
  StudentBehaviorModel,
  // Messaging Hub
  ChatMessage,
  ChatGroup,
  ChatGroupMember,
  ChatReadReceipt,
  CalendarEvent,
  AppNotification,
  FinanceStaff,
  ErpFeeStructure,
  StudentBilling,
  ErpFeePayment,
  ErpAmenity,
  StudentAmenity,
  Payroll,
  StaffLoan,
  LoanRepayment,
  ErpExpense,
  ErpAsset,
  ErpRepair,
  ResourceRequest,
  ResourceRequestItem,
  BudgetApproval,
  SalaryComponent,
  SalaryStructure,
  SalaryStructureAssignment,
  PayrollEntry,
  // Operations Modules
  LeaveOutRequest,
  LeaveOutEvent,
  GateLog,
  VisitingSchool,
  SecurityIncident,
  CameraFeed,
  DutyAssignment,
  StoreAsset,
  AssetAssignment,
  StockItem,
  ProcurementRequest,
  LibraryBook,
  LibraryLoan,
  LibraryMember,
  FleetVehicle,
  TransportEnrollment,
  TransportEvent,
  VehicleMaintenanceLog,
  FleetIncident,
  SchoolTrip,
  CasualWorker,
  CasualAttendance,
  VisitorQueueEntry,
  BulkMessageJob,
  Appointment,
  DormBlock,
  DormRoom,
  BedSlot,
  DormFacility,
  InspectionReport,
  DiningTable,
  BoardingStaffAssignment,
  JobVacancy,
  StaffDocument,
  StaffStatutory,
  WorkforceIncident,
  WelfareFund,
  WelfareContribution,
  TeacherQuarterAssignment,
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
  ChatDao get chatDao;
  CalendarDao get calendarDao;
  NotificationDao get notificationDao;
  DepartmentDao get departmentDao;
  DeptActivityDao get deptActivityDao;
  ClubDao get clubDao;
  TodDao get todDao;
  FinanceErpDao get financeErpDao;
  OperationsDao get operationsDao;

  static Future<AppDatabase> create() async {
    return await $FloorAppDatabase
        .databaseBuilder('cbc_school.db')
        .addMigrations([
          migration1to2, migration2to3, migration3to4, migration4to5,
          migration5to6, migration6to7, migration7to8, migration8to9,
          migration9to10, migration10to11, migration11to12, migration12to13, migration13to14, migration14to15,
          migration15to16, migration16to17,
        ])
        .build();
    }
}
