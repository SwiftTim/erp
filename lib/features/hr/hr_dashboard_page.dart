// lib/features/hr/hr_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../../core/constants/document_templates.dart';
import '../../core/widgets/printable_document_hub.dart';

class HrDashboardPage extends ConsumerStatefulWidget {
  const HrDashboardPage({super.key});
  @override
  ConsumerState<HrDashboardPage> createState() => _HrDashboardPageState();
}

class _HrDashboardPageState extends ConsumerState<HrDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<JobVacancy> _vacancies = [];
  List<StaffDocument> _documents = [];
  List<WorkforceIncident> _incidents = [];
  List<WelfareFund> _funds = [];
  List<TeacherQuarterAssignment> _quarters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider.future);
    final vac = await db.operationsDao.getAllVacancies();
    final docs = await db.operationsDao.getDocumentsForStaff('');
    final inc = await db.operationsDao.getAllWorkforceIncidents();
    final funds = await db.operationsDao.getAllWelfareFunds();
    final quarters = await db.operationsDao.getActiveQuarterAssignments();
    if (mounted) {
      setState(() {
        _vacancies = vac;
        _documents = docs;
        _incidents = inc;
        _funds = funds;
        _quarters = quarters;
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
        title: const Text('HR Office', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {
              PrintableDocumentHub.show(
                context,
                'Human Resources Office',
                DocumentTemplates.getTemplatesForModule('hr'),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFFE11D48)),
            label: const Text('Forms / Slips', style: TextStyle(color: Color(0xFFE11D48))),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFFE11D48),
          indicatorColor: const Color(0xFFE11D48),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Recruitment'),
            Tab(text: 'Workforce'),
            Tab(text: 'Welfare'),
            Tab(text: 'Quarters'),
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
                _buildRecruitment(),
                _buildWorkforce(),
                _buildWelfare(),
                _buildQuarters(),
              ],
            ),
    );
  }

  Widget? _buildFab() {
    final fns = [null, _showAddVacancy, _showLogIncident, _showAddFund, _showAssignQuarter];
    final labels = ['', 'New Vacancy', 'Log Incident', 'Add Fund', 'Assign Quarter'];
    final icons = [null, Icons.work_outline, Icons.report_outlined, Icons.savings_outlined, Icons.house_outlined];
    final i = _tab.index;
    if (i == 0 || fns[i] == null) return null;
    return FloatingActionButton.extended(
      onPressed: fns[i],
      label: Text(labels[i]),
      icon: Icon(icons[i]),
      backgroundColor: const Color(0xFFE11D48),
      foregroundColor: Colors.white,
    );
  }

  Widget _buildDashboard() {
    final openVac = _vacancies.where((v) => v.status == 'open').length;
    final openInc = _incidents.where((i) => i.status == 'open').length;
    final totalBalance = _funds.fold(0.0, (s, f) => s + f.balance);

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
            _statCard('Open Vacancies', '$openVac', Icons.work_outline, const Color(0xFFE11D48)),
            _statCard('Open Incidents', '$openInc', Icons.report_outlined, Colors.orange),
            _statCard('Welfare Funds', '${_funds.length}', Icons.savings_outlined, Colors.teal),
            _statCard('Welfare Balance', 'KSh ${NumberFormat('#,###').format(totalBalance)}', Icons.account_balance_wallet_outlined, Colors.green),
            _statCard('Staff Quarters', '${_quarters.length}', Icons.house_outlined, Colors.blue),
            _statCard('Staff Docs', '${_documents.length}', Icons.folder_outlined, Colors.purple),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Quick Tools',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _toolCard(Icons.document_scanner_outlined, 'Upload Staff Document',
            'TSC cert, degree, ID, NSSF, SHA…', Colors.blue, _showUploadDocument),
        _toolCard(Icons.manage_accounts_outlined, 'Statutory Records',
            'NSSF, SHA (SHIF), TSC numbers', Colors.teal, _showStatutoryRecord),
        _toolCard(Icons.warning_amber_outlined, 'Workforce Incidents',
            'Log assault / misconduct cases', Colors.orange, _showLogIncident),
        _toolCard(Icons.house_outlined, 'Teacher Quarters',
            'On-site accommodation assignments', Colors.purple, _showAssignQuarter),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _toolCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.2))),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecruitment() {
    if (_vacancies.isEmpty) {
      return const Center(child: Text('No vacancies posted.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vacancies.length,
      itemBuilder: (_, i) {
        final v = _vacancies[i];
        final stageColor = v.status == 'filled'
            ? Colors.green
            : v.status == 'closed'
                ? Colors.grey
                : const Color(0xFFE11D48);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: stageColor.withValues(alpha: 0.1),
              child: Icon(Icons.work_outline, color: stageColor),
            ),
            title: Text(v.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${v.grade} • ${v.department}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(v.status,
                    style: TextStyle(color: stageColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              if (v.status == 'open')
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  onPressed: () => _fillVacancy(v),
                ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildWorkforce() {
    if (_incidents.isEmpty) {
      return const Center(child: Text('No workforce incidents on record.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _incidents.length,
      itemBuilder: (_, i) {
        final inc = _incidents[i];
        final color = inc.status == 'resolved'
            ? Colors.green
            : inc.status == 'under_review'
                ? Colors.orange
                : Colors.red;
        final date = DateFormat('dd MMM yyyy').format(
            DateTime.fromMillisecondsSinceEpoch(inc.created_at));
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(Icons.report_outlined, color: color),
            ),
            title: Text(inc.staff_name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${inc.type.toUpperCase()} • $date'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(inc.status,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(inc.description),
                  if (inc.action_taken != null) ...[
                    const SizedBox(height: 8),
                    Text('Action: ${inc.action_taken}',
                        style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                  ],
                  if (inc.status == 'open') ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _resolveIncident(inc),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      child: const Text('Mark Resolved', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelfare() {
    final totalBalance = _funds.fold(0.0, (s, f) => s + f.balance);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: Colors.teal.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              const Icon(Icons.savings_outlined, color: Colors.teal, size: 32),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Welfare Balance',
                    style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                Text('KSh ${NumberFormat('#,###').format(totalBalance)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        ..._funds.map((f) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFCCFBF1),
              child: Icon(Icons.savings_outlined, color: Colors.teal),
            ),
            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Balance: KSh ${NumberFormat('#,###').format(f.balance)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              TextButton(onPressed: () => _addContribution(f, 'contribution'), child: const Text('Contribute')),
              TextButton(
                onPressed: () => _addContribution(f, 'payout'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Payout'),
              ),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _buildQuarters() {
    if (_quarters.isEmpty) {
      return const Center(child: Text('No quarter assignments.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quarters.length,
      itemBuilder: (_, i) {
        final q = _quarters[i];
        final date = DateFormat('dd MMM yyyy')
            .format(DateTime.fromMillisecondsSinceEpoch(q.assigned_date));
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEDE9FE),
              child: Icon(Icons.house_outlined, color: Colors.purple),
            ),
            title: Text(q.staff_name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Unit ${q.quarter_unit} • Since $date'),
          ),
        );
      },
    );
  }

  Future<void> _fillVacancy(JobVacancy v) async {
    final db = await ref.read(databaseProvider.future);
    await db.operationsDao.updateJobVacancy(JobVacancy(
      id: v.id,
      title: v.title,
      grade: v.grade,
      department: v.department,
      status: 'filled',
      budget_ref: v.budget_ref,
      created_at: v.created_at,
    ));
    _load();
  }

  Future<void> _resolveIncident(WorkforceIncident inc) async {
    final actionCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Incident'),
        content: TextField(
          controller: actionCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Action Taken'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.resolveWorkforceIncident(
                  inc.id, 'resolved', actionCtrl.text.trim());
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Future<void> _addContribution(WelfareFund fund, String type) async {
    final amtCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${type == 'contribution' ? 'Add Contribution' : 'Record Payout'} — ${fund.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Staff Name')),
          const SizedBox(height: 8),
          TextField(controller: amtCtrl, decoration: InputDecoration(labelText: 'Amount (KSh)', suffixText: type == 'payout' ? '(deducted)' : null), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amtCtrl.text) ?? 0;
              if (amount <= 0 || nameCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertWelfareContribution(WelfareContribution(
                fund_id: fund.id,
                staff_id: const Uuid().v4(),
                staff_name: nameCtrl.text.trim(),
                amount: amount,
                type: type,
                date: DateTime.now().millisecondsSinceEpoch,
              ));
              final newBalance = type == 'contribution'
                  ? fund.balance + amount
                  : (fund.balance - amount).clamp(0, double.infinity);
              await db.operationsDao.updateWelfareFund(WelfareFund(
                id: fund.id,
                name: fund.name,
                balance: newBalance.toDouble(),
                created_at: fund.created_at,
              ));
              Navigator.pop(ctx);
              _load();
            },
            child: Text(type == 'contribution' ? 'Add' : 'Record Payout'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddVacancy() async {
    final titleCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    String dept = 'Administration';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Post New Vacancy'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
            const SizedBox(height: 8),
            TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Job Grade')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: dept,
              decoration: const InputDecoration(labelText: 'Department'),
              items: ['Administration', 'Teaching', 'Catering', 'Security', 'Library', 'Fleet', 'Health', 'Finance']
                  .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (d) => setS(() => dept = d!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                await db.operationsDao.insertJobVacancy(JobVacancy(
                  id: const Uuid().v4(),
                  title: titleCtrl.text.trim(),
                  grade: gradeCtrl.text.trim(),
                  department: dept,
                  created_at: DateTime.now().millisecondsSinceEpoch,
                ));
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogIncident() async {
    final staffCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'misconduct';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Log Workforce Incident'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: staffCtrl, decoration: const InputDecoration(labelText: 'Staff Name')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Incident Type'),
              items: ['assault', 'misconduct', 'other']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                  .toList(),
              onChanged: (t) => setS(() => type = t!),
            ),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (staffCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final user = ref.read(currentUserProvider);
                await db.operationsDao.insertWorkforceIncident(WorkforceIncident(
                  id: const Uuid().v4(),
                  staff_id: const Uuid().v4(),
                  staff_name: staffCtrl.text.trim(),
                  type: type,
                  description: descCtrl.text.trim(),
                  reported_by: user?.name ?? 'HR',
                  created_at: DateTime.now().millisecondsSinceEpoch,
                ));
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUploadDocument() async {
    final staffCtrl = TextEditingController();
    final fileCtrl = TextEditingController();
    String docType = 'tsc';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Upload Staff Document'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: staffCtrl, decoration: const InputDecoration(labelText: 'Staff Name/ID')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: docType,
              decoration: const InputDecoration(labelText: 'Document Type'),
              items: ['tsc', 'degree', 'good_conduct', 'id', 'nssf', 'sha', 'other']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                  .toList(),
              onChanged: (t) => setS(() => docType = t!),
            ),
            const SizedBox(height: 8),
            TextField(controller: fileCtrl, decoration: const InputDecoration(labelText: 'File Name / Reference')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (staffCtrl.text.isEmpty || fileCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final user = ref.read(currentUserProvider);
                await db.operationsDao.insertStaffDocument(StaffDocument(
                  id: const Uuid().v4(),
                  staff_id: staffCtrl.text.trim(),
                  doc_type: docType,
                  file_url: 'local://${fileCtrl.text.trim()}',
                  file_name: fileCtrl.text.trim(),
                  uploaded_at: DateTime.now().millisecondsSinceEpoch,
                  uploaded_by: user?.name ?? 'HR',
                ));
                Navigator.pop(ctx);
                _load();
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStatutoryRecord() async {
    final staffCtrl = TextEditingController();
    final nssfCtrl = TextEditingController();
    final shaCtrl = TextEditingController();
    final tscCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Statutory Details'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: staffCtrl, decoration: const InputDecoration(labelText: 'Staff ID')),
            const SizedBox(height: 8),
            TextField(controller: nssfCtrl, decoration: const InputDecoration(labelText: 'NSSF Number')),
            const SizedBox(height: 8),
            TextField(controller: shaCtrl, decoration: const InputDecoration(labelText: 'SHA (SHIF) Number')),
            const SizedBox(height: 8),
            TextField(controller: tscCtrl, decoration: const InputDecoration(labelText: 'TSC Number')),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'School Email')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (staffCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertStaffStatutory(StaffStatutory(
                staff_id: staffCtrl.text.trim(),
                nssf_number: nssfCtrl.text.isEmpty ? null : nssfCtrl.text.trim(),
                sha_number: shaCtrl.text.isEmpty ? null : shaCtrl.text.trim(),
                tsc_number: tscCtrl.text.isEmpty ? null : tscCtrl.text.trim(),
                email: emailCtrl.text.isEmpty ? null : emailCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFund() async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Welfare Fund'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Fund Name (e.g. Funeral Kitty)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertWelfareFund(WelfareFund(
                id: const Uuid().v4(),
                name: nameCtrl.text.trim(),
                created_at: DateTime.now().millisecondsSinceEpoch,
              ));
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignQuarter() async {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Teacher Quarter'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Staff Name')),
          const SizedBox(height: 8),
          TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Quarter Unit (e.g. QA-01)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || unitCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertTeacherQuarter(TeacherQuarterAssignment(
                id: const Uuid().v4(),
                staff_id: const Uuid().v4(),
                staff_name: nameCtrl.text.trim(),
                quarter_unit: unitCtrl.text.trim(),
                assigned_date: DateTime.now().millisecondsSinceEpoch,
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
}
