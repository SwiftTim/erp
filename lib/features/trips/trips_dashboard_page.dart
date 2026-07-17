// lib/features/trips/trips_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';

class TripsDashboardPage extends ConsumerStatefulWidget {
  const TripsDashboardPage({super.key});
  @override
  ConsumerState<TripsDashboardPage> createState() => _TripsDashboardPageState();
}

class _TripsDashboardPageState extends ConsumerState<TripsDashboardPage> {
  List<SchoolTrip> _trips = [];
  bool _loading = true;
  String _filter = 'All';

  static const _stages = [
    'draft', 'deputy_review', 'reception_notify',
    'finance_budget', 'headteacher_sign', 'fleet_dispatch', 'completed'
  ];
  static const _stageLabels = [
    'Draft', 'Deputy Review', 'Reception → Parent Notify',
    'Finance Budget', 'Headteacher Sign', 'Fleet Dispatch', 'Completed'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider.future);
    final trips = await db.operationsDao.getAllTrips();
    if (mounted) setState(() { _trips = trips; _loading = false; });
  }

  List<SchoolTrip> get _filtered => _filter == 'All'
      ? _trips
      : _trips.where((t) => t.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Trips & Tours', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewTrip,
        label: const Text('Plan Trip'),
        icon: const Icon(Icons.travel_explore),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No trips found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildTripCard(_filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', ..._stages];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final label = f == 'All'
              ? 'All (${_trips.length})'
              : _stageLabels[_stages.indexOf(f)];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              selected: _filter == f,
              onSelected: (_) => setState(() => _filter = f),
              selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTripCard(SchoolTrip trip) {
    final stageIdx = _stages.indexOf(trip.status);
    final stageLabel = stageIdx >= 0 ? _stageLabels[stageIdx] : trip.status;
    final stageColor = trip.status == 'completed'
        ? Colors.green
        : trip.status == 'draft'
            ? Colors.grey
            : const Color(0xFFF59E0B);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: stageColor.withValues(alpha: 0.1),
                child: Icon(Icons.travel_explore, color: stageColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.venue,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('By ${trip.teacher_name} • ${trip.class_id}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(stageLabel,
                    style: TextStyle(
                        color: stageColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 12),
            // Stage progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stageIdx >= 0
                    ? (stageIdx + 1) / _stages.length
                    : 0,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: stageColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(trip.purpose,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (trip.amount > 0)
                Text('KSh ${NumberFormat('#,###').format(trip.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            if (trip.status != 'completed') ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _advanceStage(trip),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Advance Stage'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _advanceStage(SchoolTrip trip) async {
    final idx = _stages.indexOf(trip.status);
    if (idx < 0 || idx >= _stages.length - 1) return;
    final nextStage = _stages[idx + 1];
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider);
    await db.operationsDao.updateSchoolTrip(SchoolTrip(
      id: trip.id,
      teacher_id: trip.teacher_id,
      teacher_name: trip.teacher_name,
      class_id: trip.class_id,
      venue: trip.venue,
      purpose: trip.purpose,
      student_ids: trip.student_ids,
      status: nextStage,
      deputy_approved_by:
          nextStage == 'reception_notify' ? user?.name : trip.deputy_approved_by,
      amount: trip.amount,
      headteacher_signature: nextStage == 'fleet_dispatch'
          ? 'Signed by ${user?.name}'
          : trip.headteacher_signature,
      fleet_alloc_ref: trip.fleet_alloc_ref,
      created_at: trip.created_at,
      trip_date: trip.trip_date,
    ));
    _load();
  }

  Future<void> _showNewTrip() async {
    final venueCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan New Trip'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Venue / Destination')),
            const SizedBox(height: 8),
            TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose')),
            const SizedBox(height: 8),
            TextField(controller: classCtrl, decoration: const InputDecoration(labelText: 'Class (e.g. Grade 7A)')),
            const SizedBox(height: 8),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Estimated Cost per Student (KSh)'), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (venueCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              final user = ref.read(currentUserProvider);
              await db.operationsDao.insertSchoolTrip(SchoolTrip(
                id: const Uuid().v4(),
                teacher_id: user?.id ?? '',
                teacher_name: user?.name ?? 'Teacher',
                class_id: classCtrl.text.trim(),
                venue: venueCtrl.text.trim(),
                purpose: purposeCtrl.text.trim(),
                student_ids: '[]',
                amount: double.tryParse(costCtrl.text) ?? 0,
                created_at: DateTime.now().millisecondsSinceEpoch,
              ));
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
