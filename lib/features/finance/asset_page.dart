import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../auth/auth_provider.dart';

class AssetPage extends ConsumerStatefulWidget {
  const AssetPage({super.key});

  @override
  ConsumerState<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends ConsumerState<AssetPage> {
  List<Map<String, dynamic>> _assetsWithRepairs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final assets = await db.financeErpDao.getAllAssets();
    final repairs = await db.financeErpDao.getAllRepairs();
    
    final List<Map<String, dynamic>> data = [];
    for (var asset in assets) {
      final assetRepairs = repairs.where((r) => r.asset_id == asset.asset_id).toList();
      data.add({
        'asset': asset,
        'repairs': assetRepairs,
      });
    }

    if (mounted) {
      setState(() {
        _assetsWithRepairs = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asset & Repairs')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _assetsWithRepairs.length,
              itemBuilder: (context, index) {
                final item = _assetsWithRepairs[index];
                final ErpAsset asset = item['asset'] as ErpAsset;
                final List<ErpRepair> repairs = item['repairs'] as List<ErpRepair>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(asset.asset_name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: asset.status == 'Active' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(asset.status, style: TextStyle(color: asset.status == 'Active' ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Category: ${asset.category}'),
                        Text('Condition: ${asset.condition}'),
                        Text('Value: KES ${asset.purchase_value.toStringAsFixed(0)}'),
                        const Divider(height: 24),
                        const Text('Recent Repairs', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (repairs.isEmpty)
                          const Text('No repairs recorded.', style: TextStyle(color: Colors.grey, fontSize: 12))
                        else
                          ...repairs.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(r.description, style: const TextStyle(fontSize: 12))),
                                    Text('KES ${r.repair_cost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
