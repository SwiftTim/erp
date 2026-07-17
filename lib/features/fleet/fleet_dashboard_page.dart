// lib/features/fleet/fleet_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

class FleetDashboardPage extends ConsumerStatefulWidget {
  const FleetDashboardPage({super.key});
  @override
  ConsumerState<FleetDashboardPage> createState() => _FleetDashboardPageState();
}

class _FleetDashboardPageState extends ConsumerState<FleetDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<FleetVehicle> _vehicles = [];
  List<MaintenanceLog> _maintenance = [];
  bool _loading = true;

  static const _accent = Color(0xFF0D9488); // teal

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
    final vehicles = await db.operationsDao.getAllVehicles();
    final logs = await db.operationsDao.getAllMaintenanceLogs();
    if (mounted) {
      setState(() {
        _vehicles = vehicles;
        _maintenance = logs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final active = _vehicles.where((v) => v.status == 'active').length;
    final inService = _vehicles.where((v) => v.status == 'maintenance').length;

    return AppShell(
      title: 'Fleet Management',
      actions: [
        TextButton.icon(
          onPressed: () => PrintableDocumentHub.show(
            context, 'Fleet', DocumentTemplates.getTemplatesForModule('fleet')),
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
                  _buildWelcomeCard(user, active, inService),
                  const SizedBox(height: 24),
                  _buildStatsGrid(active, inService),
                  const SizedBox(height: 24),
                  _buildTabSection(),
                ]),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(dynamic user, int active, int inService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          Text(user?.name ?? 'Fleet Manager',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(children: [
            _miniStat('Total Vehicles', '${_vehicles.length}'),
            const SizedBox(width: 32),
            _miniStat('Active', '$active'),
            const SizedBox(width: 32),
            _miniStat('In Maintenance', '$inService'),
          ]),
        ]),
        Positioned(right: 0, top: 0,
          child: Icon(Icons.directions_bus_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1))),
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

  Widget _buildStatsGrid(int active, int inService) {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
      children: [
        _statCard('Fleet Size', '${_vehicles.length}', Icons.directions_bus_outlined, _accent),
        _statCard('Active', '$active', Icons.check_circle_outline, Colors.green),
        _statCard('Maintenance', '$inService', Icons.build_outlined, Colors.orange),
        _statCard('Service Logs', '${_maintenance.length}', Icons.history_outlined, Colors.blue),
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
      Text('Fleet Operations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
        child: Column(children: [
          TabBar(
            controller: _tab,
            labelColor: _accent, indicatorColor: _accent,
            unselectedLabelColor: Colors.grey, dividerColor: Colors.transparent,
            tabs: const [Tab(text: 'Vehicles'), Tab(text: 'Maintenance Logs')],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(controller: _tab, children: [
              _buildVehicleTab(),
              _buildMaintenanceTab(),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildVehicleTab() {
    if (_vehicles.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('No vehicles registered.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: _showAddVehicle, icon: const Icon(Icons.add), label: const Text('Register Vehicle')),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _vehicles.length,
      itemBuilder: (_, i) {
        final v = _vehicles[i];
        final statusColor = v.status == 'active' ? Colors.green : Colors.orange;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _accent.withValues(alpha: 0.1),
              child: const Icon(Icons.directions_bus_outlined, color: _accent, size: 18)),
            title: Text(v.registration, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${v.make} ${v.model} • ${v.capacity} seats'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(v.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (v.driver_name != null) _row('Driver', v.driver_name!),
                  if (v.insurance_expiry != null) _row('Insurance Expiry', v.insurance_expiry!),
                  _row('Odometer', '${v.odometer_km} km'),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton.icon(
                      onPressed: () => _showLogMaintenance(v),
                      icon: const Icon(Icons.build_outlined, size: 14),
                      label: const Text('Log Service'),
                    ),
                  ]),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
    ]),
  );

  Widget _buildMaintenanceTab() {
    if (_maintenance.isEmpty) return const Center(child: Text('No maintenance logs yet.'));
    final fmt = DateFormat('d MMM yyyy');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _maintenance.length,
      itemBuilder: (_, i) {
        final log = _maintenance[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: const Icon(Icons.build_outlined, color: Colors.orange, size: 18)),
            title: Text(log.description, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('KSh ${log.cost.toStringAsFixed(2)} • ${fmt.format(DateTime.fromMillisecondsSinceEpoch(log.date))}'),
          ),
        );
      },
    );
  }

  Widget? _buildFab() {
    if (_tab.index == 0) {
      return FloatingActionButton.extended(
        onPressed: _showAddVehicle, label: const Text('Add Vehicle'),
        icon: const Icon(Icons.add), backgroundColor: _accent, foregroundColor: Colors.white,
      );
    }
    return null;
  }

  Future<void> _showAddVehicle() async {
    final regCtrl = TextEditingController();
    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final insuranceCtrl = TextEditingController();
    final odoCtrl = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Vehicle'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: regCtrl, decoration: const InputDecoration(labelText: 'Registration Number')),
            const SizedBox(height: 8),
            TextField(controller: makeCtrl, decoration: const InputDecoration(labelText: 'Make (e.g. Toyota)')),
            const SizedBox(height: 8),
            TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model (e.g. Coaster)')),
            const SizedBox(height: 8),
            TextField(controller: capacityCtrl, decoration: const InputDecoration(labelText: 'Seat Capacity'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Assigned Driver')),
            const SizedBox(height: 8),
            TextField(controller: insuranceCtrl, decoration: const InputDecoration(labelText: 'Insurance Expiry (e.g. 31 Dec 2025)')),
            const SizedBox(height: 8),
            TextField(controller: odoCtrl, decoration: const InputDecoration(labelText: 'Odometer (km)'), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (regCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertVehicle(FleetVehicle(
                id: const Uuid().v4(), registration: regCtrl.text.trim().toUpperCase(),
                make: makeCtrl.text.trim(), model: modelCtrl.text.trim(),
                capacity: int.tryParse(capacityCtrl.text) ?? 0,
                driver_name: driverCtrl.text.isEmpty ? null : driverCtrl.text.trim(),
                insurance_expiry: insuranceCtrl.text.isEmpty ? null : insuranceCtrl.text.trim(),
                odometer_km: double.tryParse(odoCtrl.text) ?? 0,
                status: 'active',
              ));
              Navigator.pop(ctx); _load();
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogMaintenance(FleetVehicle v) async {
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Service: ${v.registration}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Service Description'), minLines: 2, maxLines: 3),
          const SizedBox(height: 8),
          TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Cost (KSh)'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (descCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertMaintenanceLog(MaintenanceLog(
                id: const Uuid().v4(), vehicle_id: v.id,
                description: descCtrl.text.trim(), cost: double.tryParse(costCtrl.text) ?? 0,
                date: DateTime.now().millisecondsSinceEpoch,
              ));
              Navigator.pop(ctx); _load();
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }
}
