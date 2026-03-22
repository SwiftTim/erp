// lib/features/finance/payroll_batch_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../auth/auth_provider.dart';
import 'package:intl/intl.dart';

class PayrollBatchPage extends ConsumerStatefulWidget {
  const PayrollBatchPage({super.key});

  @override
  ConsumerState<PayrollBatchPage> createState() => _PayrollBatchPageState();
}

class _PayrollBatchPageState extends ConsumerState<PayrollBatchPage> {
  List<PayrollEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final entries = await db.financeErpDao.getAllPayrollEntries();
    
    if (mounted) {
      setState(() {
        _entries = entries..sort((a, b) => b.posting_date.compareTo(a.posting_date));
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Payroll Management')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewBatchDialog,
        icon: const Icon(Icons.playlist_add_check),
        label: const Text('New Payroll Entry'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No batch payroll entries found.', style: TextStyle(color: Colors.grey)),
          const Text('Create a new entry to process salaries at once.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final e = _entries[index];
        final isDraft = e.status == 'Draft';
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: isDraft ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
              child: Icon(isDraft ? Icons.edit_note : Icons.check_circle_outline, color: isDraft ? Colors.orange : Colors.green),
            ),
            title: Text(e.month, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Structure: ${e.structure_id}'),
            trailing: _getStatusBadge(e.status),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('Posting Date', DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.posting_date))),
                    _infoRow('Staff Count', '${e.count_processed} Staff members'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (isDraft)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                              child: const Text('Submit Payroll'),
                            ),
                          )
                        else
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                              label: const Text('Batch Payslips'),
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    final color = status == 'Draft' ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showNewBatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Payroll Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Processing batch payroll will generate salary slips for all staff assigned to a specific structure.'),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Salary Structure'),
              items: const [
                DropdownMenuItem(value: 'STR_TEACH', child: Text('Teaching Staff')),
                DropdownMenuItem(value: 'STR_ADMIN', child: Text('Admin Staff')),
              ],
              onChanged: (v) {},
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Month'),
              items: const [
                DropdownMenuItem(value: 'April 2026', child: Text('April 2026')),
                DropdownMenuItem(value: 'May 2026', child: Text('May 2026')),
              ],
              onChanged: (v) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text('Create Batch'),
          ),
        ],
      ),
    );
  }
}
