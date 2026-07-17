// lib/features/finance/finance_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class FinanceSettingsPage extends ConsumerStatefulWidget {
  const FinanceSettingsPage({super.key});

  @override
  ConsumerState<FinanceSettingsPage> createState() => _FinanceSettingsPageState();
}

class _FinanceSettingsPageState extends ConsumerState<FinanceSettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // General Settings
  String _payrollFrequency = 'Monthly';
  final _paymentDayController = TextEditingController(text: '30');
  final _workingDaysController = TextEditingController(text: '22');

  // Bank Management Data
  final List<Map<String, dynamic>> _banks = [
    {'bank': 'Equity Bank', 'branch': 'Corporate', 'code': '68', 'active': true},
    {'bank': 'KCB Bank', 'branch': 'Nairobi Main', 'code': '01', 'active': true},
    {'bank': 'Co-operative Bank', 'branch': 'Nairobi Central', 'code': '11', 'active': true},
    {'bank': 'NCBA', 'branch': 'Harambee Avenue', 'code': '07', 'active': true},
    {'bank': 'Absa Bank', 'branch': 'Corporate', 'code': '03', 'active': true},
  ];

  // Job Group Data
  final List<Map<String, dynamic>> _jobGroups = [
    {'group': 'JG-A', 'category': 'Support Staff', 'basic': 25000.0, 'house': 4000.0, 'transport': 2000.0, 'medical': 1000.0, 'employees': 4},
    {'group': 'JG-B', 'category': 'Teacher', 'basic': 45000.0, 'house': 6000.0, 'transport': 3000.0, 'medical': 2000.0, 'employees': 15},
    {'group': 'JG-C', 'category': 'Senior Teacher', 'basic': 62000.0, 'house': 8000.0, 'transport': 4000.0, 'medical': 3000.0, 'employees': 2},
    {'group': 'JG-D', 'category': 'Deputy Headteacher', 'basic': 78000.0, 'house': 10000.0, 'transport': 5000.0, 'medical': 5000.0, 'employees': 1},
    {'group': 'JG-E', 'category': 'Headteacher', 'basic': 95000.0, 'house': 12000.0, 'transport': 6000.0, 'medical': 5000.0, 'employees': 1},
  ];

  // Progressive PAYE Tax Bands
  final List<Map<String, dynamic>> _payeBands = [
    {'from': 0, 'to': 24000, 'tax': 10.0},
    {'from': 24001, 'to': 32333, 'tax': 25.0},
    {'from': 32334, 'to': 500000, 'tax': 30.0},
    {'from': 500001, 'to': 800000, 'tax': 32.5},
    {'from': 800001, 'to': 999999999, 'tax': 35.0},
  ];

  // Statutory Deduction Rates
  double _nssfRate = 6.0;
  double _nssfMaxPensionable = 72000.0;
  double _shifRate = 2.75;
  double _housingLevyRate = 1.5;

  // Formula Builder States
  String _formulaName = 'Housing Levy';
  String _formulaVar1 = 'Basic Salary';
  String _formulaOp = '×';
  double _formulaVal = 1.5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentDayController.dispose();
    _workingDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll & Statutory Settings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Job Groups'),
            Tab(text: 'Tax Rules (PAYE)'),
            Tab(text: 'Statutory Deductions'),
            Tab(text: 'Bank Management'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildJobGroupsTab(),
          _buildTaxRulesTab(),
          _buildStatutoryDeductionsTab(),
          _buildBankManagementTab(),
        ],
      ),
    );
  }

  // 1. General Tab
  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('General Payroll Rules'),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _payrollFrequency,
                    decoration: const InputDecoration(
                      labelText: 'Payroll Frequency',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'Biweekly', child: Text('Biweekly')),
                      DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _payrollFrequency = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _paymentDayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Salary Payment Day (of Month)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.today),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _workingDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Default Working Days',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: 'KES',
                    decoration: const InputDecoration(
                      labelText: 'Base Currency',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'KES', child: Text('Kenyan Shilling (KES)')),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('General settings saved successfully')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Save General Settings'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              )
            ],
          )
        ],
      ),
    );
  }

  // 2. Job Groups Tab
  Widget _buildJobGroupsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader('Job Group Templates'),
              ElevatedButton.icon(
                onPressed: _showAddJobGroupDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Job Group'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.green.withValues(alpha: 0.05)),
                columns: const [
                  DataColumn(label: Text('Job Group')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Basic Salary (KSh)')),
                  DataColumn(label: Text('House Allowance')),
                  DataColumn(label: Text('Transport')),
                  DataColumn(label: Text('Medical')),
                  DataColumn(label: Text('Employees Assigned')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _jobGroups.map((jg) {
                  return DataRow(cells: [
                    DataCell(Text(jg['group'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(jg['category'])),
                    DataCell(Text(NumberFormat('#,###').format(jg['basic']))),
                    DataCell(Text(NumberFormat('#,###').format(jg['house']))),
                    DataCell(Text(NumberFormat('#,###').format(jg['transport']))),
                    DataCell(Text(NumberFormat('#,###').format(jg['medical']))),
                    DataCell(Text(jg['employees'].toString())),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () => _showEditJobGroupDialog(jg),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              _jobGroups.remove(jg);
                            });
                          },
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Tax Rules (PAYE Form / Bands Builder)
  Widget _buildTaxRulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader('P.A.Y.E. Progressive Tax Bands'),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _payeBands.add({'from': 0, 'to': 0, 'tax': 0.0});
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Band'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Allows dynamic modification of Kenya Revenue Authority (KRA) progressive income tax brackets. Adjust bands as tax codes change.',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _payeBands.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final band = _payeBands[index];
                final fromController = TextEditingController(text: band['from'].toString());
                final toController = TextEditingController(text: band['to'] == 999999999 ? 'Above' : band['to'].toString());
                final taxController = TextEditingController(text: band['tax'].toString());

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text('Band ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Text('From KSh: '),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: fromController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          onChanged: (val) {
                            band['from'] = int.tryParse(val) ?? 0;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('To KSh: '),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: toController,
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          onChanged: (val) {
                            if (val.trim().toLowerCase() == 'above' || val.trim() == '∞') {
                              band['to'] = 999999999;
                            } else {
                              band['to'] = int.tryParse(val) ?? 999999999;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Tax Rate: '),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: taxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(suffixText: '%', isDense: true, border: OutlineInputBorder()),
                          onChanged: (val) {
                            band['tax'] = double.tryParse(val) ?? 0.0;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _payeBands.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tax brackets updated successfully')),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Save Tax Config'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              )
            ],
          )
        ],
      ),
    );
  }

  // 4. Statutory Deductions Tab & Formula Builder
  Widget _buildStatutoryDeductionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Statutory Deduction Settings'),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Standard Formulas & Rates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(height: 24),
                        _buildDeductionConfigRow('NSSF (Social Security)', _nssfRate, 'Percentage (Employer/Employee 6%)', (val) {
                          setState(() => _nssfRate = val);
                        }),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SizedBox(width: 240, child: Text('NSSF Max Pensionable Salary (KSh)')),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                controller: TextEditingController(text: _nssfMaxPensionable.toStringAsFixed(0)),
                                onChanged: (val) {
                                  _nssfMaxPensionable = double.tryParse(val) ?? 72000.0;
                                },
                              ),
                            )
                          ],
                        ),
                        const Divider(height: 32),
                        _buildDeductionConfigRow('SHIF (Health Insurance)', _shifRate, 'Percentage of Gross Salary (2.75%)', (val) {
                          setState(() => _shifRate = val);
                        }),
                        const Divider(height: 32),
                        _buildDeductionConfigRow('Housing Levy', _housingLevyRate, 'Employer 1.5% / Employee 1.5%', (val) {
                          setState(() => _housingLevyRate = val);
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Card(
                  color: Colors.blue.withValues(alpha: 0.02),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.withValues(alpha: 0.1))),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.build_outlined, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Graphical Formula Builder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text(
                          'Configure dynamic allowances or deductions visually without writing code.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _formulaName,
                          decoration: const InputDecoration(labelText: 'Target Deduction/Allowance', isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'Housing Levy', child: Text('Housing Levy')),
                            DropdownMenuItem(value: 'Medical Insurance', child: Text('Medical Insurance')),
                            DropdownMenuItem(value: 'Transport Allowance', child: Text('Transport Allowance')),
                            DropdownMenuItem(value: 'Pension Saving', child: Text('Pension Saving')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _formulaName = val;
                                if (val == 'Medical Insurance') {
                                  _formulaVar1 = 'Gross Salary';
                                  _formulaOp = '×';
                                  _formulaVal = 2.5;
                                } else if (val == 'Transport Allowance') {
                                  _formulaVar1 = 'Fixed';
                                  _formulaOp = '+';
                                  _formulaVal = 4000;
                                } else if (val == 'Pension Saving') {
                                  _formulaVar1 = 'Basic Salary';
                                  _formulaOp = '×';
                                  _formulaVal = 5.0;
                                } else {
                                  _formulaVar1 = 'Basic Salary';
                                  _formulaOp = '×';
                                  _formulaVal = 1.5;
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Formula Structure:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _pillWidget(_formulaVar1),
                                  const SizedBox(width: 8),
                                  _pillWidget(_formulaOp, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  _pillWidget(_formulaVal.toString(), color: Colors.teal),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _formulaVar1,
                                decoration: const InputDecoration(labelText: 'Variable', isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'Basic Salary', child: Text('Basic')),
                                  DropdownMenuItem(value: 'Gross Salary', child: Text('Gross')),
                                  DropdownMenuItem(value: 'Fixed', child: Text('Fixed')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _formulaVar1 = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: DropdownButtonFormField<String>(
                                value: _formulaOp,
                                decoration: const InputDecoration(labelText: 'Op', isDense: true),
                                items: const [
                                  DropdownMenuItem(value: '×', child: Text('×')),
                                  DropdownMenuItem(value: '+', child: Text('+')),
                                  DropdownMenuItem(value: '-', child: Text('-')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _formulaOp = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Val', isDense: true),
                                initialValue: _formulaVal.toString(),
                                onChanged: (val) {
                                  setState(() {
                                    _formulaVal = double.tryParse(val) ?? 0.0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Formula for $_formulaName saved successfully!')),
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Save Formula'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All deductions and rules saved.')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Save & Apply Rules'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _pillWidget(String label, {Color color = Colors.blue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildDeductionConfigRow(String label, double percentage, String formulaDesc, Function(double) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(formulaDesc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(suffixText: '%', isDense: true, border: OutlineInputBorder()),
            controller: TextEditingController(text: percentage.toString()),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null) onChanged(parsed);
            },
          ),
        ),
      ],
    );
  }

  // 5. Bank Management Tab
  Widget _buildBankManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader('Disbursement Banks'),
              ElevatedButton.icon(
                onPressed: _showAddBankDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Bank'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _banks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final b = _banks[index];
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.account_balance, color: Colors.white)),
                  title: Text(b['bank'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Branch: ${b['branch']} • Code: ${b['code']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: b['active'],
                        onChanged: (val) {
                          setState(() {
                            b['active'] = val;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditBankDialog(b),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  // Dialog Boxes
  void _showAddJobGroupDialog() {
    final groupC = TextEditingController();
    final catC = TextEditingController();
    final basicC = TextEditingController();
    final houseC = TextEditingController();
    final transC = TextEditingController();
    final medC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Job Group Template'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: groupC, decoration: const InputDecoration(labelText: 'Job Group Code (e.g. JG-F)')),
              TextField(controller: catC, decoration: const InputDecoration(labelText: 'Category/Position')),
              TextField(controller: basicC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Basic Salary (KSh)')),
              TextField(controller: houseC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'House Allowance')),
              TextField(controller: transC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Transport Allowance')),
              TextField(controller: medC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Medical Allowance')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _jobGroups.add({
                  'group': groupC.text.trim().toUpperCase(),
                  'category': catC.text.trim(),
                  'basic': double.tryParse(basicC.text) ?? 0.0,
                  'house': double.tryParse(houseC.text) ?? 0.0,
                  'transport': double.tryParse(transC.text) ?? 0.0,
                  'medical': double.tryParse(medC.text) ?? 0.0,
                  'employees': 0,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Save Template'),
          )
        ],
      ),
    );
  }

  void _showEditJobGroupDialog(Map<String, dynamic> jg) {
    final basicC = TextEditingController(text: jg['basic'].toString());
    final houseC = TextEditingController(text: jg['house'].toString());
    final transC = TextEditingController(text: jg['transport'].toString());
    final medC = TextEditingController(text: jg['medical'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Job Group ${jg['group']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: basicC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Basic Salary (KSh)')),
              TextField(controller: houseC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'House Allowance')),
              TextField(controller: transC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Transport Allowance')),
              TextField(controller: medC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Medical Allowance')),
              const SizedBox(height: 12),
              const Text('This is simply a template. Future employee assignments will use these default templates. Existing employees will not be overridden immediately.',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                jg['basic'] = double.tryParse(basicC.text) ?? jg['basic'];
                jg['house'] = double.tryParse(houseC.text) ?? jg['house'];
                jg['transport'] = double.tryParse(transC.text) ?? jg['transport'];
                jg['medical'] = double.tryParse(medC.text) ?? jg['medical'];
              });
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          )
        ],
      ),
    );
  }

  void _showAddBankDialog() {
    final nameC = TextEditingController();
    final branchC = TextEditingController();
    final codeC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Disbursement Bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Bank Name')),
            TextField(controller: branchC, decoration: const InputDecoration(labelText: 'Branch Name')),
            TextField(controller: codeC, decoration: const InputDecoration(labelText: 'Clearing Bank Code')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _banks.add({
                  'bank': nameC.text.trim(),
                  'branch': branchC.text.trim(),
                  'code': codeC.text.trim(),
                  'active': true,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add Bank'),
          )
        ],
      ),
    );
  }

  void _showEditBankDialog(Map<String, dynamic> b) {
    final nameC = TextEditingController(text: b['bank']);
    final branchC = TextEditingController(text: b['branch']);
    final codeC = TextEditingController(text: b['code']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Disbursement Bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Bank Name')),
            TextField(controller: branchC, decoration: const InputDecoration(labelText: 'Branch Name')),
            TextField(controller: codeC, decoration: const InputDecoration(labelText: 'Clearing Bank Code')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                b['bank'] = nameC.text.trim();
                b['branch'] = branchC.text.trim();
                b['code'] = codeC.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          )
        ],
      ),
    );
  }
}
