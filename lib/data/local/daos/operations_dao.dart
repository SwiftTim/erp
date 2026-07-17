// lib/data/local/daos/operations_dao.dart

import 'package:floor/floor.dart';
import '../../models/operations_models.dart';

@dao
abstract class OperationsDao {
  // ── Leave-Out ──────────────────────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLeaveOut(LeaveOutRequest req);

  @Query('SELECT * FROM leave_out_requests ORDER BY created_at DESC')
  Future<List<LeaveOutRequest>> getAllLeaveOuts();

  @Query('SELECT * FROM leave_out_requests WHERE status = :status ORDER BY created_at DESC')
  Future<List<LeaveOutRequest>> getLeaveOutsByStatus(String status);

  @Query('SELECT * FROM leave_out_requests WHERE id = :id')
  Future<LeaveOutRequest?> getLeaveOutById(String id);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLeaveOutEvent(LeaveOutEvent event);

  @Query('SELECT * FROM leave_out_events WHERE leave_out_id = :id ORDER BY timestamp DESC')
  Future<List<LeaveOutEvent>> getLeaveOutEvents(String id);

  @Query('UPDATE leave_out_requests SET status = :status WHERE id = :id')
  Future<void> updateLeaveOutStatus(String id, String status);

  // ── Gate / Security (expanded) ─────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertGateLog(GateLog log);

  @Query('SELECT * FROM gate_logs ORDER BY entry_ts DESC LIMIT 100')
  Future<List<GateLog>> getGateLogs();

  @Query('SELECT * FROM gate_logs WHERE exit_ts IS NULL ORDER BY entry_ts DESC')
  Future<List<GateLog>> getActiveGateLogs();

  @Query('UPDATE gate_logs SET exit_ts = :exitTs WHERE id = :id')
  Future<void> checkOutGate(String id, int exitTs);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertVisitingSchool(VisitingSchool vs);

  @Query('SELECT * FROM visiting_schools ORDER BY entry_ts DESC')
  Future<List<VisitingSchool>> getVisitingSchools();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSecurityIncident(SecurityIncident inc);

  @Query('SELECT * FROM security_incidents ORDER BY created_at DESC')
  Future<List<SecurityIncident>> getSecurityIncidents();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCameraFeed(CameraFeed feed);

  @Query('SELECT * FROM camera_feeds')
  Future<List<CameraFeed>> getCameraFeeds();

  @Query('SELECT * FROM camera_feeds WHERE zone = :zone')
  Future<List<CameraFeed>> getCameraFeedsByZone(String zone);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertDutyAssignment(DutyAssignment da);

  @Query('SELECT * FROM duty_assignments WHERE shift_date = :date')
  Future<List<DutyAssignment>> getDutyAssignmentsByDate(int date);

  // ── Store Keeper ──────────────────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertStoreAsset(StoreAsset asset);

  @Query('SELECT * FROM store_assets ORDER BY name ASC')
  Future<List<StoreAsset>> getAllStoreAssets();

  @Query('SELECT * FROM store_assets WHERE status = :status')
  Future<List<StoreAsset>> getStoreAssetsByStatus(String status);

  @Query('UPDATE store_assets SET status = :status WHERE id = :id')
  Future<void> updateStoreAssetStatus(String id, String status);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAssetAssignment(AssetAssignment aa);

  @Query('SELECT * FROM asset_assignments WHERE asset_id = :assetId ORDER BY assigned_at DESC')
  Future<List<AssetAssignment>> getAssignmentsForAsset(String assetId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertStockItem(StockItem item);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateStockItem(StockItem item);

  @Query('SELECT * FROM stock_items ORDER BY name ASC')
  Future<List<StockItem>> getAllStockItems();

  @Query('SELECT * FROM stock_items WHERE quantity_on_hand <= reorder_level')
  Future<List<StockItem>> getLowStockItems();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertProcurementRequest(ProcurementRequest req);

  @Query('SELECT * FROM procurement_requests ORDER BY created_at DESC')
  Future<List<ProcurementRequest>> getAllProcurementRequests();

  @Query('SELECT * FROM procurement_requests WHERE source_module = :module ORDER BY created_at DESC')
  Future<List<ProcurementRequest>> getProcurementByModule(String module);

  @Query('SELECT * FROM procurement_requests WHERE status = :status ORDER BY created_at DESC')
  Future<List<ProcurementRequest>> getProcurementByStatus(String status);

  @Query('UPDATE procurement_requests SET status = :status, approval_log = :log WHERE id = :id')
  Future<void> updateProcurementStatus(String id, String status, String log);

  // ── Library ───────────────────────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLibraryBook(LibraryBook book);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateLibraryBook(LibraryBook book);

  @Query('SELECT * FROM library_books ORDER BY title ASC')
  Future<List<LibraryBook>> getAllBooks();

  @Query('SELECT * FROM library_books WHERE title LIKE :q OR author LIKE :q')
  Future<List<LibraryBook>> searchBooks(String q);

  @Query('SELECT * FROM library_books WHERE id = :id')
  Future<LibraryBook?> getBookById(String id);

  @Query('SELECT * FROM library_books WHERE available_copies > 0 ORDER BY title ASC')
  Future<List<LibraryBook>> getAvailableBooks();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLibraryLoan(LibraryLoan loan);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateLibraryLoan(LibraryLoan loan);

  @Query('SELECT * FROM library_loans WHERE returned_at IS NULL ORDER BY borrowed_at DESC')
  Future<List<LibraryLoan>> getActiveLoans();

  @Query('SELECT * FROM library_loans WHERE borrower_id = :borrowerId ORDER BY borrowed_at DESC')
  Future<List<LibraryLoan>> getLoansByBorrower(String borrowerId);

  @Query('SELECT * FROM library_loans WHERE returned_at IS NULL AND due_at < :now')
  Future<List<LibraryLoan>> getOverdueLoans(int now);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLibraryMember(LibraryMember member);

  @Query('SELECT * FROM library_members ORDER BY name ASC')
  Future<List<LibraryMember>> getAllLibraryMembers();

  // ── Fleet ─────────────────────────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertFleetVehicle(FleetVehicle v);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateFleetVehicle(FleetVehicle v);

  @Query('SELECT * FROM fleet_vehicles ORDER BY plate_number ASC')
  Future<List<FleetVehicle>> getAllVehicles();

  @Query('SELECT * FROM fleet_vehicles WHERE status = :status')
  Future<List<FleetVehicle>> getVehiclesByStatus(String status);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertTransportEnrollment(TransportEnrollment e);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateTransportEnrollment(TransportEnrollment e);

  @Query('SELECT * FROM transport_enrollments WHERE active = 1 ORDER BY student_name ASC')
  Future<List<TransportEnrollment>> getActiveEnrollments();

  @Query('SELECT * FROM transport_enrollments WHERE van_id = :vanId AND active = 1')
  Future<List<TransportEnrollment>> getEnrollmentsByVan(String vanId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertTransportEvent(TransportEvent e);

  @Query('SELECT * FROM transport_events WHERE van_id = :vanId ORDER BY timestamp DESC LIMIT 50')
  Future<List<TransportEvent>> getTransportEventsByVan(String vanId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertMaintenanceLog(VehicleMaintenanceLog log);

  @Query('SELECT * FROM vehicle_maintenance_logs WHERE vehicle_id = :vehicleId ORDER BY date DESC')
  Future<List<VehicleMaintenanceLog>> getMaintenanceLogs(String vehicleId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertFleetIncident(FleetIncident inc);

  @Query('SELECT * FROM fleet_incidents ORDER BY reported_at DESC')
  Future<List<FleetIncident>> getFleetIncidents();

  // ── Trips & Tours ─────────────────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSchoolTrip(SchoolTrip trip);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateSchoolTrip(SchoolTrip trip);

  @Query('SELECT * FROM school_trips ORDER BY created_at DESC')
  Future<List<SchoolTrip>> getAllTrips();

  @Query('SELECT * FROM school_trips WHERE status = :status ORDER BY created_at DESC')
  Future<List<SchoolTrip>> getTripsByStatus(String status);

  // ── Casual Workers ────────────────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCasualWorker(CasualWorker w);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateCasualWorker(CasualWorker w);

  @Query('SELECT * FROM casual_workers WHERE active = 1 ORDER BY name ASC')
  Future<List<CasualWorker>> getActiveCasualWorkers();

  @Query('SELECT * FROM casual_workers ORDER BY name ASC')
  Future<List<CasualWorker>> getAllCasualWorkers();

  @Query('SELECT * FROM casual_workers WHERE national_id = :nid')
  Future<CasualWorker?> findCasualWorkerByNationalId(String nid);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertCasualAttendance(CasualAttendance att);

  @Query('UPDATE casual_attendance SET out_ts = :outTs WHERE id = :id')
  Future<void> recordCasualOut(int id, int outTs);

  @Query('SELECT * FROM casual_attendance WHERE worker_id = :workerId ORDER BY in_ts DESC')
  Future<List<CasualAttendance>> getCasualAttendance(String workerId);

  @Query('SELECT * FROM casual_attendance WHERE out_ts IS NULL AND worker_id = :workerId')
  Future<CasualAttendance?> getOpenCasualAttendance(String workerId);

  // ── Reception ─────────────────────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertVisitorQueueEntry(VisitorQueueEntry entry);

  @Query('SELECT * FROM visitor_queue WHERE status = :status ORDER BY arrived_at ASC')
  Future<List<VisitorQueueEntry>> getVisitorQueue(String status);

  @Query('UPDATE visitor_queue SET status = :status, attended_at = :ts WHERE id = :id')
  Future<void> updateVisitorQueueStatus(String id, String status, int ts);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertBulkMessageJob(BulkMessageJob job);

  @Query('SELECT * FROM bulk_message_jobs ORDER BY sent_at DESC LIMIT 50')
  Future<List<BulkMessageJob>> getBulkMessageJobs();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAppointment(Appointment appt);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateAppointment(Appointment appt);

  @Query('SELECT * FROM appointments ORDER BY datetime DESC')
  Future<List<Appointment>> getAllAppointments();

  @Query('SELECT * FROM appointments WHERE status = :status ORDER BY datetime ASC')
  Future<List<Appointment>> getAppointmentsByStatus(String status);

  // ── Boarding ──────────────────────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertDormBlock(DormBlock block);

  @Query('SELECT * FROM dorm_blocks ORDER BY name ASC')
  Future<List<DormBlock>> getDormBlocks();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertDormRoom(DormRoom room);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateDormRoom(DormRoom room);

  @Query('SELECT * FROM dorm_rooms WHERE block_id = :blockId ORDER BY room_number ASC')
  Future<List<DormRoom>> getRoomsByBlock(String blockId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertBedSlot(BedSlot bed);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateBedSlot(BedSlot bed);

  @Query('SELECT * FROM bed_slots WHERE room_id = :roomId')
  Future<List<BedSlot>> getBedSlotsByRoom(String roomId);

  @Query('SELECT * FROM bed_slots WHERE student_id IS NULL')
  Future<List<BedSlot>> getVacantBeds();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertDormFacility(DormFacility fac);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateDormFacility(DormFacility fac);

  @Query('SELECT * FROM dorm_facilities ORDER BY next_due ASC')
  Future<List<DormFacility>> getAllFacilities();

  @Query('SELECT * FROM dorm_facilities WHERE next_due < :ts OR status = :status')
  Future<List<DormFacility>> getOverdueFacilities(int ts, String status);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertInspectionReport(InspectionReport report);

  @Query('SELECT * FROM inspection_reports ORDER BY submitted_at DESC')
  Future<List<InspectionReport>> getAllInspections();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertDiningTable(DiningTable table);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateDiningTable(DiningTable table);

  @Query('SELECT * FROM dining_tables ORDER BY table_number ASC')
  Future<List<DiningTable>> getAllDiningTables();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertBoardingStaff(BoardingStaffAssignment bsa);

  @Query('SELECT * FROM boarding_staff ORDER BY role ASC')
  Future<List<BoardingStaffAssignment>> getBoardingStaff();

  // ── HR ────────────────────────────────────────────────────────────────────
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertJobVacancy(JobVacancy v);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateJobVacancy(JobVacancy v);

  @Query('SELECT * FROM job_vacancies ORDER BY created_at DESC')
  Future<List<JobVacancy>> getAllVacancies();

  @Query('SELECT * FROM job_vacancies WHERE status = :status')
  Future<List<JobVacancy>> getVacanciesByStatus(String status);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertStaffDocument(StaffDocument doc);

  @Query('SELECT * FROM staff_documents WHERE staff_id = :staffId ORDER BY uploaded_at DESC')
  Future<List<StaffDocument>> getDocumentsForStaff(String staffId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertStaffStatutory(StaffStatutory stat);

  @Query('SELECT * FROM staff_statutory WHERE staff_id = :staffId')
  Future<StaffStatutory?> getStatutoryForStaff(String staffId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertWorkforceIncident(WorkforceIncident inc);

  @Query('SELECT * FROM workforce_incidents ORDER BY created_at DESC')
  Future<List<WorkforceIncident>> getAllWorkforceIncidents();

  @Query('UPDATE workforce_incidents SET status = :status, action_taken = :action WHERE id = :id')
  Future<void> resolveWorkforceIncident(String id, String status, String action);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertWelfareFund(WelfareFund fund);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> updateWelfareFund(WelfareFund fund);

  @Query('SELECT * FROM welfare_funds ORDER BY name ASC')
  Future<List<WelfareFund>> getAllWelfareFunds();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertWelfareContribution(WelfareContribution c);

  @Query('SELECT * FROM welfare_contributions WHERE fund_id = :fundId ORDER BY date DESC')
  Future<List<WelfareContribution>> getContributionsByFund(String fundId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertTeacherQuarter(TeacherQuarterAssignment qa);

  @Query('SELECT * FROM teacher_quarters WHERE active = 1 ORDER BY quarter_unit ASC')
  Future<List<TeacherQuarterAssignment>> getActiveQuarterAssignments();
}
