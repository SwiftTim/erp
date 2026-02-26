// lib/features/admin/inventory_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/enterprise_models.dart';
import '../../data/models/finance_model.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import '../../core/services/audit_service.dart';

class InventoryManagementPage extends ConsumerStatefulWidget {
  const InventoryManagementPage({super.key});

  @override
  ConsumerState<InventoryManagementPage> createState() => _InventoryManagementPageState();
}

class _InventoryManagementPageState extends ConsumerState<InventoryManagementPage> {
  List<InventoryAsset> _assets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final db = await ref.read(databaseProvider.future);
    final assets = await db.enterpriseDao.findAllAssets();
    if (mounted) {
      setState(() {
        _assets = assets;
        _loading = false;
      });
    }
  }

  void _showProcureSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProcureAssetSheet(onSaved: _loadAssets),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Asset Inventory',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _assets.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _assets.length,
                          itemBuilder: (context, i) {
                            final asset = _assets[i];
                            return _AssetCard(asset: asset);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showProcureSheet,
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Procure Asset'),
      ),
    );
  }

  Widget _buildHeader() {
    final totalValue = _assets.fold(0.0, (sum, a) => sum + ((a.unitCost ?? 0.0) * a.quantity));
    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _HeaderStat(label: 'Total Items', value: '${_assets.length}'),
          _HeaderStat(label: 'Inventory Value', value: 'KES ${totalValue.toStringAsFixed(0)}', color: AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No assets found in inventory.', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final InventoryAsset asset;
  const _AssetCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.category_outlined, color: AppTheme.primary),
        ),
        title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${asset.category} • ${asset.location}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text('Qty: ${asset.quantity}', style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text(asset.condition, style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        trailing: asset.unitCost != null 
          ? Text('KES ${(asset.unitCost! * asset.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold))
          : null,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AssetMaintenanceSheet(asset: asset),
          );
        },
      ),
    );
  }
}

class _AssetMaintenanceSheet extends ConsumerStatefulWidget {
  final InventoryAsset asset;
  const _AssetMaintenanceSheet({required this.asset});

  @override
  ConsumerState<_AssetMaintenanceSheet> createState() => _AssetMaintenanceSheetState();
}

class _AssetMaintenanceSheetState extends ConsumerState<_AssetMaintenanceSheet> {
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  List<AssetMaintenanceLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final db = await ref.read(databaseProvider.future);
    final logs = await db.enterpriseDao.findMaintenanceLogs(widget.asset.id);
    if (mounted) setState(() => _logs = logs);
  }

  Future<void> _saveLog() async {
    final desc = _descCtrl.text.trim();
    final cost = double.tryParse(_costCtrl.text) ?? 0.0;
    if (desc.isEmpty) return;

    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider)!;

    final newLog = AssetMaintenanceLog(
      id: const Uuid().v4(),
      assetId: widget.asset.id,
      description: desc,
      cost: cost,
      servicedAt: DateTime.now().millisecondsSinceEpoch,
      recordedBy: user.id,
    );

    await db.enterpriseDao.insertMaintenanceLog(newLog);

    // Sync large maintenance costs with Finance
    if (cost >= 1000) {
      await db.financeDao.insertExpenditure(ExpenditureModel(
        id: const Uuid().v4(),
        category: 'Maintenance & Repairs',
        amount: cost,
        description: 'Serviced [${widget.asset.name}]: $desc',
        recordedBy: user.id,
        expenseDate: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    _descCtrl.clear();
    _costCtrl.clear();
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text(widget.asset.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text("Historical Maintenance Logs", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description (e.g., Screen repair)'))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: _costCtrl, decoration: const InputDecoration(labelText: 'Cost (KES)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _saveLog, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: _logs.isEmpty 
              ? const Center(child: Text("No servicing records found.", style: TextStyle(fontStyle: FontStyle.italic)))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, i) {
                    final log = _logs[i];
                    return ListTile(
                      leading: const Icon(Icons.build_circle_outlined, color: Colors.blue),
                      title: Text(log.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("Secured on ${DateTime.fromMillisecondsSinceEpoch(log.servicedAt).toString().substring(0, 10)}"),
                      trailing: Text('KES ${log.cost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _HeaderStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _ProcureAssetSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _ProcureAssetSheet({required this.onSaved});

  @override
  ConsumerState<_ProcureAssetSheet> createState() => _ProcureAssetSheetState();
}

class _ProcureAssetSheetState extends ConsumerState<_ProcureAssetSheet> {
  final _nameCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _costCtrl = TextEditingController();
  String _selectedCategory = 'Furniture';
  String _selectedCondition = 'New';
  bool _syncWithFinance = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text('Procure Institutional Asset', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Bridge Inventory with Finance Ledger', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Asset Name (e.g. Dell Latitudes)')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Furniture', 'ICT', 'Lab Equipment', 'Sports', 'Books'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(controller: _locCtrl, decoration: const InputDecoration(labelText: 'Storage Location')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(controller: _qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(controller: _costCtrl, decoration: const InputDecoration(labelText: 'Unit Cost (KES)', prefixText: 'KES '), keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: const InputDecoration(labelText: 'Condition Upon Receipt'),
              items: ['New', 'Good', 'Refurbished'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCondition = v!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Sync with Finance Ledger'),
              subtitle: const Text('Automatically record as an institutional expenditure'),
              value: _syncWithFinance,
              onChanged: (v) => setState(() => _syncWithFinance = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: const Text('Complete Procurement'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    final cost = double.tryParse(_costCtrl.text) ?? 0.0;
    final user = ref.read(currentUserProvider)!;
    final db = await ref.read(databaseProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;
    final uuid = const Uuid().v4();

    // 1. Save Asset
    final asset = InventoryAsset(
      id: uuid,
      name: name,
      category: _selectedCategory,
      location: _locCtrl.text.trim(),
      quantity: qty,
      condition: _selectedCondition,
      unitCost: cost > 0 ? cost : null,
      purchaseDate: now,
    );
    await db.enterpriseDao.insertAsset(asset);

    // 2. Sync with Finance if requested
    if (_syncWithFinance && cost > 0) {
      final totalAmount = cost * qty;
      final expenditure = ExpenditureModel(
        id: const Uuid().v4(),
        category: 'Assets & Infrastructure',
        amount: totalAmount,
        description: 'Procurement of $qty x $name (@ KES $cost)',
        recordedBy: user.id,
        expenseDate: now,
      );
      await db.financeDao.insertExpenditure(expenditure);
      
      ref.read(auditServiceProvider).log(
        'PROCURE_ASSET', 
        'Inventory/Finance', 
        'Procured $qty $name. Linked to expenditure ledger.'
      );
    } else {
      ref.read(auditServiceProvider).log(
        'ADD_ASSET', 
        'Inventory', 
        'Added $qty $name to local inventory.'
      );
    }

    widget.onSaved();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inventory updated. ${_syncWithFinance ? "Linked to Finance." : ""}')),
    );
  }
}
