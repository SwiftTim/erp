// lib/features/finance/finance_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../dashboard/widgets/app_shell.dart';
import '../dashboard/widgets/stat_card.dart';

import '../auth/auth_provider.dart';
import '../../core/data/finance_erp_seed.dart';
import 'package:intl/intl.dart';

class FinanceDashboardPage extends ConsumerStatefulWidget {
  const FinanceDashboardPage({super.key});

  @override
  ConsumerState<FinanceDashboardPage> createState() => _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends ConsumerState<FinanceDashboardPage> {
  double _totalCollected = 0;
  double _totalOutstanding = 0;
  double _monthlyPayroll = 0;
  double _monthlyExpenses = 0;
  int _totalStudents = 0;
  bool _loading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    final db = await ref.read(databaseProvider.future);
    
    final students = await db.studentDao.findAll();
    final payments = await db.financeErpDao.getAllPayments();
    final billings = await db.financeErpDao.getAllBillings();
    final payrolls = await db.financeErpDao.getAllPayrolls();
    final expenses = await db.financeErpDao.getAllExpenses();

    double totalCollected = 0;
    for (final p in payments) {
      totalCollected += p.amount_paid;
    }

    double totalOutstanding = 0;
    for (final b in billings) {
      totalOutstanding += b.balance;
    }

    double monthlyPayroll = 0;
    // For demo, sum all payrolls. In real app, filter by current month.
    for (final p in payrolls) {
      monthlyPayroll += p.net_salary;
    }

    double monthlyExpenses = 0;
    for (final e in expenses) {
      monthlyExpenses += e.amount;
    }

    if (mounted) {
      setState(() {
        _totalStudents = students.length;
        _totalCollected = totalCollected;
        _totalOutstanding = totalOutstanding;
        _monthlyPayroll = monthlyPayroll;
        _monthlyExpenses = monthlyExpenses;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Finance Hub',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Operational Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2,
                    children: [
                      StatCard(label: 'Total Students', value: _totalStudents.toString(), icon: Icons.people_outline, color: Colors.blue),
                      StatCard(label: 'Fees Collected', value: 'KES ${_totalCollected.toStringAsFixed(0)}', icon: Icons.payments_outlined, color: Colors.green),
                      StatCard(label: 'Outstanding Fees', value: 'KES ${_totalOutstanding.toStringAsFixed(0)}', icon: Icons.money_off_outlined, color: Colors.red),
                      StatCard(label: 'Monthly Payroll', value: 'KES ${NumberFormat('#,###').format(_monthlyPayroll)}', icon: Icons.request_quote_outlined, color: Colors.purple),
                      StatCard(label: 'Monthly Expenses', value: 'KES ${NumberFormat('#,###').format(_monthlyExpenses)}', icon: Icons.trending_down_outlined, color: Colors.orange),
                      StatCard(
                        label: 'Budget Remaining', 
                        value: 'KES ${NumberFormat('#,###').format((2000000 - _monthlyExpenses).clamp(0, 2000000))}', 
                        icon: Icons.account_balance_outlined, 
                        color: Colors.teal,
                        trend: 'Limit: 2M',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Financial Overview', 
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      TextButton.icon(
                        onPressed: _isGenerating ? null : _handleGenerateData,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_isGenerating ? 'Generating...' : 'Refresh/Generate Data'),
                        style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildQuickLinks(context),
                  const SizedBox(height: 32),
                  Text('Recent Fee Payments', 
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRecentPaymentsTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      {'label': 'Billing', 'icon': Icons.receipt_long_outlined, 'route': Routes.financeBilling, 'color': Colors.blue},
      {'label': 'Fees', 'icon': Icons.list_alt_outlined, 'route': Routes.financeStructure, 'color': Colors.teal},
      {'label': 'Staff Payroll', 'icon': Icons.account_balance_wallet_outlined, 'route': Routes.financePayroll, 'color': Colors.green},
      {'label': 'Batch Payroll', 'icon': Icons.playlist_add_check, 'route': Routes.financePayrollBatch, 'color': Colors.indigo},
      {'label': 'Salary Struct', 'icon': Icons.account_tree_outlined, 'route': Routes.financeSalaryStructures, 'color': Colors.blueGrey},
      {'label': 'Expenses', 'icon': Icons.shopping_cart_outlined, 'route': Routes.financeExpenses, 'color': Colors.orange},
      {'label': 'Assets', 'icon': Icons.precision_manufacturing_outlined, 'route': Routes.financeAssets, 'color': Colors.purple},
      {'label': 'Amenities', 'icon': Icons.apartment_outlined, 'route': Routes.financeAmenities, 'color': Colors.indigo},
      {'label': 'Loan Management', 'icon': Icons.monetization_on_outlined, 'route': Routes.financeLoans, 'color': Colors.brown},
      {'label': 'Procurement Tracking', 'icon': Icons.shopping_bag_outlined, 'route': Routes.financeProcurement, 'color': Colors.deepOrange},
      {'label': 'Budget Approvals', 'icon': Icons.approval_outlined, 'route': Routes.financeApprovals, 'color': Colors.indigo},
      {'label': 'Reports', 'icon': Icons.analytics_outlined, 'route': Routes.reports, 'color': Colors.red},
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: links.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final link = links[index];
          final route = link['route'] as String;
          return InkWell(
            onTap: () => context.push(route),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (link['color'] as Color).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (link['color'] as Color).withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(link['icon'] as IconData, color: link['color'] as Color),
                  const SizedBox(height: 8),
                  Text(link['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentPaymentsTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Latest Student Payments', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          // In a real app, logic to fetch top 5 payments would go here
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Visit the Payments & Receipts module to view all records.', 
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGenerateData() async {
    setState(() => _isGenerating = true);
    try {
      final db = await ref.read(databaseProvider.future);
      await seedFinanceErp(db);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Financial data generated successfully!')),
        );
        _loadFinanceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
