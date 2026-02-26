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
            content: Text('Session Expired: You were logged out due to inactivity.'),
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
    _checkEmergency(context);

    final navItems = _buildNavItems(user);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      onPointerHover: (_) => _resetInactivityTimer(),
      child: isDesktop ? _buildDesktopLayout(navItems, user) : _buildMobileLayout(navItems),
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

  Future<void> _checkEmergency(BuildContext context) async {
    final db = await ref.read(databaseProvider.future);
    final memos = await db.enterpriseDao.findAllMemos();
    final emergency = memos.where((m) => m.priority == 'EMERGENCY').firstOrNull;
    
    if (emergency != null) {
      final dismissedId = ref.read(_dismissedEmergencyProvider);
      if (dismissedId != emergency.id) {
        // Schedule microtask to avoid building during build
        Future.microtask(() => _showEmergencyOverride(context, emergency));
      }
    }
  }

  void _showEmergencyOverride(BuildContext context, dynamic memo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog.fullscreen(
          backgroundColor: Colors.red,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 100, color: Colors.white),
                const SizedBox(height: 32),
                const Text('EMERGENCY BROADCAST', 
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white54, thickness: 2),
                const SizedBox(height: 32),
                Text(memo.title, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Text(memo.body ?? memo.content, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    ref.read(_dismissedEmergencyProvider.notifier).state = memo.id;
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('I HAVE READ THIS ALERT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
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

  List<_NavItem> _buildNavItems(UserModel? user) {
    if (user == null) return [];

    final level = user.roleLevel;
    final List<_NavItem> items = [
      _NavItem(Icons.dashboard_outlined, 'Home', Routes.dashboard),
    ];

    // ── 🔵 OPERATIONAL ENGINES ───────────────────────────────────────────────
    items.add(_NavItem(null, 'OPERATIONAL', '', isHeader: true));
    
    // Academics
    if (level <= AppConstants.roleSeniorTeacher) {
      items.add(_NavItem(Icons.people_alt_outlined, 'Learners', Routes.students));
    }
    if (level == AppConstants.roleTeacher || level == AppConstants.roleSeniorTeacher) {
      items.add(_NavItem(Icons.auto_stories_outlined, 'My Teaching', Routes.teacherTimetable));
      items.add(_NavItem(Icons.edit_calendar_outlined, 'CBC Assessments', Routes.assessment));
      items.add(_NavItem(Icons.how_to_reg_outlined, 'Roll Call', Routes.attendance));
    }
    
    // Coordination
    if (level <= AppConstants.roleDeputy) {
      items.add(_NavItem(Icons.grid_on_outlined, 'Timetable Engine', Routes.timetable));
      items.add(_NavItem(Icons.engineering_outlined, 'Teacher Capacity', Routes.timetableCapacity));
      items.add(_NavItem(Icons.assignment_outlined, 'Class Demands', Routes.timetableDemand));
    }
    
    // Finance
    if (level <= AppConstants.roleHeadteacher || level == AppConstants.roleAccountant || level == AppConstants.roleParent) {
      items.add(_NavItem(Icons.account_balance_outlined, 'Finance Hub', level == AppConstants.roleParent ? Routes.statement : Routes.finance));
    }

    // Special Modules
    if (level == AppConstants.roleNurse) items.add(_NavItem(Icons.medical_services_outlined, 'Health Center', Routes.health));
    if (level == AppConstants.roleCatering) items.add(_NavItem(Icons.restaurant_outlined, 'Catering', Routes.catering));
    if (level == AppConstants.roleSecurity) items.add(_NavItem(Icons.security_outlined, 'Security', Routes.security));
    
    items.add(_NavItem(Icons.groups_outlined, 'Clubs & Societies', Routes.clubs));

    // ── 🟢 CONNECTIVE ENGINES ────────────────────────────────────────────────
    items.add(_NavItem(null, 'CONNECTIVE', '', isHeader: true));
    items.add(_NavItem(Icons.forum_outlined, 'Messaging', Routes.messaging));
    
    if (level <= AppConstants.roleHeadteacher) {
      items.add(_NavItem(Icons.insights_outlined, 'Executive Analytics', Routes.analytics));
    }
    
    if (user.hasFlag(AppConstants.flagHOD)) {
      items.add(_NavItem(Icons.fact_check_outlined, 'HOD Moderation', Routes.moderation));
    }

    // ── 🟣 INFRASTRUCTURE ────────────────────────────────────────────────────
    items.add(_NavItem(null, 'INFRASTRUCTURE', '', isHeader: true));
    
    if (level <= AppConstants.roleHeadteacher) {
      items.add(_NavItem(Icons.manage_accounts_outlined, 'Faculty & RBAC', Routes.staff));
      items.add(_NavItem(Icons.assignment_turned_in_outlined, 'Admissions', Routes.admissions));
      items.add(_NavItem(Icons.policy_outlined, 'Audit Logs', Routes.audit));
    }

    items.add(_NavItem(Icons.inventory_2_outlined, 'Asset Inventory', Routes.inventory));
    items.add(_NavItem(Icons.event_note_outlined, 'Leave Manager', Routes.leave));

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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
