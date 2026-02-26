// lib/features/finance/student_ledger_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/widgets/app_shell.dart';

class StudentLedgerPage extends ConsumerWidget {
  final String studentId;
  const StudentLedgerPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Load student + transactions from DB
    return AppShell(
      title: 'Fee Ledger',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Student summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Grade: —  ·  UPI: —'),
                  Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _LedgerStat(label: 'Total Due', value: 'KES —'),
                      _LedgerStat(label: 'Total Paid', value: 'KES —'),
                      _LedgerStat(label: 'Balance', value: 'KES —'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Transaction History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          const Center(child: Text('No transactions yet.')),
        ],
      ),
    );
  }
}

class _LedgerStat extends StatelessWidget {
  final String label;
  final String value;
  const _LedgerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
