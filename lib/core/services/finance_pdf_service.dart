// lib/core/services/finance_pdf_service.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/finance_model.dart';
import '../../data/models/student_model.dart';
import 'package:intl/intl.dart';

class FinancePdfService {
  static Future<void> generateReceipt(StudentModel student, FeeTransactionModel transaction) async {
    final pdf = pw.Document();
    final df = DateFormat('dd MMM yyyy, HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(children: [
                    pw.Text('CBC SCHOOL ERP', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Official Fee Receipt', style: pw.TextStyle(fontSize: 14)),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                  ]),
                ),
                pw.SizedBox(height: 20),
                _row('Receipt No:', transaction.id.substring(0, 8).toUpperCase()),
                _row('Date:', df.format(DateTime.fromMillisecondsSinceEpoch(transaction.transactionDate))),
                pw.SizedBox(height: 10),
                _row('Student Name:', student.fullName),
                _row('UPI / ID:', student.upi),
                _row('Grade:', student.grade),
                pw.SizedBox(height: 20),
                pw.Container(
                  color: PdfColors.grey100,
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('PAYMENT AMOUNT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('KES ${transaction.amountPaid.toStringAsFixed(2)}', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                _row('Payment Mode:', transaction.paymentMode),
                _row('Reference:', transaction.referenceNo),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('This is a computer-generated receipt. No signature required.',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
