// lib/features/boarding/boarding_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

// MoE spacing constants (Kenya Boarding Rules — configurable)
const double kMinAreaPerBoarderM2 = 3.7; // m² per boarder (MoE minimum)
const double kAisleWidthM = 1.2;          // minimum aisle clearance
const double kBunkHeightM = 1.9;          // headroom per bunk level

class BoardingDashboardPage extends ConsumerStatefulWidget {
  const BoardingDashboardPage({super.key});
  @override
  ConsumerState<BoardingDashboardPage> createState() => _BoardingDashboardPageState();
}

class _BoardingDashboardPageState extends ConsumerState<BoardingDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<DormBlock> _blocks = [];
  List<DormRoom> _rooms = [];
  List<BedSlot> _beds = [];
  List<InspectionReport> _inspections = [];
  List<DiningTable> _tables = [];
  List<BoardingStaffAssignment> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider.future);
    final blocks = await db.operationsDao.getDormBlocks();
    List<DormRoom> allRooms = [];
    List<BedSlot> allBeds = [];
    for (final b in blocks) {
      final rooms = await db.operationsDao.getRoomsByBlock(b.id);
      allRooms.addAll(rooms);
      for (final r in rooms) {
        final beds = await db.operationsDao.getBedSlotsByRoom(r.id);
        allBeds.addAll(beds);
      }
    }
    final insp = await db.operationsDao.getAllInspections();
    final tables = await db.operationsDao.getAllDiningTables();
    final bStaff = await db.operationsDao.getBoardingStaff();
    if (mounted) {
      setState(() {
        _blocks = blocks;
        _rooms = allRooms;
        _beds = allBeds;
        _inspections = insp;
        _tables = tables;
        _staff = bStaff;
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
        title: const Text('Boarding Master', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {
              PrintableDocumentHub.show(
                context,
                'Boarding & Dorms',
                DocumentTemplates.getTemplatesForModule('boarding'),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF8B5CF6)),
            label: const Text('Forms / Slips', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF8B5CF6),
          indicatorColor: const Color(0xFF8B5CF6),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Dormitories'),
            Tab(text: 'Dining'),
            Tab(text: 'Inspections'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildOverview(),
                _buildDormitories(),
                _buildDining(),
                _buildInspections(),
              ],
            ),
    );
  }

  Widget? _buildFab() {
    final labels = ['Add Block', 'Add Block', 'Add Table', 'New Inspection'];
    final icons = [Icons.apartment_outlined, Icons.apartment_outlined, Icons.table_restaurant_outlined, Icons.checklist_outlined];
    final fns = [_showAddBlock, _showAddBlock, _showAddDiningTable, _showNewInspection];
    final i = _tab.index;
    return FloatingActionButton.extended(
      onPressed: fns[i],
      label: Text(labels[i]),
      icon: Icon(icons[i]),
      backgroundColor: const Color(0xFF8B5CF6),
      foregroundColor: Colors.white,
    );
  }

  Widget _buildOverview() {
    final vacant = _beds.where((b) => b.student_id == null).length;
    final occupied = _beds.where((b) => b.student_id != null).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _statCard('Blocks', '${_blocks.length}', Icons.apartment_outlined, const Color(0xFF8B5CF6)),
            _statCard('Rooms', '${_rooms.length}', Icons.meeting_room_outlined, Colors.blue),
            _statCard('Total Beds', '${_beds.length}', Icons.bed_outlined, Colors.teal),
            _statCard('Occupied', '$occupied', Icons.person_outlined, Colors.orange),
            _statCard('Vacant', '$vacant', Icons.bed_outlined, Colors.green),
            _statCard('Dining Tables', '${_tables.length}', Icons.table_restaurant_outlined, Colors.pink),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Boarding Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (_staff.isEmpty)
          const Text('No boarding staff assigned.', style: TextStyle(color: Colors.grey))
        else
          ..._staff.map((s) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: s.role == 'matron'
                    ? Colors.pink.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                child: Icon(Icons.person_outlined,
                    color: s.role == 'matron' ? Colors.pink : Colors.blue),
              ),
              title: Text(s.staff_name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${s.role.toUpperCase()} • ${s.duties}'),
            ),
          )),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _showAddBoardingStaff,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add Boarding Staff'),
        ),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDormitories() {
    if (_blocks.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.apartment_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No dormitory blocks set up yet.'),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blocks.length,
      itemBuilder: (_, i) {
        final block = _blocks[i];
        final blockRooms = _rooms.where((r) => r.block_id == block.id).toList();
        final blockBeds = _beds.where((b) => blockRooms.any((r) => r.id == b.room_id)).length;
        final occupied = _beds.where((b) =>
            blockRooms.any((r) => r.id == b.room_id) && b.student_id != null).length;
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              child: const Icon(Icons.apartment_outlined, color: Color(0xFF8B5CF6)),
            ),
            title: Text(block.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${block.type.toUpperCase()} • ${blockRooms.length} rooms • $occupied/$blockBeds beds'),
            children: [
              ...blockRooms.map((room) {
                final roomBeds = _beds.where((b) => b.room_id == room.id).toList();
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: const Icon(Icons.meeting_room_outlined, size: 18),
                  title: Text('Room ${room.room_number}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${room.bed_count} beds • ${room.length_m}m × ${room.width_m}m'),
                  trailing: TextButton(
                    onPressed: () => _showRoomBeds(room, roomBeds),
                    child: const Text('View Beds'),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton.icon(
                    onPressed: () => _showAddRoom(block),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Room'),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDining() {
    if (_tables.isEmpty) {
      return const Center(child: Text('No dining tables configured.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tables.length,
      itemBuilder: (_, i) {
        final t = _tables[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.pink.withValues(alpha: 0.1),
              child: Text('T${t.table_number}',
                  style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
            ),
            title: Text('Table ${t.table_number} — ${t.grade_level}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Leaders: ${t.leader_ids.isEmpty ? 'Not set' : t.leader_ids}'),
          ),
        );
      },
    );
  }

  Widget _buildInspections() {
    if (_inspections.isEmpty) {
      return const Center(child: Text('No inspection reports.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inspections.length,
      itemBuilder: (_, i) {
        final r = _inspections[i];
        final color = r.severity == 'critical'
            ? Colors.red
            : r.severity == 'needs_attention'
                ? Colors.orange
                : Colors.green;
        final time = DateFormat('dd MMM • h:mm a').format(
            DateTime.fromMillisecondsSinceEpoch(r.submitted_at));
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(Icons.checklist_outlined, color: color),
            ),
            title: Text(r.area_type.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${r.condition_notes}\nBy ${r.submitted_by} • $time',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(r.severity,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  void _showRoomBeds(DormRoom room, List<BedSlot> beds) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text('Room ${room.room_number} — Beds',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            _bedCalculatorCard(room),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: beds.length,
                itemBuilder: (_, i) {
                  final b = beds[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    child: ListTile(
                      leading: Icon(
                          b.student_id == null
                              ? Icons.bed_outlined
                              : Icons.person_outlined,
                          color: b.student_id == null ? Colors.green : Colors.blue),
                      title: Text(b.student_name ?? 'Vacant (${b.bunk_position})',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: b.student_id == null
                          ? null
                          : Text('${b.student_class} • ${b.reg_number}'),
                      trailing: b.student_id == null
                          ? TextButton(
                              onPressed: () => _assignBed(b),
                              child: const Text('Assign'))
                          : null,
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _bedCalculatorCard(DormRoom room) {
    // MoE Bed Count Calculator
    final floorArea = room.length_m * room.width_m;
    final bunkFootprint = 0.9 * 2.0; // standard single bunk footprint m²
    final usableArea = floorArea - (room.length_m * kAisleWidthM);
    final maxBunks = (usableArea / bunkFootprint).floor();
    final maxBedsDoubleDecker = maxBunks * 2;
    final moeLimit = (floorArea / kMinAreaPerBoarderM2).floor();
    final recommended = maxBedsDoubleDecker < moeLimit
        ? maxBedsDoubleDecker
        : moeLimit;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🏗️ MoE Bed Calculator',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Text('Room: ${room.length_m}m × ${room.width_m}m = ${floorArea.toStringAsFixed(1)} m²',
            style: const TextStyle(fontSize: 12)),
        Text('MoE min ${kMinAreaPerBoarderM2}m²/boarder → max $moeLimit persons',
            style: const TextStyle(fontSize: 12)),
        Text('Double-decker capacity: $maxBedsDoubleDecker beds',
            style: const TextStyle(fontSize: 12)),
        Text('✅ Recommended: $recommended beds (registered: ${room.bed_count})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                color: Color(0xFF8B5CF6))),
      ]),
    );
  }

  Future<void> _assignBed(BedSlot bed) async {
    final nameCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final regCtrl = TextEditingController();
    Navigator.pop(context);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Student to Bed'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Student Name')),
          const SizedBox(height: 8),
          TextField(controller: classCtrl, decoration: const InputDecoration(labelText: 'Class')),
          const SizedBox(height: 8),
          TextField(controller: regCtrl, decoration: const InputDecoration(labelText: 'Reg Number')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.updateBedSlot(BedSlot(
                id: bed.id,
                room_id: bed.room_id,
                bunk_position: bed.bunk_position,
                student_id: const Uuid().v4(),
                student_name: nameCtrl.text.trim(),
                student_class: classCtrl.text.trim(),
                reg_number: regCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddBlock() async {
    final nameCtrl = TextEditingController();
    String type = 'boys';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Dormitory Block'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Block Name (e.g. Block A)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: ['boys', 'girls', 'mixed']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                  .toList(),
              onChanged: (t) => setS(() => type = t!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertDormBlock(DormBlock(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  type: type,
                ));
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddRoom(DormBlock block) async {
    final roomCtrl = TextEditingController();
    final lenCtrl = TextEditingController(text: '8');
    final widCtrl = TextEditingController(text: '6');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Room to ${block.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room Number')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: lenCtrl, decoration: const InputDecoration(labelText: 'Length (m)'), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: widCtrl, decoration: const InputDecoration(labelText: 'Width (m)'), keyboardType: TextInputType.number)),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (roomCtrl.text.isEmpty) return;
              final l = double.tryParse(lenCtrl.text) ?? 8;
              final w = double.tryParse(widCtrl.text) ?? 6;
              // auto-calculate beds using MoE rules
              final floorArea = l * w;
              final moeLimit = (floorArea / kMinAreaPerBoarderM2).floor();
              final db = await ref.read(databaseProvider.future);
              final roomId = const Uuid().v4();
              await db.operationsDao.insertDormRoom(DormRoom(
                id: roomId,
                block_id: block.id,
                room_number: roomCtrl.text.trim(),
                length_m: l,
                width_m: w,
                bed_count: moeLimit,
              ));
              // Create bed slots
              for (int i = 0; i < moeLimit; i++) {
                await db.operationsDao.insertBedSlot(BedSlot(
                  id: const Uuid().v4(),
                  room_id: roomId,
                  bunk_position: i.isEven ? 'lower' : 'upper',
                ));
              }
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Add Room'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDiningTable() async {
    final gradeCtrl = TextEditingController();
    final numCtrl = TextEditingController(text: '${_tables.length + 1}');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Dining Table'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Table Number'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Grade Level (e.g. Grade 7)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertDiningTable(DiningTable(
                id: const Uuid().v4(),
                table_number: int.tryParse(numCtrl.text) ?? _tables.length + 1,
                grade_level: gradeCtrl.text.trim(),
                student_ids: '[]',
                leader_ids: '[]',
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

  Future<void> _showNewInspection() async {
    String area = 'washroom';
    String severity = 'clean';
    final notesCtrl = TextEditingController();
    final user = ref.read(currentUserProvider);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Submit Inspection Report'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: area,
              decoration: const InputDecoration(labelText: 'Area'),
              items: ['washroom', 'classroom', 'dining', 'compound']
                  .map((a) => DropdownMenuItem(value: a, child: Text(a.toUpperCase())))
                  .toList(),
              onChanged: (a) => setS(() => area = a!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: severity,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: ['clean', 'minor_issues', 'needs_attention', 'critical']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ').toUpperCase())))
                  .toList(),
              onChanged: (s) => setS(() => severity = s!),
            ),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertInspectionReport(InspectionReport(
                  id: const Uuid().v4(),
                  area_type: area,
                  condition_notes: notesCtrl.text.trim(),
                  submitted_by: user?.name ?? 'TOD',
                  submitted_at: DateTime.now().millisecondsSinceEpoch,
                  severity: severity,
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

  Future<void> _showAddBoardingStaff() async {
    final nameCtrl = TextEditingController();
    final dutiesCtrl = TextEditingController();
    String role = 'matron';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Boarding Staff'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Staff Name')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: ['matron', 'patron']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                  .toList(),
              onChanged: (r) => setS(() => role = r!),
            ),
            const SizedBox(height: 8),
            TextField(controller: dutiesCtrl, decoration: const InputDecoration(labelText: 'Duties'), maxLines: 2),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertBoardingStaff(BoardingStaffAssignment(
                  staff_id: const Uuid().v4(),
                  staff_name: nameCtrl.text.trim(),
                  role: role,
                  duties: dutiesCtrl.text.trim(),
                ));
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
