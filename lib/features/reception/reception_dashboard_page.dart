// lib/features/reception/reception_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

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

  static const _accent = Color(0xFF0EA5E9); // sky blue

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
    final user = ref.watch(currentUserProvider);
    return AppShell(
      title: 'Reception Hub',
      actions: [
        TextButton.icon(
          onPressed: () => PrintableDocumentHub.show(
            context, 'Receptionist', DocumentTemplates.getTemplatesForModule('reception')),
          icon: const Icon(Icons.print_outlined, size: 18, color: _accent),
          label: const Text('Forms', style: TextStyle(color: _accent)),
        ),
      ],
      floatingActionButton: _buildFab(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildWelcomeCard(user),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildTabSection(),
                ]),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          Text(user?.name ?? 'Receptionist',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(children: [
            _miniStat('Visitor Queue', '${_queue.length}'),
            const SizedBox(width: 32),
            _miniStat('Appointments', '${_appointments.length}'),
            const SizedBox(width: 32),
            _miniStat('Total Messages', '${_messageJobs.length}'),
          ]),
        ]),
        Positioned(right: 0, top: 0,
          child: Icon(Icons.desk_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1))),
      ]),
    );
  }

  Widget _miniStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
    ],
  );

  Widget _buildStatsGrid() {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
      children: [
        _statCard('Visitor Queue', '${_queue.length}', Icons.people_outline, _accent),
        _statCard('Appointments', '${_appointments.length}', Icons.calendar_today_outlined, Colors.purple),
        _statCard('Messages Dispatched', '${_messageJobs.length}', Icons.sms_outlined, Colors.green),
        _statCard('Today\'s Date', DateFormat('d MMM').format(DateTime.now()), Icons.today_outlined, Colors.blue),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildTabSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Front Desk Operations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
        child: Column(children: [
          TabBar(
            controller: _tab,
            labelColor: _accent, indicatorColor: _accent,
            unselectedLabelColor: Colors.grey, dividerColor: Colors.transparent,
            tabs: [
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Queue'),
                if (_queue.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(radius: 8, backgroundColor: Colors.red,
                    child: Text('${_queue.length}', style: const TextStyle(fontSize: 10, color: Colors.white))),
                ],
              ])),
              const Tab(text: 'Appointments'),
              const Tab(text: 'Communications'),
            ],
          ),
          SizedBox(
            height: 480,
            child: TabBarView(controller: _tab, children: [
              _buildQueueTab(),
              _buildAppointmentsTab(),
              _buildCommunicationsTab(),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildQueueTab() {
    if (_queue.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('No visitors waiting.', style: TextStyle(color: Colors.grey)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _queue.length,
      itemBuilder: (_, i) {
        final v = _queue[i];
        final wait = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(v.arrived_at));
        final waitStr = wait.inMinutes < 60 ? '${wait.inMinutes} min ago' : '${wait.inHours} hr ago';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _accent.withValues(alpha: 0.1),
              child: Text('${i + 1}', style: const TextStyle(color: _accent, fontWeight: FontWeight.bold)),
            ),
            title: Text(v.visitor_name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('📍 Seeing: ${v.person_to_see ?? 'Not specified'}'),
              Text('Purpose: ${v.purpose} • Waiting: $waitStr', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
            trailing: FilledButton(
              onPressed: () => _attendVisitor(v),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Attend'),
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
      padding: const EdgeInsets.all(12),
      itemCount: _appointments.length,
      itemBuilder: (_, i) {
        final a = _appointments[i];
        final dt = DateFormat('dd MMM yyyy • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(a.datetime));
        final color = a.status == 'confirmed' ? Colors.green : a.status == 'cancelled' ? Colors.red : Colors.orange;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(Icons.calendar_today_outlined, color: color, size: 18)),
            title: Text(a.requester_name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Meeting With: ${a.requested_with.replaceAll('_', ' ').toUpperCase()}'),
              Text('$dt • ${a.purpose}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(a.status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommunicationsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Templates Dispatcher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        _commCard('Fee Arrears SMS', 'Send fee reminders to parents with balances', Icons.account_balance_wallet_outlined, Colors.red, () => _sendBulk('finance')),
        _commCard('Leave-Out Notices', 'Inform parents of student leave-outs', Icons.person_off_outlined, const Color(0xFF4F46E5), () => _sendBulk('leave_out')),
        _commCard('Fleet Notices', 'Drop/pick updates & vehicle alerts', Icons.directions_bus_outlined, Colors.teal, () => _sendBulk('fleet')),
        _commCard('Trip Notices', 'Trip permissions & payments', Icons.travel_explore, const Color(0xFFF59E0B), () => _sendBulk('trips')),
        const SizedBox(height: 18),
        const Text('Recent Dispatch Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        if (_messageJobs.isEmpty)
          const Text('No recent message dispatches.', style: TextStyle(color: Colors.grey, fontSize: 11))
        else
          ..._messageJobs.take(5).map((j) {
            final ts = j.sent_at == null ? 'Queued' : DateFormat('dd MMM • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(j.sent_at!));
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                leading: Icon(Icons.sms_outlined, color: j.status == 'sent' ? Colors.green : Colors.orange, size: 18),
                title: Text(j.source_module.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                subtitle: Text(j.message_template, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                trailing: Text(ts, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            );
          }),
      ],
    );
  }

  Widget _commCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: IconButton(icon: Icon(Icons.send_outlined, color: color, size: 18), onPressed: onTap),
      ),
    );
  }

  Widget? _buildFab() {
    if (_tab.index == 0) {
      return FloatingActionButton.extended(
        onPressed: _showAddToQueue, label: const Text('Add Visitor'),
        icon: const Icon(Icons.person_add_outlined), backgroundColor: _accent, foregroundColor: Colors.white,
      );
    }
    if (_tab.index == 1) {
      return FloatingActionButton.extended(
        onPressed: _showNewAppointment, label: const Text('Book Appointment'),
        icon: const Icon(Icons.calendar_today), backgroundColor: _accent, foregroundColor: Colors.white,
      );
    }
    return null;
  }

  Future<void> _attendVisitor(VisitorQueueEntry v) async {
    final db = await ref.read(databaseProvider.future);
    await db.operationsDao.updateVisitorQueueStatus(v.id, 'attended', DateTime.now().millisecondsSinceEpoch);
    _load();
  }

  Future<void> _sendBulk(String module) async {
    final msgCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Broadcast: ${module.toUpperCase()}'),
        content: TextField(
          controller: msgCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'SMS Content', hintText: 'Dear parent, ...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (msgCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertBulkMessageJob(BulkMessageJob(
                id: const Uuid().v4(), source_module: module, message_template: msgCtrl.text.trim(),
                recipient_list: '[]', sent_at: DateTime.now().millisecondsSinceEpoch, status: 'sent',
              ));
              Navigator.pop(ctx); _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message job queued for dispatch ✅')));
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
          TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact')),
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
                id: const Uuid().v4(), visitor_name: nameCtrl.text.trim(),
                contact: contactCtrl.text.trim(), purpose: purposeCtrl.text.trim(),
                person_to_see: seeCtrl.text.isEmpty ? null : seeCtrl.text.trim(),
                arrived_at: DateTime.now().millisecondsSinceEpoch,
              ));
              Navigator.pop(ctx); _load();
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
          title: const Text('Schedule Appointment'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Visitor Name')),
              const SizedBox(height: 8),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Details')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: with_,
                decoration: const InputDecoration(labelText: 'Meeting With'),
                items: ['principal', 'deputy', 'director']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                onChanged: (v) => setS(() => with_ = v!),
              ),
              const SizedBox(height: 8),
              TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose / Agenda')),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date & Time', style: TextStyle(fontSize: 13)),
                subtitle: Text(DateFormat('dd MMM yyyy • h:mm a').format(selectedDt)),
                trailing: const Icon(Icons.calendar_today, size: 18),
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
                  id: const Uuid().v4(), requested_with: with_, requester_name: nameCtrl.text.trim(),
                  requester_contact: contactCtrl.text.trim(), purpose: purposeCtrl.text.trim(),
                  datetime: selectedDt.millisecondsSinceEpoch,
                ));
                Navigator.pop(ctx); _load();
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
        context: ctx, initialDate: initial,
        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null) return null;
    final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
