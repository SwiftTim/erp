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
  ConsumerState<StaffLoanRequestPage> createState() =>
      _StaffLoanRequestPageState();
}

class _StaffLoanRequestPageState extends ConsumerState<StaffLoanRequestPage> {
  List<StaffLoan> _myLoans = [];
  bool _loading = true;
  static const _products = <_LoanProduct>[
    _LoanProduct('Emergency Loan', 30000, 3, 6),
    _LoanProduct('Development Loan', 150000, 8, 24),
    _LoanProduct('Salary Advance', 80000, 0, 1),
    _LoanProduct('School Fees Loan', 50000, 5, 12),
  ];

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
          Icon(Icons.account_balance_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('You have no active or pending loans.',
              style: TextStyle(color: Colors.grey)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Loan Ref: ${loan.loan_id.substring(0, 8).toUpperCase()}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
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
                        Text(
                            'Principal: KSh ${NumberFormat('#,###').format(loan.loan_amount)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                            'Total to Pay: KSh ${NumberFormat('#,###').format(loan.total_repayment)}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            'Monthly: KSh ${NumberFormat('#,###').format(loan.monthly_deduction)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                        Text('${loan.repayment_period} Months',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Remaining: KSh ${NumberFormat('#,###').format(loan.remaining_balance)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
      case 'Approved':
        color = Colors.green;
        break;
      case 'Completed':
        color = Colors.blue;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
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

  Widget _getProgressIndicator(StaffLoan loan) {
    if (loan.status == 'Pending')
      return const Text('Awaiting Review',
          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic));
    final paid = loan.total_repayment - loan.remaining_balance;
    final percent = (paid / loan.total_repayment).clamp(0, 1).toDouble();
    return SizedBox(
      width: 100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade200,
            color: Colors.green),
      ),
    );
  }

  void _showLoanRequestForm() {
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    final guarantorNameController = TextEditingController();
    final guarantorStaffNoController = TextEditingController();
    final guarantorPhoneController = TextEditingController();
    var product = _products.first;
    var repaymentMonths = product.maxMonths;
    var startMonth = 'Next Payroll';
    double monthly = 0;
    double total = 0;
    final user = ref.read(currentUserProvider);
    final salary = _estimatedSalary(user?.id ?? '');
    final activeLoans = _myLoans
        .where((l) => l.status == 'Approved' && l.remaining_balance > 0)
        .length;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        List<String> validationMessages() {
          final amt = double.tryParse(amountController.text) ?? 0;
          final rate = product.interestRate / 100;
          total = amt + (amt * rate);
          monthly = repaymentMonths == 0 ? 0 : total / repaymentMonths;
          final messages = <String>[];
          if (amt <= 0) messages.add('Enter a valid loan amount.');
          if (amt > product.maxAmount)
            messages.add(
                '${product.name} maximum is KSh ${NumberFormat('#,###').format(product.maxAmount)}.');
          if (monthly > salary * 0.4)
            messages.add('Monthly deduction exceeds 40% of estimated salary.');
          if (total > salary * 6)
            messages
                .add('Total repayment exceeds six months of estimated salary.');
          if (activeLoans >= 2)
            messages.add('Policy allows a maximum of two active loans.');
          if (purposeController.text.trim().length < 8)
            messages.add('Add a clear purpose for the request.');
          if (guarantorNameController.text.trim().length < 3)
            messages.add('Add the guarantor full name.');
          if (guarantorStaffNoController.text.trim().length < 3)
            messages.add('Add the guarantor staff number or payroll ID.');
          final guarantorPhone =
              guarantorPhoneController.text.replaceAll(RegExp(r'\s+'), '');
          if (guarantorPhone.length < 9)
            messages.add('Add a valid guarantor phone number.');
          return messages;
        }

        final messages = validationMessages();
        final canSubmit = messages.isEmpty;

        return AlertDialog(
          title: const Text('Request Staff Loan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<_LoanProduct>(
                  value: product,
                  decoration: const InputDecoration(labelText: 'Loan Product'),
                  items: _products
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() {
                    product = v ?? product;
                    repaymentMonths = product.maxMonths;
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Requested Amount (KSh)'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: repaymentMonths,
                  decoration:
                      const InputDecoration(labelText: 'Repayment Period'),
                  items: _monthOptions(product.maxMonths)
                      .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text('$m Month${m == 1 ? '' : 's'}')))
                      .toList(),
                  onChanged: (v) => setDialogState(
                      () => repaymentMonths = v ?? repaymentMonths),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: startMonth,
                  decoration:
                      const InputDecoration(labelText: 'Preferred Start Month'),
                  items: const [
                    'Next Payroll',
                    'Following Month',
                    'After Approval'
                  ]
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => startMonth = v ?? startMonth),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeController,
                  minLines: 2,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Purpose / Comments'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: guarantorNameController,
                  decoration:
                      const InputDecoration(labelText: 'Guarantor Full Name'),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: guarantorStaffNoController,
                  decoration: const InputDecoration(
                      labelText: 'Guarantor Staff No. / Payroll ID'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: guarantorPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Guarantor Phone'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      _previewRow('Interest',
                          '${product.interestRate.toStringAsFixed(1)}% Flat'),
                      _previewRow('Total Repayment',
                          'KSh ${NumberFormat('#,###').format(total)}'),
                      _previewRow('Monthly Deduction',
                          'KSh ${NumberFormat('#,###').format(monthly)}',
                          isBold: true),
                      _previewRow('Estimated Salary After Deduction',
                          'KSh ${NumberFormat('#,###').format((salary - monthly).clamp(0, double.infinity))}'),
                      _previewRow('Start Month', startMonth),
                      _previewRow(
                          'Guarantor',
                          guarantorNameController.text.trim().isEmpty
                              ? 'Required'
                              : guarantorNameController.text.trim()),
                    ],
                  ),
                ),
                if (messages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: messages
                          .map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• $m',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.deepOrange)),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Policy: max 40% salary deduction, two active loans, guarantor required, HOD → Finance → Principal approval.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: canSubmit
                  ? () async {
                      final amt = double.tryParse(amountController.text) ?? 0;
                      final db = await ref.read(databaseProvider.future);
                      final user = ref.read(currentUserProvider)!;

                      await db.financeErpDao.insertLoan(StaffLoan(
                        loan_id: const Uuid().v4(),
                        staff_id: user.id,
                        loan_amount: amt,
                        interest_rate: product.interestRate,
                        repayment_period: repaymentMonths,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '${product.name} request submitted with guarantor ${guarantorNameController.text.trim()}.')),
                        );
                      }
                    }
                  : null,
              child: const Text('Submit Request'),
            ),
          ],
        );
      }),
    );
  }

  List<int> _monthOptions(int maxMonths) {
    final base =
        <int>[1, 3, 6, 12, 18, 24].where((m) => m <= maxMonths).toList();
    if (!base.contains(maxMonths)) base.add(maxMonths);
    return base.toSet().toList()..sort();
  }

  double _estimatedSalary(String staffId) {
    if (staffId.isEmpty) return 45000;
    return 50000.0 + (staffId.hashCode.abs() % 25 * 1000);
  }

  Widget _previewRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanProduct {
  final String name;
  final double maxAmount;
  final double interestRate;
  final int maxMonths;

  const _LoanProduct(
      this.name, this.maxAmount, this.interestRate, this.maxMonths);
}
