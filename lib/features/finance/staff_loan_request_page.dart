// lib/features/finance/staff_loan_request_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../auth/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class StaffLoanRequestPage extends ConsumerStatefulWidget {
  const StaffLoanRequestPage({super.key});

  @override
  ConsumerState<StaffLoanRequestPage> createState() => _StaffLoanRequestPageState();
}

class _StaffLoanRequestPageState extends ConsumerState<StaffLoanRequestPage> {
  List<StaffLoan> _myLoans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final db = await ref.read(databaseProvider.future);
    final loans = await db.financeErpDao.getAllLoans();
    
    if (mounted) {
      setState(() {
        _myLoans = loans.where((l) => l.staff_id == user.id).toList()
          ..sort((a, b) => b.created_at.compareTo(a.created_at));
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Loans & Advances'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myLoans.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLoanRequestForm,
        icon: const Icon(Icons.monetization_on),
        label: const Text('Request Loan'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('You have no active or pending loans.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myLoans.length,
      itemBuilder: (context, index) {
        final loan = _myLoans[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Loan Ref: ${loan.loan_id.substring(0,8).toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    _getStatusBadge(loan.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Principal: KSh ${NumberFormat('#,###').format(loan.loan_amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Total to Pay: KSh ${NumberFormat('#,###').format(loan.total_repayment)}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Monthly: KSh ${NumberFormat('#,###').format(loan.monthly_deduction)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        Text('${loan.repayment_period} Months', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Remaining: KSh ${NumberFormat('#,###').format(loan.remaining_balance)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    _getProgressIndicator(loan),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Approved': color = Colors.green; break;
      case 'Completed': color = Colors.blue; break;
      case 'Rejected': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _getProgressIndicator(StaffLoan loan) {
    if (loan.status == 'Pending') return const Text('Awaiting Review', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic));
    final paid = loan.total_repayment - loan.remaining_balance;
    final percent = (paid / loan.total_repayment).clamp(0, 1).toDouble();
    return SizedBox(
      width: 100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: percent, backgroundColor: Colors.grey.shade200, color: Colors.green),
      ),
    );
  }

  void _showLoanRequestForm() {
    final amountController = TextEditingController();
    String repayment = '6 Months';
    String interest = '5%';
    double monthly = 0;
    double total = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void _updatePreview() {
            final amt = double.tryParse(amountController.text) ?? 0;
            final months = int.parse(repayment.split(' ')[0]);
            final rate = 0.05; // fixed for demo
            total = amt + (amt * rate);
            monthly = total / months;
          }

          return AlertDialog(
            title: const Text('Request Staff Loan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Loan Amount (KSh)'),
                  onChanged: (_) => setDialogState(() => _updatePreview()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: repayment,
                  decoration: const InputDecoration(labelText: 'Repayment Period'),
                  items: ['3 Months', '6 Months', '12 Months', '18 Months'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setDialogState(() { repayment = v!; _updatePreview(); }),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      _previewRow('Total Interest', '5% (Flat)'),
                      _previewRow('Total Repayment', 'KSh ${NumberFormat('#,###').format(total)}'),
                      _previewRow('Monthly Deduction', 'KSh ${NumberFormat('#,###').format(monthly)}', isBold: true),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(amountController.text) ?? 0;
                  if (amt <= 0) return;

                  final db = await ref.read(databaseProvider.future);
                  final user = ref.read(currentUserProvider)!;

                  await db.financeErpDao.insertLoan(StaffLoan(
                    loan_id: const Uuid().v4(),
                    staff_id: user.id,
                    loan_amount: amt,
                    interest_rate: 5.0,
                    repayment_period: int.parse(repayment.split(' ')[0]),
                    monthly_deduction: monthly,
                    total_repayment: total,
                    remaining_balance: total,
                    status: 'Pending',
                    issue_date: DateTime.now().millisecondsSinceEpoch,
                    created_at: DateTime.now().millisecondsSinceEpoch,
                  ));

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan request submitted for review.')));
                  }
                },
                child: const Text('Submit Request'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _previewRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
