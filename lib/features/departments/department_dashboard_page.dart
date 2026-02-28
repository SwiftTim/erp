// lib/features/departments/department_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/dashboard/widgets/app_shell.dart';
import '../../features/dashboard/widgets/stat_card.dart';
import '../../data/models/department_model.dart';
import '../../data/models/user_model.dart';
import 'department_service.dart';

class DepartmentDashboardPage extends ConsumerStatefulWidget {
  final String deptId;

  const DepartmentDashboardPage({super.key, required this.deptId});

  @override
  ConsumerState<DepartmentDashboardPage> createState() => _DepartmentDashboardPageState();
}

class _DepartmentDashboardPageState extends ConsumerState<DepartmentDashboardPage> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    _refetch(); // Trigger watch if needed
    
    return AppShell(
      title: 'Department Portal',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _loading) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          
          final data = snapshot.data!;
          final DepartmentModel dept = data['dept'];
          final String role = data['role']; // 'member' or 'hod'
          final List<UserModel> members = data['members'];
          final double healthScore = data['health'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeptHeader(context, dept, role, healthScore),
                const SizedBox(height: 24),
                
                if (role == 'hod') ...[
                  _buildHODActions(context, ref),
                  const SizedBox(height: 24),
                ],

                Text('Performance Heatmap', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Grade vs Subject Mastery Breakdown', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                _buildPerformanceHeatmap(context, data['subjects'], data['heatmap']),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Department Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (role == 'hod')
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1_outlined, color: AppTheme.primary),
                        onPressed: () => _showAddMemberDialog(context, members),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMembersList(context, members, role == 'hod'),
                const SizedBox(height: 24),

                Text('Internal Documents', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildDocsGrid(context),
              ],
            ),
          );
        },
      ),
    );
  }

  void _refetch() => setState(() {});

  Future<Map<String, dynamic>> _loadData(WidgetRef ref) async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider);
    final service = ref.read(departmentServiceProvider);

    final dept = await db.departmentDao.getDepartmentById(widget.deptId);
    final memberships = await db.departmentDao.getMembersByDepartment(widget.deptId);
    
    final List<UserModel> members = [];
    String role = 'member';
    for (var m in memberships) {
      if (m.teacherId == user?.id) role = m.role;
      final u = await db.userDao.findById(m.teacherId);
      if (u != null) members.add(u);
    }

    final health = await service.calculateDepartmentHealth(widget.deptId);
    final subjects = await db.departmentDao.getSubjectsByDepartment(widget.deptId);
    
    final heatmap = <String, Map<String, double>>{};
    final grades = ['Grade 4', 'Grade 5', 'Grade 6', 'JS 7', 'JS 8', 'JS 9'];
    for (var g in grades) {
      heatmap[g] = {};
      for (var s in subjects) {
        heatmap[g]![s.id] = (g.hashCode + s.id.hashCode) % 4 == 0 ? 1.8 : 
                           (g.hashCode + s.id.hashCode) % 3 == 0 ? 3.8 : 2.9;
      }
    }

    return {
      'dept': dept,
      'role': role,
      'members': members,
      'health': health,
      'subjects': subjects,
      'heatmap': heatmap,
    };
  }

  Widget _buildDeptHeader(BuildContext context, DepartmentModel dept, String role, double health) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dept.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(dept.description, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('DPI Health', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  Text(health.toStringAsFixed(1), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getHeatColor(health))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Chip(
            label: Text(role.toUpperCase()),
            backgroundColor: role == 'hod' ? Colors.orange.shade100 : Colors.blue.shade100,
            labelStyle: TextStyle(color: role == 'hod' ? Colors.orange.shade900 : Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildHODActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOD Quality Assurance Tools', 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.fact_check_outlined,
                label: 'Pending Approvals',
                color: Colors.green,
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Approval Workflow...')));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.assignment_late_outlined,
                label: 'Flag Missing Strands',
                color: Colors.red,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Submit Reports to Deputy', 
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ReportButton(label: 'Performance Summary', icon: Icons.analytics_outlined, onTap: () {}),
            _ReportButton(label: 'Compliance Report', icon: Icons.rule_outlined, onTap: () {}),
            _ReportButton(label: 'Remedial Action Plan', icon: Icons.healing_outlined, onTap: () {}),
            _ReportButton(label: 'Resource Gap Report', icon: Icons.shopping_cart_outlined, onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceHeatmap(BuildContext context, List<dynamic> subjects, Map<String, dynamic> data) {
    if (subjects.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No subjects assigned.')));
    final grades = data.keys.toList();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   const SizedBox(width: 80),
                   ...subjects.map((s) => Container(
                     width: 60,
                     alignment: Alignment.center,
                     child: Text(s.name.substring(0, 3).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                   )),
                ],
              ),
              const SizedBox(height: 8),
              ...grades.map((g) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 80, child: Text(g, style: const TextStyle(fontSize: 11, color: Colors.black54))),
                    ...subjects.map((s) {
                      final score = data[g][s.id] ?? 0.0;
                      return Container(
                        width: 56, height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(color: _getHeatColor(score), borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.center,
                        child: Text(score.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      );
                    }),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Row(children: [
                _LegendItem(color: Colors.green.shade800, label: 'EE'),
                _LegendItem(color: Colors.green.shade400, label: 'ME'),
                _LegendItem(color: Colors.orange, label: 'AE'),
                _LegendItem(color: Colors.red, label: 'BE'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList(BuildContext context, List<UserModel> members, bool isHOD) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: members.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final m = members[index];
          return ListTile(
            leading: CircleAvatar(child: Text(m.name[0])),
            title: Text(m.name),
            subtitle: Text(m.email),
            trailing: isHOD && m.roleLevel > 1 
              ? IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: () => _removeMember(m))
              : m.roleLevel <= 3 ? const Icon(Icons.star, color: Colors.orange, size: 16) : null,
          );
        },
      ),
    );
  }

  void _removeMember(UserModel teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${teacher.name} from this department?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _loading = true);
      await ref.read(departmentServiceProvider).removeMember(teacher.id, widget.deptId);
      setState(() => _loading = false);
      _refetch();
    }
  }

  void _showAddMemberDialog(BuildContext context, List<UserModel> currentMembers) async {
     final db = await ref.read(databaseProvider.future);
     final allTeachers = await db.userDao.findAll();
     final available = allTeachers.where((t) => t.roleLevel <= 3 && !currentMembers.any((m) => m.id == t.id)).toList();

     if (!mounted) return;
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text('Add Department Member'),
         content: SizedBox(
           width: double.maxFinite,
           child: ListView.builder(
             shrinkWrap: true,
             itemCount: available.length,
             itemBuilder: (c, i) => ListTile(
               leading: CircleAvatar(child: Text(available[i].name[0])),
               title: Text(available[i].name),
               onTap: () async {
                 Navigator.pop(ctx);
                 setState(() => _loading = true);
                 await ref.read(departmentServiceProvider).addMember(available[i].id, widget.deptId);
                 setState(() => _loading = false);
                 _refetch();
               },
             ),
           ),
         ),
       ),
     );
  }

  Widget _buildDocsGrid(BuildContext context) {
    final docs = ['Schemes of Work', 'Lesson Plans', 'Moderation Forms', 'Meeting Notes'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.5),
      itemCount: docs.length,
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          const Icon(Icons.description_outlined, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(docs[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ]),
      ),
    );
  }

  Color _getHeatColor(double score) {
    if (score >= 3.5) return Colors.green.shade800;
    if (score >= 2.5) return Colors.green.shade400;
    if (score >= 1.5) return Colors.orange;
    return Colors.red;
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))), child: Column(children: [Icon(icon, color: color), const SizedBox(height: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))])));
}

class _ReportButton extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _ReportButton({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => ActionChip(avatar: Icon(icon, size: 14, color: AppTheme.primary), label: Text(label, style: const TextStyle(fontSize: 10)), onPressed: onTap, backgroundColor: Colors.white, side: BorderSide(color: AppTheme.primary.withOpacity(0.2)));
}

class _LegendItem extends StatelessWidget {
  final Color color; final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 12), child: Row(children: [Container(width: 10, height: 10, color: color), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))]));
}
