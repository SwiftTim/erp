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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final loans = await db.financeErpDao.getAllLoans();
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
        _loans = data..sort((a, b) => (b['loan'] as StaffLoan).created_at.compareTo((a['loan'] as StaffLoan).created_at));
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
          : _loans.isEmpty
              ? const Center(child: Text('No loan requests found.'))
              : _buildLoanList(),
    );
  }

  Widget _buildLoanList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _loans.length,
      itemBuilder: (context, index) {
        final item = _loans[index];
        final StaffLoan l = item['loan'];
        final UserModel? u = item['user'];

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(l.status).withValues(alpha: 0.1),
              child: Icon(_getStatusIcon(l.status), color: _getStatusColor(l.status), size: 20),
            ),
            title: Text(u?.name ?? 'Unknown Staff', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('KSh ${NumberFormat('#,###').format(l.loan_amount)} • ${l.repayment_period} Months'),
            trailing: _getStatusBadge(l.status),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow('Total Repayment', 'KSh ${NumberFormat('#,###').format(l.total_repayment)}'),
                    _detailRow('Monthly Deduction', 'KSh ${NumberFormat('#,###').format(l.monthly_deduction)}'),
                    _detailRow('Current Balance', 'KSh ${NumberFormat('#,###').format(l.remaining_balance)}', isBold: true),
                    _detailRow('Approved By', l.approved_by ?? 'N/A'),
                    const SizedBox(height: 16),
                    if (l.status == 'Pending')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => _updateLoanStatus(l, 'Rejected'), child: const Text('Reject', style: TextStyle(color: Colors.red))),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateLoanStatus(l, 'Approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
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
      issue_date: status == 'Approved' ? DateTime.now().millisecondsSinceEpoch : l.issue_date,
      created_at: l.created_at,
    ));

    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loan status updated to $status.')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green;
      case 'Completed': return Colors.blue;
      case 'Rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved': return Icons.check_circle_outline;
      case 'Completed': return Icons.verified;
      case 'Rejected': return Icons.cancel_outlined;
      default: return Icons.hourglass_top;
    }
  }

  Widget _getStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
