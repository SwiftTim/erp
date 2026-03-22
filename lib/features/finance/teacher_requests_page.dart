// lib/features/finance/teacher_requests_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../auth/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TeacherRequestsPage extends ConsumerStatefulWidget {
  const TeacherRequestsPage({super.key});

  @override
  ConsumerState<TeacherRequestsPage> createState() => _TeacherRequestsPageState();
}

class _TeacherRequestsPageState extends ConsumerState<TeacherRequestsPage> {
  List<ResourceRequest> _myRequests = [];
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
    final requests = await db.financeErpDao.getResourceRequestsByTeacher(user.id);
    
    if (mounted) {
      setState(() {
        _myRequests = requests..sort((a, b) => b.created_at.compareTo(a.created_at));
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Requests'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myRequests.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestForm,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No resource requests yet.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myRequests.length,
      itemBuilder: (context, index) {
        final req = _myRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: _getStatusIcon(req.status),
            title: Text(req.purpose, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Submitted on ${DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(req.created_at))}'),
            trailing: _getStatusBadge(req.status),
            children: [
              FutureBuilder<List<ResourceRequestItem>>(
                future: _getRequestItems(req.request_id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final items = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(),
                        ...items.map((it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${it.quantity}x ${it.item_name}'),
                              if (it.price > 0)
                                Text('KSh ${NumberFormat('#,###').format(it.total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                        if (req.total_budget > 0) ...[
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Budget:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('KSh ${NumberFormat('#,###').format(req.total_budget)}', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (req.status == 'Pending Budgeting')
                          const Text('Waiting for Finance to enter prices...', 
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<ResourceRequestItem>> _getRequestItems(String requestId) async {
    final db = await ref.read(databaseProvider.future);
    return db.financeErpDao.getRequestItems(requestId);
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'Approved': return const Icon(Icons.check_circle, color: Colors.green);
      case 'Rejected': return const Icon(Icons.cancel, color: Colors.red);
      case 'Pending Approval': return const Icon(Icons.pending, color: Colors.blue);
      default: return const Icon(Icons.hourglass_empty, color: Colors.orange);
    }
  }

  Widget _getStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Approved': color = Colors.green; break;
      case 'Rejected': color = Colors.red; break;
      case 'Pending Approval': color = Colors.blue; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showRequestForm() {
    final purposeController = TextEditingController();
    final List<Map<String, dynamic>> items = [{'name': TextEditingController(), 'qty': TextEditingController()}];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Resource Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: purposeController,
                  decoration: const InputDecoration(labelText: 'Purpose / Description', hintText: 'e.g. For Form 1 class assignments'),
                ),
                const SizedBox(height: 20),
                const Text('Items Needed', style: TextStyle(fontWeight: FontWeight.bold)),
                ...items.asMap().entries.map((entry) {
                   int idx = entry.key;
                   var controllers = entry.value;
                   return Padding(
                     padding: const EdgeInsets.only(top: 8),
                     child: Row(
                       children: [
                         Expanded(flex: 3, child: TextField(controller: controllers['name'], decoration: const InputDecoration(hintText: 'Item Name (e.g. Markers)'))),
                         const SizedBox(width: 8),
                         Expanded(flex: 1, child: TextField(controller: controllers['qty'], decoration: const InputDecoration(hintText: 'Qty'), keyboardType: TextInputType.number)),
                         IconButton(onPressed: () => setDialogState(() => items.removeAt(idx)), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                       ],
                     ),
                   );
                }),
                TextButton.icon(
                  onPressed: () => setDialogState(() => items.add({'name': TextEditingController(), 'qty': TextEditingController()})),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (purposeController.text.isEmpty || items.any((i) => i['name'].text.isEmpty)) return;
                
                final requestId = const Uuid().v4();
                final db = await ref.read(databaseProvider.future);
                final user = ref.read(currentUserProvider)!;

                await db.financeErpDao.insertResourceRequest(ResourceRequest(
                  request_id: requestId,
                  teacher_id: user.id,
                  purpose: purposeController.text,
                  status: 'Pending Budgeting',
                  total_budget: 0,
                  created_at: DateTime.now().millisecondsSinceEpoch,
                ));

                for (var item in items) {
                  await db.financeErpDao.insertRequestItem(ResourceRequestItem(
                    request_id: requestId,
                    item_name: item['name'].text,
                    quantity: int.tryParse(item['qty'].text) ?? 1,
                    price: 0,
                    total: 0,
                  ));
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent to Finance.')));
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
