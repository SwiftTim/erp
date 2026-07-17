// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/dashboard/teacher_dashboard.dart';
import '../../features/dashboard/headteacher_dashboard.dart';
import '../../features/dashboard/parent_dashboard.dart';
import '../../features/students/students_list_page.dart';
import '../../features/students/student_detail_page.dart';
import '../../features/students/student_registration_page.dart';
import '../../features/assessment/assessment_entry_page.dart';
import '../../features/assessment/hod_moderation_page.dart';
import '../../features/assessment/competency_matrix_page.dart';
import '../../features/evidence/evidence_vault_page.dart';
import '../../features/attendance/attendance_page.dart';
import '../../features/finance/finance_dashboard_page.dart';
import '../../features/finance/student_ledger_page.dart';
import '../../features/reports/report_generator_page.dart';
import '../../features/messaging/messaging_hub_page.dart';
import '../../features/messaging/school_calendar_page.dart';
import '../../features/curriculum/syllabus_coverage_page.dart';
import '../../features/admin/staff_management_page.dart';
import '../../features/admin/compliance_dashboard_page.dart';
import '../../features/departments/department_list_page.dart';
import '../../features/departments/department_dashboard_page.dart';
import '../../features/departments/deputy_dept_comparison_page.dart';
import '../../features/clubs/club_list_page.dart';
import '../../features/clubs/club_detail_page.dart';

import '../../features/health/health_dashboard_page.dart';
import '../../features/admissions/admissions_dashboard_page.dart';
import '../../features/analytics/analytics_dashboard_page.dart';
import '../../features/catering/catering_dashboard_page.dart';
import '../../features/juniorschool/pathway_engine_page.dart';
import '../../features/discipline/discipline_dashboard_page.dart';
import '../../features/security/visitor_dashboard_page.dart';
import '../../features/counseling/counseling_dashboard_page.dart';
import '../../features/admin/inventory_management_page.dart';
import '../../features/admin/audit_log_page.dart';
import '../../features/admin/leave_management_page.dart';
import '../../features/admin/timetable_engine_page.dart';
import '../../features/admin/teacher_capacity_page.dart';
import '../../features/admin/class_demand_page.dart';
import '../../features/admin/substitution_management_page.dart';
import '../../features/finance/finance_placeholder_page.dart';
import '../../features/finance/student_billing_page.dart';
import '../../features/finance/payroll_page.dart';
import '../../features/finance/fee_structure_page.dart';
import '../../features/finance/expense_page.dart';
import '../../features/finance/asset_page.dart';
import '../../features/finance/parent_ledger_page.dart';
import '../../features/dashboard/widgets/app_shell.dart';
import '../../features/teaching/teacher_timetable_page.dart';
import '../../features/teaching/instructional_hub_page.dart';
import '../../features/tod/tod_roster_page.dart';
import '../../features/tod/tod_records_page.dart';
import '../../features/tod/tod_watchlist_page.dart';
import '../../features/tod/tod_report_page.dart';
import '../../features/finance/salary_structure_page.dart';
import '../../features/finance/payroll_batch_page.dart';
import '../../features/finance/staff_loans_page.dart';
import '../../features/finance/resource_procurement_page.dart';
import '../../features/finance/principal_approvals_page.dart';
import '../../features/finance/teacher_requests_page.dart';
import '../../features/finance/staff_loan_request_page.dart';
import '../../features/finance/payments_receipts_page.dart';
import '../../features/finance/finance_reports_page.dart';
import '../../features/finance/finance_settings_page.dart';
import '../../core/constants/app_constants.dart';
// ── New Operations Modules ───────────────────────────────────────────────────
import '../../features/leave_out/leave_out_page.dart';
import '../../features/store/store_dashboard_page.dart';
import '../../features/library/library_dashboard_page.dart';
import '../../features/fleet/fleet_dashboard_page.dart';
import '../../features/trips/trips_dashboard_page.dart';
import '../../features/casual_staff/casual_staff_page.dart';
import '../../features/reception/reception_dashboard_page.dart';
import '../../features/boarding/boarding_dashboard_page.dart';
import '../../features/hr/hr_dashboard_page.dart';

// ── Route Names ────────────────────────────────────────────────────────────────
class Routes {
  static const login = '/login';
  static const dashboard = '/';
  static const students = '/students';
  static const studentDetail = '/students/:id';
  static const studentNew = '/students/new';
  static const assessment = '/assessment';
  static const matrix = '/matrix';
  static const evidence = '/evidence/:studentId';
  static const attendance = '/attendance';
  static const finance = '/finance';
  static const ledger = '/finance/ledger/:studentId';
  static const statement = '/finance/statement';
  static const financeBilling = '/finance/billing';
  static const financeStructure = '/finance/structure';
  static const financePayments = '/finance/payments';
  static const financePayroll = '/finance/payroll';
  static const financeLoans = '/finance/loans';
  static const financeProcurement = '/finance/procurement';
  static const String financeApprovals = '/finance/approvals';
  static const String financeSalaryStructures = '/finance/salary-structures';
  static const String financePayrollBatch = '/finance/payroll-batch';
  static const financeExpenses = '/finance/expenses';
  static const financeAssets = '/finance/assets';
  static const financeAmenities = '/finance/amenities';
  static const financeReports = '/finance/reports';
  static const financeSettings = '/finance/settings';
  static const reports = '/reports';
  static const messaging = '/messaging';
  static const messagingCalendar = '/messaging/calendar';
  static const staff = '/admin/staff';
  static const admissions = '/admin/admissions';
  static const analytics = '/admin/analytics';
  static const moderation = '/assessment/moderation';
  static const health = '/operations/health';
  static const catering = '/operations/catering';
  static const security = '/operations/security';
  static const discipline = '/specialty/discipline';
  static const counseling = '/specialty/counseling';
  static const pathway = '/juniorschool/pathway';
  static const timetable = '/timetable';
  static const timetableCapacity = '/timetable/capacity';
  static const timetableDemand = '/timetable/demand';
  static const clubs = '/clubs';
  static const inventory = '/admin/inventory';
  static const leave = '/leave';
  static const audit = '/admin/audit';
  static const compliance = '/admin/compliance';
  static const substitutions = '/admin/substitutions';
  static const syllabus = '/curriculum/syllabus';
  static const timetableEngine = '/timetable'; // alias for engine page
  static const teacherTimetable = '/teaching/timetable';
  static const instructionalHub = '/teaching/hub/:slotId';
  static const departments = '/departments';
  static const departmentDetail = '/departments/:id';
  static const deptComparison = '/departments/comparison';
  static const clubDetail = '/clubs/:id';

  // Staff / Teacher Portals
  static const staffLoanRequest = '/staff/loans';
  static const teacherProcurementRequest = '/teacher/procurement';

  // Teacher on Duty (TOD)
  static const todRoster = '/tod/roster';
  static const todRecords = '/tod/records';
  static const todAmber = '/tod/amber';
  static const todRed = '/tod/red';
  static const todReports = '/tod/reports';

  // ── New Operations Modules ───────────────────────────────────────────────
  static const leaveOut    = '/operations/leave-out';
  static const store       = '/operations/store';
  static const library     = '/operations/library';
  static const fleet       = '/operations/fleet';
  static const trips       = '/operations/trips';
  static const casualStaff = '/operations/casual-staff';
  static const reception   = '/operations/reception';
  static const boarding    = '/operations/boarding';
  static const hr          = '/operations/hr';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.dashboard,
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isLoginPage = state.matchedLocation == Routes.login;
      if (!isLoggedIn && !isLoginPage) return Routes.login;
      if (isLoggedIn && isLoginPage) return Routes.dashboard;

      // ── ROLE PROTECTION ──
      if (isLoggedIn) {
        final user = ref.read(currentUserProvider);
        if (user == null) return null; // Should not happen

        final location = state.matchedLocation;

        // Admin-only modules (Role Level 1-2)
        final isAdminRoute = location.contains('/admin/') ||
            location == Routes.staff ||
            location == Routes.audit ||
            location == Routes.compliance;

        if (isAdminRoute && user.roleLevel > AppConstants.roleDeputy) {
          return Routes.dashboard; // Redirect common teachers away from admin
        }

        // Finance-only modules (Role Level 1-2 or Accountant)
        final isFinanceRoute = location.contains('/finance/');
        if (isFinanceRoute &&
            user.roleLevel > AppConstants.roleDeputy &&
            user.roleLevel != AppConstants.roleAccountant) {
          return Routes.dashboard;
        }

        // Health-only
        if (location == Routes.health &&
            user.roleLevel != AppConstants.roleNurse &&
            user.roleLevel > AppConstants.roleDeputy) {
          return Routes.dashboard;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.dashboard,
        builder: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user == null) return const LoginPage();
          switch (user.roleLevel) {
            case AppConstants.roleDirector:
            case AppConstants.roleHeadteacher:
            case AppConstants.roleDeputy:
              return const HeadteacherDashboard();
            case AppConstants.roleTeacher:
            case AppConstants.roleSeniorTeacher:
              return const TeacherDashboard();
            case AppConstants.roleParent:
              return const ParentDashboard();
            case AppConstants.roleAccountant:
              return const FinanceDashboardPage();
            case AppConstants.roleNurse:
              return const HealthDashboardPage();
            case AppConstants.roleCatering:
              return const CateringDashboardPage();
            case AppConstants.roleSecurity:
              return const VisitorDashboardPage();
            case AppConstants.roleReceptionist:
              return const ReceptionDashboardPage();
            case AppConstants.roleBoardingMaster:
              return const BoardingDashboardPage();
            case AppConstants.roleLibrarian:
              return const LibraryDashboardPage();
            case AppConstants.roleFleetManager:
              return const FleetDashboardPage();
            case AppConstants.roleHR:
              return const HrDashboardPage();
            case AppConstants.roleStoreKeeper:
              return const StoreDashboardPage();
            default:
              return const LoginPage();
          }
        },
      ),
      GoRoute(
        path: Routes.students,
        builder: (_, __) => const StudentsListPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const StudentRegistrationPage(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                StudentDetailPage(id: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.assessment,
        builder: (_, __) => const AssessmentEntryPage(),
      ),
      GoRoute(
        path: Routes.matrix,
        builder: (_, __) => const CompetencyMatrixPage(),
      ),
      GoRoute(
        path: '/evidence/:studentId',
        builder: (_, state) => EvidenceVaultPage(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: Routes.attendance,
        builder: (_, __) => const AttendancePage(),
      ),
      GoRoute(
        path: Routes.finance,
        builder: (_, __) => const FinanceDashboardPage(),
        routes: [
          GoRoute(
            path: 'ledger/:studentId',
            builder: (_, state) => StudentLedgerPage(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
          GoRoute(
              path: 'approvals',
              builder: (context, state) => const PrincipalApprovalsPage()),
          GoRoute(
              path: 'salary-structures',
              builder: (context, state) => const SalaryStructurePage()),
          GoRoute(
              path: 'payroll-batch',
              builder: (context, state) => const PayrollBatchPage()),
        ],
      ),
      GoRoute(
        path: Routes.financeBilling,
        builder: (_, __) => const AppShell(
            title: 'Student Billing', body: StudentBillingPage()),
      ),
      GoRoute(
        path: Routes.financeStructure,
        builder: (_, __) =>
            const AppShell(title: 'Fee Structure', body: FeeStructurePage()),
      ),
      GoRoute(
        path: Routes.financePayments,
        builder: (_, __) => const AppShell(
            title: 'Payments & Receipts', body: PaymentsReceiptsPage()),
      ),
      GoRoute(
        path: Routes.financePayroll,
        builder: (_, __) =>
            const AppShell(title: 'Staff Payroll', body: PayrollPage()),
      ),
      GoRoute(
        path: Routes.financeLoans,
        builder: (_, __) =>
            const AppShell(title: 'Staff Loans', body: StaffLoansPage()),
      ),
      GoRoute(
        path: Routes.financeProcurement,
        builder: (_, __) => const AppShell(
            title: 'Procurement', body: ResourceProcurementPage()),
      ),
      GoRoute(
        path: Routes.financeExpenses,
        builder: (_, __) =>
            const AppShell(title: 'Expenses', body: ExpensePage()),
      ),
      GoRoute(
        path: Routes.financeAssets,
        builder: (_, __) =>
            const AppShell(title: 'Asset & Repairs', body: AssetPage()),
      ),
      GoRoute(
        path: Routes.financeAmenities,
        builder: (_, __) => const AppShell(
            title: 'Amenities Billing',
            body: FinancePlaceHolderPage(title: 'Amenities Billing')),
      ),
      GoRoute(
        path: Routes.financeReports,
        builder: (_, __) => const AppShell(
            title: 'Financial Reports', body: FinanceReportsPage()),
      ),
      GoRoute(
        path: Routes.financeSettings,
        builder: (_, __) => const AppShell(
            title: 'Payroll Settings', body: FinanceSettingsPage()),
      ),
      GoRoute(
        path: Routes.reports,
        builder: (_, __) => const ReportGeneratorPage(),
      ),
      GoRoute(
        path: Routes.messaging,
        builder: (_, __) => const MessagingHubPage(),
        routes: [
          GoRoute(
            path: 'calendar',
            builder: (_, __) => const SchoolCalendarPage(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.staff,
        builder: (_, __) => const StaffManagementPage(),
      ),
      GoRoute(
        path: Routes.admissions,
        builder: (_, __) => const AdmissionsDashboardPage(),
      ),
      GoRoute(
        path: Routes.analytics,
        builder: (_, __) => const AnalyticsDashboardPage(),
      ),
      GoRoute(
        path: Routes.moderation,
        builder: (_, __) => const HodModerationPage(),
      ),
      GoRoute(
        path: Routes.health,
        builder: (_, __) => const HealthDashboardPage(),
      ),
      GoRoute(
        path: Routes.catering,
        builder: (_, __) => const CateringDashboardPage(),
      ),
      GoRoute(
        path: Routes.security,
        builder: (_, __) => const VisitorDashboardPage(),
      ),
      GoRoute(
        path: Routes.discipline,
        builder: (_, __) => const DisciplineDashboardPage(),
      ),
      GoRoute(
        path: Routes.counseling,
        builder: (_, __) => const CounselingDashboardPage(),
      ),
      GoRoute(
        path: Routes.statement,
        builder: (_, __) => const ParentLedgerPage(),
      ),
      GoRoute(
        path: Routes.pathway,
        builder: (_, __) => const PathwayEnginePage(),
      ),
      GoRoute(
        path: Routes.timetable,
        builder: (_, __) => const TimetableEnginePage(),
      ),
      GoRoute(
        path: Routes.timetableCapacity,
        builder: (_, __) => const TeacherCapacityPage(),
      ),
      GoRoute(
        path: Routes.timetableDemand,
        builder: (_, __) => const ClassDemandPage(),
      ),
      GoRoute(
        path: Routes.clubs,
        builder: (_, __) => const ClubListPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                ClubDetailPage(clubId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.inventory,
        builder: (_, __) => const InventoryManagementPage(),
      ),
      GoRoute(
        path: Routes.leave,
        builder: (_, __) =>
            const AppShell(title: 'Staff Leave', body: LeaveManagementPage()),
      ),
      GoRoute(
        path: Routes.audit,
        builder: (_, __) => const AuditLogPage(),
      ),
      GoRoute(
        path: Routes.compliance,
        builder: (_, __) => const ComplianceDashboardPage(),
      ),
      GoRoute(
        path: Routes.substitutions,
        builder: (_, __) => const SubstitutionManagementPage(),
      ),
      GoRoute(
        path: Routes.syllabus,
        builder: (_, __) => const SyllabusCoveragePage(),
      ),
      GoRoute(
        path: Routes.teacherTimetable,
        builder: (_, __) => const TeacherTimetablePage(),
      ),
      GoRoute(
        path: Routes.instructionalHub,
        builder: (_, state) =>
            InstructionalHubPage(slotId: state.pathParameters['slotId']!),
      ),
      GoRoute(
        path: Routes.departments,
        builder: (_, __) => const DepartmentListPage(),
      ),
      GoRoute(
        path: Routes.deptComparison,
        builder: (_, __) => const DeputyDeptComparisonPage(),
      ),
      GoRoute(
        path: Routes.departmentDetail,
        builder: (_, state) =>
            DepartmentDashboardPage(deptId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.todRoster,
        builder: (_, __) => const TodRosterPage(),
      ),
      GoRoute(
        path: Routes.todRecords,
        builder: (_, __) => const TodRecordsPage(),
      ),
      GoRoute(
        path: Routes.todAmber,
        builder: (_, __) => const TodWatchlistPage(statusFilter: 'Amber'),
      ),
      GoRoute(
        path: Routes.todRed,
        builder: (_, __) => const TodWatchlistPage(statusFilter: 'Red'),
      ),
      GoRoute(
        path: Routes.todReports,
        builder: (_, __) => const TodReportPage(),
      ),
      GoRoute(
        path: Routes.staffLoanRequest,
        builder: (_, __) => const AppShell(
            title: 'My Loans & Advances', body: StaffLoanRequestPage()),
      ),
      GoRoute(
        path: Routes.teacherProcurementRequest,
        builder: (_, __) => const AppShell(
            title: 'Resource Requests', body: TeacherRequestsPage()),
      ),
      // ── New Operations Modules ────────────────────────────────────────────
      GoRoute(
        path: Routes.leaveOut,
        builder: (_, __) => const AppShell(title: 'Student Leave-Out', body: LeaveOutPage()),
      ),
      GoRoute(
        path: Routes.store,
        builder: (_, __) => const StoreDashboardPage(),
      ),
      GoRoute(
        path: Routes.library,
        builder: (_, __) => const LibraryDashboardPage(),
      ),
      GoRoute(
        path: Routes.fleet,
        builder: (_, __) => const FleetDashboardPage(),
      ),
      GoRoute(
        path: Routes.trips,
        builder: (_, __) => const TripsDashboardPage(),
      ),
      GoRoute(
        path: Routes.casualStaff,
        builder: (_, __) => const CasualStaffPage(),
      ),
      GoRoute(
        path: Routes.reception,
        builder: (_, __) => const ReceptionDashboardPage(),
      ),
      GoRoute(
        path: Routes.boarding,
        builder: (_, __) => const BoardingDashboardPage(),
      ),
      GoRoute(
        path: Routes.hr,
        builder: (_, __) => const HrDashboardPage(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
