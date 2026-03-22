// lib/features/finance/resource_procurement_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResourceProcurementPage extends ConsumerStatefulWidget {
  const ResourceProcurementPage({super.key});

  @override
  ConsumerState<ResourceProcurementPage> createState() => _ResourceProcurementPageState();
}

class _ResourceProcurementPageState extends ConsumerState<ResourceProcurementPage> {
  List<Map<String, dynamic>> _allRequests = [];
  bool _loading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procurement Tracking'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allRequests.isEmpty
              ? const Center(child: Text('No procurement requests in the system.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allRequests.length,
                  itemBuilder: (context, index) {
                    final item = _allRequests[index];
                    final ResourceRequest r = item['request'];
                    final UserModel? u = item['user'];
                    final List<ResourceRequestItem> items = item['items'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u?.name ?? 'Unknown Teacher', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(r.purpose, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                                _getStatusBadge(r.status),
                              ],
                            ),
                            const Divider(height: 24),
                            ...items.map((it) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text('${it.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(it.item_name),
                                  const Spacer(),
                                  if (r.status != 'Pending Budgeting')
                                    Text('KSh ${NumberFormat('#,###').format(it.total)}'),
                                ],
                              ),
                            )),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Date: ${DateFormat('dd MMM').format(DateTime.fromMillisecondsSinceEpoch(r.created_at))}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (r.status == 'Pending Budgeting')
                                  ElevatedButton.icon(
                                    onPressed: () => _showBudgetingDialog(item),
                                    icon: const Icon(Icons.attach_money, size: 16),
                                    label: const Text('Set Prices'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                  )
                                else if (r.status == 'Pending Approval')
                                  Row(
                                    children: [
                                      Text('Budget: KSh ${NumberFormat('#,###').format(r.total_budget)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      IconButton(onPressed: () => _generatePDF(item), icon: const Icon(Icons.picture_as_pdf, color: Colors.blueGrey)),
                                    ],
                                  )
                                else
                                  Text('Total: KSh ${NumberFormat('#,###').format(r.total_budget)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
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

  void _showBudgetingDialog(Map<String, dynamic> item) {
    final ResourceRequest r = item['request'];
    final List<ResourceRequestItem> items = item['items'];
    final controllers = {for (var it in items) it.id!: TextEditingController()};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Budget Resource Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter unit prices for each item requested.'),
              const SizedBox(height: 16),
              ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: Text('${it.quantity}x ${it.item_name}')),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: controllers[it.id!],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(prefixText: 'KSh ', isDense: true),
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

              if (context.mounted) {
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Submit for Approval'),
          ),
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
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('SCHOOL PROCUREMENT REQUEST', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18))),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('REQUEST ID: ${r.request_id.substring(0,8).toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('TEACHER: ${u?.name ?? 'N/A'}'),
                      pw.Text('DEPARTMENT: ${u?.departmentId ?? 'Academic'}'),
                    ],
                  ),
                  pw.Text('DATE: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(r.created_at))}'),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text('PURPOSE: ${r.purpose}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Item Description', 'Qty', 'Unit Price', 'Total'],
                data: items.map((it) => [it.item_name, it.quantity, NumberFormat('#,000').format(it.price), NumberFormat('#,000').format(it.total)]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL BUDGET: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text('KSh ${NumberFormat('#,###').format(r.total_budget)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.green900)),
                ],
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [pw.Text('____________________'), pw.Text('Finance Sign', style: const pw.TextStyle(fontSize: 8))]),
                  pw.Column(children: [pw.Text('____________________'), pw.Text('Principal Sign', style: const pw.TextStyle(fontSize: 8))]),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }
}
