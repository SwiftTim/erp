// lib/features/hr/hr_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/operations_models.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
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

  static const _accent = Color(0xFFE11D48); // rose/pink

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
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
    final user = ref.watch(currentUserProvider);
    final openVac = _vacancies.where((v) => v.status == 'open').length;
    final openInc = _incidents.where((i) => i.status == 'open').length;

    return AppShell(
      title: 'HR Office',
      actions: [
        TextButton.icon(
          onPressed: () => PrintableDocumentHub.show(
              context, 'HR Office', DocumentTemplates.getTemplatesForModule('hr')),
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
                  _buildWelcomeCard(user, openVac, openInc),
                  const SizedBox(height: 24),
                  _buildStatsGrid(openVac, openInc),
                  const SizedBox(height: 24),
                  _buildTabSection(),
                ]),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(dynamic user, int openVac, int openInc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          Text(user?.name ?? 'HR Manager',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(children: [
            _miniStat('Active Vacancies', '$openVac'),
            const SizedBox(width: 32),
            _miniStat('Open Incidents', '$openInc'),
            const SizedBox(width: 32),
            _miniStat('Total Funds', '${_funds.length}'),
          ]),
        ]),
        Positioned(right: 0, top: 0,
          child: Icon(Icons.badge_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1))),
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

  Widget _buildStatsGrid(int openVac, int openInc) {
    final totalBalance = _funds.fold(0.0, (s, f) => s + f.balance);
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    return GridView.count(
      crossAxisCount: isDesktop ? 6 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
      children: [
        _statCard('Vacancies', '$openVac', Icons.work_outline, _accent),
        _statCard('Incidents', '$openInc', Icons.report_outlined, Colors.orange),
        _statCard('Welfare Funds', '${_funds.length}', Icons.savings_outlined, Colors.teal),
        _statCard('Total Welfare', 'KSh ${NumberFormat('#,###').format(totalBalance)}', Icons.account_balance_wallet_outlined, Colors.green),
        _statCard('Quarters Unit', '${_quarters.length}', Icons.house_outlined, Colors.blue),
        _statCard('Uploaded Docs', '${_documents.length}', Icons.folder_outlined, Colors.purple),
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
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildTabSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Operational Desk', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
              Tab(text: 'Quick Tools'),
              Tab(text: 'Recruitment'),
              Tab(text: 'Workforce Logs'),
              Tab(text: 'Welfare Funds'),
              Tab(text: 'Quarters Assign'),
            ],
          ),
          SizedBox(
            height: 480,
            child: TabBarView(controller: _tab, children: [
              _buildQuickToolsTab(),
              _buildRecruitmentTab(),
              _buildWorkforceTab(),
              _buildWelfareTab(),
              _buildQuartersTab(),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildQuickToolsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Administrative Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _toolCard(Icons.document_scanner_outlined, 'Upload Staff Document', 'TSC certifications, higher degrees, ID card copies', Colors.blue, _showUploadDocument),
        _toolCard(Icons.manage_accounts_outlined, 'Statutory Records', 'Register NSSF, SHA / SHIF, TSC numbers', Colors.teal, _showStatutoryRecord),
        _toolCard(Icons.warning_amber_outlined, 'Log Incident Report', 'Report discipline, payroll discrepancies, minor disputes', Colors.orange, _showLogIncident),
        _toolCard(Icons.house_outlined, 'Teacher Quarters Allocation', 'Manage staff residential spaces and check-ins', Colors.purple, _showAssignQuarter),
      ],
    );
  }

  Widget _toolCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecruitmentTab() {
    if (_vacancies.isEmpty) return const Center(child: Text('No vacancies posted.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _vacancies.length,
      itemBuilder: (_, i) {
        final v = _vacancies[i];
        final stageColor = v.status == 'filled' ? Colors.green : v.status == 'closed' ? Colors.grey : _accent;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: stageColor.withValues(alpha: 0.1), child: Icon(Icons.work_outline, color: stageColor, size: 18)),
            title: Text(v.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${v.grade} • ${v.department}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: stageColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(v.status.toUpperCase(), style: TextStyle(color: stageColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              if (v.status == 'open')
                IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20), onPressed: () => _fillVacancy(v)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildWorkforceTab() {
    if (_incidents.isEmpty) return const Center(child: Text('No workforce incidents recorded.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _incidents.length,
      itemBuilder: (_, i) {
        final inc = _incidents[i];
        final color = inc.status == 'resolved' ? Colors.green : inc.status == 'under_review' ? Colors.orange : Colors.red;
        final date = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(inc.created_at));
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ExpansionTile(
            leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.report_outlined, color: color, size: 18)),
            title: Text(inc.staff_name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${inc.type.toUpperCase()} • $date'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(inc.status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(inc.description, style: const TextStyle(fontSize: 13)),
                  if (inc.action_taken != null) ...[
                    const SizedBox(height: 8),
                    Text('Action Taken: ${inc.action_taken}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
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

  Widget _buildWelfareTab() {
    final totalBalance = _funds.fold(0.0, (s, f) => s + f.balance);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          elevation: 0, color: Colors.teal.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.savings_outlined, color: Colors.teal, size: 28),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Accumulated Welfare Reserves', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 12)),
                Text('KSh ${NumberFormat('#,###').format(totalBalance)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        ..._funds.map((f) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFCCFBF1), child: Icon(Icons.savings_outlined, color: Colors.teal, size: 18)),
            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Balance: KSh ${NumberFormat('#,###').format(f.balance)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              TextButton(onPressed: () => _addContribution(f, 'contribution'), child: const Text('Contribute')),
              TextButton(onPressed: () => _addContribution(f, 'payout'), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Payout')),
            ]),
          ),
        )),
      ],
    );
  }

  Widget _buildQuartersTab() {
    if (_quarters.isEmpty) return const Center(child: Text('No Quarter allocations.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _quarters.length,
      itemBuilder: (_, i) {
        final q = _quarters[i];
        final date = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(q.assigned_date));
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFEDE9FE), child: Icon(Icons.house_outlined, color: Colors.purple, size: 18)),
            title: Text(q.staff_name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Unit ${q.quarter_unit} • Allocation date: $date'),
          ),
        );
      },
    );
  }

  Widget? _buildFab() {
    final fns = [null, _showAddVacancy, _showLogIncident, _showAddFund, _showAssignQuarter];
    final labels = ['', 'New Vacancy', 'Log Incident', 'New Fund', 'Assign Quarter'];
    final icons = [null, Icons.work_outline, Icons.report_outlined, Icons.savings_outlined, Icons.house_outlined];
    final i = _tab.index;
    if (i == 0 || fns[i] == null) return null;
    return FloatingActionButton.extended(
      onPressed: fns[i], label: Text(labels[i]!),
      icon: Icon(icons[i]!), backgroundColor: _accent, foregroundColor: Colors.white,
    );
  }

  Future<void> _fillVacancy(JobVacancy v) async {
    final db = await ref.read(databaseProvider.future);
    await db.operationsDao.updateJobVacancy(JobVacancy(
      id: v.id, title: v.title, grade: v.grade, department: v.department,
      status: 'filled', budget_ref: v.budget_ref, created_at: v.created_at,
    ));
    _load();
  }

  Future<void> _showAddFund() async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Welfare Fund'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Fund Name (e.g. Welfare Kitty, Medical Support)'),
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
              if (mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('Create Fund'),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveIncident(WorkforceIncident inc) async {
    final actionCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Incident Case'),
        content: TextField(controller: actionCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Final Resolution Action')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.resolveWorkforceIncident(inc.id, 'resolved', actionCtrl.text.trim());
              Navigator.pop(ctx); _load();
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
        title: Text('${type == 'contribution' ? 'New Contribution' : 'Log Payout'} — ${fund.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Staff Name')),
          const SizedBox(height: 8),
          TextField(controller: amtCtrl, decoration: InputDecoration(labelText: 'Amount (KSh)', suffixText: type == 'payout' ? '(Deduction)' : null), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amtCtrl.text) ?? 0;
              if (amount <= 0 || nameCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertWelfareContribution(WelfareContribution(
                fund_id: fund.id, staff_id: const Uuid().v4(), staff_name: nameCtrl.text.trim(),
                amount: amount, type: type, date: DateTime.now().millisecondsSinceEpoch,
              ));
              final newBalance = type == 'contribution' ? fund.balance + amount : (fund.balance - amount).clamp(0, double.infinity);
              await db.operationsDao.updateWelfareFund(WelfareFund(id: fund.id, name: fund.name, balance: newBalance.toDouble(), created_at: fund.created_at));
              Navigator.pop(ctx); _load();
            },
            child: Text(type == 'contribution' ? 'Save' : 'Save Payout'),
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
          title: const Text('Create Job Vacancy'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
            const SizedBox(height: 8),
            TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Job Grade (e.g. D1)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: dept, decoration: const InputDecoration(labelText: 'Department'),
              items: ['Administration', 'Teaching', 'Catering', 'Security', 'Library', 'Fleet', 'Health', 'Finance'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
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
                  id: const Uuid().v4(), title: titleCtrl.text.trim(), grade: gradeCtrl.text.trim(),
                  department: dept, created_at: DateTime.now().millisecondsSinceEpoch,
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

  Future<void> _showLogIncident() async {
    final staffCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'misconduct';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Log Incident Report'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: staffCtrl, decoration: const InputDecoration(labelText: 'Accused/Concerned Staff Name')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: type, decoration: const InputDecoration(labelText: 'Accusation Level'),
              items: ['assault', 'misconduct', 'other'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
              onChanged: (t) => setS(() => type = t!),
            ),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Incident Description'), maxLines: 2),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (staffCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final user = ref.read(currentUserProvider);
                await db.operationsDao.insertWorkforceIncident(WorkforceIncident(
                  id: const Uuid().v4(), staff_id: const Uuid().v4(), staff_name: staffCtrl.text.trim(),
                  type: type, description: descCtrl.text.trim(), reported_by: user?.name ?? 'HR',
                  created_at: DateTime.now().millisecondsSinceEpoch,
                ));
                Navigator.pop(ctx); _load();
              },
              child: const Text('Report'),
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
          title: const Text('Upload Staff Document Reference'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: staffCtrl, decoration: const InputDecoration(labelText: 'Staff Name or ID')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: docType, decoration: const InputDecoration(labelText: 'Document Tag'),
              items: ['tsc', 'degree', 'good_conduct', 'id', 'nssf', 'sha', 'other'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
              onChanged: (t) => setS(() => docType = t!),
            ),
            const SizedBox(height: 8),
            TextField(controller: fileCtrl, decoration: const InputDecoration(labelText: 'Reference Detail / Doc Name')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (staffCtrl.text.isEmpty || fileCtrl.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final user = ref.read(currentUserProvider);
                await db.operationsDao.insertStaffDocument(StaffDocument(
                  id: const Uuid().v4(), staff_id: staffCtrl.text.trim(), doc_type: docType,
                  file_url: 'local://${fileCtrl.text.trim()}', file_name: fileCtrl.text.trim(),
                  uploaded_at: DateTime.now().millisecondsSinceEpoch, uploaded_by: user?.name ?? 'HR',
                ));
                Navigator.pop(ctx); _load();
              },
              child: const Text('Record Document'),
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
        title: const Text('Enter Statutory Registrations'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: staffCtrl, decoration: const InputDecoration(labelText: 'Staff National ID / Employee Code')),
            const SizedBox(height: 8),
            TextField(controller: nssfCtrl, decoration: const InputDecoration(labelText: 'NSSF Registration No')),
            const SizedBox(height: 8),
            TextField(controller: shaCtrl, decoration: const InputDecoration(labelText: 'SHA (SHIF) Unique No')),
            const SizedBox(height: 8),
            TextField(controller: tscCtrl, decoration: const InputDecoration(labelText: 'TSC No (If Teacher)')),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Official Corporate Email')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (staffCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertStaffStatutory(StaffStatutory(
                staff_id: staffCtrl.text.trim(), nssf_number: nssfCtrl.text.isEmpty ? null : nssfCtrl.text.trim(),
                sha_number: shaCtrl.text.isEmpty ? null : shaCtrl.text.trim(), tsc_number: tscCtrl.text.isEmpty ? null : tscCtrl.text.trim(),
                email: emailCtrl.text.isEmpty ? null : emailCtrl.text.trim(),
              ));
              Navigator.pop(ctx); _load();
            },
            child: const Text('Save Details'),
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
        title: const Text('Assign Resident Housing Unit'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Teacher / Staff Name')),
          const SizedBox(height: 8),
          TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Resident Unit Identifier (e.g. Unit 3B)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || unitCtrl.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.operationsDao.insertTeacherQuarter(TeacherQuarterAssignment(
                id: const Uuid().v4(), staff_id: const Uuid().v4(), staff_name: nameCtrl.text.trim(),
                quarter_unit: unitCtrl.text.trim(), assigned_date: DateTime.now().millisecondsSinceEpoch,
              ));
              Navigator.pop(ctx); _load();
            },
            child: const Text('Assign Block'),
          ),
        ],
      ),
    );
  }
}
