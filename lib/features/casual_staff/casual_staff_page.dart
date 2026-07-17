// lib/features/casual_staff/casual_staff_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

class CasualStaffPage extends ConsumerStatefulWidget {
  const CasualStaffPage({super.key});
  @override
  ConsumerState<CasualStaffPage> createState() => _CasualStaffPageState();
}

class _CasualStaffPageState extends ConsumerState<CasualStaffPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<CasualWorker> _workers = [];
  List<CasualAttendance> _todayAttendance = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider.future);
    final workers = await db.operationsDao.getActiveCasualWorkers();
    // Gather today's attendance for each worker
    final List<CasualAttendance> todayAll = [];
    final todayStart = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0).millisecondsSinceEpoch;
    for (final w in workers) {
      final att = await db.operationsDao.getCasualAttendance(w.id);
      todayAll.addAll(att.where((a) => a.in_ts >= todayStart));
    }
    if (mounted) {
      setState(() {
        _workers = workers;
        _todayAttendance = todayAll;
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
        title: const Text('Casual Staff', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {
              PrintableDocumentHub.show(
                context,
                'Non-Teaching / Casual Staff',
                DocumentTemplates.getTemplatesForModule('casual_staff'),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF7C3AED)),
            label: const Text('Forms / Slips', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF7C3AED),
          indicatorColor: const Color(0xFF7C3AED),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Workers'),
            Tab(text: "Today's Attendance"),
          ],
        ),
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showRegisterWorker,
              label: const Text('Register Worker'),
              icon: const Icon(Icons.person_add_outlined),
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildWorkerList(),
                _buildAttendanceList(),
              ],
            ),
    );
  }

  Widget _buildWorkerList() {
    if (_workers.isEmpty) {
      return const Center(child: Text('No casual workers registered.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workers.length,
      itemBuilder: (_, i) {
        final w = _workers[i];
        final rate = NumberFormat('#,###').format(w.agreed_rate_per_day);
        // Check if worker is expired (within 30 days of end_date)
        final nearExpiry = w.end_date != null &&
            DateTime.now().millisecondsSinceEpoch >
                w.end_date! - const Duration(days: 30).inMilliseconds;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: w.blacklisted
                    ? Colors.red.withValues(alpha: 0.4)
                    : nearExpiry
                        ? Colors.orange.withValues(alpha: 0.4)
                        : Colors.transparent),
          ),
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: w.blacklisted
                  ? Colors.red.withValues(alpha: 0.1)
                  : const Color(0xFF7C3AED).withValues(alpha: 0.1),
              child: Icon(
                  w.blacklisted ? Icons.block_outlined : Icons.badge_outlined,
                  color: w.blacklisted ? Colors.red : const Color(0xFF7C3AED)),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(w.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (w.blacklisted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('BLACKLISTED',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                if (nearExpiry && !w.blacklisted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('EXPIRING',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(w.job_description,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text('KSh $rate/day • ID: ${w.national_id}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.login, color: Colors.green, size: 20),
                  tooltip: 'Check In',
                  onPressed: () => _checkIn(w),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.orange, size: 20),
                  tooltip: 'Check Out',
                  onPressed: () => _checkOut(w),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceList() {
    if (_todayAttendance.isEmpty) {
      return const Center(child: Text("No attendance recorded today."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todayAttendance.length,
      itemBuilder: (_, i) {
        final a = _todayAttendance[i];
        final worker = _workers.where((w) => w.id == a.worker_id).firstOrNull;
        final inTime = DateFormat('h:mm a')
            .format(DateTime.fromMillisecondsSinceEpoch(a.in_ts));
        final outTime = a.out_ts != null
            ? DateFormat('h:mm a')
                .format(DateTime.fromMillisecondsSinceEpoch(a.out_ts!))
            : 'Still on site';
        final hours = a.out_ts != null
            ? ((a.out_ts! - a.in_ts) / 3600000).toStringAsFixed(1)
            : '-';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: a.out_ts != null
                  ? Colors.teal.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              child: Icon(
                  a.out_ts != null ? Icons.check_circle_outline : Icons.circle,
                  color: a.out_ts != null ? Colors.teal : Colors.green,
                  size: 20),
            ),
            title: Text(worker?.name ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('In: $inTime → Out: $outTime'),
            trailing: Text('$hours hrs',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Future<void> _checkIn(CasualWorker w) async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider);
    // Check if already checked in
    final open = await db.operationsDao.getOpenCasualAttendance(w.id);
    if (open != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${w.name} is already checked in.')));
      }
      return;
    }
    await db.operationsDao.insertCasualAttendance(CasualAttendance(
      worker_id: w.id,
      in_ts: DateTime.now().millisecondsSinceEpoch,
      recorded_by: user?.name ?? 'Gate',
    ));
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${w.name} checked IN ✅')));
    }
  }

  Future<void> _checkOut(CasualWorker w) async {
    final db = await ref.read(databaseProvider.future);
    final open = await db.operationsDao.getOpenCasualAttendance(w.id);
    if (open == null || open.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${w.name} has not checked in yet.')));
      }
      return;
    }
    await db.operationsDao.recordCasualOut(
        open.id!, DateTime.now().millisecondsSinceEpoch);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${w.name} checked OUT 👋')));
    }
  }

  Future<void> _showRegisterWorker() async {
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final jobCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '800');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Casual Worker'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 8),
            TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'National ID')),
            const SizedBox(height: 8),
            TextField(controller: jobCtrl, decoration: const InputDecoration(labelText: 'Job Description')),
            const SizedBox(height: 8),
            TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Rate per Day (KSh)'), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || idCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              // Check blacklist
              final existing = await db.operationsDao.findCasualWorkerByNationalId(idCtrl.text.trim());
              if (existing != null && existing.blacklisted) {
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                          '⚠️ ${existing.name} is blacklisted: ${existing.blacklist_reason ?? 'No reason given'}')));
                }
                return;
              }
              final user = ref.read(currentUserProvider);
              await db.operationsDao.insertCasualWorker(CasualWorker(
                id: const Uuid().v4(),
                name: nameCtrl.text.trim(),
                national_id: idCtrl.text.trim(),
                job_description: jobCtrl.text.trim(),
                agreed_rate_per_day: double.tryParse(rateCtrl.text) ?? 800,
                registered_by: user?.name ?? 'Receptionist',
                start_date: DateTime.now().millisecondsSinceEpoch,
              ));
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}
