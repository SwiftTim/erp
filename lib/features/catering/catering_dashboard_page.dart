// lib/features/catering/catering_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/catering_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class CateringDashboardPage extends ConsumerStatefulWidget {
  const CateringDashboardPage({super.key});

  @override
  ConsumerState<CateringDashboardPage> createState() => _CateringDashboardPageState();
}

class _CateringDashboardPageState extends ConsumerState<CateringDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MealPlanModel> _meals = [];
  List<Map<String, dynamic>> _allergyList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    
    // 1. Load Meal Plan
    final meals = await db.cateringDao.findForTerm(1, '2026');
    
    // 2. Load Allergy Grid (Cross-module check)
    // In a real app, this would be a specialized query, for now we filter
    final students = await db.studentDao.findAll();
    final List<Map<String, dynamic>> allergies = [];
    
    for (final s in students) {
      final med = await db.medicalDao.findForStudent(s.id);
      if (med != null && med.allergies != null) {
        final List<dynamic> list = json.decode(med.allergies!);
        if (list.isNotEmpty) {
          allergies.add({
            'name': s.fullName,
            'grade': s.grade,
            'allergies': list.join(", "),
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _meals = meals;
        _allergyList = allergies;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Kitchen & Catering',
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primary,
            tabs: const [
              Tab(text: 'Weekly Meal Plan', icon: Icon(Icons.restaurant_menu)),
              Tab(text: 'Allergy Watchlist', icon: Icon(Icons.warning_amber_rounded)),
            ],
          ),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMealPlanTab(),
                    _buildAllergyTab(),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanTab() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final dayMeals = _meals.where((m) => m.dayOfWeek == day).toList();

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            initiallyExpanded: i == 0,
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text(day.substring(0, 1), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.edit_note, size: 20),
              onPressed: () => _editMeal(day, dayMeals),
            ),
            children: [
              _buildMealRow('Breakfast', dayMeals.where((m) => m.mealType == 'Breakfast').firstOrNull?.menu ?? 'To be updated'),
              _buildMealRow('Lunch', dayMeals.where((m) => m.mealType == 'Lunch').firstOrNull?.menu ?? 'To be updated'),
              _buildMealRow('Snack', dayMeals.where((m) => m.mealType == 'Snack').firstOrNull?.menu ?? 'To be updated'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editMeal(String day, List<MealPlanModel> currentMeals) async {
    final bCtrl = TextEditingController(text: currentMeals.where((m) => m.mealType == 'Breakfast').firstOrNull?.menu);
    final lCtrl = TextEditingController(text: currentMeals.where((m) => m.mealType == 'Lunch').firstOrNull?.menu);
    final sCtrl = TextEditingController(text: currentMeals.where((m) => m.mealType == 'Snack').firstOrNull?.menu);

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Menu: $day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bCtrl, decoration: const InputDecoration(labelText: 'Breakfast')),
            TextField(controller: lCtrl, decoration: const InputDecoration(labelText: 'Lunch')),
            TextField(controller: sCtrl, decoration: const InputDecoration(labelText: 'Snack')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              final types = ['Breakfast', 'Lunch', 'Snack'];
              final ctrls = [bCtrl, lCtrl, sCtrl];
              
              for (int i = 0; i < types.length; i++) {
                final existing = currentMeals.where((m) => m.mealType == types[i]).firstOrNull;
                if (existing != null) {
                  await db.cateringDao.updateMeal(MealPlanModel(
                    id: existing.id,
                    dayOfWeek: day,
                    mealType: types[i],
                    menu: ctrls[i].text,
                    academicYear: '2026',
                    term: 1,
                  ));
                } else {
                  await db.cateringDao.insertMeal(MealPlanModel(
                    id: Uuid().v4(),
                    dayOfWeek: day,
                    mealType: types[i],
                    menu: ctrls[i].text,
                    academicYear: '2026',
                    term: 1,
                  ));
                }
              }
              Navigator.pop(context, true);
            },
            child: const Text('Save Menu'),
          ),
        ],
      ),
    );

    if (updated == true) _loadData();
  }

  Widget _buildMealRow(String type, String menu) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(menu, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyTab() {
    if (_allergyList.isEmpty) {
      return const Center(child: Text('No allergies reported in the school.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allergyList.length,
      itemBuilder: (context, i) {
        final entry = _allergyList[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.red.shade50,
          child: ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.red),
            title: Text(entry['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            subtitle: Text('Grade: ${entry['grade']} • Allergic to: ${entry['allergies']}'),
          ),
        );
      },
    );
  }
}
