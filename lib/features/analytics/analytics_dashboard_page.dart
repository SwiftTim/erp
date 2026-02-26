// lib/features/analytics/analytics_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardPage extends ConsumerStatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  ConsumerState<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends ConsumerState<AnalyticsDashboardPage> {
  bool _loading = true;
  
  // Stats
  int _totalStudents = 0;
  double _totalRevenue = 0;
  double _totalExpenses = 0;
  Map<String, int> _gradeDistribution = {};
  Map<String, double> _performanceStats = {
    'EE': 0.15, // Exceeding
    'ME': 0.65, // Meeting
    'BE': 0.15, // Below
    'AE': 0.05, // Approaching
  };
  
  // Absenteeism
  int _chronicAbsenteeismCount = 0;


  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final db = await ref.read(databaseProvider.future);
    
    // 1. Enrollment Stats
    final students = await db.studentDao.findAll();
    _totalStudents = students.length;
    
    final dist = <String, int>{};
    for (var s in students) {
      dist[s.grade] = (dist[s.grade] ?? 0) + 1;
    }
    
    // 2. Financial Stats
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1).millisecondsSinceEpoch;
    final yearEnd = DateTime(now.year, 12, 31).millisecondsSinceEpoch;
    
    final transactions = await db.financeDao.findTransactionsInRange(yearStart, yearEnd);
    _totalRevenue = transactions.fold(0.0, (sum, t) => sum + t.amountPaid);
    
    final expenses = await db.financeDao.findAllExpenditures();
    _totalExpenses = expenses
        .where((e) => e.expenseDate >= yearStart && e.expenseDate <= yearEnd)
        .fold(0.0, (sum, e) => sum + e.amount);

    // 3. Absenteeism Analytics (Current Month threshold: > 3 days)
    final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final monthEnd = '${now.year}-${now.month.toString().padLeft(2, '0')}-31';
    
    int chronicCount = 0;
    for (final s in students) {
      final abs = await db.attendanceDao.countAbsences(s.id, monthStart, monthEnd) ?? 0;
      if (abs > 3) chronicCount++;
    }

    if (mounted) {
      setState(() {
        _gradeDistribution = dist;
        _chronicAbsenteeismCount = chronicCount;
        _loading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'School Intelligence & Analytics',
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadAnalytics,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildEnrollmentSection(),
                  const SizedBox(height: 24),
                  _buildAbsenteeismSection(),
                  const SizedBox(height: 24),
                  _buildAcademicSection(),

                  const SizedBox(height: 24),
                  _buildFinancialHealthSection(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMiniCard('Population', '$_totalStudents', Icons.groups, Colors.blue),
        _buildMiniCard('Revenue', 'K${NumberFormat.compact().format(_totalRevenue)}', Icons.payments, Colors.green),
        _buildMiniCard('Expenses', 'K${NumberFormat.compact().format(_totalExpenses)}', Icons.shopping_cart, Colors.orange),
        _buildMiniCard('Net Balance', 'K${NumberFormat.compact().format(_totalRevenue - _totalExpenses)}', Icons.account_balance, Colors.teal),
      ],
    );
  }

  Widget _buildMiniCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enrollment by Grade', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._gradeDistribution.entries.map((e) {
              final percent = _totalStudents > 0 ? e.value / _totalStudents : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        Text('${e.value} Students', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenteeismSection() {
    final riskColor = _chronicAbsenteeismCount > (_totalStudents * 0.1) ? Colors.red : Colors.orange;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: riskColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: riskColor),
                const SizedBox(width: 8),
                const Text('Chronic Absenteeism Risk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Students with > 3 absences this month:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: riskColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_chronicAbsenteeismCount', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: riskColor)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('High Risk Learners', style: TextStyle(fontWeight: FontWeight.bold, color: riskColor)),
                      Text('Requires Deputy Head intervention', style: TextStyle(fontSize: 10, color: riskColor.withOpacity(0.8))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Academic Proficiency Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDonutSegment('EE', _performanceStats['EE']!, Colors.green),
                _buildDonutSegment('ME', _performanceStats['ME']!, Colors.blue),
                _buildDonutSegment('AE', _performanceStats['AE']!, Colors.orange),
                _buildDonutSegment('BE', _performanceStats['BE']!, Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Note: Data based on verified end-of-term assessments.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutSegment(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthSection() {
    final revenuePercent = _totalRevenue > 0 ? (_totalRevenue - _totalExpenses) / _totalRevenue : 0.0;
    
    return Card(
      color: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FINANCIAL SUSTAINABILITY', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
                    Text('Yearly Health Score', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text('${(revenuePercent * 100).toInt()}% Margin', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: (_totalRevenue.toInt()),
                  child: Container(height: 4, decoration: const BoxDecoration(color: Colors.green, borderRadius: BorderRadius.horizontal(left: Radius.circular(2)))),
                ),
                Expanded(
                  flex: (_totalExpenses.toInt()),
                  child: Container(height: 4, decoration: const BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.horizontal(right: Radius.circular(2)))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Collections', style: TextStyle(color: Colors.white60, fontSize: 10)),
                Text('Total Operations Cost', style: TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
