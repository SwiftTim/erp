// lib/features/reports/report_generator_page.dart
// Generates KNEC-format CBC Learner Progress Reports as PDF

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../data/sync/export_service.dart';
import '../../data/local/app_database.dart';
import '../auth/auth_provider.dart';
import '../../core/services/cbc_aggregation_service.dart';

class ReportGeneratorPage extends ConsumerStatefulWidget {
  const ReportGeneratorPage({super.key});

  @override
  ConsumerState<ReportGeneratorPage> createState() => _ReportGeneratorPageState();
}

class _ReportGeneratorPageState extends ConsumerState<ReportGeneratorPage> {
  String? _selectedGrade;
  int _selectedTerm = 1;
  bool _generating = false;

  Future<void> _generateReport() async {
    if (_selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a grade first.')));
      return;
    }
    setState(() => _generating = true);

    final pdfBytes = await _buildSampleReport(_selectedGrade!, _selectedTerm);

    setState(() => _generating = false);

    if (!mounted) return;
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }

  Future<void> _runExport(String grade, String type) async {
    final db = await ref.read(databaseProvider.future);
    final service = ExportService(db);
    try {
      await service.exportKnecFormat(grade, type);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<Uint8List> _buildSampleReport(String grade, int term) async {
    final doc = pw.Document();
    final db = await ref.read(databaseProvider.future);
    final aggregationService = CBCAggregationService(db);
    
    // 1. Fetch real students for this grade
    final allStudents = await db.studentDao.findAll();
    final gradeStudents = allStudents.where((s) => s.grade == grade).toList();

    for (final student in gradeStudents) {
      // 2. Fetch real aggregated subject scores
      final areas = await db.curriculumDao.findAreasByLevel(AppConstants.gradeBand(grade));
      final subjectScores = <String, CBCScore>{};
      
      for (final area in areas) {
        final score = await aggregationService.getSubjectScore(student.id, area.id, term, '2026');
        if (score != null) {
          subjectScores[area.name] = score;
        }
      }

      final totalPaid = await db.financeDao.totalPaid(student.id) ?? 0.0;
      final balance = 15000.0 - totalPaid; // Fixed term fee
      final isDefaulter = balance > 1000; // Allow small balance
      
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('006B3C'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('KENYA CBC LEARNER PROGRESS REPORT',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Grade: $grade  ·  Term $term  ·  Academic Year 2026',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Student details
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Student Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(student.fullName)),
                  pw.Padding(padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('UPI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(student.upi)),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Gender', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(student.gender)),
                  pw.Padding(padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Grade', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(grade)),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // Assessment scores
            pw.Text('ACADEMIC PERFORMANCE (Aggregated Subject Mastery)',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: ['Learning Area', 'Mastery', 'Remarks']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(h,
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ))
                      .toList(),
                ),
                if (subjectScores.isEmpty)
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('No assessments recorded yet.', style: const pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('N/A')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Please complete markings.', style: const pw.TextStyle(fontSize: 10))),
                  ])
                else
                  ...subjectScores.entries.map((entry) =>
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(entry.key, style: pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(isDefaulter ? '***' : entry.value.band, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: isDefaulter ? PdfColors.red : PdfColors.black))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(isDefaulter ? 'Fees Balance withheld.' : entry.value.label, style: pw.TextStyle(fontSize: 9))),
                    ])),
              ],
            ),
            pw.SizedBox(height: 20),

            // Core Competencies
            pw.Text('CORE COMPETENCIES',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 6,
              children: AppConstants.coreCompetencies.map((c) =>
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(c, style: const pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(width: 6),
                        pw.Text(isDefaulter ? '***' : 'ME', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: isDefaulter ? PdfColors.red : PdfColor.fromHex('#1565C0'))),
                    ]),
                  )).toList(),
            ),
            pw.Spacer(),

            // Signature row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Class Teacher: ________________________________'),
                  pw.SizedBox(height: 4),
                  pw.Text('Date: ________________________', style: const pw.TextStyle(fontSize: 10)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Headteacher: ________________________________'),
                  pw.SizedBox(height: 4),
                  pw.Text('Date: ________________________', style: const pw.TextStyle(fontSize: 10)),
                ]),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text('Note: This is an aggregated CBC 2026 Learner Progress Report.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ));
    }

    if (gradeStudents.isEmpty) {
      doc.addPage(pw.Page(build: (ctx) => pw.Center(child: pw.Text('No students found for $grade'))));
    }

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Report Generator',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Generate CBC Learner Progress Report',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('KNEC-format PDF report for end-of-term distribution',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _selectedGrade,
                      decoration: const InputDecoration(
                          labelText: 'Select Grade', prefixIcon: Icon(Icons.school_outlined)),
                      items: AppConstants.allGrades
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedGrade = v),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      value: _selectedTerm,
                      decoration: const InputDecoration(
                          labelText: 'Select Term', prefixIcon: Icon(Icons.calendar_month_outlined)),
                      items: [1, 2, 3]
                          .map((t) => DropdownMenuItem(value: t, child: Text('Term $t')))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTerm = v ?? 1),
                    ),
                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: _generating ? null : _generateReport,
                      icon: _generating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(_generating ? 'Generating…' : 'Generate & Print PDF'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // KNEC Export card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KNEC Data Export',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Export assessment data in KPSEA (Grade 6) or KJSEA (Grade 9) format for upload to the KNEC portal.'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                              icon: const Icon(Icons.upload_file_outlined),
                              label: const Text('KPSEA Grade 6'),
                              onPressed: () => _runExport('Grade 6', 'KPSEA')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                              icon: const Icon(Icons.upload_file_outlined),
                              label: const Text('KJSEA Grade 9'),
                              onPressed: () => _runExport('Grade 9', 'KJSEA')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
