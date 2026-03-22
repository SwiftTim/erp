import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../../data/models/student_model.dart';
import '../auth/auth_provider.dart';

class StudentBillingPage extends ConsumerStatefulWidget {
  const StudentBillingPage({super.key});

  @override
  ConsumerState<StudentBillingPage> createState() => _StudentBillingPageState();
}

class _StudentBillingPageState extends ConsumerState<StudentBillingPage> {
  List<Map<String, dynamic>> _allBillings = [];
  List<Map<String, dynamic>> _filteredBillings = [];
  bool _loading = true;
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
    final billings = await db.financeErpDao.getAllBillings();
    final students = await db.studentDao.findAll();
    
    final studentMap = {for (var s in students) s.id: s};

    final List<Map<String, dynamic>> data = [];
    for (var b in billings) {
      final s = studentMap[b.student_id];
      data.add({
        'billing': b,
        'student': s,
      });
    }

    if (mounted) {
      setState(() {
        _allBillings = data;
        _filteredBillings = data;
        _loading = false;
      });
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBillings = _allBillings.where((item) {
        final StudentModel? s = item['student'] as StudentModel?;
        return s?.fullName.toLowerCase().contains(query) ?? false;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Billing & Fees'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name...',
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
                : _filteredBillings.isEmpty
                    ? const Center(child: Text('No matching billing records found.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.blue.withValues(alpha: 0.05)),
                            columns: const [
                              DataColumn(label: Text('Student Name')),
                              DataColumn(label: Text('Grade')),
                              DataColumn(label: Text('Total (KES)')),
                              DataColumn(label: Text('Balance')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _filteredBillings.map((item) {
                              final StudentBilling b = item['billing'] as StudentBilling;
                              final StudentModel? s = item['student'] as StudentModel?;
                              final statusColor = b.status == 'Cleared' 
                                  ? Colors.green 
                                  : b.status == 'Partial' ? Colors.orange : Colors.red;

                              return DataRow(cells: [
                                DataCell(Text(s?.fullName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(s?.grade ?? '--')),
                                DataCell(Text(b.total_amount.toStringAsFixed(0))),
                                DataCell(Text(
                                  b.balance.toStringAsFixed(0),
                                  style: TextStyle(color: b.balance > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                                )),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(b.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                )),
                                  DataCell(IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 20),
                                    onPressed: () => _showBillingDetails(b, s),
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      );
    }

    void _showBillingDetails(StudentBilling b, StudentModel? s) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Billing Breakdown: ${s?.fullName ?? 'Unknown'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _billItem('Tuition Fee', b.tuition),
              _billItem('Transport Fee', b.transport),
              _billItem('Swimming Club', b.swimming),
              _billItem('Other Charges', b.other_charges),
              const Divider(),
              _billItem('Total Billed', b.total_amount, isBold: true),
              _billItem('Current Balance', b.balance, color: b.balance > 0 ? Colors.red : Colors.green, isBold: true),
              const SizedBox(height: 12),
              Chip(
                label: Text(b.status),
                backgroundColor: (b.status == 'Cleared' ? Colors.green : b.status == 'Partial' ? Colors.orange : Colors.red).withValues(alpha: 0.1),
                labelStyle: TextStyle(color: b.status == 'Cleared' ? Colors.green : b.status == 'Partial' ? Colors.orange : Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }

    Widget _billItem(String label, double amount, {bool isBold = false, Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
            Text(amount.toStringAsFixed(2), style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
          ],
        ),
      );
    }
}
