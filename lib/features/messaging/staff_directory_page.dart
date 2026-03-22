// lib/features/messaging/staff_directory_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';
import 'messaging_hub_provider.dart';
import 'chat_window_page.dart';

class StaffDirectoryPage extends ConsumerStatefulWidget {
  const StaffDirectoryPage({super.key});

  @override
  ConsumerState<StaffDirectoryPage> createState() =>
      _StaffDirectoryPageState();
}

class _StaffDirectoryPageState extends ConsumerState<StaffDirectoryPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterDept;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(allStaffProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
        centerTitle: false,
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allStaff) {
          final others =
              allStaff.where((s) => s.id != currentUser?.id).toList();

          // Group by department/role
          final structured = _structureStaff(others);
          final filtered = _filter(structured, _query, _filterDept);

          return Column(
            children: [
              // Search + Filter bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search staff…',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  })
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Department filter chips
              _buildDeptFilterRow(others),
              const Divider(height: 1),
              // Staff list
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_outlined,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No staff found',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final entry = filtered[i];
                          if (entry is String) {
                            // Section header
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                              child: Text(
                                entry,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            );
                          }
                          final staff = entry as UserModel;
                          return _StaffCard(
                            staff: staff,
                            currentUserId: currentUser?.id ?? '',
                            onChat: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatWindowPage(
                                    otherUser: staff,
                                    currentUserId: currentUser?.id ?? '',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeptFilterRow(List<UserModel> staff) {
    // Collect unique departments
    final depts = <String>{};
    for (final s in staff) {
      if (s.departmentId != null && s.departmentId!.isNotEmpty) {
        depts.add(s.departmentId!);
      }
    }
    if (depts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filterDept == null,
            onSelected: (_) => setState(() => _filterDept = null),
          ),
          ...depts.map((d) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(d),
                  selected: _filterDept == d,
                  onSelected: (_) =>
                      setState(() => _filterDept = _filterDept == d ? null : d),
                ),
              )),
        ],
      ),
    );
  }

  /// Returns list of mixed String (header) + UserModel (staff)
  List<dynamic> _structureStaff(List<UserModel> staff) {
    // Group by role-based sections
    final Map<String, List<UserModel>> sections = {
      'ADMINISTRATION': [],
      'SENIOR STAFF': [],
      'ACADEMIC STAFF': [],
      'SUPPORT STAFF': [],
    };

    for (final s in staff) {
      if (s.roleLevel <= AppConstants.roleDeputy) {
        sections['ADMINISTRATION']!.add(s);
      } else if (s.roleLevel == AppConstants.roleSeniorTeacher) {
        sections['SENIOR STAFF']!.add(s);
      } else if (s.roleLevel == AppConstants.roleTeacher) {
        sections['ACADEMIC STAFF']!.add(s);
      } else {
        sections['SUPPORT STAFF']!.add(s);
      }
    }

    final result = <dynamic>[];
    sections.forEach((header, members) {
      if (members.isNotEmpty) {
        result.add(header);
        result.addAll(members);
      }
    });
    return result;
  }

  List<dynamic> _filter(List<dynamic> items, String q, String? dept) {
    if (q.isEmpty && dept == null) return items;

    final result = <dynamic>[];
    String? currentHeader;

    for (final item in items) {
      if (item is String) {
        currentHeader = item;
        continue;
      }
      final staff = item as UserModel;
      final matchQ = q.isEmpty ||
          staff.name.toLowerCase().contains(q.toLowerCase()) ||
          staff.email.toLowerCase().contains(q.toLowerCase());
      final matchDept = dept == null || staff.departmentId == dept;

      if (matchQ && matchDept) {
        if (currentHeader != null && !result.contains(currentHeader)) {
          result.add(currentHeader);
        }
        result.add(staff);
      }
    }
    return result;
  }
}

class _StaffCard extends StatelessWidget {
  final UserModel staff;
  final String currentUserId;
  final VoidCallback onChat;

  const _StaffCard({
    required this.staff,
    required this.currentUserId,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final initials = staff.name
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
    final roleColor = _roleColor(staff.roleLevel);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initials,
                      style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(
                      AppConstants.roleNames[staff.roleLevel] ?? 'Staff',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (staff.departmentId != null &&
                        staff.departmentId!.isNotEmpty)
                      Text(
                        staff.departmentId!,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
              // Online status dot
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColor(staff),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusLabel(staff),
                    style: TextStyle(
                        fontSize: 9, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Chat button
              IconButton(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary.withOpacity(0.08),
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(UserModel u) {
    // Simple heuristic: admin roles are considered online during business hours
    final hour = DateTime.now().hour;
    final isBusinessHours = hour >= 7 && hour <= 17;
    if (u.roleLevel <= 3 && isBusinessHours) return Colors.green;
    if (isBusinessHours) return Colors.green.withOpacity(0.6);
    return Colors.grey;
  }

  String _statusLabel(UserModel u) {
    final hour = DateTime.now().hour;
    if (hour < 7 || hour > 18) return 'Offline';
    if (u.roleLevel <= 3) return 'Online';
    return 'Active';
  }

  Color _roleColor(int level) {
    if (level <= 3) return Colors.purple;
    if (level <= 5) return AppTheme.primary;
    return Colors.teal;
  }
}
