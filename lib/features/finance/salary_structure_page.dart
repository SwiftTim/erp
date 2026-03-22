// lib/features/finance/salary_structure_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_erp_models.dart';
import '../auth/auth_provider.dart';
import 'package:intl/intl.dart';

class SalaryStructurePage extends ConsumerStatefulWidget {
  const SalaryStructurePage({super.key});

  @override
  ConsumerState<SalaryStructurePage> createState() => _SalaryStructurePageState();
}

class _SalaryStructurePageState extends ConsumerState<SalaryStructurePage> {
  List<SalaryStructure> _structures = [];
  List<SalaryComponent> _components = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final structures = await db.financeErpDao.getAllSalaryStructures();
    final components = await db.financeErpDao.getAllSalaryComponents();
    
    if (mounted) {
      setState(() {
        _structures = structures;
        _components = components;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Structures'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Structures'),
                      Tab(text: 'Components'),
                    ],
                    labelColor: Colors.blue,
                    indicatorColor: Colors.blue,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStructureList(),
                        _buildComponentList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStructureList() {
    return _structures.isEmpty
        ? const Center(child: Text('No salary structures defined.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _structures.length,
            itemBuilder: (context, index) {
              final s = _structures[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.account_tree_outlined, color: Colors.white)),
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Company: ${s.company} • Active: ${s.is_active ? "Yes" : "No"}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _viewStructureDetails(s),
                ),
              );
            },
          );
  }

  Widget _buildComponentList() {
    return _components.isEmpty
        ? const Center(child: Text('No salary components defined.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _components.length,
            itemBuilder: (context, index) {
              final c = _components[index];
              final isEarning = c.type == 'Earning';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    isEarning ? Icons.add_circle_outline : Icons.remove_circle_outline,
                    color: isEarning ? Colors.green : Colors.red,
                  ),
                  title: Text(c.name),
                  subtitle: Text('${c.type} ${c.is_statutory ? "• Statutory" : ""}'),
                  trailing: c.default_amount > 0 
                    ? Text('KSh ${NumberFormat('#,###').format(c.default_amount)}', style: const TextStyle(fontWeight: FontWeight.bold))
                    : const Text('Formula Base', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                ),
              );
            },
          );
  }

  void _viewStructureDetails(SalaryStructure s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Standard Earnings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const ListTile(dense: true, title: Text('Basic Salary'), trailing: Text('Base %')),
            const ListTile(dense: true, title: Text('House Allowance'), trailing: Text('Fixed KSh 5,000')),
            const ListTile(dense: true, title: Text('Transport Allowance'), trailing: Text('Fixed KSh 3,000')),
            const SizedBox(height: 16),
            const Text('Standard Deductions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const ListTile(dense: true, title: Text('PAYE'), trailing: Text('Tax Table')),
            const ListTile(dense: true, title: Text('NHIF/SHIF'), trailing: Text('2.75%')),
            const ListTile(dense: true, title: Text('NSSF'), trailing: Text('Tier I/II')),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
