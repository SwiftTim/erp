// lib/features/catering/catering_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/catering_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';
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

  static const _accent = Color(0xFFF59E0B); // Amber / Orange

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final db = await ref.read(databaseProvider.future);
    
    // Load Meal Plan
    final meals = await db.cateringDao.findForTerm(1, '2026');
    
    // Load Allergy Grid
    final students = await db.studentDao.findAll();
    final List<Map<String, dynamic>> allergies = [];
    
    for (final s in students) {
      final med = await db.medicalDao.findForStudent(s.id);
      if (med != null && med.allergies != null) {
        try {
          final List<dynamic> list = json.decode(med.allergies!);
          if (list.isNotEmpty) {
            allergies.add({
              'name': s.fullName,
              'grade': s.grade,
              'allergies': list.join(", "),
            });
          }
        } catch (_) {
          // Fallback if not valid JSON
          if (med.allergies!.isNotEmpty) {
            allergies.add({
              'name': s.fullName,
              'grade': s.grade,
              'allergies': med.allergies,
            });
          }
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
    final user = ref.watch(currentUserProvider);

    return AppShell(
      title: 'Kitchen & Catering',
      actions: [
        TextButton.icon(
          onPressed: () => PrintableDocumentHub.show(
            context,
            'Kitchen & Catering',
            DocumentTemplates.getTemplatesForModule('catering'),
          ),
          icon: const Icon(Icons.print_outlined, size: 18, color: _accent),
          label: const Text('Forms', style: TextStyle(color: _accent)),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildWelcomeCard(user),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildTabSection(),
                ]),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          Text(user?.name ?? 'Head Chef',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(children: [
            _miniStat('Weekly Menus', '${_meals.length}'),
            const SizedBox(width: 32),
            _miniStat('Critical Allergies', '${_allergyList.length}'),
            const SizedBox(width: 32),
            _miniStat('Term Rotation', 'Term 1 2026'),
          ]),
        ]),
        Positioned(right: 0, top: 0,
          child: Icon(Icons.restaurant_menu_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1))),
      ]),
    );
  }

  Widget _miniStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
    ],
  );

  Widget _buildStatsGrid() {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
      children: [
        _statCard('Total Allergy Alerts', '${_allergyList.length}', Icons.warning_amber_outlined, Colors.red),
        _statCard('Catalogued Meals', '${_meals.length}', Icons.restaurant, _accent),
        _statCard('Meal Schedule Days', '5 Days (Mon-Fri)', Icons.calendar_today_outlined, Colors.teal),
        _statCard('Dining Service Status', 'Operational', Icons.check_circle_outline, Colors.green),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildTabSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Catering & Dietaries', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
        child: Column(children: [
          TabBar(
            controller: _tabController,
            labelColor: _accent, indicatorColor: _accent,
            unselectedLabelColor: Colors.grey, dividerColor: Colors.transparent,
            tabs: [
              const Tab(text: 'Weekly Meal Plan'),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Allergy Watchlist'),
                if (_allergyList.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(radius: 8, backgroundColor: Colors.red,
                    child: Text('${_allergyList.length}', style: const TextStyle(fontSize: 10, color: Colors.white))),
                ],
              ])),
            ],
          ),
          SizedBox(
            height: 480,
            child: TabBarView(controller: _tabController, children: [
              _buildMealPlanTab(),
              _buildAllergyTab(),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildMealPlanTab() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final dayMeals = _meals.where((m) => m.dayOfWeek == day).toList();

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            initiallyExpanded: i == 0,
            leading: CircleAvatar(
              backgroundColor: _accent.withValues(alpha: 0.1),
              child: Text(day.substring(0, 1), style: const TextStyle(color: _accent, fontWeight: FontWeight.bold)),
            ),
            title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.edit_note, size: 22, color: _accent),
              onPressed: () => _editMeal(day, dayMeals),
            ),
            children: [
              _buildMealRow('Breakfast', dayMeals.where((m) => m.mealType == 'Breakfast').firstOrNull?.menu ?? 'To be updated'),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMealRow('Lunch', dayMeals.where((m) => m.mealType == 'Lunch').firstOrNull?.menu ?? 'To be updated'),
              const Divider(height: 1, indent: 16, endIndent: 16),
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
            TextField(controller: bCtrl, decoration: const InputDecoration(labelText: 'Breakfast Menu Item')),
            TextField(controller: lCtrl, decoration: const InputDecoration(labelText: 'Lunch Menu Item')),
            TextField(controller: sCtrl, decoration: const InputDecoration(labelText: 'Snack / Tea Menu Item')),
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
                    id: const Uuid().v4(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      return const Center(child: Text('No allergies reported in the student database.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _allergyList.length,
      itemBuilder: (context, i) {
        final entry = _allergyList[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.red.shade50,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade100)),
          child: ListTile(
            leading: const Icon(Icons.warning_amber_outlined, color: Colors.red),
            title: Text(entry['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            subtitle: Text('Grade: ${entry['grade']} • Allergic reaction triggers: ${entry['allergies']}'),
          ),
        );
      },
    );
  }
}
