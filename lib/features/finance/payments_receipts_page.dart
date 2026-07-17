// lib/features/finance/payments_receipts_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/finance_erp_models.dart';
import '../../data/models/student_model.dart';
import '../auth/auth_provider.dart';
import 'widgets/mpesa_payment_dialog.dart';

class PaymentsReceiptsPage extends ConsumerStatefulWidget {
  const PaymentsReceiptsPage({super.key});

  @override
  ConsumerState<PaymentsReceiptsPage> createState() => _PaymentsReceiptsPageState();
}

class _PaymentsReceiptsPageState extends ConsumerState<PaymentsReceiptsPage> {
  List<Map<String, dynamic>> _payments = [];
  List<StudentModel> _students = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPayments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterPayments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final payments = await db.financeErpDao.getAllPayments();
    final students = await db.studentDao.findAll();
    final studentMap = {for (var s in students) s.id: s};

    final List<Map<String, dynamic>> data = [];
    for (var p in payments) {
      data.add({
        'payment': p,
        'student': studentMap[p.student_id],
      });
    }

    if (mounted) {
      setState(() {
        _payments = data..sort((a, b) => (b['payment'] as ErpFeePayment).date_paid.compareTo((a['payment'] as ErpFeePayment).date_paid));
        _students = students;
        _filteredPayments = _payments;
        _loading = false;
      });
    }
  }

  void _filterPayments() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPayments = _payments.where((item) {
        final StudentModel? s = item['student'] as StudentModel?;
        final ErpFeePayment p = item['payment'] as ErpFeePayment;
        return (s?.fullName.toLowerCase().contains(query) ?? false) || 
               p.transaction_code.toLowerCase().contains(query) || 
               p.payment_method.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalCollected = _payments.fold(0.0, (sum, item) => sum + (item['payment'] as ErpFeePayment).amount_paid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Receipts'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _showReceivePaymentOption,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Receive Payment'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Total Collected KPI Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.green.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Fees Collected (Term 1)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'KSh ${NumberFormat('#,###').format(totalCollected)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green),
                    ),
                  ],
                ),
                Text('Total Payments: ${_payments.length}', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name, payment method or transaction code...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                    ? const Center(child: Text('No payments recorded matching search criteria.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredPayments.length,
                        itemBuilder: (context, index) {
                          final item = _filteredPayments[index];
                          final ErpFeePayment p = item['payment'];
                          final StudentModel? s = item['student'];
                          final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(p.date_paid));

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: p.payment_method.contains('M-Pesa') ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                child: Icon(
                                  p.payment_method.contains('M-Pesa') ? Icons.phone_android : Icons.account_balance,
                                  color: p.payment_method.contains('M-Pesa') ? Colors.green : Colors.blue,
                                ),
                              ),
                              title: Text(s?.fullName ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${p.payment_method} • Code: ${p.transaction_code}\n$dateStr'),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+ KSh ${NumberFormat('#,###').format(p.amount_paid)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('By ${p.received_by}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              onTap: () => _showReceiptDetails(p, s),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showReceiptDetails(ErpFeePayment p, StudentModel? s) {
    final dateStr = DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(p.date_paid));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fee Receipt Details', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.green, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            _receiptInfoRow('Receipt Status', 'SUCCESSFUL', valueColor: Colors.green, isBold: true),
            _receiptInfoRow('Student Name', s?.fullName ?? 'N/A'),
            _receiptInfoRow('Grade / Class', s?.grade ?? 'N/A'),
            _receiptInfoRow('Amount Paid', 'KSh ${NumberFormat('#,###').format(p.amount_paid)}', isBold: true),
            _receiptInfoRow('Payment Method', p.payment_method),
            _receiptInfoRow('Transaction Ref', p.transaction_code),
            _receiptInfoRow('Payment Date', dateStr),
            _receiptInfoRow('Issued By', p.received_by),
            const Divider(height: 32),
            const Center(
              child: Text(
                'CBC School Management System\nThis is an official finance receipt.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to printer...')));
            },
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _receiptInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black87,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showReceivePaymentOption() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Select Payment Mechanism', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: const Icon(Icons.phone_android, color: Colors.green),
                ),
                title: const Text('M-Pesa STK Push Transfer'),
                subtitle: const Text('Trigger parent verification request directly via Safaricom API'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showMpesaPicker();
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.account_balance, color: Colors.blue),
                ),
                title: const Text('Manual Cash / Bank Payment'),
                subtitle: const Text('Record bank deposits, cheques, or physical cash collections'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showManualPayForm();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMpesaPicker() {
    // Capture a stable navigator reference from the page context BEFORE
    // any dialogs are opened. This prevents the stale-context assertion.
    final pageNav = Navigator.of(context);
    StudentModel? selectedStudent;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Select Student for M-Pesa'),
        content: SizedBox(
          width: 400,
          child: Autocomplete<StudentModel>(
            displayStringForOption: (StudentModel option) => option.fullName,
            optionsBuilder: (TextEditingValue textEditingValue) {
              // Show ALL students when field is empty; filter when typing
              final query = textEditingValue.text.toLowerCase();
              if (query.isEmpty) return _students;
              return _students.where((s) =>
                  s.fullName.toLowerCase().contains(query) ||
                  (s.upi.toLowerCase().contains(query)));
            },
            onSelected: (StudentModel student) {
              selectedStudent = student;
            },
            fieldViewBuilder: (ctx, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Type or tap to see all learners',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedStudent == null) return;
              // Close the picker dialog
              Navigator.of(dialogCtx).pop();
              // Now open the payment dialog using the stable page navigator's context
              if (!mounted) return;
              final res = await showDialog<bool>(
                context: pageNav.context,
                builder: (ctx) =>
                    MpesaPaymentDialog(student: selectedStudent!),
              );
              if (res == true && mounted) {
                _loadData();
              }
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showManualPayForm() {
    StudentModel? selectedStudent;
    final amountC = TextEditingController();
    final refC = TextEditingController();
    String method = 'Bank Deposit';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manual Receipt Form'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Autocomplete<StudentModel>(
                    displayStringForOption: (StudentModel option) => option.fullName,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<StudentModel>.empty();
                      }
                      return _students.where((StudentModel student) {
                        return student.fullName.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (StudentModel student) {
                      selectedStudent = student;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Search Learner',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: const InputDecoration(labelText: 'Receipt Mode', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Bank Deposit', child: Text('Bank Deposit')),
                      DropdownMenuItem(value: 'Cheque Payment', child: Text('Cheque Payment')),
                      DropdownMenuItem(value: 'Cash Collection', child: Text('Cash Collection')),
                      DropdownMenuItem(value: 'Mobile Money', child: Text('M-Pesa (Manual)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => method = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (KSh)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: refC,
                    decoration: const InputDecoration(labelText: 'Txn Reference / slips No.', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedStudent != null && amountC.text.isNotEmpty && refC.text.isNotEmpty) {
                  final db = await ref.read(databaseProvider.future);
                  final amtVal = double.parse(amountC.text);
                  final nav = Navigator.of(context);

                  // Insert payment
                  await db.financeErpDao.insertPayment(ErpFeePayment(
                    payment_id: const Uuid().v4(),
                    student_id: selectedStudent!.id,
                    amount_paid: amtVal,
                    payment_method: method,
                    transaction_code: refC.text.trim().toUpperCase(),
                    date_paid: DateTime.now().millisecondsSinceEpoch,
                    received_by: 'Accountant Jane',
                  ));

                  // Deduct billing balance
                  StudentBilling? studentBilling = await db.financeErpDao.getBillingByStudent(selectedStudent!.id);
                  if (studentBilling == null) {
                    final allBillings = await db.financeErpDao.getAllBillings();
                    final targetId = selectedStudent!.id.trim().toLowerCase();
                    for (final b in allBillings) {
                      if (b.student_id.trim().toLowerCase() == targetId) {
                        studentBilling = b;
                        break;
                      }
                    }
                  }

                  final String billingId = studentBilling != null && studentBilling.billing_id.isNotEmpty
                      ? studentBilling.billing_id
                      : 'Bill_${selectedStudent!.id}_Term1';
                      
                  final double currentBalance = studentBilling != null
                      ? studentBilling.balance
                      : (selectedStudent!.grade.contains('7') || selectedStudent!.grade.contains('8') || selectedStudent!.grade.contains('9')
                          ? 25000.0 : 18000.0) + 5500.0;
                          
                  final double totalAmount = studentBilling != null
                      ? studentBilling.total_amount
                      : currentBalance;

                  final double newBal = (currentBalance - amtVal).clamp(0.0, double.infinity);
                  
                  await db.financeErpDao.insertBilling(StudentBilling(
                    billing_id: billingId,
                    student_id: selectedStudent!.id,
                    term: studentBilling != null ? studentBilling.term : 1,
                    tuition: studentBilling != null ? studentBilling.tuition : (selectedStudent!.grade.contains('7') || selectedStudent!.grade.contains('8') || selectedStudent!.grade.contains('9') ? 25000.0 : 18000.0),
                    transport: studentBilling != null ? studentBilling.transport : 0.0,
                    meals: studentBilling != null ? studentBilling.meals : 0.0,
                    swimming: studentBilling != null ? studentBilling.swimming : 0.0,
                    other_charges: studentBilling != null ? studentBilling.other_charges : 5500.0,
                    total_amount: totalAmount,
                    balance: newBal,
                    status: newBal <= 0 ? 'Cleared' : 'Partial',
                  ));

                  nav.pop();
                  _loadData();
                }
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
