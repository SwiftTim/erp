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
import '../../features/messaging/messaging_page.dart';
import '../../features/curriculum/syllabus_coverage_page.dart';
import '../../features/admin/staff_management_page.dart';
import '../../features/admin/compliance_dashboard_page.dart';
import '../../features/departments/department_list_page.dart';
import '../../features/departments/department_dashboard_page.dart';

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
import '../../features/admin/timetable_engine_page.dart';
import '../../features/admin/teacher_capacity_page.dart';
import '../../features/admin/class_demand_page.dart';
import '../../features/admin/substitution_management_page.dart';
import '../../features/finance/parent_ledger_page.dart';
import '../../features/dashboard/widgets/app_shell.dart';
import '../../features/teaching/teacher_timetable_page.dart';
import '../../features/teaching/instructional_hub_page.dart';
import '../../core/constants/app_constants.dart';

// ── Route Names ────────────────────────────────────────────────────────────────
class Routes {
  static const login          = '/login';
  static const dashboard      = '/';
  static const students       = '/students';
  static const studentDetail  = '/students/:id';
  static const studentNew     = '/students/new';
  static const assessment     = '/assessment';
  static const matrix         = '/matrix';
  static const evidence       = '/evidence/:studentId';
  static const attendance     = '/attendance';
  static const finance        = '/finance';
  static const ledger         = '/finance/ledger/:studentId';
  static const statement      = '/finance/statement';
  static const reports        = '/reports';
  static const messaging      = '/messaging';
  static const staff          = '/admin/staff';
  static const admissions     = '/admin/admissions';
  static const analytics      = '/admin/analytics';
  static const moderation     = '/assessment/moderation';
  static const health         = '/operations/health';
  static const catering       = '/operations/catering';
  static const security       = '/operations/security';
  static const discipline     = '/specialty/discipline';
  static const counseling     = '/specialty/counseling';
  static const pathway        = '/juniorschool/pathway';
  static const timetable      = '/timetable';
  static const timetableCapacity = '/timetable/capacity';
  static const timetableDemand = '/timetable/demand';
  static const clubs          = '/clubs';
  static const inventory      = '/admin/inventory';
  static const leave          = '/admin/leave';
  static const audit          = '/admin/audit';
  static const compliance     = '/admin/compliance';
  static const substitutions  = '/admin/substitutions';
  static const syllabus       = '/curriculum/syllabus';
  static const timetableEngine   = '/timetable';  // alias for engine page
  static const teacherTimetable = '/teaching/timetable';
  static const instructionalHub = '/teaching/hub/:slotId';
  static const departments    = '/departments';
  static const departmentDetail = '/departments/:id';
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
        if (location == Routes.health && user.roleLevel != AppConstants.roleNurse && user.roleLevel > AppConstants.roleDeputy) {
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
            builder: (_, state) => StudentDetailPage(id: state.pathParameters['id']!),
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
        ],
      ),
      GoRoute(
        path: Routes.reports,
        builder: (_, __) => const ReportGeneratorPage(),
      ),
      GoRoute(
        path: Routes.messaging,
        builder: (_, __) => const MessagingPage(),
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
        builder: (_, __) => const AppShell(title: 'Clubs & Societies', body: Center(child: Text('Extra-curricular dashboard coming soon'))),
      ),
      GoRoute(
        path: Routes.inventory,
        builder: (_, __) => const InventoryManagementPage(),
      ),
      GoRoute(
        path: Routes.leave,
        builder: (_, __) => const AppShell(title: 'Staff Leave', body: Center(child: Text('Leave Approval Workflow coming soon'))),
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
        builder: (_, state) => InstructionalHubPage(slotId: state.pathParameters['slotId']!),
      ),
      GoRoute(
        path: Routes.departments,
        builder: (_, __) => const DepartmentListPage(),
      ),
      GoRoute(
        path: Routes.departmentDetail,
        builder: (_, state) => DepartmentDashboardPage(deptId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
