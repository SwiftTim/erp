// lib/features/leave_out/leave_out_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

class LeaveOutPage extends ConsumerStatefulWidget {
  const LeaveOutPage({super.key});
  @override
  ConsumerState<LeaveOutPage> createState() => _LeaveOutPageState();
}

class _LeaveOutPageState extends ConsumerState<LeaveOutPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<LeaveOutRequest> _active = [];
  List<LeaveOutRequest> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider.future);
    final active = await db.operationsDao.getLeaveOutsByStatus('Active');
    final history = await db.operationsDao.getLeaveOutsByStatus('Returned');
    if (mounted) {
      setState(() {
        _active = active;
        _history = history;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Student Leave-Out',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton.icon(
            onPressed: () {
              PrintableDocumentHub.show(
                context,
                'Leave-Out',
                DocumentTemplates.getTemplatesForModule('leave_out'),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF4F46E5)),
            label: const Text('Forms / Slips', style: TextStyle(color: Color(0xFF4F46E5))),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF4F46E5),
          indicatorColor: const Color(0xFF4F46E5),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewLeaveOutDialog,
        label: const Text('New Leave-Out'),
        icon: const Icon(Icons.person_off_outlined),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildDashboard(cs),
                _buildActiveList(),
                _buildHistoryList(),
              ],
            ),
    );
  }

  Widget _buildDashboard(ColorScheme cs) {
    final serious = _active.where((r) => r.severity == 'Serious Case').length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _statCard('Currently Out', '${_active.length}',
                Icons.person_off_outlined, const Color(0xFFE44C3E)),
            const SizedBox(width: 12),
            _statCard('Serious Cases', '$serious',
                Icons.warning_amber_rounded, Colors.deepOrange),
            const SizedBox(width: 12),
            _statCard('Returned Today', '${_history.length}',
                Icons.person_outlined, Colors.green),
          ]),
          const SizedBox(height: 24),
          const Text('Notification Flow',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _flowCard('1', 'Deputy marks student for leave-out',
              Icons.edit_note, const Color(0xFF4F46E5)),
          _flowCard('2', 'Reason & severity logged • Notifications fan out',
              Icons.notifications_active_outlined, Colors.orange),
          _flowCard('3', 'Gate records physical exit (auto-timestamp)',
              Icons.door_front_door_outlined, Colors.teal),
          _flowCard('4', 'Attendance auto-flips to ABSENT across all modules',
              Icons.cancel_schedule_send_outlined, Colors.red),
          _flowCard('5', 'Student returns → Gateman clicks IN → PRESENT restored',
              Icons.login_outlined, Colors.green),
          const SizedBox(height: 24),
          if (_active.isNotEmpty) ...[
            const Text('Currently Out',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ..._active.take(3).map(_buildCard),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _flowCard(String step, String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(step, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildActiveList() {
    if (_active.isEmpty) {
      return const Center(child: Text('No students currently out.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _active.length,
      itemBuilder: (_, i) => _buildCard(_active[i]),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return const Center(child: Text('No leave-out history for today.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (_, i) => _buildCard(_history[i]),
    );
  }

  Widget _buildCard(LeaveOutRequest req) {
    final isSerious = req.severity == 'Serious Case';
    final time = DateFormat('h:mm a').format(
        DateTime.fromMillisecondsSinceEpoch(req.created_at));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isSerious
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isSerious
                ? Colors.red.withValues(alpha: 0.1)
                : const Color(0xFF4F46E5).withValues(alpha: 0.1),
            child: Icon(
                isSerious ? Icons.warning_amber : Icons.person_off_outlined,
                color: isSerious ? Colors.red : const Color(0xFF4F46E5),
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(req.student_name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (isSerious)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('SERIOUS',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${req.reason} • ${req.requested_by.replaceAll('_', ' ')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text('At $time',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          if (req.status == 'Active')
            TextButton(
              onPressed: () => _markReturned(req),
              child: const Text('Returned'),
            ),
        ],
      ),
    );
  }

  Future<void> _markReturned(LeaveOutRequest req) async {
    final db = await ref.read(databaseProvider.future);
    await db.operationsDao.updateLeaveOutStatus(req.id, 'Returned');
    await db.operationsDao.insertLeaveOutEvent(LeaveOutEvent(
      leave_out_id: req.id,
      event_type: 'ENTRY',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      recorded_by: ref.read(currentUserProvider)?.id ?? 'gate',
    ));
    _load();
  }

  Future<void> _showNewLeaveOutDialog() async {
    final studentCtrl = TextEditingController();
    String reason = 'Medical';
    String requestedBy = 'parent_call';
    String severity = 'Normal';
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('New Leave-Out Request',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: studentCtrl,
                decoration: const InputDecoration(
                    labelText: 'Student Name', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: ['Medical', 'Family', 'Appointment', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setS(() => reason = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: requestedBy,
                decoration: const InputDecoration(labelText: 'Requested By'),
                items: [
                  const DropdownMenuItem(
                      value: 'parent_call', child: Text('Parent Call')),
                  const DropdownMenuItem(
                      value: 'teacher', child: Text('Teacher')),
                  const DropdownMenuItem(value: 'self', child: Text('Self')),
                ],
                onChanged: (v) => setS(() => requestedBy = v!),
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Severity: '),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Normal'),
                  selected: severity == 'Normal',
                  onSelected: (_) => setS(() => severity = 'Normal'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Serious Case'),
                  selected: severity == 'Serious Case',
                  selectedColor: Colors.red.withValues(alpha: 0.2),
                  onSelected: (_) => setS(() => severity = 'Serious Case'),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (studentCtrl.text.trim().isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final user = ref.read(currentUserProvider);
                await db.operationsDao.insertLeaveOut(LeaveOutRequest(
                  id: const Uuid().v4(),
                  student_id: const Uuid().v4(),
                  student_name: studentCtrl.text.trim(),
                  reason: reason,
                  reason_notes: notesCtrl.text.trim(),
                  requested_by: requestedBy,
                  severity: severity,
                  created_by: user?.name ?? 'Deputy',
                  created_at: DateTime.now().millisecondsSinceEpoch,
                ));
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
