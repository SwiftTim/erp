// lib/features/finance/parent_ledger_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/student_model.dart';
import '../../data/models/finance_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'widgets/mpesa_payment_dialog.dart';
import '../../core/services/finance_pdf_service.dart';


class ParentLedgerPage extends ConsumerStatefulWidget {
  const ParentLedgerPage({super.key});

  @override
  ConsumerState<ParentLedgerPage> createState() => _ParentLedgerPageState();
}

class _ParentLedgerPageState extends ConsumerState<ParentLedgerPage> {
  List<StudentModel> _myStudents = [];
  Map<String, List<FeeTransactionModel>> _payments = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final parent = ref.read(currentUserProvider);
    if (parent == null) return;

    final db = await ref.read(databaseProvider.future);
    final kids = await db.studentDao.findByParent(parent.id);
    
    final Map<String, List<FeeTransactionModel>> paymentMap = {};
    for (final kid in kids) {
      final payments = await db.financeDao.findTransactionsForStudent(kid.id);
      paymentMap[kid.id] = payments;
    }

    if (mounted) {
      setState(() {
        _myStudents = kids;
        _payments = paymentMap;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Finance & Statements',
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _myStudents.isEmpty
            ? const Center(child: Text('No students linked to your account.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myStudents.length,
                itemBuilder: (context, i) {
                  final s = _myStudents[i];
                  final payments = _payments[s.id] ?? [];
                  final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amountPaid);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStudentHeader(s, totalPaid),
                        const Divider(height: 1),
                        _buildPaymentList(s, payments),
                      ],

                    ),
                  );
                },
              ),
    );
  }

  Widget _buildStudentHeader(StudentModel s, double totalPaid) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary,
            child: Text(s.fullName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${s.grade} • UPI: ${s.upi}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL PAID', style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
              Text('KES ${NumberFormat("#,##0").format(totalPaid)}', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => MpesaPaymentDialog(student: s),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                label: const Text('Pay Fees', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(StudentModel student, List<FeeTransactionModel> payments) {
    if (payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('No payment history found for this term.', style: TextStyle(fontStyle: FontStyle.italic))),
      );
    }

    return Column(
      children: payments.map((p) {
        final date = DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(p.transactionDate));
        return ListTile(
          dense: true,
          leading: const Icon(Icons.receipt_long_outlined, size: 20),
          title: Text(p.paymentMode, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(date),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('KES ${NumberFormat("#,##0").format(p.amountPaid)}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.download_outlined, color: Colors.blue, size: 20),
                onPressed: () {
                  FinancePdfService.generateReceipt(student, p);
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

}
