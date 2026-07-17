// lib/features/store/store_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Store Keeper',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF4F46E5),
          indicatorColor: const Color(0xFF4F46E5),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Assets'),
            Tab(text: 'Stock'),
            Tab(text: 'Procurement'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _buildDashboard(),
                _buildAssetList(),
                _buildStockList(),
                _buildProcurementList(),
              ],
            ),
    );
  }

  Widget? _buildFab() {
    final labels = ['', 'Add Asset', 'Add Stock', 'New Request'];
    final icons = [null, Icons.add_box_outlined, Icons.inventory_2_outlined, Icons.shopping_cart_outlined];
    final fns = [null, _showAddAsset, _showAddStock, _showNewProcurement];
    final i = _tab.index;
    if (i == 0) return null;
    return FloatingActionButton.extended(
      onPressed: fns[i],
      label: Text(labels[i]),
      icon: Icon(icons[i]),
      backgroundColor: const Color(0xFF4F46E5),
      foregroundColor: Colors.white,
    );
  }

  Widget _buildDashboard() {
    final inStore = _assets.where((a) => a.status == 'in_store').length;
    final assigned = _assets.where((a) => a.status == 'assigned').length;
    final lowStock = _stock.where((s) => s.quantity_on_hand <= s.reorder_level).length;
    final pendingProc = _procurement.where((p) => p.status == 'pending').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _statCard('Total Assets', '${_assets.length}',
                  Icons.devices_other_outlined, const Color(0xFF4F46E5)),
              _statCard('In Store', '$inStore',
                  Icons.warehouse_outlined, Colors.green),
              _statCard('Assigned', '$assigned',
                  Icons.assignment_ind_outlined, Colors.blue),
              _statCard('Low Stock Alerts', '$lowStock',
                  Icons.warning_amber_outlined, Colors.orange),
              _statCard('Stock Lines', '${_stock.length}',
                  Icons.inventory_outlined, Colors.teal),
              _statCard('Pending Orders', '$pendingProc',
                  Icons.pending_actions_outlined, Colors.red),
            ],
          ),
          const SizedBox(height: 20),
          if (lowStock > 0) ...[
            const Text('⚠️ Low Stock Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ..._stock
                .where((s) => s.quantity_on_hand <= s.reorder_level)
                .map(_buildStockCard),
          ],
        ],
      ),
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
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildAssetList() {
    if (_assets.isEmpty) {
      return const Center(child: Text('No assets registered.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assets.length,
      itemBuilder: (_, i) {
        final a = _assets[i];
        final statusColor = a.status == 'in_store'
            ? Colors.green
            : a.status == 'assigned'
                ? Colors.blue
                : Colors.grey;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(Icons.devices_other_outlined, color: statusColor),
            ),
            title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${a.category} • Tag: ${a.tag_number} • ${a.condition}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(a.status.replaceAll('_', ' '),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockList() {
    if (_stock.isEmpty) {
      return const Center(child: Text('No stock items.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stock.length,
      itemBuilder: (_, i) => _buildStockCard(_stock[i]),
    );
  }

  Widget _buildStockCard(StockItem s) {
    final isLow = s.quantity_on_hand <= s.reorder_level;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: isLow
                  ? Colors.orange.withValues(alpha: 0.4)
                  : Colors.transparent)),
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isLow ? Colors.orange.withValues(alpha: 0.1) : Colors.teal.withValues(alpha: 0.1),
          child: Icon(Icons.inventory_2_outlined,
              color: isLow ? Colors.orange : Colors.teal),
        ),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${s.category} • Reorder at ${s.reorder_level} ${s.unit}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${s.quantity_on_hand}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isLow ? Colors.orange : Colors.teal)),
            Text(s.unit,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildProcurementList() {
    if (_procurement.isEmpty) {
      return const Center(child: Text('No procurement requests.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _procurement.length,
      itemBuilder: (_, i) {
        final p = _procurement[i];
        final statusColor = p.status == 'approved'
            ? Colors.green
            : p.status == 'rejected'
                ? Colors.red
                : Colors.orange;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              child: Icon(Icons.shopping_cart_outlined, color: statusColor),
            ),
            title: Text('${p.item} (×${p.qty})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${p.source_module} • KSh ${NumberFormat('#,###').format(p.estimated_cost)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(p.status,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                if (p.status == 'pending') ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
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
    await db.operationsDao.updateProcurementStatus(
        p.id, 'approved', 'Approved by ${user?.name ?? 'Manager'}');
    _load();
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
          title: const Text('Add Asset'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Asset Name')),
            const SizedBox(height: 8),
            TextField(controller: tagCtrl, decoration: const InputDecoration(labelText: 'Tag Number')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Equipment', 'Furniture', 'IT Device', 'Sports', 'Other']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setS(() => category = v!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: condition,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: ['New', 'Good', 'Fair', 'Poor']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                  id: const Uuid().v4(),
                  category: category,
                  name: nameCtrl.text.trim(),
                  tag_number: tagCtrl.text.trim(),
                  condition: condition,
                  created_at: DateTime.now().millisecondsSinceEpoch,
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
          title: const Text('Add Stock Item'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Stationery', 'Cleaning', 'Equipment', 'Uniform', 'Food']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setS(() => category = v!),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: reorderCtrl, decoration: const InputDecoration(labelText: 'Reorder Level'), keyboardType: TextInputType.number)),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertStockItem(StockItem(
                  id: const Uuid().v4(),
                  category: category,
                  name: nameCtrl.text.trim(),
                  unit: unit,
                  quantity_on_hand: int.tryParse(qtyCtrl.text) ?? 0,
                  reorder_level: int.tryParse(reorderCtrl.text) ?? 5,
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
          title: const Text('Procurement Request'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: source,
                decoration: const InputDecoration(labelText: 'Requesting Module'),
                items: ['store', 'library', 'boarding', 'finance']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setS(() => source = v!),
              ),
              const SizedBox(height: 8),
              TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: 'Item / Description')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Est. Cost (KSh)'), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 8),
              TextField(controller: justCtrl, decoration: const InputDecoration(labelText: 'Justification'), maxLines: 2),
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
                  id: const Uuid().v4(),
                  source_module: source,
                  item: itemCtrl.text.trim(),
                  qty: int.tryParse(qtyCtrl.text) ?? 1,
                  estimated_cost: double.tryParse(costCtrl.text) ?? 0,
                  justification: justCtrl.text.trim(),
                  requested_by: user?.name ?? 'Staff',
                  created_at: DateTime.now().millisecondsSinceEpoch,
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
}
