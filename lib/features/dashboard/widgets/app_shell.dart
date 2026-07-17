// lib/features/dashboard/widgets/app_shell.dart
// Adaptive navigation shell: NavigationDrawer on desktop, BottomNavigationBar on mobile

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../auth/auth_provider.dart';
import '../../../data/models/user_model.dart';
import 'dart:async';
import '../../tod/tod_provider.dart';
import '../../messaging/messaging_hub_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

final _dismissedEmergencyProvider = StateProvider<String?>((ref) => null);

class _AppShellState extends ConsumerState<AppShell> {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    // HARDENING: Force logout after 15 minutes of inactivity
    _inactivityTimer = Timer(const Duration(minutes: 15), () {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).logout();
        context.go(Routes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Session Expired: You were logged out due to inactivity.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width > 900;
    final user = ref.watch(currentUserProvider);

    // ── EMERGENCY BROADCAST CHECK ──
    final memoState = ref.watch(memoHubProvider);
    final dismissedId = ref.watch(_dismissedEmergencyProvider);
    final emergency = memoState.memos
        .where((m) => m.priority == 'EMERGENCY' && m.id != dismissedId)
        .firstOrNull;
    if (emergency != null) {
      return _buildEmergencyScreen(emergency);
    }

    final isOnDuty = ref.watch(isOnDutyProvider).value ?? false;
    final navItems = _buildNavItems(user, isOnDuty);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      onPointerHover: (_) => _resetInactivityTimer(),
      child: isDesktop
          ? _buildDesktopLayout(navItems, user)
          : _buildMobileLayout(navItems),
    );
  }

  Widget _buildDesktopLayout(List<_NavItem> navItems, UserModel? user) {
    // Only real destinations (no headers) — this is what NavigationDrawer
    // uses for its selectedIndex / onDestinationSelected callback index.
    final destItems = navItems.where((i) => !i.isHeader).toList();

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          NavigationDrawer(
            onDestinationSelected: (i) => _onNav(context, destItems[i].route),
            selectedIndex: _currentDestIndex(context, destItems),
            children: [
              _DrawerHeader(user: user),
              const SizedBox(height: 8),
              ...navItems.map((item) {
                if (item.isHeader) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
                    child: Text(item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          letterSpacing: 1.2,
                        )),
                  );
                }
                return NavigationDrawerDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                );
              }),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: const Text('Sign Out'),
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go(Routes.login);
                },
              ),
            ],
          ),
          // ── Main Content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(widget.title),
                  actions: widget.actions,
                ),
                Expanded(child: widget.body),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildMobileLayout(List<_NavItem> navItems) {
    final destItems = navItems.where((i) => !i.isHeader).toList();
    final mobileItems = destItems.take(5).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ...?widget.actions,
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'logout') {
                ref.read(authNotifierProvider.notifier).logout();
                context.go(Routes.login);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
          ),
        ],
      ),
      body: widget.body,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (i) => _onNav(context, mobileItems[i].route),
        selectedIndex: _currentDestIndex(context, mobileItems),
        destinations: mobileItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  void _onNav(BuildContext context, String route) => context.go(route);

  Widget _buildEmergencyScreen(dynamic memo) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 100, color: Colors.white),
              const SizedBox(height: 32),
              const Text('EMERGENCY BROADCAST',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
              const SizedBox(height: 16),
              const Divider(color: Colors.white54, thickness: 2),
              const SizedBox(height: 32),
              Text(memo.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Text(memo.content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  ref.read(_dismissedEmergencyProvider.notifier).state =
                      memo.id;
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('I HAVE READ THIS ALERT',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the selected index within [destItems] (headers already excluded).
  int _currentDestIndex(BuildContext context, List<_NavItem> destItems) {
    final loc = GoRouterState.of(context).matchedLocation;
    // Find longest prefix match so '/finance/ledger/123' highlights Finance
    int best = 0;
    int bestLen = 0;
    for (int i = 0; i < destItems.length; i++) {
      final r = destItems[i].route;
      if (r.isNotEmpty && loc.startsWith(r) && r.length > bestLen) {
        best = i;
        bestLen = r.length;
      }
    }
    return best;
  }

  List<_NavItem> _buildNavItems(UserModel? user, bool isOnDuty) {
    if (user == null) return [];

    final level = user.roleLevel;
    final List<_NavItem> items = [
      _NavItem(Icons.dashboard_outlined, 'Home', Routes.dashboard),
    ];

    // ── 🔵 OPERATIONAL ENGINES ───────────────────────────────────────────────
    items.add(_NavItem(null, 'OPERATIONAL', '', isHeader: true));

    // Academics
    if (level <= AppConstants.roleSeniorTeacher) {
      items.add(
          _NavItem(Icons.people_alt_outlined, 'Learners', Routes.students));
    }
    if (level == AppConstants.roleTeacher ||
        level == AppConstants.roleSeniorTeacher) {
      items.add(_NavItem(
          Icons.auto_stories_outlined, 'My Teaching', Routes.teacherTimetable));
      items.add(_NavItem(
          Icons.edit_calendar_outlined, 'CBC Assessments', Routes.assessment));
      items.add(_NavItem(
          Icons.corporate_fare_outlined, 'My Department', Routes.departments));
      items.add(
          _NavItem(Icons.how_to_reg_outlined, 'Roll Call', Routes.attendance));
    }

    // Coordination
    if (level <= AppConstants.roleDeputy) {
      items.add(_NavItem(
          Icons.business_outlined, 'All Departments', Routes.departments));
      items.add(_NavItem(Icons.compare_arrows_outlined, 'Dept Comparison',
          Routes.deptComparison));
      items.add(_NavItem(
          Icons.grid_on_outlined, 'Timetable Engine', Routes.timetable));
      items.add(_NavItem(Icons.engineering_outlined, 'Teacher Capacity',
          Routes.timetableCapacity));
      items.add(_NavItem(
          Icons.assignment_outlined, 'Class Demands', Routes.timetableDemand));
    }

    // Teacher on Duty - Deputy Controls
    if (level <= AppConstants.roleDeputy) {
      items.add(_NavItem(null, 'TEACHER ON DUTY', '', isHeader: true));
      items.add(_NavItem(
          Icons.event_repeat_outlined, 'Duty Roster', Routes.todRoster));
      items.add(_NavItem(
          Icons.analytics_outlined, 'Weekly Reports', Routes.todReports));
      items.add(_NavItem(
          Icons.warning_amber_outlined, 'Amber Watchlist', Routes.todAmber));
      items.add(_NavItem(
          Icons.report_problem_outlined, 'Red Escalation', Routes.todRed));
    }

    // Teacher on Duty - Active Teacher Menu
    if (isOnDuty) {
      items.add(_NavItem(null, 'DUTY PANEL', '', isHeader: true));
      items.add(_NavItem(
          Icons.assignment_ind_outlined, 'TOD Records', Routes.todRecords));
      items.add(_NavItem(
          Icons.summarize_outlined, 'Submit Daily Report', Routes.todReports));
    }

    // Finance
    if (level <= AppConstants.roleHeadteacher ||
        level == AppConstants.roleAccountant ||
        level == AppConstants.roleParent) {
      items.add(_NavItem(null, 'FINANCE', '', isHeader: true));
      items.add(_NavItem(
          Icons.account_balance_outlined,
          'Dashboard',
          level == AppConstants.roleParent
              ? Routes.statement
              : Routes.finance));
      if (level != AppConstants.roleParent) {
        items.add(_NavItem(Icons.receipt_long_outlined, 'Student Billing',
            Routes.financeBilling));
        items.add(_NavItem(Icons.account_tree_outlined, 'Fee Structure',
            Routes.financeStructure));
        items.add(_NavItem(Icons.payments_outlined, 'Payments & Receipts',
            Routes.financePayments));
        items.add(_NavItem(
            Icons.request_quote_outlined, 'Payroll', Routes.financePayroll));
        items.add(_NavItem(
            Icons.credit_score_outlined, 'Staff Loans', Routes.financeLoans));
        items.add(_NavItem(Icons.shopping_bag_outlined, 'Procurement',
            Routes.financeProcurement));
        items.add(_NavItem(
            Icons.trending_down_outlined, 'Expenses', Routes.financeExpenses));
        items.add(_NavItem(
            Icons.handyman_outlined, 'Asset & Repairs', Routes.financeAssets));
        items.add(_NavItem(Icons.room_preferences_outlined, 'Amenities Billing',
            Routes.financeAmenities));
        items.add(_NavItem(Icons.bar_chart_outlined, 'Financial Reports',
            Routes.financeReports));
        if (level <= AppConstants.roleHeadteacher) {
          items.add(_NavItem(
              Icons.tune_outlined, 'Payroll Settings', Routes.financeSettings));
        }
      }
    }

    // ── Operational Role-Specific Module Menus ───────────────────────────────
    if (level == AppConstants.roleNurse) {
      items.add(_NavItem(null, 'CLINIC', '', isHeader: true));
      items.add(_NavItem(Icons.medical_services_outlined, 'Health Dashboard', Routes.health));
    }
    if (level == AppConstants.roleCatering) {
      items.add(_NavItem(null, 'CATERING', '', isHeader: true));
      items.add(_NavItem(Icons.restaurant_outlined, 'Kitchen & Meals', Routes.catering));
    }
    if (level == AppConstants.roleSecurity) {
      items.add(_NavItem(null, 'SECURITY', '', isHeader: true));
      items.add(_NavItem(Icons.security_outlined, 'Gate & Visitors', Routes.security));
      items.add(_NavItem(Icons.directions_car_outlined, 'Vehicle Passes', Routes.security));
    }
    if (level == AppConstants.roleReceptionist) {
      items.add(_NavItem(null, 'FRONT DESK', '', isHeader: true));
      items.add(_NavItem(Icons.desk_outlined, 'Reception Hub', Routes.reception));
    }
    if (level == AppConstants.roleBoardingMaster) {
      items.add(_NavItem(null, 'BOARDING', '', isHeader: true));
      items.add(_NavItem(Icons.apartment_outlined, 'Boarding Master', Routes.boarding));
    }
    if (level == AppConstants.roleLibrarian) {
      items.add(_NavItem(null, 'LIBRARY', '', isHeader: true));
      items.add(_NavItem(Icons.local_library_outlined, 'Library System', Routes.library));
    }
    if (level == AppConstants.roleFleetManager) {
      items.add(_NavItem(null, 'FLEET', '', isHeader: true));
      items.add(_NavItem(Icons.directions_bus_outlined, 'Fleet Management', Routes.fleet));
      items.add(_NavItem(Icons.travel_explore, 'Trips & Tours', Routes.trips));
    }
    if (level == AppConstants.roleHR) {
      items.add(_NavItem(null, 'HUMAN RESOURCES', '', isHeader: true));
      items.add(_NavItem(Icons.badge_outlined, 'HR Office', Routes.hr));
      items.add(_NavItem(Icons.event_note_outlined, 'Leave Manager', Routes.leave));
    }
    if (level == AppConstants.roleStoreKeeper) {
      items.add(_NavItem(null, 'STORES', '', isHeader: true));
      items.add(_NavItem(Icons.inventory_outlined, 'Storeroom', Routes.store));
      items.add(_NavItem(Icons.people_outline, 'Casual Staff', Routes.casualStaff));
    }
    if (level == AppConstants.roleAdmissions) {
      items.add(_NavItem(null, 'ADMISSIONS', '', isHeader: true));
      items.add(_NavItem(Icons.assignment_turned_in_outlined, 'Admissions Portal', Routes.admissions));
    }

    // ── 🟡 STAFF SELF SERVICE (all non-parent, non-student staff) ────────────
    if (level != AppConstants.roleParent && level != AppConstants.roleStudent) {
      items.add(_NavItem(null, 'SELF SERVICE', '', isHeader: true));
      items.add(_NavItem(Icons.event_available_outlined, 'My Leave', Routes.leave));
      items.add(_NavItem(Icons.credit_card_outlined, 'My Loans', Routes.staffLoanRequest));
      items.add(_NavItem(Icons.groups_outlined, 'Clubs & Societies', Routes.clubs));
      items.add(_NavItem(Icons.forum_outlined, 'Messaging Hub', Routes.messaging));
    }

    // ── 🟢 CONNECTIVE ENGINES ────────────────────────────────────────────────
    if (level <= AppConstants.roleHeadteacher || level == AppConstants.roleAccountant) {
      items.add(_NavItem(null, 'CONNECTIVE', '', isHeader: true));
      items.add(_NavItem(Icons.forum_outlined, 'Messaging Hub', Routes.messaging));
    }

    if (level <= AppConstants.roleHeadteacher) {
      items.add(_NavItem(
          Icons.insights_outlined, 'Executive Analytics', Routes.analytics));
    }

    if (user.hasFlag(AppConstants.flagHOD)) {
      items.add(_NavItem(
          Icons.fact_check_outlined, 'HOD Moderation', Routes.moderation));
    }

    // ── 🟣 INFRASTRUCTURE ────────────────────────────────────────────────────
    if (level <= AppConstants.roleHeadteacher) {
      items.add(_NavItem(null, 'INFRASTRUCTURE', '', isHeader: true));
      items.add(_NavItem(
          Icons.manage_accounts_outlined, 'Faculty & RBAC', Routes.staff));
      items.add(_NavItem(Icons.assignment_turned_in_outlined, 'Admissions',
          Routes.admissions));
      items.add(_NavItem(Icons.policy_outlined, 'Audit Logs', Routes.audit));
      items.add(_NavItem(
          Icons.inventory_2_outlined, 'Asset Inventory', Routes.inventory));
      items.add(
          _NavItem(Icons.event_note_outlined, 'Leave Manager', Routes.leave));
    }

    return items;
  }
}

class _NavItem {
  final IconData? icon;
  final String label;
  final String route;
  final bool isHeader;
  _NavItem(this.icon, this.label, this.route, {this.isHeader = false});
}

class _DrawerHeader extends StatelessWidget {
  final dynamic user;
  const _DrawerHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primary,
            radius: 24,
            child: Text(
              (user?.name as String? ?? 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                Text(
                  AppConstants.roleNames[user?.roleLevel ?? 5] ?? 'User',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
