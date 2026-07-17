// lib/features/fleet/fleet_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';

class FleetDashboardPage extends ConsumerStatefulWidget {
  const FleetDashboardPage({super.key});
  @override
  ConsumerState<FleetDashboardPage> createState() => _FleetDashboardPageState();
}

class _FleetDashboardPageState extends ConsumerState<FleetDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<FleetVehicle> _vehicles = [];
  List<TransportEnrollment> _enrollments = [];
  List<FleetIncident> _incidents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider.future);
    final veh = await db.operationsDao.getAllVehicles();
    final enr = await db.operationsDao.getActiveEnrollments();
    final inc = await db.operationsDao.getFleetIncidents();
    if (mounted) {
      setState(() {
        _vehicles = veh;
        _enrollments = enr;
        _incidents = inc;
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
        title: const Text('Fleet Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF10B981),
          indicatorColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Vehicles'),
            Tab(text: 'Students'),
            Tab(text: 'Incidents'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tab.index == 0 ? _showAddVehicle : _showEnrollStudent,
        label: Text(_tab.index == 0 ? 'Add Vehicle' : 'Enroll Student'),
        icon: Icon(_tab.index == 0 ? Icons.directions_bus_outlined : Icons.person_add_outlined),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildVehicleList(),
                _buildStudentList(),
                _buildIncidentList(),
              ],
            ),
    );
  }

  Widget _buildVehicleList() {
    if (_vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No vehicles registered.'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicles.length,
      itemBuilder: (_, i) {
        final v = _vehicles[i];
        final range = v.consumption_rate > 0
            ? ((v.fuel_level / v.consumption_rate)).toStringAsFixed(0)
            : '∞';
        final fuelPct = v.tank_capacity > 0 ? v.fuel_level / v.tank_capacity : 0.0;
        final isLowFuel = fuelPct < 0.15;
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                      child: const Icon(Icons.directions_bus_outlined,
                          color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.plate_number,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Driver: ${v.driver_name} • ${v.seats} seats',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    _statusTag(v.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.local_gas_station_outlined,
                              size: 14,
                              color: isLowFuel ? Colors.red : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                              '${v.fuel_level.toStringAsFixed(1)}L / ${v.tank_capacity.toStringAsFixed(0)}L',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isLowFuel ? Colors.red : Colors.grey)),
                          if (isLowFuel) ...[
                            const SizedBox(width: 6),
                            const Text('⚠️ LOW',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ]
                        ]),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fuelPct.clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            color: isLowFuel ? Colors.red : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('~$range km range',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('odo ${v.odometer_km.toStringAsFixed(0)} km',
                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showFuelUpdate(v),
                      icon: const Icon(Icons.local_gas_station_outlined, size: 16),
                      label: const Text('Fuel Update'),
                    ),
                    TextButton.icon(
                      onPressed: () => _showMaintenanceLog(v),
                      icon: const Icon(Icons.build_outlined, size: 16),
                      label: const Text('Maintenance'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusTag(String status) {
    final color = status == 'active'
        ? Colors.green
        : status == 'maintenance'
            ? Colors.orange
            : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStudentList() {
    final byVan = <String, List<TransportEnrollment>>{};
    for (final e in _enrollments) {
      byVan.putIfAbsent(e.van_id, () => []).add(e);
    }
    if (byVan.isEmpty) {
      return const Center(child: Text('No transport enrollments.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: byVan.entries.map((entry) {
        final vanLabel = _vehicles
                .where((v) => v.id == entry.key)
                .firstOrNull
                ?.plate_number ??
            entry.key.substring(0, 8);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          child: ExpansionTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2FE),
              child: Icon(Icons.directions_bus_outlined, color: Color(0xFF0EA5E9)),
            ),
            title: Text('Van: $vanLabel',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${entry.value.length} students'),
            children: entry.value
                .map((e) => ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(e.student_name),
                      subtitle:
                          Text('📍 ${e.pickup_location} • 📞 ${e.guardian_contact}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_downward,
                                color: Colors.orange, size: 18),
                            tooltip: 'Dropped',
                            onPressed: () => _recordEvent(e, 'DROP'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_upward,
                                color: Colors.green, size: 18),
                            tooltip: 'Picked',
                            onPressed: () => _recordEvent(e, 'PICK'),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIncidentList() {
    if (_incidents.isEmpty) {
      return const Center(child: Text('No incidents reported. ✅'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _incidents.length,
      itemBuilder: (_, i) {
        final inc = _incidents[i];
        final time = DateFormat('dd MMM • h:mm a').format(
            DateTime.fromMillisecondsSinceEpoch(inc.reported_at));
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          color: Colors.red.withValues(alpha: 0.03),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            title: Text(inc.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('Van: ${inc.van_id.substring(0, 8)}… • $time'),
            trailing: inc.notified_fleet_manager
                ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                : const Icon(Icons.pending, color: Colors.orange, size: 18),
          ),
        );
      },
    );
  }

  Future<void> _recordEvent(TransportEnrollment e, String type) async {
    final db = await ref.read(databaseProvider.future);
    await db.operationsDao.insertTransportEvent(TransportEvent(
      student_id: e.student_id,
      van_id: e.van_id,
      event_type: type,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.student_name} — $type recorded ✅')));
    }
  }

  Future<void> _showAddVehicle() async {
    final plateCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final seatsCtrl = TextEditingController(text: '14');
    final tankCtrl = TextEditingController(text: '60');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'Plate Number')),
          const SizedBox(height: 8),
          TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: seatsCtrl, decoration: const InputDecoration(labelText: 'Seats'), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: tankCtrl, decoration: const InputDecoration(labelText: 'Tank (L)'), keyboardType: TextInputType.number)),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (plateCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertFleetVehicle(FleetVehicle(
                id: const Uuid().v4(),
                plate_number: plateCtrl.text.trim(),
                driver_id: const Uuid().v4(),
                driver_name: driverCtrl.text.trim(),
                seats: int.tryParse(seatsCtrl.text) ?? 14,
                tank_capacity: double.tryParse(tankCtrl.text) ?? 60,
                fuel_level: double.tryParse(tankCtrl.text) ?? 60,
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

  Future<void> _showEnrollStudent() async {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String? selectedVanId;

    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a vehicle first.')));
      return;
    }
    selectedVanId = _vehicles.first.id;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Enroll Student in Transport'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Student Name')),
            const SizedBox(height: 8),
            TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Guardian Contact')),
            const SizedBox(height: 8),
            TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Pickup Location')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedVanId,
              decoration: const InputDecoration(labelText: 'Assign to Van'),
              items: _vehicles
                  .map((v) => DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.plate_number} — ${v.driver_name}'),
                      ))
                  .toList(),
              onChanged: (v) => setS(() => selectedVanId = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || selectedVanId == null) return;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertTransportEnrollment(TransportEnrollment(
                  id: const Uuid().v4(),
                  student_id: const Uuid().v4(),
                  student_name: nameCtrl.text.trim(),
                  guardian_contact: contactCtrl.text.trim(),
                  pickup_location: locationCtrl.text.trim(),
                  van_id: selectedVanId!,
                ));
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Enroll'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFuelUpdate(FleetVehicle v) async {
    final litreCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Fuel Top-Up: ${v.plate_number}'),
        content: TextField(
          controller: litreCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Litres Added', suffixText: 'L'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final added = double.tryParse(litreCtrl.text) ?? 0;
              final newLevel = (v.fuel_level + added).clamp(0, v.tank_capacity);
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.updateFleetVehicle(FleetVehicle(
                id: v.id,
                plate_number: v.plate_number,
                seats: v.seats,
                driver_id: v.driver_id,
                driver_name: v.driver_name,
                consumption_rate: v.consumption_rate,
                tank_capacity: v.tank_capacity,
                odometer_km: v.odometer_km,
                fuel_level: newLevel.toDouble(),
                status: v.status,
              ));
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMaintenanceLog(FleetVehicle v) async {
    final notesCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    String mainType = 'service';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Maintenance: ${v.plate_number}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: mainType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: ['service', 'repair', 'paint', 'oil', 'extinguisher']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (t) => setS(() => mainType = t!),
            ),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            const SizedBox(height: 8),
            TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Cost (KSh)'), keyboardType: TextInputType.number),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertMaintenanceLog(VehicleMaintenanceLog(
                  id: const Uuid().v4(),
                  vehicle_id: v.id,
                  type: mainType,
                  date: DateTime.now().millisecondsSinceEpoch,
                  cost: double.tryParse(costCtrl.text) ?? 0,
                  notes: notesCtrl.text.trim(),
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }
}
