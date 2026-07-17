// lib/features/finance/resource_procurement_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/finance_erp_models.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';

class ResourceProcurementPage extends ConsumerStatefulWidget {
  const ResourceProcurementPage({super.key});

  @override
  ConsumerState<ResourceProcurementPage> createState() => _ResourceProcurementPageState();
}

class _ResourceProcurementPageState extends ConsumerState<ResourceProcurementPage> {
  List<Map<String, dynamic>> _allRequests = [];
  bool _loading = true;
  String _selectedStatusTab = 'Pending';

  // Mock department budgets for budget validation
  final Map<String, Map<String, double>> _deptBudgets = {
    'Languages': {'annual': 450000.0, 'spent': 210000.0},
    'Mathematics': {'annual': 350000.0, 'spent': 185000.0},
    'Science': {'annual': 600000.0, 'spent': 480000.0},
    'Humanities': {'annual': 250000.0, 'spent': 260000.0},
    'Administration': {'annual': 500000.0, 'spent': 180000.0},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final requests = await db.financeErpDao.getAllResourceRequests();
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
        _allRequests = data;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredRequests() {
    return _allRequests.where((item) {
      final ResourceRequest r = item['request'];
      final status = r.status.toLowerCase();
      if (_selectedStatusTab == 'Pending') {
        return status.contains('pending') || status.contains('budgeting') || status.contains('progress');
      } else if (_selectedStatusTab == 'Approved') {
        return status.contains('approved');
      } else if (_selectedStatusTab == 'Rejected') {
        return status.contains('reject') || status.contains('decline');
      } else {
        return status.contains('purchased') || status.contains('paid') || status.contains('completed');
      }
    }).toList();
  }

  int _getCount(String tab) {
    return _allRequests.where((item) {
      final ResourceRequest r = item['request'];
      final status = r.status.toLowerCase();
      if (tab == 'Pending') return status.contains('pending') || status.contains('budgeting') || status.contains('progress');
      if (tab == 'Approved') return status.contains('approved');
      if (tab == 'Rejected') return status.contains('reject') || status.contains('decline');
      return status.contains('purchased') || status.contains('paid') || status.contains('completed');
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredRequests();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Procurement & Budget Check'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status filter tabs
                Container(
                  color: Colors.blue.withValues(alpha: 0.03),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statusFilterChip('Pending', _getCount('Pending')),
                      _statusFilterChip('Approved', _getCount('Approved')),
                      _statusFilterChip('Rejected', _getCount('Rejected')),
                      _statusFilterChip('Purchased', _getCount('Purchased')),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text('No requests with "$_selectedStatusTab" status.'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildRequestCard(filtered[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item) {
    final ResourceRequest r = item['request'];
    final UserModel? u = item['user'];
    final List<ResourceRequestItem> items = item['items'];

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(r.status).withValues(alpha: 0.1),
          child: Icon(Icons.shopping_bag_outlined, color: _getStatusColor(r.status)),
        ),
        title: Text(u?.name ?? 'Teacher Request', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${r.purpose} • Dept: ${u?.departmentId ?? 'Academic'}'),
        trailing: _buildStatusBadge(r.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Line Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                _buildItemsTable(items, r),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: KSh ${NumberFormat('#,###').format(r.total_budget)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(r.created_at)),
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Divider(height: 32),
                _buildActionButtons(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<ResourceRequestItem> items, ResourceRequest r) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade200, width: 1,
          borderRadius: BorderRadius.circular(8)),
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50),
          children: const [
            Padding(padding: EdgeInsets.all(8), child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(8), child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          ],
        ),
        ...items.map((it) => TableRow(children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(it.item_name, style: const TextStyle(fontSize: 12))),
          Padding(padding: const EdgeInsets.all(8), child: Text(it.quantity.toString(), style: const TextStyle(fontSize: 12))),
          Padding(padding: const EdgeInsets.all(8), child: Text(r.status == 'Pending Budgeting' ? '—' : 'KSh ${NumberFormat('#,###').format(it.price)}', style: const TextStyle(fontSize: 12))),
          Padding(padding: const EdgeInsets.all(8), child: Text(r.status == 'Pending Budgeting' ? '—' : 'KSh ${NumberFormat('#,###').format(it.total)}', style: const TextStyle(fontSize: 12))),
        ])),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> item) {
    final ResourceRequest r = item['request'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (r.status == 'Pending Budgeting')
          ElevatedButton.icon(
            onPressed: () => _showBudgetingFormDialog(item),
            icon: const Icon(Icons.price_change_outlined, size: 16),
            label: const Text('Set Prices'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        if (r.status == 'Pending Approval') ...[
          OutlinedButton.icon(
            onPressed: () => _runBudgetCheck(item),
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
            label: const Text('Budget Check'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
          ),
          ElevatedButton.icon(
            onPressed: () => _generatePDF(item),
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('PDF Invoice'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            onPressed: () => _submitForApproval(item),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send for Approval'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
        if (r.status == 'Approved')
          ElevatedButton.icon(
            onPressed: () => _markAsPurchased(item),
            icon: const Icon(Icons.shopping_cart_checkout_outlined, size: 16),
            label: const Text('Mark Purchased'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusFilterChip(String label, int count) {
    final isSelected = _selectedStatusTab == label;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedStatusTab = label);
      },
      selectedColor: AppTheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'Pending Approval': return Colors.blue;
      case 'Purchased': return Colors.teal;
      case 'Needs Principal Approval': return Colors.deepOrange;
      default: return Colors.orange;
    }
  }

  // ── Dialogs & Actions ────────────────────────────────────────────────────────

  void _showBudgetingFormDialog(Map<String, dynamic> item) {
    final ResourceRequest r = item['request'];
    final List<ResourceRequestItem> items = item['items'];
    final controllers = {for (var it in items) it.id!: TextEditingController()};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finance — Set Item Prices'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter unit prices to calculate total procurement budget.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: Text('${it.quantity}× ${it.item_name}', style: const TextStyle(fontWeight: FontWeight.w500))),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: controllers[it.id!],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(prefixText: 'KSh ', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              double totalBudget = 0;

              for (var it in items) {
                final price = double.tryParse(controllers[it.id!]!.text) ?? 0;
                final total = it.quantity * price;
                totalBudget += total;
                await db.financeErpDao.insertRequestItem(ResourceRequestItem(
                  id: it.id,
                  request_id: it.request_id,
                  item_name: it.item_name,
                  quantity: it.quantity,
                  price: price,
                  total: total,
                ));
              }

              await db.financeErpDao.insertResourceRequest(ResourceRequest(
                request_id: r.request_id,
                teacher_id: r.teacher_id,
                purpose: r.purpose,
                status: 'Pending Approval',
                total_budget: totalBudget,
                created_at: r.created_at,
              ));

              if (context.mounted) Navigator.pop(context);
              _loadData();
            },
            child: const Text('Save & Submit for Approval'),
          ),
        ],
      ),
    );
  }

  void _runBudgetCheck(Map<String, dynamic> item) {
    final ResourceRequest r = item['request'];
    final UserModel? u = item['user'];
    final String dept = u?.departmentId ?? 'Administration';
    final deptData = _deptBudgets[dept] ?? {'annual': 500000.0, 'spent': 200000.0};

    final double remaining = deptData['annual']! - deptData['spent']!;
    final bool fits = r.total_budget <= remaining;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(fits ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                color: fits ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text('$dept Budget Check', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _budgetRow('Annual Budget', deptData['annual']!),
            _budgetRow('Total Spent (YTD)', deptData['spent']!),
            _budgetRow('Available Balance', remaining,
                color: remaining > 0 ? Colors.green : Colors.red, bold: true),
            const Divider(height: 24),
            _budgetRow('Request Amount', r.total_budget,
                color: fits ? Colors.blue : Colors.orange, bold: true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (fits ? Colors.green : Colors.red).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fits
                    ? '✅ Budget fits. You may proceed with approval.'
                    : '⚠️ Budget exceeded! This request will be flagged for Principal approval.',
                style: TextStyle(
                    color: fits ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                    fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _budgetRow(String label, double value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text('KSh ${NumberFormat('#,###').format(value)}',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _generatePDF(Map<String, dynamic> item) async {
    final ResourceRequest r = item['request'];
    final UserModel? u = item['user'];
    final List<ResourceRequestItem> items = item['items'];

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('SCHOOL PROCUREMENT VOUCHER',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('REQ: ${r.request_id.substring(0, 8).toUpperCase()}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Teacher: ${u?.name ?? 'N/A'}'),
                      pw.Text('Department: ${u?.departmentId ?? 'Academic'}'),
                    ],
                  ),
                  pw.Text(
                    'Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(r.created_at))}',
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Purpose: ${r.purpose}'),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Item Description', 'Qty', 'Unit Price (KSh)', 'Total (KSh)'],
                data: items
                    .map((it) => [
                          it.item_name,
                          it.quantity,
                          NumberFormat('#,###').format(it.price),
                          NumberFormat('#,###').format(it.total)
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TOTAL BUDGET: KSh ${NumberFormat('#,###').format(r.total_budget)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                ),
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.Text('____________________'),
                    pw.Text('Finance Officer', style: const pw.TextStyle(fontSize: 8)),
                  ]),
                  pw.Column(children: [
                    pw.Text('____________________'),
                    pw.Text('Principal / Director', style: const pw.TextStyle(fontSize: 8)),
                  ]),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                  child: pw.Text('CBC School Management System — Auto Generated',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey))),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  Future<void> _submitForApproval(Map<String, dynamic> item) async {
    final ResourceRequest r = item['request'];
    final UserModel? u = item['user'];
    final String dept = u?.departmentId ?? 'Administration';
    final deptData = _deptBudgets[dept] ?? {'annual': 500000.0, 'spent': 200000.0};
    final double remaining = deptData['annual']! - deptData['spent']!;
    final bool fits = r.total_budget <= remaining;

    final db = await ref.read(databaseProvider.future);
    final String nextStatus = fits ? 'Pending Approval' : 'Needs Principal Approval';

    await db.financeErpDao.insertResourceRequest(ResourceRequest(
      request_id: r.request_id,
      teacher_id: r.teacher_id,
      purpose: r.purpose,
      status: nextStatus,
      total_budget: r.total_budget,
      created_at: r.created_at,
    ));

    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request escalated → $nextStatus')));
    }
  }

  Future<void> _markAsPurchased(Map<String, dynamic> item) async {
    final ResourceRequest r = item['request'];
    final db = await ref.read(databaseProvider.future);

    await db.financeErpDao.insertResourceRequest(ResourceRequest(
      request_id: r.request_id,
      teacher_id: r.teacher_id,
      purpose: r.purpose,
      status: 'Purchased',
      total_budget: r.total_budget,
      created_at: r.created_at,
    ));

    await db.financeErpDao.insertExpense(ErpExpense(
      expense_id: 'EXP_PURCH_${r.request_id}',
      category: 'Procurement',
      description: 'Resource Purchase: ${r.purpose}',
      amount: r.total_budget,
      payment_method: 'Cash/EFT',
      date: DateTime.now().millisecondsSinceEpoch,
      approved_by: 'Finance Bursar',
    ));

    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as Purchased and posted to expenses.')));
    }
  }
}
