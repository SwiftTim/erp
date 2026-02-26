// lib/data/sync/export_service.dart

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../local/app_database.dart';
import '../../core/constants/app_constants.dart';

class ExportService {
  final AppDatabase db;

  ExportService(this.db);

  /// Exports assessment data for a specific grade in KNEC-ready Excel format
  Future<void> exportKnecFormat(String grade, String knecType) async {
    final excel = Excel.createExcel();
    final sheet = excel['KNEC_EXPORT'];
    excel.delete('Sheet1');

    // 1. Headers (Simplified KNEC template)
    sheet.appendRow([
      TextCellValue('UPI'),
      TextCellValue('Student Name'),
      TextCellValue('Learning Area'),
      TextCellValue('Strand'),
      TextCellValue('Sub-strand'),
      TextCellValue('Score'),
      TextCellValue('Points'),
      TextCellValue('Performance Label'),
    ]);

    // 2. Fetch all assessments for this grade
    // Note: In real app, we'd have a specific query for grade-wide assessments
    final students = await db.studentDao.findAll();
    final filteredStudents = students.where((s) => s.grade == grade).toList();

    for (final student in filteredStudents) {
      final assessments = await db.assessmentDao.findForStudent(student.id, 1, '2026');
      
      for (final a in assessments) {
        // Fetch labels from constants
        final label = AppConstants.rubricDescription[a.score] ?? 'N/A';
        
        sheet.appendRow([
          TextCellValue(student.upi),
          TextCellValue(student.fullName),
          TextCellValue('N/A'), // TODO: join with LearningArea name
          TextCellValue('N/A'), // TODO: join with Strand name
          TextCellValue('N/A'), // TODO: join with SubStrand name
          IntCellValue(a.score),
          IntCellValue(a.score), // Points based on score
          TextCellValue(label),
        ]);
      }
    }

    // 3. Save and share
    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final directory = await getTemporaryDirectory();
    final fileName = '${knecType}_Export_${grade.replaceAll(' ', '_')}_2026.xlsx';
    final file = File('${directory.path}/$fileName')
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);

    await Share.shareXFiles([XFile(file.path)], text: '$knecType Export for $grade');
  }
}
