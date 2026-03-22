import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/services/kenyan_tax_service.dart';
import 'package:uuid/uuid.dart';

class PayrollPage extends ConsumerStatefulWidget {
  const PayrollPage({super.key});

  @override
  ConsumerState<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends ConsumerState<PayrollPage> {
  List<Map<String, dynamic>> _allPayroll = [];
  List<Map<String, dynamic>> _filteredPayroll = [];
  bool _loading = true;
  String _selectedMonth = 'March 2026';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final payrolls = await db.financeErpDao.getAllPayrolls();
    final users = await db.userDao.findAll();
    final staffs = await db.financeErpDao.getAllStaff();
    
    final userMap = {for (var u in users) u.id: u};
    final staffMap = {for (var s in staffs) s.staff_id: s};

    final List<Map<String, dynamic>> data = [];
    for (var p in payrolls) {
      final u = userMap[p.staff_id];
      final s = staffMap[p.staff_id];
      data.add({
        'payroll': p,
        'user': u,
        'staff': s,
      });
    }

    if (mounted) {
      setState(() {
        _allPayroll = data;
        _filterByMonth();
        _loading = false;
      });
    }
  }

  void _filterByMonth() {
    _filterData();
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPayroll = _allPayroll.where((item) {
        final Payroll p = item['payroll'] as Payroll;
        final UserModel? u = item['user'] as UserModel?;
        bool matchesMonth = p.month == _selectedMonth;
        bool matchesSearch = u?.name.toLowerCase().contains(query) ?? false;
        return matchesMonth && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Payroll & Statutory Deductions'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _showProcessPayrollDialog,
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
            label: const Text('Run Payroll'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.withValues(alpha: 0.05),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search staff members...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedMonth,
                  items: ['January 2026', 'February 2026', 'March 2026', 'April 2026']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedMonth = v!;
                      _filterByMonth();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayroll.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.money_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('No payroll processed for $_selectedMonth.'),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStatutorySummary(),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.green.withValues(alpha: 0.05)),
                                columns: const [
                                  DataColumn(label: Text('Staff Member')),
                                  DataColumn(label: Text('Month')),
                                  DataColumn(label: Text('Gross (KES)')),
                                  DataColumn(label: Text('PAYE')),
                                  DataColumn(label: Text('SHIF/NSSF/AHL')),
                                  DataColumn(label: Text('Net Pay')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _filteredPayroll.map((item) {
                                  final Payroll p = item['payroll'] as Payroll;
                                  final UserModel? u = item['user'] as UserModel?;

                                  return DataRow(cells: [
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(u?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(p.processed_by, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    )),
                                    DataCell(Text(p.month)),
                                    DataCell(Text((p.basic_salary + p.allowances).toStringAsFixed(0))),
                                    DataCell(Text(p.paye.toStringAsFixed(0), style: const TextStyle(color: Colors.red))),
                                    DataCell(Text(
                                      (p.nssf + p.shif + p.housing_levy).toStringAsFixed(0),
                                      style: const TextStyle(color: Colors.orange),
                                    )),
                                    DataCell(Text(
                                      p.net_salary.toStringAsFixed(0),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                    )),
                                    DataCell(Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(p.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _getStatusColor(p.status).withValues(alpha: 0.3)),
                                      ),
                                      child: Text(p.status, style: TextStyle(color: _getStatusColor(p.status), fontSize: 10, fontWeight: FontWeight.bold)),
                                    )),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                          onPressed: () => _showEditPayrollDialog(item),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            p.status == 'Draft' ? Icons.check_circle_outline : (p.status == 'Approved' ? Icons.currency_exchange : Icons.verified_outlined), 
                                            color: _getStatusColor(p.status), 
                                            size: 20
                                          ),
                                          onPressed: p.status == 'Paid' ? null : () => _showStatusActionDialog(item),
                                          tooltip: p.status == 'Draft' ? 'Approve' : 'Mark as Paid',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.picture_as_pdf, color: Colors.blueGrey, size: 20),
                                          onPressed: () => _exportPayslip(item),
                                        ),
                                      ],
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutorySummary() {
    double totalGross = 0;
    double totalPaye = 0;
    double totalLevy = 0;
    double totalShif = 0;

    for (var item in _filteredPayroll) {
      final p = item['payroll'] as Payroll;
      totalGross += (p.basic_salary + p.allowances);
      totalPaye += p.paye;
      totalLevy += p.housing_levy;
      totalShif += p.shif;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.withValues(alpha: 0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Gross Total', totalGross),
            _statItem('PAYE Total', totalPaye, color: Colors.red),
            _statItem('Housing Levy', totalLevy, color: Colors.orange),
            _statItem('SHIF Total', totalShif, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, double value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(NumberFormat('#,###').format(value), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _showProcessPayrollDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Run Payroll for $_selectedMonth'),
        content: const Text('This will calculate NSSF, SHIF, Housing Levy, and PAYE for all registered staff members based on current Kenyan tax laws.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _runPayrollLogic();
            },
            child: const Text('Confirm & Process'),
          ),
        ],
      ),
    );
  }

  Future<void> _runPayrollLogic() async {
    setState(() => _loading = true);
    final db = await ref.read(databaseProvider.future);
    final users = await db.userDao.findAll();
    final staffUsers = users.where((u) => u.roleLevel != AppConstants.roleParent && u.roleLevel != AppConstants.roleStudent).toList();

    for (var user in staffUsers) {
      // Fetch actual active loans for this staff
      final activeLoans = await db.financeErpDao.getActiveLoansByStaff(user.id);
      double totalLoanDeduction = 0;
      for (var loan in activeLoans) {
        if (loan.remaining_balance > 0) {
          totalLoanDeduction += loan.monthly_deduction;
        }
      }

      // Logic from seed, but triggered manually
      final basic = 45000.0 + (user.id.hashCode % 20 * 1000); // Semi-deterministic for demo
      final allowances = 5000.0 + (user.id.hashCode % 5 * 1000);
      final taxData = KenyanTaxService.calculatePayroll(basic, allowances);
      String status = 'Draft'; // Start as draft for manual review
        
      await db.financeErpDao.insertPayroll(Payroll(
        payroll_id: '${user.id}_${_selectedMonth.replaceAll(' ', '_')}',
        staff_id: user.id,
        month: _selectedMonth,
        basic_salary: basic,
        allowances: allowances,
        deductions: taxData['paye']! + taxData['nssf']! + taxData['shif']! + taxData['housing_levy']!,
        nssf: taxData['nssf']!,
        shif: taxData['shif']!,
        housing_levy: taxData['housing_levy']!,
        paye: taxData['paye']!,
        loan_deduction: totalLoanDeduction,
        net_salary: (taxData['net']! - totalLoanDeduction),
        status: status,
        processed_by: 'Accountant Jane',
        date_processed: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payroll for $_selectedMonth processed successfully.')));
    }
  }

  void _showEditPayrollDialog(Map<String, dynamic> item) {
    final Payroll p = item['payroll'] as Payroll;
    final UserModel? u = item['user'] as UserModel?;
    final basicController = TextEditingController(text: p.basic_salary.toStringAsFixed(0));
    final allowanceController = TextEditingController(text: p.allowances.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Payroll: ${u?.name ?? 'Staff'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: basicController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Basic Salary (KES)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: allowanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Allowances (KES)'),
            ),
            const SizedBox(height: 16),
            const Text('Note: Taxes (NSSF, SHIF, PAYE, Housing Levy) will be automatically recalculated based on these values.', 
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newBasic = double.tryParse(basicController.text) ?? p.basic_salary;
              final newAllowances = double.tryParse(allowanceController.text) ?? p.allowances;
              
              final taxData = KenyanTaxService.calculatePayroll(newBasic, newAllowances);
              final db = await ref.read(databaseProvider.future);
              
              await db.financeErpDao.insertPayroll(Payroll(
                payroll_id: p.payroll_id,
                staff_id: p.staff_id,
                month: p.month,
                basic_salary: newBasic,
                allowances: newAllowances,
                deductions: taxData['paye']! + taxData['nssf']! + taxData['shif']! + taxData['housing_levy']!,
                nssf: taxData['nssf']!,
                shif: taxData['shif']!,
                housing_levy: taxData['housing_levy']!,
                paye: taxData['paye']!,
                loan_deduction: p.loan_deduction,
                net_salary: taxData['net']! - p.loan_deduction,
                processed_by: p.processed_by,
                date_processed: DateTime.now().millisecondsSinceEpoch,
              ));

              if (mounted) {
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payroll entry updated.')));
              }
            },
            child: const Text('Update & Recalculate'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.blue;
      case 'Paid': return Colors.green;
      default: return Colors.orange;
    }
  }

  void _showStatusActionDialog(Map<String, dynamic> item) {
    final Payroll p = item['payroll'] as Payroll;
    final String nextStatus = p.status == 'Draft' ? 'Approved' : 'Paid';
    final String actionText = p.status == 'Draft' ? 'Approve' : 'Mark as Paid';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText Payroll'),
        content: Text('Are you sure you want to change the status of this payroll record to "$nextStatus"? This action will be audited.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              // If marked as Paid, handle loan balance updates
              if (nextStatus == 'Paid') {
                final activeLoans = await db.financeErpDao.getActiveLoansByStaff(p.staff_id);
                for (var loan in activeLoans) {
                  if (loan.remaining_balance > 0) {
                    final newBalance = (loan.remaining_balance - loan.monthly_deduction).clamp(0.0, double.infinity);
                    
                    await db.financeErpDao.insertLoan(StaffLoan(
                      loan_id: loan.loan_id,
                      staff_id: loan.staff_id,
                      loan_amount: loan.loan_amount,
                      interest_rate: loan.interest_rate,
                      repayment_period: loan.repayment_period,
                      monthly_deduction: loan.monthly_deduction,
                      total_repayment: loan.total_repayment,
                      remaining_balance: newBalance,
                      status: newBalance <= 0 ? 'Completed' : 'Approved',
                      approved_by: loan.approved_by,
                      issue_date: loan.issue_date,
                      created_at: loan.created_at,
                    ));

                    // Record repayment
                    await db.financeErpDao.insertLoanRepayment(LoanRepayment(
                      repayment_id: const Uuid().v4(),
                      loan_id: loan.loan_id,
                      payroll_id: p.payroll_id,
                      amount: loan.monthly_deduction,
                      payment_date: DateTime.now().millisecondsSinceEpoch,
                      deducted_from_payroll: true,
                    ));
                  }
                }
              }

              await db.financeErpDao.insertPayroll(Payroll(
                payroll_id: p.payroll_id,
                staff_id: p.staff_id,
                month: p.month,
                basic_salary: p.basic_salary,
                allowances: p.allowances,
                deductions: p.deductions,
                nssf: p.nssf,
                shif: p.shif,
                housing_levy: p.housing_levy,
                paye: p.paye,
                loan_deduction: p.loan_deduction,
                net_salary: p.net_salary,
                status: nextStatus,
                processed_by: p.processed_by,
                date_processed: p.date_processed,
              ));
              if (mounted) {
                Navigator.pop(context);
                _loadData();
              }
            },
            child: Text('Confirm $actionText'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPayslip(Map<String, dynamic> item) async {
    final Payroll p = item['payroll'] as Payroll;
    final UserModel? u = item['user'] as UserModel?;
    final doc = pw.Document();
    
    final gross = p.basic_salary + p.allowances;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('SCHOOL STAFF PAYSLIP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.Center(child: pw.Text(p.month, style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 20),
              
               pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('STAFF NAME: ${u?.name ?? 'Unknown'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('STAFF ID: ${u?.id.substring(0, 8) ?? 'N/A'}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Text('DATE: ${DateTime.fromMillisecondsSinceEpoch(p.date_processed).toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1),
              
              _payslipRow('Basic Salary', p.basic_salary),
              _payslipRow('Allowances', p.allowances),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GROSS SALARY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(gross.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('DEDUCTIONS & STATUTORY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.red900)),
              _payslipRow('PAYE Tax', p.paye, isDeduction: true),
              _payslipRow('NSSF Contribution', p.nssf, isDeduction: true),
              _payslipRow('SHIF (Health Insurance)', p.shif, isDeduction: true),
              _payslipRow('Affordable Housing Levy', p.housing_levy, isDeduction: true),
              if (p.loan_deduction > 0) _payslipRow('Loan Recovery', p.loan_deduction, isDeduction: true),
              
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NET SALARY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.green900)),
                  pw.Text(p.net_salary.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.green900)),
                ],
              ),
              
              pw.SizedBox(height: 10),
              if (item['staff'] != null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('DISBURSEMENT:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${(item['staff'] as FinanceStaff).bank_name} - ${(item['staff'] as FinanceStaff).account_no}', 
                        style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),

              pw.SizedBox(height: 20),
              pw.Text('Processed by: ${p.processed_by}', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              pw.Center(child: pw.Text('This is a computer-generated payslip.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey))),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _payslipRow(String label, double amount, {bool isDeduction = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            '${isDeduction ? "-" : ""}${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 9, color: isDeduction ? PdfColors.red : PdfColors.black),
          ),
        ],
      ),
    );
  }
}
