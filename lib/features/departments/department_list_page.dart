// lib/features/departments/department_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/dashboard/widgets/app_shell.dart';
import '../../data/models/department_model.dart';
import 'department_service.dart';

class DepartmentListPage extends ConsumerWidget {
  const DepartmentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final service = ref.watch(departmentServiceProvider);

    return AppShell(
      title: 'School Departments',
      body: FutureBuilder<List<DepartmentModel>>(
        future: user != null ? ref.read(departmentServiceProvider).getMyDepartments(user.id) : Future.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final depts = snapshot.data ?? [];

          if (depts.isEmpty) {
            return const Center(child: Text('You are not assigned to any departments.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: depts.length,
            itemBuilder: (context, index) {
              final d = depts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Icon(Icons.business_outlined, color: AppTheme.primary),
                  ),
                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(d.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/departments/${d.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
