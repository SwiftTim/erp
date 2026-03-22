// lib/features/finance/principal_approvals_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class PrincipalApprovalsPage extends ConsumerStatefulWidget {
  const PrincipalApprovalsPage({super.key});

  @override
  ConsumerState<PrincipalApprovalsPage> createState() => _PrincipalApprovalsPageState();
}

class _PrincipalApprovalsPageState extends ConsumerState<PrincipalApprovalsPage> {
  List<Map<String, dynamic>> _pendingApprovals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final requests = await db.financeErpDao.getResourceRequestsByStatus('Pending Approval');
    final users = await db.userDao.findAll();
    final userMap = {for (var u in users) u.id: u};

    final List<Map<String, dynamic>> data = [];
    for (var r in requests) {
      final items = await db.financeErpDao.getRequestItems(r.request_id);
      data.add({
        'request': r,
        'user': userMap[r.teacher_id],
        'items': items,
      });
    }

    if (mounted) {
      setState(() {
        _pendingApprovals = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Approvals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingApprovals.isEmpty
              ? const Center(child: Text('All caught up! No budgets pending approval.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _pendingApprovals.length,
                  itemBuilder: (context, index) {
                    final item = _pendingApprovals[index];
                    final ResourceRequest r = item['request'];
                    final UserModel? u = item['user'];
                    final List<ResourceRequestItem> items = item['items'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary,
                                  child: const Icon(Icons.request_quote, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(u?.name ?? 'Teacher', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(r.purpose, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Text(
                                  'KSh ${NumberFormat('#,###').format(r.total_budget)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ...items.map((it) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Text('${it.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(it.item_name),
                                      const Spacer(),
                                      Text('KSh ${NumberFormat('#,###').format(it.total)}'),
                                    ],
                                  ),
                                )),
                                const Divider(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _handleApproval(r, 'Rejected'),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Decline'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _handleApproval(r, 'Approved'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                        child: const Text('Approve Budget'),
                                      ),
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
                ),
    );
  }

  Future<void> _handleApproval(ResourceRequest r, String decision) async {
    final db = await ref.read(databaseProvider.future);
    
    await db.financeErpDao.insertResourceRequest(ResourceRequest(
      request_id: r.request_id,
      teacher_id: r.teacher_id,
      purpose: r.purpose,
      status: decision,
      total_budget: r.total_budget,
      created_at: r.created_at,
    ));

    if (decision == 'Approved') {
      // Automatically create an expense entry
      await db.financeErpDao.insertExpense(ErpExpense(
        expense_id: 'EXP_PROC_${r.request_id}',
        category: 'Procurement',
        description: 'Approved Resource Request: ${r.purpose}',
        amount: r.total_budget,
        payment_method: 'Bank/M-Pesa',
        date: DateTime.now().millisecondsSinceEpoch,
        approved_by: 'Principal (Auto)',
      ));
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $decision')));
    _loadData();
  }
}
