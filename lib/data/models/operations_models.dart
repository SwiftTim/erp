// lib/data/models/operations_models.dart
// ignore_for_file: non_constant_identifier_names

import 'package:floor/floor.dart';

// ══════════════════════════════════════════════════════════════════════════════
// LEAVE-OUT MODULE
// ══════════════════════════════════════════════════════════════════════════════

@Entity(tableName: 'leave_out_requests')
class LeaveOutRequest {
  @PrimaryKey()
  final String id;
  final String student_id;
  final String student_name;
  final String reason;           // Medical / Family / Appointment / Other
  final String reason_notes;
  final String requested_by;    // parent_call / teacher / self
  final String severity;        // Normal / Serious Case
  final String status;          // Active, Returned, Cancelled
  final String created_by;
  final int created_at;

  const LeaveOutRequest({
    required this.id,
    required this.student_id,
    required this.student_name,
    required this.reason,
    this.reason_notes = '',
    required this.requested_by,
    this.severity = 'Normal',
    this.status = 'Active',
    required this.created_by,
    required this.created_at,
  });
}

@Entity(tableName: 'leave_out_events')
class LeaveOutEvent {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String leave_out_id;
  final String event_type; // EXIT / ENTRY
  final int timestamp;
  final String recorded_by;

  const LeaveOutEvent({
    this.id,
    required this.leave_out_id,
    required this.event_type,
    required this.timestamp,
    required this.recorded_by,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// SECURITY / GATE MODULE (expanded)
// ══════════════════════════════════════════════════════════════════════════════

@Entity(tableName: 'gate_logs')
class GateLog {
  @PrimaryKey()
  final String id;
  final String type; // vehicle / person / delivery / visiting_school
  final String? reg_number;
  final String contact;
  final String reason;
  final String? student_id;
  final String? destination_dept; // for deliveries
  final int entry_ts;
  final int? exit_ts;
  final String recorded_by;

  const GateLog({
    required this.id,
    required this.type,
    this.reg_number,
    required this.contact,
    required this.reason,
    this.student_id,
    this.destination_dept,
    required this.entry_ts,
    this.exit_ts,
    required this.recorded_by,
  });
}

@Entity(tableName: 'visiting_schools')
class VisitingSchool {
  @PrimaryKey()
  final String id;
  final String school_name;
  final String teacher_name;
  final int student_count;
  final String reason;
  final int entry_ts;
  final int? exit_ts;
  final String recorded_by;

  const VisitingSchool({
    required this.id,
    required this.school_name,
    required this.teacher_name,
    required this.student_count,
    required this.reason,
    required this.entry_ts,
    this.exit_ts,
    required this.recorded_by,
  });
}

@Entity(tableName: 'security_incidents')
class SecurityIncident {
  @PrimaryKey()
  final String id;
  final String shift;
  final String description;
  final String? photo_url;
  final bool flagged_indiscipline;
  final String? escalated_to;
  final int created_at;
  final String created_by;

  const SecurityIncident({
    required this.id,
    required this.shift,
    required this.description,
    this.photo_url,
    this.flagged_indiscipline = false,
    this.escalated_to,
    required this.created_at,
    required this.created_by,
  });
}

@Entity(tableName: 'camera_feeds')
class CameraFeed {
  @PrimaryKey()
  final String id;
  final String label;
  final String ip_address;
  final String access_key_hash;
  final String zone; // compound / classroom / vehicle
  final String issued_by;

  const CameraFeed({
    required this.id,
    required this.label,
    required this.ip_address,
    required this.access_key_hash,
    required this.zone,
    required this.issued_by,
  });
}

@Entity(tableName: 'duty_assignments')
class DutyAssignment {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String guard_id;
  final String guard_name;
  final String role; // lead / subordinate / frisk_male / frisk_female
  final int shift_date;

  const DutyAssignment({
    this.id,
    required this.guard_id,
    required this.guard_name,
    required this.role,
    required this.shift_date,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// STORE KEEPER MODULE
// ══════════════════════════════════════════════════════════════════════════════

@Entity(tableName: 'store_assets')
class StoreAsset {
  @PrimaryKey()
  final String id;
  final String category;
  final String name;
  final String tag_number;
  final String condition; // New, Good, Fair, Poor
  final String status;    // in_store / assigned / retired
  final int created_at;

  const StoreAsset({
    required this.id,
    required this.category,
    required this.name,
    required this.tag_number,
    this.condition = 'Good',
    this.status = 'in_store',
    required this.created_at,
  });
}

@Entity(tableName: 'asset_assignments')
class AssetAssignment {
  @PrimaryKey()
  final String id;
  final String asset_id;
  final String assigned_to_type; // staff / student / dept
  final String assigned_to_id;
  final String assign_condition;
  final String? return_condition;
  final int assigned_at;
  final int? returned_at;

  const AssetAssignment({
    required this.id,
    required this.asset_id,
    required this.assigned_to_type,
    required this.assigned_to_id,
    required this.assign_condition,
    this.return_condition,
    required this.assigned_at,
    this.returned_at,
  });
}

@Entity(tableName: 'stock_items')
class StockItem {
  @PrimaryKey()
  final String id;
  final String category; // stationery / equipment / uniform / cleaning
  final String name;
  final String unit;
  final int quantity_on_hand;
  final int reorder_level;

  const StockItem({
    required this.id,
    required this.category,
    required this.name,
    required this.unit,
    required this.quantity_on_hand,
    this.reorder_level = 5,
  });
}

@Entity(tableName: 'procurement_requests')
class ProcurementRequest {
  @PrimaryKey()
  final String id;
  final String source_module; // store / library / boarding / finance
  final String item;
  final int qty;
  final double estimated_cost;
  final String justification;
  final String requested_by;
  final String status; // pending / finance_review / approved / rejected / ordered
  final String? approval_log;
  final int created_at;

  const ProcurementRequest({
    required this.id,
    this.source_module = 'store',
    required this.item,
    required this.qty,
    required this.estimated_cost,
    required this.justification,
    required this.requested_by,
    this.status = 'pending',
    this.approval_log,
    required this.created_at,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// LIBRARY MODULE
// ══════════════════════════════════════════════════════════════════════════════

@Entity(tableName: 'library_books')
class LibraryBook {
  @PrimaryKey()
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final int total_copies;
  final int available_copies;
  final String shelf_location;
  final int version; // for optimistic concurrency

  const LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    this.isbn = '',
    this.category = 'General',
    required this.total_copies,
    required this.available_copies,
    this.shelf_location = '',
    this.version = 1,
  });
}

@Entity(tableName: 'library_loans')
class LibraryLoan {
  @PrimaryKey()
  final String id;
  final String book_id;
  final String borrower_id;
  final String borrower_name;
  final String borrower_type; // student / staff
  final int borrowed_at;
  final int due_at;
  final int? returned_at;
  final double fine_amount;

  const LibraryLoan({
    required this.id,
    required this.book_id,
    required this.borrower_id,
    required this.borrower_name,
    this.borrower_type = 'student',
    required this.borrowed_at,
    required this.due_at,
    this.returned_at,
    this.fine_amount = 0.0,
  });
}

@Entity(tableName: 'library_members')
class LibraryMember {
  @PrimaryKey()
  final String id;
  final String person_id;
  final String name;
  final String type; // student / staff
  final int borrow_limit;
  final bool is_active;

  const LibraryMember({
    required this.id,
    required this.person_id,
    required this.name,
    required this.type,
    this.borrow_limit = 3,
    this.is_active = true,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// FLEET MODULE
// ══════════════════════════════════════════════════════════════════════════════

@Entity(tableName: 'fleet_vehicles')
class FleetVehicle {
  @PrimaryKey()
  final String id;
  final String plate_number;
  final int seats;
  final String driver_id;
  final String driver_name;
  final double consumption_rate; // L/km
  final double tank_capacity;    // litres
  final double odometer_km;
  final double fuel_level;       // litres currently
  final String status; // active / maintenance / retired

  const FleetVehicle({
    required this.id,
    required this.plate_number,
    this.seats = 14,
    required this.driver_id,
    required this.driver_name,
    this.consumption_rate = 0.1,
    this.tank_capacity = 60.0,
    this.odometer_km = 0.0,
    this.fuel_level = 60.0,
    this.status = 'active',
  });
}

@Entity(tableName: 'transport_enrollments')
class TransportEnrollment {
  @PrimaryKey()
  final String id;
  final String student_id;
  final String student_name;
  final String guardian_contact;
  final String pickup_location;
  final String van_id;
  final bool active;

  const TransportEnrollment({
    required this.id,
    required this.student_id,
    required this.student_name,
    required this.guardian_contact,
    required this.pickup_location,
    required this.van_id,
    this.active = true,
  });
}

@Entity(tableName: 'transport_events')
class TransportEvent {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String student_id;
  final String van_id;
  final String event_type; // DROP / PICK
  final int timestamp;

  const TransportEvent({
    this.id,
    required this.student_id,
    required this.van_id,
    required this.event_type,
    required this.timestamp,
  });
}

@Entity(tableName: 'vehicle_maintenance_logs')
class VehicleMaintenanceLog {
  @PrimaryKey()
  final String id;
  final String vehicle_id;
  final String type; // repair / paint / extinguisher / service / oil
  final int date;
  final double cost;
  final String notes;

  const VehicleMaintenanceLog({
    required this.id,
    required this.vehicle_id,
    required this.type,
    required this.date,
    required this.cost,
    this.notes = '',
  });
}

@Entity(tableName: 'fleet_incidents')
class FleetIncident {
  @PrimaryKey()
  final String id;
  final String van_id;
  final String description;
  final int reported_at;
  final String reported_by;
  final bool notified_fleet_manager;
  final bool notified_receptionist;

  const FleetIncident({
    required this.id,
    required this.van_id,
    required this.description,
    required this.reported_at,
    required this.reported_by,
    this.notified_fleet_manager = false,
    this.notified_receptionist = false,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// TRIPS & TOURS MODULE
// ══════════════════════════════════════════════════════════════════════════════

@Entity(tableName: 'school_trips')
class SchoolTrip {
  @PrimaryKey()
  final String id;
  final String teacher_id;
  final String teacher_name;
  final String class_id;
  final String venue;
  final String purpose;
  final String student_ids; // JSON-encoded list
  final String status;      // draft / deputy_review / reception_notify / finance_budget / headteacher_sign / fleet_dispatch / completed
  final String? deputy_approved_by;
  final double amount;
  final String? headteacher_signature;
  final String? fleet_alloc_ref;
  final int created_at;
  final int? trip_date;

  const SchoolTrip({
    required this.id,
    required this.teacher_id,
    required this.teacher_name,
    required this.class_id,
    required this.venue,
    required this.purpose,
    required this.student_ids,
    this.status = 'draft',
    this.deputy_approved_by,
    this.amount = 0.0,
    this.headteacher_signature,
    this.fleet_alloc_ref,
    required this.created_at,
    this.trip_date,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// CASUAL / NON-TEACHING STAFF MODULE
// ══════════════════════════════════════════════════════════════════════════════

@Entity(tableName: 'casual_workers')
class CasualWorker {
  @PrimaryKey()
  final String id;
  final String name;
  final String national_id;
  final String job_description;
  final double agreed_rate_per_day;
  final String registered_by;
  final int start_date;
  final int? end_date;
  final bool active;
  final bool blacklisted;
  final String? blacklist_reason;

  const CasualWorker({
    required this.id,
    required this.name,
    required this.national_id,
    required this.job_description,
    required this.agreed_rate_per_day,
    required this.registered_by,
    required this.start_date,
    this.end_date,
    this.active = true,
    this.blacklisted = false,
    this.blacklist_reason,
  });
}

@Entity(tableName: 'casual_attendance')
class CasualAttendance {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String worker_id;
  final int in_ts;
  final int? out_ts;
  final String recorded_by;

  const CasualAttendance({
    this.id,
    required this.worker_id,
    required this.in_ts,
    this.out_ts,
    required this.recorded_by,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// RECEPTION MODULE
// ══════════════════════════════════════════════════════════════════════════════

@Entity(tableName: 'visitor_queue')
class VisitorQueueEntry {
  @PrimaryKey()
  final String id;
  final String visitor_name;
  final String contact;
  final String purpose;
  final String? person_to_see;
  final int arrived_at;
  final int? attended_at;
  final String status; // waiting / attended / left

  const VisitorQueueEntry({
    required this.id,
    required this.visitor_name,
    required this.contact,
    required this.purpose,
    this.person_to_see,
    required this.arrived_at,
    this.attended_at,
    this.status = 'waiting',
  });
}

@Entity(tableName: 'bulk_message_jobs')
class BulkMessageJob {
  @PrimaryKey()
  final String id;
  final String source_module; // finance / leave_out / fleet / trips
  final String message_template;
  final String recipient_list; // JSON-encoded phone numbers
  final int? sent_at;
  final String status; // queued / sent / failed

  const BulkMessageJob({
    required this.id,
    required this.source_module,
    required this.message_template,
    required this.recipient_list,
    this.sent_at,
    this.status = 'queued',
  });
}

@Entity(tableName: 'appointments')
class Appointment {
  @PrimaryKey()
  final String id;
  final String requested_with; // principal / director / deputy
  final String requester_name;
  final String requester_contact;
  final String purpose;
  final int datetime;
  final String status; // pending / confirmed / cancelled / completed

  const Appointment({
    required this.id,
    required this.requested_with,
    required this.requester_name,
    required this.requester_contact,
    required this.purpose,
    required this.datetime,
    this.status = 'pending',
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// BOARDING MODULE
// ══════════════════════════════════════════════════════════════════════════════

@Entity(tableName: 'dorm_blocks')
class DormBlock {
  @PrimaryKey()
  final String id;
  final String name;
  final String type; // boys / girls / mixed
  final int floor_count;

  const DormBlock({
    required this.id,
    required this.name,
    required this.type,
    this.floor_count = 1,
  });
}

@Entity(tableName: 'dorm_rooms')
class DormRoom {
  @PrimaryKey()
  final String id;
  final String block_id;
  final String room_number;
  final int floor;
  final double length_m;
  final double width_m;
  final int bed_count;

  const DormRoom({
    required this.id,
    required this.block_id,
    required this.room_number,
    this.floor = 1,
    required this.length_m,
    required this.width_m,
    required this.bed_count,
  });
}

@Entity(tableName: 'bed_slots')
class BedSlot {
  @PrimaryKey()
  final String id;
  final String room_id;
  final String bunk_position; // upper / lower
  final String? student_id;
  final String? student_name;
  final String? student_class;
  final String? reg_number;

  const BedSlot({
    required this.id,
    required this.room_id,
    required this.bunk_position,
    this.student_id,
    this.student_name,
    this.student_class,
    this.reg_number,
  });
}

@Entity(tableName: 'dorm_facilities')
class DormFacility {
  @PrimaryKey()
  final String id;
  final String room_or_block_id;
  final String type; // extinguisher / locker / washroom
  final int last_serviced;
  final int next_due;
  final String status; // ok / needs_service / overdue

  const DormFacility({
    required this.id,
    required this.room_or_block_id,
    required this.type,
    required this.last_serviced,
    required this.next_due,
    this.status = 'ok',
  });
}

@Entity(tableName: 'inspection_reports')
class InspectionReport {
  @PrimaryKey()
  final String id;
  final String area_type; // washroom / classroom / dining / compound
  final String condition_notes;
  final String submitted_by;
  final int submitted_at;
  final String severity; // clean / minor_issues / needs_attention / critical

  const InspectionReport({
    required this.id,
    required this.area_type,
    required this.condition_notes,
    required this.submitted_by,
    required this.submitted_at,
    this.severity = 'clean',
  });
}

@Entity(tableName: 'dining_tables')
class DiningTable {
  @PrimaryKey()
  final String id;
  final int table_number;
  final String grade_level;
  final String student_ids;  // JSON-encoded list
  final String leader_ids;   // JSON-encoded list (2 leaders)

  const DiningTable({
    required this.id,
    required this.table_number,
    required this.grade_level,
    required this.student_ids,
    required this.leader_ids,
  });
}

@Entity(tableName: 'boarding_staff')
class BoardingStaffAssignment {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String staff_id;
  final String staff_name;
  final String role; // matron / patron
  final String duties;

  const BoardingStaffAssignment({
    this.id,
    required this.staff_id,
    required this.staff_name,
    required this.role,
    this.duties = '',
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// HR MODULE
// ══════════════════════════════════════════════════════════════════════════════

@Entity(tableName: 'job_vacancies')
class JobVacancy {
  @PrimaryKey()
  final String id;
  final String title;
  final String grade;
  final String department;
  final String status; // open / finance_review / approved / filled / closed
  final String? budget_ref;
  final int created_at;

  const JobVacancy({
    required this.id,
    required this.title,
    required this.grade,
    required this.department,
    this.status = 'open',
    this.budget_ref,
    required this.created_at,
  });
}

@Entity(tableName: 'staff_documents')
class StaffDocument {
  @PrimaryKey()
  final String id;
  final String staff_id;
  final String doc_type; // tsc / degree / good_conduct / id / nssf / sha / other
  final String file_url;
  final String file_name;
  final int uploaded_at;
  final String uploaded_by;

  const StaffDocument({
    required this.id,
    required this.staff_id,
    required this.doc_type,
    required this.file_url,
    required this.file_name,
    required this.uploaded_at,
    required this.uploaded_by,
  });
}

@Entity(tableName: 'staff_statutory')
class StaffStatutory {
  @PrimaryKey()
  final String staff_id;
  final String? nssf_number;
  final String? sha_number;
  final String? tsc_number;
  final String? national_id;
  final String? email;

  const StaffStatutory({
    required this.staff_id,
    this.nssf_number,
    this.sha_number,
    this.tsc_number,
    this.national_id,
    this.email,
  });
}

@Entity(tableName: 'workforce_incidents')
class WorkforceIncident {
  @PrimaryKey()
  final String id;
  final String staff_id;
  final String staff_name;
  final String type; // assault / misconduct / other
  final String description;
  final String reported_by;
  final String? action_taken;
  final String status; // open / under_review / resolved
  final int created_at;

  const WorkforceIncident({
    required this.id,
    required this.staff_id,
    required this.staff_name,
    required this.type,
    required this.description,
    required this.reported_by,
    this.action_taken,
    this.status = 'open',
    required this.created_at,
  });
}

@Entity(tableName: 'welfare_funds')
class WelfareFund {
  @PrimaryKey()
  final String id;
  final String name; // e.g. "Funeral Kitty"
  final double balance;
  final int created_at;

  const WelfareFund({
    required this.id,
    required this.name,
    this.balance = 0.0,
    required this.created_at,
  });
}

@Entity(tableName: 'welfare_contributions')
class WelfareContribution {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String fund_id;
  final String staff_id;
  final String staff_name;
  final double amount;
  final String type;  // contribution / payout
  final int date;

  const WelfareContribution({
    this.id,
    required this.fund_id,
    required this.staff_id,
    required this.staff_name,
    required this.amount,
    this.type = 'contribution',
    required this.date,
  });
}

@Entity(tableName: 'teacher_quarters')
class TeacherQuarterAssignment {
  @PrimaryKey()
  final String id;
  final String staff_id;
  final String staff_name;
  final String quarter_unit;
  final int assigned_date;
  final bool active;

  const TeacherQuarterAssignment({
    required this.id,
    required this.staff_id,
    required this.staff_name,
    required this.quarter_unit,
    required this.assigned_date,
    this.active = true,
  });
}
