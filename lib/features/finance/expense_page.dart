// lib/features/finance/expense_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/finance_erp_models.dart';
import '../auth/auth_provider.dart';

class ExpensePage extends ConsumerStatefulWidget {
  const ExpensePage({super.key});

  @override
  ConsumerState<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends ConsumerState<ExpensePage> {
  List<ErpExpense> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final expenses = await db.financeErpDao.getAllExpenses();
    if (mounted) {
      setState(() {
        _expenses = expenses..sort((a, b) => b.date.compareTo(a.date));
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Totals for operating summary
    double totalUtilities = _calculateTotalByCategory('Electricity') + _calculateTotalByCategory('Water') + _calculateTotalByCategory('Internet') + _calculateTotalByCategory('Utility');
    double totalRepairs = _calculateTotalByCategory('Repair') + _calculateTotalByCategory('Maintenance');
    double totalFuel = _calculateTotalByCategory('Fuel') + _calculateTotalByCategory('Transport');
    double totalProcurement = _calculateTotalByCategory('Procurement') + _calculateTotalByCategory('Stationery') + _calculateTotalByCategory('Food Supplies');
    double totalEmergency = _calculateTotalByCategory('Emergency');
    double totalAll = _expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operating Expense Management'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _showChooseExpenseTypeDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Expense'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Overview Bar
                  _sectionHeader('Corporate Operating Overview'),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _expenseSummaryCard('Total Operating Cost', totalAll, Colors.red),
                        const SizedBox(width: 16),
                        _expenseSummaryCard('Utility Bills', totalUtilities, Colors.blue),
                        const SizedBox(width: 16),
                        _expenseSummaryCard('Asset Repairs', totalRepairs, Colors.orange),
                        const SizedBox(width: 16),
                        _expenseSummaryCard('Fuel & Transit', totalFuel, Colors.indigo),
                        const SizedBox(width: 16),
                        _expenseSummaryCard('Procured Supplies', totalProcurement, Colors.purple),
                        const SizedBox(width: 16),
                        _expenseSummaryCard('Emergency Funds', totalEmergency, Colors.pink),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _sectionHeader('Recent Expense Records'),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _expenses.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = _expenses[index];
                        final dateStr = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date));
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getCategoryColor(e.category).withValues(alpha: 0.1),
                            child: Icon(_getCategoryIcon(e.category), color: _getCategoryColor(e.category)),
                          ),
                          title: Text(e.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${e.description}\nPaid via: ${e.payment_method} • Appr by: ${e.approved_by}'),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('- KSh ${NumberFormat('#,###').format(e.amount)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                              Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  double _calculateTotalByCategory(String category) {
    return _expenses
        .where((e) => e.category.toLowerCase().contains(category.toLowerCase()))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _expenseSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withValues(alpha: 0.15))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              'KSh ${NumberFormat('#,###').format(value)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('fuel')) return Colors.indigo;
    if (c.contains('repair') || c.contains('maintenance')) return Colors.orange;
    if (c.contains('utility') || c.contains('electricity') || c.contains('water') || c.contains('internet')) return Colors.blue;
    if (c.contains('emergency')) return Colors.pink;
    if (c.contains('procure') || c.contains('stationery') || c.contains('food')) return Colors.purple;
    return Colors.red;
  }

  IconData _getCategoryIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('fuel')) return Icons.local_gas_station_outlined;
    if (c.contains('repair') || c.contains('maintenance')) return Icons.build_circle_outlined;
    if (c.contains('utility') || c.contains('electricity') || c.contains('water') || c.contains('internet')) return Icons.bolt_outlined;
    if (c.contains('emergency')) return Icons.report_problem_outlined;
    if (c.contains('procure') || c.contains('stationery') || c.contains('food')) return Icons.shopping_bag_outlined;
    return Icons.outbox_outlined;
  }

  void _showChooseExpenseTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Expense Type'),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              _expenseTypeOption(Icons.bolt, 'Utility Bill', 'Electricity, Water, Internet, Telephony'),
              _expenseTypeOption(Icons.local_gas_station, 'Fuel Expense', 'Vehicle Refuel, Generator Diesel'),
              _expenseTypeOption(Icons.build, 'Repair & Maintenance', 'Asset Repair, Garage, Structural Repairs'),
              _expenseTypeOption(Icons.warning, 'Emergency Expense', 'Unforeseen urgent financial contingencies'),
              _expenseTypeOption(Icons.shopping_cart, 'General/Miscellaneous', 'Food Supplies, Welfare, Stationery'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _expenseTypeOption(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      onTap: () {
        Navigator.pop(context);
        if (title == 'Utility Bill') {
          _showUtilityBillForm();
        } else if (title == 'Fuel Expense') {
          _showFuelForm();
        } else if (title == 'Repair & Maintenance') {
          _showRepairForm();
        } else if (title == 'Emergency Expense') {
          _showEmergencyForm();
        } else {
          _showGeneralForm();
        }
      },
    );
  }

  // Forms
  void _showUtilityBillForm() {
    String utilityType = 'Electricity';
    final providerC = TextEditingController();
    final billingMonthC = TextEditingController(text: 'March 2026');
    final invoiceNoC = TextEditingController();
    final amountC = TextEditingController();
    final remarksC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Utility Bill Expense'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: utilityType,
                    decoration: const InputDecoration(labelText: 'Utility Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Electricity', child: Text('Electricity (Kenya Power)')),
                      DropdownMenuItem(value: 'Water', child: Text('Water (Nairobi Water Company)')),
                      DropdownMenuItem(value: 'Internet', child: Text('Internet/WIFI (Safaricom Fiber)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => utilityType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: providerC, decoration: const InputDecoration(labelText: 'Provider Name', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: billingMonthC, decoration: const InputDecoration(labelText: 'Billing Period / Month', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: invoiceNoC, decoration: const InputDecoration(labelText: 'Invoice Number', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: amountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (KSh)', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: remarksC, decoration: const InputDecoration(labelText: 'Remarks / Comments', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  _fileUploadPlaceholder(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => _saveCustomExpense(
                category: utilityType,
                amount: double.parse(amountC.text),
                description: 'Bill No: ${invoiceNoC.text} from ${providerC.text} for ${billingMonthC.text}',
              ),
              child: const Text('Save Expense'),
            )
          ],
        ),
      ),
    );
  }

  void _showFuelForm() {
    String vehicle = 'School Bus (62 Seater)';
    final driverC = TextEditingController();
    final litresC = TextEditingController();
    final costPerLitreC = TextEditingController(text: '168.50');
    final stationC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double litres = double.tryParse(litresC.text) ?? 0.0;
          double cost = double.tryParse(costPerLitreC.text) ?? 0.0;
          double calcTotal = litres * cost;

          return AlertDialog(
            title: const Text('Record Fuel Voucher'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: vehicle,
                      decoration: const InputDecoration(labelText: 'Select Vehicle', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'School Bus (62 Seater)', child: Text('School Bus (62 Seater)')),
                        DropdownMenuItem(value: 'Principal Double Cabin', child: Text('Principal Double Cabin KDM 001')),
                        DropdownMenuItem(value: 'School Generator', child: Text('Emergency Generator')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => vehicle = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: driverC, decoration: const InputDecoration(labelText: 'Driver / Operator Name', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(
                      controller: litresC, 
                      keyboardType: TextInputType.number, 
                      decoration: const InputDecoration(labelText: 'Fuel in Litres', border: OutlineInputBorder()),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: costPerLitreC, 
                      keyboardType: TextInputType.number, 
                      decoration: const InputDecoration(labelText: 'Cost Per Litre (KSh)', border: OutlineInputBorder()),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: stationC, decoration: const InputDecoration(labelText: 'Petrol Station Name', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Calculated Cost:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('KSh ${NumberFormat('#,###').format(calcTotal)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fileUploadPlaceholder(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => _saveCustomExpense(
                  category: 'Fuel',
                  amount: calcTotal,
                  description: 'Voucher for vehicle $vehicle driven by ${driverC.text} at ${stationC.text}',
                ),
                child: const Text('Save Expense'),
              )
            ],
          );
        },
      ),
    );
  }

  void _showRepairForm() {
    String asset = 'School Bus (62 Seater)';
    final reportedByC = TextEditingController();
    final problemC = TextEditingController();
    final technicianC = TextEditingController();
    final estimatedC = TextEditingController();
    final actualC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Repair / Maintenance'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: asset,
                  decoration: const InputDecoration(labelText: 'Select Corporate Asset', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'School Bus (62 Seater)', child: Text('School Bus (62 Seater)')),
                    DropdownMenuItem(value: 'Computer Lab Desktops', child: Text('Computer Lab PCs')),
                    DropdownMenuItem(value: 'Dining Hall Cooker', child: Text('Dining Hall Cooker')),
                  ],
                  onChanged: (val) {
                    if (val != null) asset = val;
                  },
                ),
                const SizedBox(height: 16),
                TextField(controller: reportedByC, decoration: const InputDecoration(labelText: 'Reported By', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: problemC, decoration: const InputDecoration(labelText: 'Problem Description', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: technicianC, decoration: const InputDecoration(labelText: 'Garage / Technician Name', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: estimatedC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estimated Cost (KSh)', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: actualC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual Final Cost (KSh)', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                _fileUploadPlaceholder(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _saveCustomExpense(
              category: 'Repair & Maintenance',
              amount: double.parse(actualC.text),
              description: 'Maintenance on $asset: ${problemC.text} by ${technicianC.text}',
            ),
            child: const Text('Save Expense'),
          )
        ],
      ),
    );
  }

  void _showEmergencyForm() {
    final reasonC = TextEditingController();
    final amountC = TextEditingController();
    final approvedByC = TextEditingController(text: 'Director Sarah');
    final descC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Emergency Expense'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: reasonC, decoration: const InputDecoration(labelText: 'Urgent Reason', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: amountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Disbursement Amount (KSh)', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: approvedByC, decoration: const InputDecoration(labelText: 'Authorizing Director', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: descC, decoration: const InputDecoration(labelText: 'Detailed Explanation', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                _fileUploadPlaceholder(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _saveCustomExpense(
              category: 'Emergency',
              amount: double.parse(amountC.text),
              description: 'Emergency: ${reasonC.text} authorized by ${approvedByC.text}',
            ),
            child: const Text('Save Expense'),
          )
        ],
      ),
    );
  }

  void _showGeneralForm() {
    final catC = TextEditingController();
    final amountC = TextEditingController();
    final descC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Operating Expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: catC, decoration: const InputDecoration(labelText: 'Expense Category (e.g. Stationery)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: amountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (KSh)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: descC, decoration: const InputDecoration(labelText: 'Expense Description', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _saveCustomExpense(
              category: catC.text.trim().isNotEmpty ? catC.text.trim() : 'Miscellaneous',
              amount: double.parse(amountC.text),
              description: descC.text,
            ),
            child: const Text('Save Expense'),
          )
        ],
      ),
    );
  }

  Widget _fileUploadPlaceholder() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating receipt upload...')));
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none), color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, color: Colors.grey),
            SizedBox(width: 8),
            Text('Attach Invoice/Receipt Copy', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCustomExpense({required String category, required double amount, required String description}) async {
    final db = await ref.read(databaseProvider.future);
    
    await db.financeErpDao.insertExpense(ErpExpense(
      expense_id: const Uuid().v4(),
      category: category,
      description: description,
      amount: amount,
      payment_method: 'Cash/EFT Transfer',
      date: DateTime.now().millisecondsSinceEpoch,
      approved_by: 'Authorized Accountant',
    ));

    Navigator.pop(context);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$category expense recorded!')));
    }
  }
}
