// lib/features/finance/finance_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/widgets/app_shell.dart';
import '../dashboard/widgets/stat_card.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/payment_service.dart';
import '../../data/models/student_model.dart';
import '../../data/models/finance_model.dart';
import '../auth/auth_provider.dart';

class FinanceDashboardPage extends ConsumerStatefulWidget {
  const FinanceDashboardPage({super.key});

  @override
  ConsumerState<FinanceDashboardPage> createState() => _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends ConsumerState<FinanceDashboardPage> {
  List<StudentModel> _students = [];
  Map<String, double> _balances = {};
  Map<String, double> _paid = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    final db = await ref.read(databaseProvider.future);
    final students = await db.studentDao.findAll();
    
    Map<String, double> paidMap = {};
    Map<String, double> balancesMap = {};

    for (final s in students) {
      final totalPaid = await db.financeDao.totalPaid(s.id) ?? 0.0;
      // Fixed fee for demo purposes: 15,000 per term
      const totalRequired = 15000.0; 
      paidMap[s.id] = totalPaid;
      balancesMap[s.id] = totalRequired - totalPaid;
    }

    if (mounted) {
      setState(() {
        _students = students;
        _paid = paidMap;
        _balances = balancesMap;
        _loading = false;
      });
    }
  }

  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordPaymentSheet(students: _students, onSaved: _loadFinanceData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCollected = _paid.values.fold(0.0, (a, b) => a + b);
    final totalOutstanding = _balances.values.fold(0.0, (a, b) => a + b);

    return AppShell(
      title: 'Finance Hub',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: StatCard(label: 'Total Collected', value: 'KES ${totalCollected.toStringAsFixed(0)}', icon: Icons.payments_outlined, color: AppTheme.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(label: 'Outstanding', value: 'KES ${totalOutstanding.toStringAsFixed(0)}', icon: Icons.money_off_outlined, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Fee Ledger', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        _TableHeader(),
                        const Divider(height: 1),
                        ..._students.map((s) => _StudentFeeRow(
                          name: s.fullName,
                          grade: s.grade,
                          paid: _paid[s.id] ?? 0,
                          balance: _balances[s.id] ?? 0,
                          status: (_balances[s.id] ?? 0) <= 0 ? 'Cleared' : (_paid[s.id] ?? 0) > 0 ? 'Partial' : 'Defaulter',
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPaymentSheet,
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
    );
  }
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final List<StudentModel> students;
  final VoidCallback onSaved;
  const _RecordPaymentSheet({required this.students, required this.onSaved});

  @override
  ConsumerState<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  StudentModel? _selectedStudent;
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String _mode = 'Cash';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Record Fee Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          DropdownButtonFormField<StudentModel>(
            value: _selectedStudent,
            decoration: const InputDecoration(labelText: 'Select Student', prefixIcon: Icon(Icons.person_outline)),
            items: widget.students.map((s) => DropdownMenuItem(value: s, child: Text(s.fullName))).toList(),
            onChanged: (v) => setState(() => _selectedStudent = v),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount (KES)', prefixText: 'KES '), keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _mode,
            decoration: const InputDecoration(labelText: 'Payment Mode', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
            items: ['Cash', 'MPesa STK', 'Bank Transfer', 'Cheque'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _mode = v!),
          ),
          const SizedBox(height: 16),
          if (_mode != 'MPesa STK')
            TextFormField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Transaction Reference (Optional)')),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isProcessing ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : Text(_mode == 'MPesa STK' ? 'Initiate STK Push' : 'Confirm Receipt'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedStudent == null || _amountCtrl.text.isEmpty) return;
    setState(() => _isProcessing = true);

    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    
    if (_mode == 'MPesa STK') {
      // For demo, we use a dummy phone. In real app, we'd fetch from Student's Parent profile
      final success = await ref.read(paymentServiceProvider).initiateStkPush('254700000000', amount, _selectedStudent!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'MPesa Payment Successful!' : 'MPesa Payment Failed or Cancelled.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
      }
    } else {
      await ref.read(paymentServiceProvider).recordPayment(
        studentId: _selectedStudent!.id,
        amount: amount,
        reference: _refCtrl.text.isEmpty ? 'OFF-${Uuid().v4().substring(0,6).toUpperCase()}' : _refCtrl.text,
        mode: _mode,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded successfully.')));
    }
    
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('STUDENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey))),
          Expanded(flex: 2, child: Text('PAID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey))),
          Expanded(flex: 2, child: Text('BALANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey))),
          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey))),
        ],
      ),
    );
  }
}

class _StudentFeeRow extends StatelessWidget {
  final String name;
  final String grade;
  final double paid;
  final double balance;
  final String status;

  const _StudentFeeRow({required this.name, required this.grade, required this.paid, required this.balance, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'Cleared' ? Colors.green : status == 'Defaulter' ? Colors.red : Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(grade, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text('KES ${paid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12))),
          Expanded(flex: 2, child: Text('KES ${balance.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: balance > 0 ? Colors.red : Colors.green, fontWeight: balance > 0 ? FontWeight.bold : FontWeight.normal))),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(status, textAlign: TextAlign.center, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

