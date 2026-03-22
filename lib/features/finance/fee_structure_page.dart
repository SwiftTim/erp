import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../../data/models/student_model.dart';
import '../auth/auth_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class FeeStructurePage extends ConsumerStatefulWidget {
  const FeeStructurePage({super.key});

  @override
  ConsumerState<FeeStructurePage> createState() => _FeeStructurePageState();
}

class _FeeStructurePageState extends ConsumerState<FeeStructurePage> {
  List<ErpFeeStructure> _fees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final fees = await db.financeErpDao.getAllFeeStructures();
    if (mounted) {
      setState(() {
        _fees = fees;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Structure Management')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Term Fee Components', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _showGenerateDesignDialog,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Design & Bulk Generate'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.blueGrey.withValues(alpha: 0.05)),
                    columns: const [
                      DataColumn(label: Text('Fee Component')),
                      DataColumn(label: Text('Term')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Amount (KES)')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _fees.map((fee) => DataRow(cells: [
                      DataCell(Text(fee.fee_name, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('Term ${fee.term}')),
                      DataCell(Text(fee.is_optional ? 'Optional' : 'Mandatory', 
                        style: TextStyle(color: fee.is_optional ? Colors.blue : Colors.orange, fontSize: 12))),
                      DataCell(Text(fee.amount.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showEditDialog(fee),
                        ),
                      ),
                    ])).toList(),
                  ),
                ],
              ),
            ),
    );
  }

  void _showEditDialog(ErpFeeStructure fee) {
    final controller = TextEditingController(text: fee.amount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${fee.fee_name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (KES)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newAmount = double.tryParse(controller.text) ?? fee.amount;
              final db = await ref.read(databaseProvider.future);
              await db.financeErpDao.insertFeeStructure(ErpFeeStructure(
                fee_id: fee.fee_id,
                fee_name: fee.fee_name,
                amount: newAmount,
                term: fee.term,
                is_optional: fee.is_optional,
              ));
              if (mounted) {
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee structure updated.')));
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showGenerateDesignDialog() {
    final remarksController = TextEditingController(text: 'We strive for academic excellence and character development. Please ensure timely fee clearance.');
    String selectedGrade = 'PP1';
    final grades = ['PP1', 'PP2', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Bulk Fee Structure Generator'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedGrade,
                  items: grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setDialogState(() => selectedGrade = v!),
                  decoration: const InputDecoration(labelText: 'Target Grade'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: remarksController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Principal\'s Remarks / Policy',
                    hintText: 'Enter specific notes for this period...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Note: This will generate a separate PDF page for every student in the selected grade.', 
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _generateBulkPdf(selectedGrade, remarksController.text);
              },
              child: const Text('Generate & Print'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateBulkPdf(String grade, String remarks) async {
    final doc = pw.Document();
    final db = await ref.read(databaseProvider.future);
    final List<StudentModel> allStudents = await db.studentDao.findAll();
    final List<StudentModel> targetStudents = allStudents.where((s) => s.grade == grade).toList();
    final fees = await db.financeErpDao.getAllFeeStructures();
    
    // Filter fees relevant to this grade if naming convention is followed
    final relevantFees = fees.where((f) => f.fee_name.contains('($grade)') || (!f.fee_name.contains('Grade') && !f.fee_name.contains('PP'))).toList();

    if (targetStudents.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No students found for $grade.')));
      }
      return;
    }

    final now = DateFormat('dd MMM yyyy').format(DateTime.now());

    for (final student in targetStudents) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SCHOOL FINANCE DEPARTMENT', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('TERM 1 FEE STRUCTURE 2026', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ],
                  ),
                  pw.Container(
                    width: 60, height: 60,
                    decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                    child: pw.Center(child: pw.Text('LOGO', style: pw.TextStyle(color: PdfColors.white, fontSize: 10))),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2, color: PdfColors.blueGrey),
              pw.SizedBox(height: 10),
              
              // Student Info
              pw.Row(
                children: [
                  pw.Expanded(child: _infoItem('STUDENT NAME', student.fullName)),
                  pw.Expanded(child: _infoItem('IDENTIFICATION (UPI)', student.upi)),
                  pw.Expanded(child: _infoItem('GRADE', student.grade)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Fee Table
              pw.Text('FEE BREAKDOWN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Component', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount (KES)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  ...relevantFees.map((f) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(f.fee_name)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(f.is_optional ? 'Optional' : 'Mandatory')),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(f.amount.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                        ],
                      )),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('TOTAL MANDATORY FEES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(
                        relevantFees.where((f) => !f.is_optional).fold<double>(0, (sum, f) => sum + f.amount).toStringAsFixed(2),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      )),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),
              
              // Principal's Remarks
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PRINCIPAL\'S REMARKS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 6),
                    pw.Text(remarks, style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
                  ],
                ),
              ),

              pw.Spacer(),
              
              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Bursar\'s Signature', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Date: $now', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('School Rubber Stamp', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Generated by CBC School Management ERP', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500))),
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _infoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
