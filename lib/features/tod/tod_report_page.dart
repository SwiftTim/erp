import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/tod_model.dart';
import '../../data/models/student_model.dart';
import '../dashboard/widgets/app_shell.dart';
import '../auth/auth_provider.dart';
import 'tod_provider.dart';

class TodReportPage extends ConsumerStatefulWidget {
  const TodReportPage({super.key});

  @override
  ConsumerState<TodReportPage> createState() => _TodReportPageState();
}

class _TodReportPageState extends ConsumerState<TodReportPage> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _reportData;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(todServiceProvider);
      final data = await service.compileDailyReport(_selectedDate);
      setState(() => _reportData = data);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'TOD Daily Report',
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2025),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
              _generateReport();
            }
          },
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null || (_reportData!['records'] as List).isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No cases recorded on ${DateFormat('MMM d, yyyy').format(_selectedDate)}'),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    const Text('Detailed Incidents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    ...(_reportData!['records'] as List<TodRecordModel>).map((r) => _IncidentTile(record: r)),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted to Deputy Dashboard')));
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Submit Final Report'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _reportData!['totalCases'];
    return Card(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Daily Summary', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text('$total', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
            const Text('Total Incidents', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            Text(DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _IncidentTile extends ConsumerWidget {
  final TodRecordModel record;
  const _IncidentTile({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<StudentModel?>(
      future: _getStudent(ref, record.studentId),
      builder: (context, snapshot) {
        final student = snapshot.data;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(student?.fullName ?? 'Loading...'),
            subtitle: Text('${record.offence} → ${record.punishment}'),
            trailing: const Icon(Icons.chevron_right),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Future<StudentModel?> _getStudent(WidgetRef ref, String id) async {
    final db = await ref.read(databaseProvider.future);
    return db.studentDao.findById(id);
  }
}
