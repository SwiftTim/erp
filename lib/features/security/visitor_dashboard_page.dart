// lib/features/security/visitor_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

class VisitorDashboardPage extends ConsumerStatefulWidget {
  const VisitorDashboardPage({super.key});
  @override
  ConsumerState<VisitorDashboardPage> createState() => _VisitorDashboardPageState();
}

class _VisitorDashboardPageState extends ConsumerState<VisitorDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<VisitorQueueEntry> _queue = [];
  List<VisitorQueueEntry> _attended = [];
  List<GateLog> _passes = [];
  bool _loading = true;

  static const _accent = Color(0xFFE11D48);

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
    final waiting = await db.operationsDao.getVisitorQueue('waiting');
    final attended = await db.operationsDao.getVisitorQueue('attended');
    final passes = await db.operationsDao.getGateLogs();
    if (mounted) {
      setState(() {
        _queue = waiting;
        _attended = attended;
        _passes = passes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return AppShell(
      title: 'Security & Gate',
      actions: [
        TextButton.icon(
          onPressed: () => PrintableDocumentHub.show(
            context, 'Security & Gate', DocumentTemplates.getTemplatesForModule('security')),
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
          colors: [Color(0xFFE11D48), Color(0xFF9F1239)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          Text(user?.name ?? 'Security Officer',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(children: [
            _miniStat('Waiting', '${_queue.length}'),
            const SizedBox(width: 32),
            _miniStat('Today Passes', '${_passes.length}'),
            const SizedBox(width: 32),
            _miniStat('Attended', '${_attended.length}'),
          ]),
        ]),
        Positioned(right: 0, top: 0,
          child: Icon(Icons.security_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1))),
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
        _statCard('Waiting', '${_queue.length}', Icons.people_outline, Colors.orange),
        _statCard('Gate Passes', '${_passes.length}', Icons.badge_outlined, _accent),
        _statCard('Attended', '${_attended.length}', Icons.check_circle_outline, Colors.green),
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
      Text('Operations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
        child: Column(children: [
          TabBar(
            controller: _tab,
            labelColor: _accent,
            indicatorColor: _accent,
            unselectedLabelColor: Colors.grey,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Queue'),
                if (_queue.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(radius: 8, backgroundColor: Colors.red,
                    child: Text('${_queue.length}', style: const TextStyle(fontSize: 10, color: Colors.white))),
                ],
              ])),
              const Tab(text: 'Gate Passes'),
              const Tab(text: 'All Visitors'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(controller: _tab, children: [
              _buildQueueTab(),
              _buildPassesTab(),
              _buildAttendedTab(),
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
            subtitle: Text('${v.purpose} • ${wait.inMinutes}m waiting'),
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

  Widget _buildPassesTab() {
    if (_passes.isEmpty) {
      return const Center(child: Text('No gate passes issued today.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _passes.length,
      itemBuilder: (_, i) {
        final p = _passes[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _accent.withValues(alpha: 0.1),
              child: const Icon(Icons.badge_outlined, color: _accent, size: 18),
            ),
            title: Text(p.contact, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${p.type.toUpperCase()} • ${p.reason}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (p.exit_ts == null ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(p.exit_ts == null ? 'IN' : 'OUT', style: TextStyle(
                color: p.exit_ts == null ? Colors.green : Colors.grey,
                fontSize: 11, fontWeight: FontWeight.bold,
              )),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendedTab() {
    if (_attended.isEmpty) return const Center(child: Text('No visitors attended yet today.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _attended.length,
      itemBuilder: (_, i) {
        final v = _attended[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.check, color: Colors.green, size: 18)),
            title: Text(v.visitor_name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(v.purpose),
          ),
        );
      },
    );
  }

  Widget? _buildFab() {
    if (_tab.index == 0) {
      return FloatingActionButton.extended(
        onPressed: _showAddToQueue,
        label: const Text('Add Visitor'),
        icon: const Icon(Icons.person_add_outlined),
        backgroundColor: _accent, foregroundColor: Colors.white,
      );
    }
    if (_tab.index == 1) {
      return FloatingActionButton.extended(
        onPressed: _showIssueGatePass,
        label: const Text('Issue Pass'),
        icon: const Icon(Icons.badge_outlined),
        backgroundColor: _accent, foregroundColor: Colors.white,
      );
    }
    return null;
  }

  Future<void> _attendVisitor(VisitorQueueEntry v) async {
    final db = await ref.read(databaseProvider.future);
    await db.operationsDao.updateVisitorQueueStatus(v.id, 'attended', DateTime.now().millisecondsSinceEpoch);
    _load();
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

  Future<void> _showIssueGatePass() async {
    final nameCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    String passType = 'visitor';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Issue Gate Pass'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Holder Name')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: passType,
              decoration: const InputDecoration(labelText: 'Pass Type'),
              items: ['visitor', 'vehicle', 'delivery', 'contractor']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
              onChanged: (t) => setS(() => passType = t!),
            ),
            const SizedBox(height: 8),
            TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Reg (if applicable)')),
            const SizedBox(height: 8),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final user = ref.read(currentUserProvider);
                await db.operationsDao.insertGateLog(GateLog(
                  id: const Uuid().v4(),
                  type: passType,
                  reg_number: vehicleCtrl.text.isEmpty ? null : vehicleCtrl.text.trim(),
                  contact: nameCtrl.text.trim(),
                  reason: reasonCtrl.text.trim(),
                  entry_ts: DateTime.now().millisecondsSinceEpoch,
                  recorded_by: user?.name ?? 'Security',
                ));
                Navigator.pop(ctx); _load();
              },
              child: const Text('Issue'),
            ),
          ],
        ),
      ),
    );
  }
}
