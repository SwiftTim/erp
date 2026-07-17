// lib/features/store/store_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

class StoreDashboardPage extends ConsumerStatefulWidget {
  const StoreDashboardPage({super.key});
  @override
  ConsumerState<StoreDashboardPage> createState() => _StoreDashboardPageState();
}

class _StoreDashboardPageState extends ConsumerState<StoreDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<StoreAsset> _assets = [];
  List<StockItem> _stock = [];
  List<ProcurementRequest> _procurement = [];
  bool _loading = true;

  static const _accent = Color(0xFF4F46E5); // indigo

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
    final assets = await db.operationsDao.getAllStoreAssets();
    final stock = await db.operationsDao.getAllStockItems();
    final proc = await db.operationsDao.getAllProcurementRequests();
    if (mounted) {
      setState(() {
        _assets = assets;
        _stock = stock;
        _procurement = proc;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final inStore = _assets.where((a) => a.status == 'in_store').length;
    final assigned = _assets.where((a) => a.status == 'assigned').length;
    final lowStock = _stock.where((s) => s.quantity_on_hand <= s.reorder_level).length;
    final pendingProc = _procurement.where((p) => p.status == 'pending').length;

    return AppShell(
      title: 'Store Keeper Hub',
      actions: [
        TextButton.icon(
          onPressed: () => PrintableDocumentHub.show(
              context, 'Store Keeper', DocumentTemplates.getTemplatesForModule('store')),
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
                  _buildWelcomeCard(user, inStore, lowStock, pendingProc),
                  const SizedBox(height: 24),
                  _buildStatsGrid(inStore, assigned, lowStock, pendingProc),
                  const SizedBox(height: 24),
                  _buildTabSection(lowStock),
                ]),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(dynamic user, int inStore, int lowStock, int pendingProc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          Text(user?.name ?? 'Store Keeper',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(children: [
            _miniStat('Assets In Store', '$inStore'),
            const SizedBox(width: 32),
            _miniStat('Low Stock Warns', '$lowStock'),
            const SizedBox(width: 32),
            _miniStat('Pending Orders', '$pendingProc'),
          ]),
        ]),
        Positioned(right: 0, top: 0,
          child: Icon(Icons.inventory_2_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1))),
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

  Widget _buildStatsGrid(int inStore, int assigned, int lowStock, int pendingProc) {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    return GridView.count(
      crossAxisCount: isDesktop ? 6 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
      children: [
        _statCard('Total Assets', '${_assets.length}', Icons.devices_other_outlined, _accent),
        _statCard('In Store', '$inStore', Icons.warehouse_outlined, Colors.green),
        _statCard('Allocated', '$assigned', Icons.assignment_ind_outlined, Colors.blue),
        _statCard('Low Stock', '$lowStock', Icons.warning_amber_outlined, Colors.orange),
        _statCard('Total Lines', '${_stock.length}', Icons.inventory_outlined, Colors.teal),
        _statCard('Pending LPO', '$pendingProc', Icons.pending_actions_outlined, Colors.red),
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
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildTabSection(int lowStock) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Inventory & Procurements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
            tabs: [
              const Tab(text: 'Dormant Assets'),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Stock Registry'),
                if (lowStock > 0) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(radius: 8, backgroundColor: Colors.orange,
                    child: Text('$lowStock', style: const TextStyle(fontSize: 10, color: Colors.white))),
                ],
              ])),
              const Tab(text: 'Procurement LPOs'),
            ],
          ),
          SizedBox(
            height: 480,
            child: TabBarView(controller: _tab, children: [
              _buildAssetList(),
              _buildStockList(),
              _buildProcurementList(),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildAssetList() {
    if (_assets.isEmpty) return const Center(child: Text('No assets registered.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _assets.length,
      itemBuilder: (_, i) {
        final a = _assets[i];
        final statusColor = a.status == 'in_store' ? Colors.green : a.status == 'assigned' ? Colors.blue : Colors.grey;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: statusColor.withValues(alpha: 0.1), child: Icon(Icons.devices_other_outlined, color: statusColor, size: 18)),
            title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${a.category} • Tag: ${a.tag_number} • Condition: ${a.condition}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(a.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockList() {
    if (_stock.isEmpty) return const Center(child: Text('No stock items in registry.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _stock.length,
      itemBuilder: (_, i) => _buildStockCard(_stock[i]),
    );
  }

  Widget _buildStockCard(StockItem s) {
    final isLow = s.quantity_on_hand <= s.reorder_level;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isLow ? Colors.orange.withValues(alpha: 0.4) : Colors.grey.shade200)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLow ? Colors.orange.withValues(alpha: 0.1) : Colors.teal.withValues(alpha: 0.1),
          child: Icon(Icons.inventory_2_outlined, color: isLow ? Colors.orange : Colors.teal, size: 18),
        ),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${s.category} • Alert when below ${s.reorder_level} ${s.unit}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${s.quantity_on_hand}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isLow ? Colors.orange : Colors.teal)),
            Text(s.unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildProcurementList() {
    if (_procurement.isEmpty) return const Center(child: Text('No external procurement orders.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _procurement.length,
      itemBuilder: (_, i) {
        final p = _procurement[i];
        final statusColor = p.status == 'approved' ? Colors.green : p.status == 'rejected' ? Colors.red : Colors.orange;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: statusColor.withValues(alpha: 0.1), child: Icon(Icons.shopping_cart_outlined, color: statusColor, size: 18)),
            title: Text('${p.item} (×${p.qty})', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${p.source_module.toUpperCase()} • KSh ${NumberFormat('#,###').format(p.estimated_cost)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(p.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                if (p.status == 'pending') ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                    onPressed: () => _approveProcurement(p),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _approveProcurement(ProcurementRequest p) async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider);
    await db.operationsDao.updateProcurementStatus(p.id, 'approved', 'Approved by ${user?.name ?? 'Manager'}');
    _load();
  }

  Widget? _buildFab() {
    final labels = ['', 'Add Asset', 'Add Stock', 'New LPO Request'];
    final icons = [null, Icons.add_box_outlined, Icons.inventory_2_outlined, Icons.shopping_cart_outlined];
    final fns = [null, _showAddAsset, _showAddStock, _showNewProcurement];
    final idx = _tab.index;
    if (idx == 0 || fns[idx] == null) return null;
    return FloatingActionButton.extended(
      onPressed: fns[idx], label: Text(labels[idx]),
      icon: Icon(icons[idx]!), backgroundColor: _accent, foregroundColor: Colors.white,
    );
  }

  Future<void> _showAddAsset() async {
    final nameCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    String category = 'Equipment';
    String condition = 'Good';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Register New Store Asset'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Asset Name (e.g. Printer, Laptop)')),
            const SizedBox(height: 8),
            TextField(controller: tagCtrl, decoration: const InputDecoration(labelText: 'Brand/Tag ID Number')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category, decoration: const InputDecoration(labelText: 'Asset Category'),
              items: ['Equipment', 'Furniture', 'IT Device', 'Sports', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setS(() => category = v!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: condition, decoration: const InputDecoration(labelText: 'Starting Condition'),
              items: ['New', 'Good', 'Fair', 'Poor'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setS(() => condition = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertStoreAsset(StoreAsset(
                  id: const Uuid().v4(), category: category, name: nameCtrl.text.trim(),
                  tag_number: tagCtrl.text.trim(), condition: condition, created_at: DateTime.now().millisecondsSinceEpoch,
                ));
                Navigator.pop(ctx); _load();
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddStock() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final reorderCtrl = TextEditingController(text: '5');
    String category = 'Stationery';
    String unit = 'pcs';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Consumable Stock Item'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category, decoration: const InputDecoration(labelText: 'Category'),
              items: ['Stationery', 'Cleaning', 'Equipment', 'Uniform', 'Food'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setS(() => category = v!),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Opening Quantity on Hand'), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: reorderCtrl, decoration: const InputDecoration(labelText: 'Min Reorder Threshold'), keyboardType: TextInputType.number)),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertStockItem(StockItem(
                  id: const Uuid().v4(), category: category, name: nameCtrl.text.trim(), unit: unit,
                  quantity_on_hand: int.tryParse(qtyCtrl.text) ?? 0, reorder_level: int.tryParse(reorderCtrl.text) ?? 5,
                ));
                Navigator.pop(ctx); _load();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNewProcurement() async {
    final itemCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController();
    final justCtrl = TextEditingController();
    String source = 'store';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Log Procurement Requisition'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: source, decoration: const InputDecoration(labelText: 'Requesting Module'),
                items: ['store', 'library', 'boarding', 'finance'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                onChanged: (v) => setS(() => source = v!),
              ),
              const SizedBox(height: 8),
              TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: 'Item Name & Description')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Estimated Cost (KSh)'), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 8),
              TextField(controller: justCtrl, decoration: const InputDecoration(labelText: 'Justification / Business Case'), maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (itemCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final user = ref.read(currentUserProvider);
                await db.operationsDao.insertProcurementRequest(ProcurementRequest(
                  id: const Uuid().v4(), source_module: source, item: itemCtrl.text.trim(),
                  qty: int.tryParse(qtyCtrl.text) ?? 1, estimated_cost: double.tryParse(costCtrl.text) ?? 0,
                  justification: justCtrl.text.trim(), requested_by: user?.name ?? 'Staff',
                  created_at: DateTime.now().millisecondsSinceEpoch,
                ));
                Navigator.pop(ctx); _load();
              },
              child: const Text('Submit LPO'),
            ),
          ],
        ),
      ),
    );
  }
}
