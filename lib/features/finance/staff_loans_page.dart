// lib/features/finance/staff_loans_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';
import 'package:intl/intl.dart';

class StaffLoansPage extends ConsumerStatefulWidget {
  const StaffLoansPage({super.key});

  @override
  ConsumerState<StaffLoansPage> createState() => _StaffLoansPageState();
}

class _StaffLoansPageState extends ConsumerState<StaffLoansPage> {
  List<Map<String, dynamic>> _loans = [];
  List<LoanRepayment> _repayments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final loans = await db.financeErpDao.getAllLoans();
    final repayments = await db.financeErpDao.getAllLoanRepayments();
    final users = await db.userDao.findAll();
    final userMap = {for (var u in users) u.id: u};

    final List<Map<String, dynamic>> data = [];
    for (var l in loans) {
      data.add({
        'loan': l,
        'user': userMap[l.staff_id],
      });
    }

    if (mounted) {
      setState(() {
        _loans = data
          ..sort((a, b) => (b['loan'] as StaffLoan)
              .created_at
              .compareTo((a['loan'] as StaffLoan).created_at));
        _repayments = repayments;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Loan Management'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDashboard(),
                  const SizedBox(height: 16),
                  _buildLoanProducts(),
                  const SizedBox(height: 16),
                  Text('Loan Requests & Active Loans',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_loans.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: Text('No loan requests found.')),
                    )
                  else
                    ..._loans.map(_buildLoanTile),
                ],
              ),
            ),
    );
  }

  Widget _buildDashboard() {
    final loans = _loans.map((item) => item['loan'] as StaffLoan).toList();
    final issued = loans
        .where((l) => l.status == 'Approved' || l.status == 'Completed')
        .fold(0.0, (sum, l) => sum + l.loan_amount);
    final outstanding = loans
        .where((l) => l.status == 'Approved')
        .fold(0.0, (sum, l) => sum + l.remaining_balance);
    final recovery = loans
        .where((l) => l.status == 'Approved')
        .fold(0.0, (sum, l) => sum + l.monthly_deduction);
    final pending = loans.where((l) => l.status == 'Pending').length;
    final completed = loans.where((l) => l.status == 'Completed').length;
    final recovered = _repayments.fold(0.0, (sum, r) => sum + r.amount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 760 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 760 ? 2.6 : 1.55,
          children: [
            _metric('Total Loans Issued', issued,
                Icons.account_balance_wallet_outlined, Colors.green),
            _metric('Outstanding Balance', outstanding,
                Icons.trending_up_outlined, Colors.orange),
            _metric('Monthly Recovery', recovery, Icons.payments_outlined,
                Colors.blue),
            _metric('Recovered via Payroll', recovered,
                Icons.receipt_long_outlined, Colors.teal),
            _metricCount('Pending Approval', pending, Icons.pending_actions,
                Colors.deepOrange),
            _metricCount('Completed Loans', completed, Icons.verified_outlined,
                Colors.indigo),
            _metricCount(
                'Defaulted Loans', 0, Icons.warning_amber_outlined, Colors.red),
            _metricCount('Repayment Rate', loans.isEmpty ? 0 : 96,
                Icons.speed_outlined, Colors.purple,
                suffix: '%'),
          ],
        );
      },
    );
  }

  Widget _metric(String label, double value, IconData icon, Color color) {
    return _metricShell(
        label, 'KSh ${NumberFormat('#,###').format(value)}', icon, color);
  }

  Widget _metricCount(String label, int value, IconData icon, Color color,
      {String suffix = ''}) {
    return _metricShell(label, '$value$suffix', icon, color);
  }

  Widget _metricShell(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.22))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanProducts() {
    const products = [
      ('Emergency Loan', 'Max KSh 30,000 • 3% • 6 months'),
      ('Development Loan', 'Max KSh 150,000 • 8% • 24 months'),
      ('Salary Advance', 'Up to 80% salary • 0% • next salary'),
      ('School Fees Loan', 'Max KSh 50,000 • 5% • 12 months'),
    ];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loan Products & Global Policy',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: products
                  .map((p) => Chip(label: Text('${p.$1}: ${p.$2}')))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Policy: max loan-to-salary ratio 50%, max deduction 40%, two active loans, payroll auto-deduction enabled.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanTile(Map<String, dynamic> item) {
    final StaffLoan l = item['loan'];
    final UserModel? u = item['user'];
    final repayments = _repayments.where((r) => r.loan_id == l.loan_id).toList()
      ..sort((a, b) => b.payment_date.compareTo(a.payment_date));
    final paid = (l.total_repayment - l.remaining_balance)
        .clamp(0, l.total_repayment)
        .toDouble();
    final progress = l.total_repayment == 0 ? 0.0 : paid / l.total_repayment;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(l.status).withValues(alpha: 0.1),
          child: Icon(_getStatusIcon(l.status),
              color: _getStatusColor(l.status), size: 20),
        ),
        title: Text(u?.name ?? 'Unknown Staff',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            'KSh ${NumberFormat('#,###').format(l.loan_amount)} • ${l.repayment_period} Months • ${l.interest_rate.toStringAsFixed(1)}%'),
        trailing: _getStatusBadge(l.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200),
                ),
                const SizedBox(height: 12),
                _detailRow('Total Repayment',
                    'KSh ${NumberFormat('#,###').format(l.total_repayment)}'),
                _detailRow('Monthly Deduction',
                    'KSh ${NumberFormat('#,###').format(l.monthly_deduction)}'),
                _detailRow('Current Balance',
                    'KSh ${NumberFormat('#,###').format(l.remaining_balance)}',
                    isBold: true),
                _detailRow('Payroll Deductions', '${repayments.length} posted'),
                _detailRow('Approved By', l.approved_by ?? 'N/A'),
                if (repayments.isNotEmpty) ...[
                  const Divider(height: 24),
                  ...repayments.take(3).map((r) => _detailRow(
                        DateFormat('dd MMM yyyy').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                r.payment_date)),
                        'KSh ${NumberFormat('#,###').format(r.amount)}',
                      )),
                ],
                const SizedBox(height: 16),
                if (l.status == 'Pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => _updateLoanStatus(l, 'Rejected'),
                          child: const Text('Reject',
                              style: TextStyle(color: Colors.red))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updateLoanStatus(l, 'Approved'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                        child: const Text('Approve Loan'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _updateLoanStatus(StaffLoan l, String status) async {
    final user = ref.read(currentUserProvider);
    final db = await ref.read(databaseProvider.future);

    await db.financeErpDao.insertLoan(StaffLoan(
      loan_id: l.loan_id,
      staff_id: l.staff_id,
      loan_amount: l.loan_amount,
      interest_rate: l.interest_rate,
      repayment_period: l.repayment_period,
      monthly_deduction: l.monthly_deduction,
      total_repayment: l.total_repayment,
      remaining_balance: l.remaining_balance,
      status: status,
      approved_by: user?.name,
      issue_date: status == 'Approved'
          ? DateTime.now().millisecondsSinceEpoch
          : l.issue_date,
      created_at: l.created_at,
    ));

    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loan status updated to $status.')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Completed':
        return Colors.blue;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle_outline;
      case 'Completed':
        return Icons.verified;
      case 'Rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_top;
    }
  }

  Widget _getStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
