// lib/core/utils/pdf_generator.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> printDocument(String title, Map<String, String> data) async {
    final pdf = await generatePdfDoc(title, data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${title.replaceAll(" ", "_")}.pdf',
    );
  }

  static Future<Uint8List> generatePdfBytes(String title, Map<String, String> data) async {
    final pdf = await generatePdfDoc(title, data);
    return pdf.save();
  }

  static Future<pw.Document> generatePdfDoc(String title, Map<String, String> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // School Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SWIFT TIM ERP ACADEMY',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.Text('P.O. Box 100-30100, Eldoret, Kenya', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Email: operations@swifttim.edu.ke | Tel: +254 700 000000', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo900,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'S',
                      style: pw.TextStyle(fontSize: 28, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.grey400, height: 20),

              // Title Section
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Details block
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: pw.Column(
                  children: data.entries.map((entry) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 150,
                            child: pw.Text(
                              entry.key,
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blueGrey800),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              entry.value,
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 140,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey700),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 140,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey700),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Recipient Signature / Stamp', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Generated via SwiftTim ERP. Official Institution Document.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
