// lib/features/reception/reception_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';

class ReceptionDashboardPage extends ConsumerStatefulWidget {
  const ReceptionDashboardPage({super.key});
  @override
  ConsumerState<ReceptionDashboardPage> createState() => _ReceptionDashboardPageState();
}

class _ReceptionDashboardPageState extends ConsumerState<ReceptionDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<VisitorQueueEntry> _queue = [];
  List<Appointment> _appointments = [];
  List<BulkMessageJob> _messageJobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider.future);
    final queue = await db.operationsDao.getVisitorQueue('waiting');
    final appts = await db.operationsDao.getAllAppointments();
    final msgs = await db.operationsDao.getBulkMessageJobs();
    if (mounted) {
      setState(() {
        _queue = queue;
        _appointments = appts;
        _messageJobs = msgs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reception Hub', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF0EA5E9),
          indicatorColor: const Color(0xFF0EA5E9),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Queue'),
                if (_queue.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text('${_queue.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ]
              ]),
            ),
            const Tab(text: 'Appointments'),
            const Tab(text: 'Communications'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildQueueTab(),
                _buildAppointmentsTab(),
                _buildCommunicationsTab(),
              ],
            ),
    );
  }

  Widget? _buildFab() {
    if (_tab.index == 0) {
      return FloatingActionButton.extended(
        onPressed: _showAddToQueue,
        label: const Text('Add to Queue'),
        icon: const Icon(Icons.person_add_outlined),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
      );
    }
    if (_tab.index == 1) {
      return FloatingActionButton.extended(
        onPressed: _showNewAppointment,
        label: const Text('New Appointment'),
        icon: const Icon(Icons.calendar_today),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
      );
    }
    return null;
  }

  Widget _buildQueueTab() {
    if (_queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No visitors waiting.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _queue.length,
      itemBuilder: (_, i) {
        final v = _queue[i];
        final wait = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(v.arrived_at));
        final waitStr = wait.inMinutes < 60
            ? '${wait.inMinutes} min ago'
            : '${wait.inHours} hr ago';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
              child: Text('${i + 1}',
                  style: const TextStyle(
                      color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold)),
            ),
            title: Text(v.visitor_name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 Seeing: ${v.person_to_see ?? 'Not specified'}'),
                Text('Purpose: ${v.purpose} • Waiting: $waitStr',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: () => _attendVisitor(v),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Attend'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsTab() {
    if (_appointments.isEmpty) {
      return const Center(child: Text('No appointments scheduled.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (_, i) {
        final a = _appointments[i];
        final dt = DateFormat('dd MMM yyyy • h:mm a')
            .format(DateTime.fromMillisecondsSinceEpoch(a.datetime));
        final color = a.status == 'confirmed'
            ? Colors.green
            : a.status == 'cancelled'
                ? Colors.red
                : Colors.orange;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(Icons.calendar_today, color: color, size: 20),
            ),
            title: Text(a.requester_name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('With: ${a.requested_with.replaceAll('_', ' ').toUpperCase()}'),
                Text('$dt • ${a.purpose}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(a.status,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommunicationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bulk Communication Channels',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _commCard(
              'Fee Arrears SMS', 'Send fee reminder to parents with balances',
              Icons.account_balance_wallet_outlined, Colors.red, () => _sendBulk('finance')),
          _commCard(
              'Leave-Out Notices', 'Inform parents of student leave-outs',
              Icons.person_off_outlined, const Color(0xFF4F46E5), () => _sendBulk('leave_out')),
          _commCard(
              'Fleet Notices', 'Drop/pick updates & incident alerts',
              Icons.directions_bus_outlined, Colors.teal, () => _sendBulk('fleet')),
          _commCard(
              'Trip Notices', 'Trip permission & payment reminders',
              Icons.travel_explore, const Color(0xFFF59E0B), () => _sendBulk('trips')),
          const SizedBox(height: 24),
          const Text('Recent Message Jobs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_messageJobs.isEmpty)
            const Text('No messages sent yet.',
                style: TextStyle(color: Colors.grey))
          else
            ..._messageJobs.take(10).map((j) {
              final ts = j.sent_at == null
                  ? 'Queued'
                  : DateFormat('dd MMM • h:mm a')
                      .format(DateTime.fromMillisecondsSinceEpoch(j.sent_at!));
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.sms_outlined,
                      color: j.status == 'sent' ? Colors.green : Colors.orange),
                  title: Text(j.source_module,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(j.message_template, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(ts,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _commCard(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.2))),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.send_outlined, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _attendVisitor(VisitorQueueEntry v) async {
    final db = await ref.read(databaseProvider.future);
    await db.operationsDao.updateVisitorQueueStatus(
        v.id, 'attended', DateTime.now().millisecondsSinceEpoch);
    _load();
  }

  Future<void> _sendBulk(String module) async {
    final msgCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Send ${module.toUpperCase()} Message'),
        content: TextField(
          controller: msgCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Message Template',
              hintText: 'Dear parent, …'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (msgCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              final now = DateTime.now().millisecondsSinceEpoch;
              await db.operationsDao.insertBulkMessageJob(BulkMessageJob(
                id: const Uuid().v4(),
                source_module: module,
                message_template: msgCtrl.text.trim(),
                recipient_list: '[]',
                sent_at: now,
                status: 'sent',
              ));
              Navigator.pop(ctx);
              _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Message job queued for dispatch ✅')));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddToQueue() async {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final seeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Visitor to Queue'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Visitor Name')),
          const SizedBox(height: 8),
          TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Number')),
          const SizedBox(height: 8),
          TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose')),
          const SizedBox(height: 8),
          TextField(controller: seeCtrl, decoration: const InputDecoration(labelText: 'Person to See (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertVisitorQueueEntry(VisitorQueueEntry(
                id: const Uuid().v4(),
                visitor_name: nameCtrl.text.trim(),
                contact: contactCtrl.text.trim(),
                purpose: purposeCtrl.text.trim(),
                person_to_see: seeCtrl.text.isEmpty ? null : seeCtrl.text.trim(),
                arrived_at: DateTime.now().millisecondsSinceEpoch,
              ));
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewAppointment() async {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    String with_ = 'principal';
    DateTime selectedDt = DateTime.now().add(const Duration(hours: 2));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('New Appointment'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Requester Name')),
              const SizedBox(height: 8),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: with_,
                decoration: const InputDecoration(labelText: 'Meeting With'),
                items: ['principal', 'deputy', 'director']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                    .toList(),
                onChanged: (v) => setS(() => with_ = v!),
              ),
              const SizedBox(height: 8),
              TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose')),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date & Time', style: TextStyle(fontSize: 13)),
                subtitle: Text(DateFormat('dd MMM yyyy • h:mm a').format(selectedDt)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final dt = await showDateTimePicker(ctx, selectedDt);
                  if (dt != null) setS(() => selectedDt = dt);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertAppointment(Appointment(
                  id: const Uuid().v4(),
                  requested_with: with_,
                  requester_name: nameCtrl.text.trim(),
                  requester_contact: contactCtrl.text.trim(),
                  purpose: purposeCtrl.text.trim(),
                  datetime: selectedDt.millisecondsSinceEpoch,
                ));
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(BuildContext ctx, DateTime initial) async {
    final date = await showDatePicker(
        context: ctx,
        initialDate: initial,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null) return null;
    final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
