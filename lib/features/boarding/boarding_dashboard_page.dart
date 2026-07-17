// lib/features/boarding/boarding_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

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

  static const _accent = Color(0xFF8B5CF6); // purple

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
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
    final user = ref.watch(currentUserProvider);
    final vacant = _beds.where((b) => b.student_id == null).length;
    final occupied = _beds.where((b) => b.student_id != null).length;

    return AppShell(
      title: 'Boarding Master',
      actions: [
        TextButton.icon(
          onPressed: () => PrintableDocumentHub.show(
            context, 'Boarding & Dorms', DocumentTemplates.getTemplatesForModule('boarding')),
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
                  _buildWelcomeCard(user, occupied, vacant),
                  const SizedBox(height: 24),
                  _buildStatsGrid(occupied, vacant),
                  const SizedBox(height: 24),
                  _buildTabSection(),
                ]),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(dynamic user, int occupied, int vacant) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          Text(user?.name ?? 'Boarding Master',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(children: [
            _miniStat('Blocks', '${_blocks.length}'),
            const SizedBox(width: 32),
            _miniStat('Total beds', '${_beds.length}'),
            const SizedBox(width: 32),
            _miniStat('Occupancy', '${occupied}/${_beds.length}'),
          ]),
        ]),
        Positioned(right: 0, top: 0,
          child: Icon(Icons.apartment_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1))),
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

  Widget _buildStatsGrid(int occupied, int vacant) {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    return GridView.count(
      crossAxisCount: isDesktop ? 6 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
      children: [
        _statCard('Blocks', '${_blocks.length}', Icons.apartment_outlined, _accent),
        _statCard('Rooms', '${_rooms.length}', Icons.meeting_room_outlined, Colors.blue),
        _statCard('Total Beds', '${_beds.length}', Icons.bed_outlined, Colors.teal),
        _statCard('Occupied', '$occupied', Icons.person_outline, Colors.orange),
        _statCard('Vacant', '$vacant', Icons.check_circle_outline, Colors.green),
        _statCard('Dining Tables', '${_tables.length}', Icons.table_restaurant_outlined, Colors.pink),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildTabSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Management & Activities', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
        child: Column(children: [
          TabBar(
            controller: _tab,
            labelColor: _accent, indicatorColor: _accent,
            unselectedLabelColor: Colors.grey, dividerColor: Colors.transparent,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Dormitories'),
              Tab(text: 'Dining Tables'),
              Tab(text: 'Inspections'),
              Tab(text: 'Staff list'),
            ],
          ),
          SizedBox(
            height: 480,
            child: TabBarView(controller: _tab, children: [
              _buildDormitoriesTab(),
              _buildDiningTab(),
              _buildInspectionsTab(),
              _buildStaffTab(),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildDormitoriesTab() {
    if (_blocks.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.apartment_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('No dormitory blocks set up yet.'),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _blocks.length,
      itemBuilder: (_, i) {
        final block = _blocks[i];
        final blockRooms = _rooms.where((r) => r.block_id == block.id).toList();
        final blockBeds = _beds.where((b) => blockRooms.any((r) => r.id == b.room_id)).length;
        final occupied = _beds.where((b) => blockRooms.any((r) => r.id == b.room_id) && b.student_id != null).length;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ExpansionTile(
            leading: CircleAvatar(backgroundColor: _accent.withValues(alpha: 0.1), child: const Icon(Icons.apartment_outlined, color: _accent, size: 18)),
            title: Text(block.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${block.type.toUpperCase()} • ${blockRooms.length} rooms • $occupied/$blockBeds beds'),
            children: [
              ...blockRooms.map((room) {
                final roomBeds = _beds.where((b) => b.room_id == room.id).toList();
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: const Icon(Icons.meeting_room_outlined, size: 18),
                  title: Text('Room ${room.room_number}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${room.bed_count} beds • ${room.length_m}m × ${room.width_m}m'),
                  trailing: TextButton(onPressed: () => _showRoomBeds(room, roomBeds), child: const Text('Beds')),
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

  Widget _buildDiningTab() {
    if (_tables.isEmpty) return const Center(child: Text('No dining tables configured.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _tables.length,
      itemBuilder: (_, i) {
        final t = _tables[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.pink.withValues(alpha: 0.1),
              child: Text('T${t.table_number}', style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold))),
            title: Text('Table ${t.table_number} — ${t.grade_level}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Leaders: ${t.leader_ids.isEmpty ? 'Not set' : t.leader_ids}'),
          ),
        );
      },
    );
  }

  Widget _buildInspectionsTab() {
    if (_inspections.isEmpty) return const Center(child: Text('No inspection reports.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _inspections.length,
      itemBuilder: (_, i) {
        final r = _inspections[i];
        final color = r.severity == 'critical' ? Colors.red : r.severity == 'needs_attention' ? Colors.orange : Colors.green;
        final time = DateFormat('dd MMM • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(r.submitted_at));
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.checklist_outlined, color: color, size: 18)),
            title: Text(r.area_type.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${r.condition_notes}\nBy ${r.submitted_by} • $time', style: const TextStyle(fontSize: 11)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(r.severity.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffTab() {
    if (_staff.isEmpty) return const Center(child: Text('No boarding staff assigned.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _staff.length,
      itemBuilder: (_, i) {
        final s = _staff[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: s.role == 'matron' ? Colors.pink.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
              child: Icon(Icons.person_outlined, color: s.role == 'matron' ? Colors.pink : Colors.blue),
            ),
            title: Text(s.staff_name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${s.role.toUpperCase()} • ${s.duties}'),
          ),
        );
      },
    );
  }

  Widget? _buildFab() {
    final labels = ['Add Block', 'Add Table', 'New Inspection', 'Add Staff'];
    final icons = [Icons.apartment_outlined, Icons.table_restaurant_outlined, Icons.checklist_outlined, Icons.person_add_outlined];
    final fns = [_showAddBlock, _showAddDiningTable, _showNewInspection, _showAddBoardingStaff];
    final idx = _tab.index;
    return FloatingActionButton.extended(
      onPressed: fns[idx], label: Text(labels[idx]),
      icon: Icon(icons[idx]), backgroundColor: _accent, foregroundColor: Colors.white,
    );
  }

  void _showRoomBeds(DormRoom room, List<BedSlot> beds) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.6,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text('Room ${room.room_number} — Beds', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            _bedCalculatorCard(room),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: ctrl, itemCount: beds.length,
                itemBuilder: (_, i) {
                  final b = beds[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: Icon(b.student_id == null ? Icons.bed_outlined : Icons.person_outlined,
                          color: b.student_id == null ? Colors.green : Colors.blue),
                      title: Text(b.student_name ?? 'Vacant (${b.bunk_position})', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: b.student_id == null ? null : Text('${b.student_class} • ${b.reg_number}'),
                      trailing: b.student_id == null ? TextButton(onPressed: () => _assignBed(b), child: const Text('Assign')) : null,
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
    final floorArea = room.length_m * room.width_m;
    final bunkFootprint = 0.9 * 2.0;
    final usableArea = floorArea - (room.length_m * kAisleWidthM);
    final maxBunks = (usableArea / bunkFootprint).floor();
    final maxBedsDoubleDecker = maxBunks * 2;
    final moeLimit = (floorArea / kMinAreaPerBoarderM2).floor();
    final recommended = maxBedsDoubleDecker < moeLimit ? maxBedsDoubleDecker : moeLimit;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🏗️ MoE Bed Calculator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Text('Room: ${room.length_m}m × ${room.width_m}m = ${floorArea.toStringAsFixed(1)} m²', style: const TextStyle(fontSize: 12)),
        Text('MoE limit (${kMinAreaPerBoarderM2}m²/boarder): Max $moeLimit boarders', style: const TextStyle(fontSize: 12)),
        Text('Double-decker max fits: $maxBedsDoubleDecker beds', style: const TextStyle(fontSize: 12)),
        Text('✅ Recommended limit: $recommended beds (Current room: ${room.bed_count})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _accent)),
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
        title: const Text('Assign Boarder to Bed'),
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
                id: bed.id, room_id: bed.room_id, bunk_position: bed.bunk_position,
                student_id: const Uuid().v4(), student_name: nameCtrl.text.trim(),
                student_class: classCtrl.text.trim(), reg_number: regCtrl.text.trim(),
              ));
              Navigator.pop(ctx); _load();
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
          title: const Text('New Dorm Block'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Block Name (e.g. Block A)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: type, decoration: const InputDecoration(labelText: 'Dorm Type'),
              items: ['boys', 'girls', 'mixed'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
              onChanged: (t) => setS(() => type = t!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertDormBlock(DormBlock(id: const Uuid().v4(), name: nameCtrl.text.trim(), type: type));
                Navigator.pop(ctx); _load();
              },
              child: const Text('Create'),
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
              final floorArea = l * w;
              final moeLimit = (floorArea / kMinAreaPerBoarderM2).floor();
              final db = await ref.read(databaseProvider.future);
              final roomId = const Uuid().v4();
              await db.operationsDao.insertDormRoom(DormRoom(id: roomId, block_id: block.id, room_number: roomCtrl.text.trim(), length_m: l, width_m: w, bed_count: moeLimit));
              for (int i = 0; i < moeLimit; i++) {
                await db.operationsDao.insertBedSlot(BedSlot(id: const Uuid().v4(), room_id: roomId, bunk_position: i.isEven ? 'lower' : 'upper'));
              }
              Navigator.pop(ctx); _load();
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
        title: const Text('New Dining Table'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: numCtrl, decoration: const InputDecoration(labelText: 'Table Number'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Grade / Class Assign')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertDiningTable(DiningTable(
                id: const Uuid().v4(), table_number: int.tryParse(numCtrl.text) ?? _tables.length + 1,
                grade_level: gradeCtrl.text.trim(), student_ids: '[]', leader_ids: '[]',
              ));
              Navigator.pop(ctx); _load();
            },
            child: const Text('Create'),
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
          title: const Text('Submit Inspection'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: area, decoration: const InputDecoration(labelText: 'Inspection Area'),
              items: ['washroom', 'classroom', 'dining', 'compound'].map((a) => DropdownMenuItem(value: a, child: Text(a.toUpperCase()))).toList(),
              onChanged: (a) => setS(() => area = a!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: severity, decoration: const InputDecoration(labelText: 'Severity / Health Class'),
              items: ['clean', 'minor_issues', 'needs_attention', 'critical'].map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ').toUpperCase()))).toList(),
              onChanged: (s) => setS(() => severity = s!),
            ),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Observations / Notes'), maxLines: 2),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertInspectionReport(InspectionReport(
                  id: const Uuid().v4(), area_type: area, condition_notes: notesCtrl.text.trim(),
                  submitted_by: user?.name ?? 'TOD', submitted_at: DateTime.now().millisecondsSinceEpoch, severity: severity,
                ));
                Navigator.pop(ctx); _load();
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
              value: role, decoration: const InputDecoration(labelText: 'Assigned Role'),
              items: ['matron', 'patron'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
              onChanged: (r) => setS(() => role = r!),
            ),
            const SizedBox(height: 8),
            TextField(controller: dutiesCtrl, decoration: const InputDecoration(labelText: 'Duties & Responsibility'), maxLines: 2),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertBoardingStaff(BoardingStaffAssignment(
                  staff_id: const Uuid().v4(), staff_name: nameCtrl.text.trim(), role: role, duties: dutiesCtrl.text.trim(),
                ));
                Navigator.pop(ctx); _load();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
