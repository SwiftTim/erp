// lib/features/finance/finance_reports_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class FinanceReportsPage extends StatefulWidget {
  const FinanceReportsPage({super.key});

  @override
  State<FinanceReportsPage> createState() => _FinanceReportsPageState();
}

class _FinanceReportsPageState extends State<FinanceReportsPage> {
  String _selectedReportType = 'Income vs Expenses';
  String _selectedPeriod = 'This Term';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generating PDF audit report...')),
            ),
            tooltip: 'Export as PDF',
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}, tooltip: 'Share Report'),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedReportType,
                    decoration: const InputDecoration(labelText: 'Report Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Income vs Expenses', child: Text('Income vs Expenses')),
                      DropdownMenuItem(value: 'Cash Flow', child: Text('Cash Flow Statement')),
                      DropdownMenuItem(value: 'Budget Performance', child: Text('Budget vs Actual')),
                      DropdownMenuItem(value: 'Payroll Cost', child: Text('Payroll Cost Analysis')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReportType = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'This Month', child: Text('This Month (March 2026)')),
                      DropdownMenuItem(value: 'This Term', child: Text('Term 1, 2026')),
                      DropdownMenuItem(value: 'This Year', child: Text('Full Year 2026')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPeriod = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Top KPI cards
            Row(
              children: [
                Expanded(child: _kpiCard('Total Income', 2465000, Colors.green, Icons.trending_up)),
                const SizedBox(width: 16),
                Expanded(child: _kpiCard('Total Expenses', 1460000, Colors.red, Icons.trending_down)),
                const SizedBox(width: 16),
                Expanded(child: _kpiCard('Net Surplus', 1005000, Colors.blue, Icons.account_balance_outlined)),
              ],
            ),
            const SizedBox(height: 28),

            // Dynamic report body
            _buildReportContent(),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String title, double value, Color color, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withValues(alpha: 0.15))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text('KSh ${NumberFormat('#,###').format(value)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'Cash Flow': return _buildCashFlow();
      case 'Budget Performance': return _buildBudgetPerformance();
      case 'Payroll Cost': return _buildPayrollCost();
      default: return _buildIncomeVsExpenses();
    }
  }

  // 1. Income vs Expenses
  Widget _buildIncomeVsExpenses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Income vs Expenses — Monthly Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              _mockBarChart([
                {'label': 'Jan', 'income': 1800000.0, 'expense': 1100000.0},
                {'label': 'Feb', 'income': 2100000.0, 'expense': 1250000.0},
                {'label': 'Mar', 'income': 2465000.0, 'expense': 1460000.0},
              ]),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot('Income', Colors.green),
                  const SizedBox(width: 24),
                  _legendDot('Expenses', Colors.red),
                ],
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Income Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _breakdownRow('Student Tuition Billing', 1850000.0, '75.0%'),
              _breakdownRow('School Transport Fees', 380000.0, '15.4%'),
              _breakdownRow('Swimming Club Billing', 150000.0, '6.1%'),
              _breakdownRow('Lab & ICT Levies', 85000.0, '3.5%'),
            ]),
          ),
        ),
      ],
    );
  }

  // 2. Cash Flow
  Widget _buildCashFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cash Flow Statement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              _cashFlowRow('School Fees Collection', 'Cash Inflow', 2380000.0, true),
              _cashFlowRow('Supplier Procurement', 'Cash Outflow', 380000.0, false),
              _cashFlowRow('Staff Payroll Payment', 'Cash Outflow', 940000.0, false),
              _cashFlowRow('Utilities Payment', 'Cash Outflow', 140000.0, false),
              const Divider(height: 24),
              _cashFlowRow('Net Cash Position', 'Summary', 920000.0, true),
            ]),
          ),
        ),
      ],
    );
  }

  // 3. Budget Performance
  Widget _buildBudgetPerformance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Department Budget Utilisation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              _budgetProgressRow('Languages Department', 450000.0, 210000.0),
              const SizedBox(height: 20),
              _budgetProgressRow('Mathematics Department', 350000.0, 185000.0),
              const SizedBox(height: 20),
              _budgetProgressRow('Science Department', 600000.0, 480000.0),
              const SizedBox(height: 20),
              _budgetProgressRow('Humanities Department', 250000.0, 260000.0), // overspent
            ]),
          ),
        ),
      ],
    );
  }

  // 4. Payroll Cost
  Widget _buildPayrollCost() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payroll Cost Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _breakdownRow('Basic Salaries', 820000.0, '73.2%'),
              _breakdownRow('Allowances (House, Transport)', 160000.0, '14.3%'),
              _breakdownRow("Employer Levies (Housing 1.5%)", 140000.0, '12.5%'),
              const Divider(),
              _breakdownRow('Total Payroll Cost', 1120000.0, '100%', bold: true),
            ]),
          ),
        ),
      ],
    );
  }

  // Helpers
  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _breakdownRow(String name, double amount, String perc, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Row(children: [
            Text('KSh ${NumberFormat('#,###').format(amount)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: bold ? AppTheme.primary : Colors.black87)),
            const SizedBox(width: 12),
            Text(perc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ],
      ),
    );
  }

  Widget _cashFlowRow(String item, String category, double amount, bool isInflow) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(category, style: TextStyle(fontSize: 11, color: isInflow ? Colors.green : Colors.red)),
        ]),
        Text(
          '${isInflow ? '+' : '−'} KSh ${NumberFormat('#,###').format(amount)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: isInflow ? Colors.green : Colors.red),
        ),
      ]),
    );
  }

  Widget _budgetProgressRow(String dept, double budget, double spent) {
    final double pct = spent / budget;
    final Color color = pct > 1.0 ? Colors.red : (pct > 0.8 ? Colors.orange : Colors.green);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(dept, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            'KSh ${NumberFormat('#,###').format(spent)} / ${NumberFormat('#,###').format(budget)}',
            style: TextStyle(fontSize: 12, color: pct > 1.0 ? Colors.red : Colors.black54),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 12,
          ),
        ),
        if (pct > 1.0)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('⚠️ Budget Exceeded — Principal approval required for further spend.',
                style: TextStyle(color: Colors.red, fontSize: 10)),
          ),
      ],
    );
  }

  Widget _mockBarChart(List<Map<String, dynamic>> data) {
    const double maxHeight = 180.0;
    const double maxVal = 2465000.0;
    return SizedBox(
      height: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final double incH = ((d['income'] as double) / maxVal * maxHeight).clamp(10.0, maxHeight);
          final double expH = ((d['expense'] as double) / maxVal * maxHeight).clamp(10.0, maxHeight);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                    width: 28, height: incH,
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 6),
                Container(
                    width: 28, height: expH,
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4))),
              ]),
              const SizedBox(height: 12),
              Text(d['label'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
