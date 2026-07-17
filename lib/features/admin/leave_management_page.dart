import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/enterprise_models.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_provider.dart';

class LeaveManagementPage extends ConsumerStatefulWidget {
  const LeaveManagementPage({super.key});

  @override
  ConsumerState<LeaveManagementPage> createState() =>
      _LeaveManagementPageState();
}

class _LeaveManagementPageState extends ConsumerState<LeaveManagementPage> {
  final _dateFormat = DateFormat('dd MMM yyyy');
  List<StaffLeave> _leaves = [];
  Map<String, UserModel> _users = {};
  bool _loading = true;
  String _statusFilter = 'All';

  static const _leaveTypes = <_LeaveTypePolicy>[
    _LeaveTypePolicy('ANNUAL', 'Annual Leave', 30, true, false, Colors.green),
    _LeaveTypePolicy('SICK', 'Sick Leave', 14, true, true, Colors.red),
    _LeaveTypePolicy(
      'MATERNITY',
      'Maternity Leave',
      90,
      true,
      true,
      Colors.purple,
      accrues: false,
      accrualMethod: 'Full entitlement on approval',
    ),
    _LeaveTypePolicy(
      'PATERNITY',
      'Paternity Leave',
      14,
      true,
      false,
      Colors.indigo,
      accrues: false,
      accrualMethod: 'Full entitlement on approval',
    ),
    _LeaveTypePolicy(
        'COMPASSIONATE', 'Compassionate Leave', 7, true, false, Colors.teal),
    _LeaveTypePolicy('STUDY', 'Study Leave', 21, true, true, Colors.blue),
    _LeaveTypePolicy(
      'OFFICIAL_DUTY',
      'Official Duty',
      30,
      true,
      false,
      Colors.cyan,
      accrues: false,
      accrualMethod: 'Duty based',
    ),
    _LeaveTypePolicy(
      'UNPAID',
      'Unpaid Leave',
      30,
      false,
      false,
      Colors.orange,
      accrues: false,
      accrualMethod: 'Manager controlled',
    ),
    _LeaveTypePolicy(
        'EMERGENCY', 'Emergency Leave', 5, true, false, Colors.deepOrange),
    _LeaveTypePolicy(
        'HALF_DAY', 'Half Day Leave', 10, true, false, Colors.brown),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider);
    final users = await db.userDao.findAll();
    final isManager = _canApprove(user);
    final leaves = isManager
        ? await db.enterpriseDao.findAllLeaves()
        : await db.enterpriseDao.findLeavesByStaff(user?.id ?? '');

    if (!mounted) return;
    setState(() {
      _users = {for (final u in users) u.id: u};
      _leaves = leaves;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canApprove = _canApprove(user);
    final visibleLeaves = _statusFilter == 'All'
        ? _leaves
        : _leaves.where((leave) => leave.status == _statusFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(canApprove ? 'Institution Leave Management' : 'My Leave'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummary(canApprove),
                  const SizedBox(height: 16),
                  _buildBalances(user),
                  const SizedBox(height: 16),
                  if (canApprove) ...[
                    _buildPolicyGrid(),
                    const SizedBox(height: 16),
                  ],
                  _buildFilterBar(),
                  const SizedBox(height: 12),
                  if (visibleLeaves.isEmpty)
                    _EmptyLeaveState(canApprove: canApprove)
                  else
                    ...visibleLeaves
                        .map((leave) => _buildLeaveCard(leave, canApprove)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestDialog,
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Request Leave'),
      ),
    );
  }

  Widget _buildSummary(bool canApprove) {
    final pending = _leaves.where((l) => l.status == 'PENDING').length;
    final approved = _leaves.where((l) => l.status == 'APPROVED').length;
    final rejected = _leaves.where((l) => l.status == 'REJECTED').length;
    final today = DateTime.now();
    final awayToday = _leaves.where((l) {
      final start = DateTime.fromMillisecondsSinceEpoch(l.startDate);
      final end = DateTime.fromMillisecondsSinceEpoch(l.endDate);
      return l.status == 'APPROVED' &&
          !today.isBefore(_dayOnly(start)) &&
          !today.isAfter(_dayOnly(end));
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 760 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth > 760 ? 2.5 : 1.55,
          children: [
            _metric('Pending Approval', pending.toString(),
                Icons.pending_actions, Colors.orange),
            _metric(canApprove ? 'Approved Leaves' : 'My Approved',
                approved.toString(), Icons.verified_outlined, Colors.green),
            _metric('Rejected', rejected.toString(), Icons.cancel_outlined,
                Colors.red),
            _metric('Away Today', awayToday.toString(),
                Icons.event_busy_outlined, Colors.blue),
          ],
        );
      },
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalances(UserModel? user) {
    final staffId = user?.id;
    final annual = _policyFor('ANNUAL');
    final sick = _policyFor('SICK');
    final emergency = _policyFor('EMERGENCY');
    final annualUsed = _approvedDaysFor(staffId, annual.code);
    final sickUsed = _approvedDaysFor(staffId, sick.code);
    final emergencyUsed = _approvedDaysFor(staffId, emergency.code);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leave Balances',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _balanceRow(
              'Annual',
              annualUsed,
              annual.maxDays,
              _accruedAllowanceFor(annual),
              Colors.green,
            ),
            _balanceRow(
              'Sick',
              sickUsed,
              sick.maxDays,
              _accruedAllowanceFor(sick),
              Colors.red,
            ),
            _balanceRow(
              'Emergency',
              emergencyUsed,
              emergency.maxDays,
              _accruedAllowanceFor(emergency),
              Colors.deepOrange,
            ),
            Text(
              'Balances accrue monthly and reset each calendar year. Non-accrual leave types are controlled by HR policy.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceRow(
    String label,
    int used,
    int annualAllowance,
    int accruedAllowance,
    Color color,
  ) {
    final remaining = (accruedAllowance - used).clamp(0, annualAllowance);
    final percent = accruedAllowance == 0 ? 0.0 : used / accruedAllowance;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent.clamp(0, 1),
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 128,
            child: Text('$remaining left / $accruedAllowance accrued',
                textAlign: TextAlign.end, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyGrid() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leave Types & Policy',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _leaveTypes.map((type) {
                return Chip(
                  avatar: Icon(
                      type.paid ? Icons.payments_outlined : Icons.money_off,
                      size: 16,
                      color: type.color),
                  label: Text(
                      '${type.label} • ${type.maxDays}d • ${type.accrualMethod}'),
                  side: BorderSide(color: type.color.withValues(alpha: 0.25)),
                  backgroundColor: type.color.withValues(alpha: 0.06),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
            value: 'All',
            label: Text('All'),
            icon: Icon(Icons.list_alt_outlined)),
        ButtonSegment(
            value: 'PENDING',
            label: Text('Pending'),
            icon: Icon(Icons.pending_actions)),
        ButtonSegment(
            value: 'APPROVED',
            label: Text('Approved'),
            icon: Icon(Icons.verified_outlined)),
        ButtonSegment(
            value: 'REJECTED',
            label: Text('Rejected'),
            icon: Icon(Icons.cancel_outlined)),
      ],
      selected: {_statusFilter},
      onSelectionChanged: (value) =>
          setState(() => _statusFilter = value.first),
    );
  }

  Widget _buildLeaveCard(StaffLeave leave, bool canApprove) {
    final staff = _users[leave.staffId];
    final type = _policyFor(leave.leaveType);
    final days = _workingDays(
      DateTime.fromMillisecondsSinceEpoch(leave.startDate),
      DateTime.fromMillisecondsSinceEpoch(leave.endDate),
    );
    final statusColor = _statusColor(leave.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: type.color.withValues(alpha: 0.12),
          child: Icon(Icons.event_available_outlined, color: type.color),
        ),
        title: Text(staff?.name ?? 'Unknown staff',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${type.label} • ${_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(leave.startDate))} to ${_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(leave.endDate))}'),
        trailing: _statusBadge(leave.status),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _infoRow('Working days', '$days'),
                _infoRow(
                    'Payroll impact',
                    type.paid
                        ? 'Paid leave, salary unchanged'
                        : 'Unpaid leave, payroll deduction required'),
                _infoRow(
                    'Attachment',
                    type.requiresAttachment
                        ? 'Required before final HR filing'
                        : 'Not required'),
                _infoRow('Timetable check',
                    'Substitute teacher review required for affected lessons'),
                _infoRow('Reason', leave.reason),
                if (leave.approvedBy != null)
                  _infoRow('Actioned by', leave.approvedBy!),
                if (canApprove && leave.status == 'PENDING') ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _updateStatus(leave, 'REJECTED'),
                        icon: Icon(Icons.close, color: statusColor),
                        label: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _updateStatus(leave, 'APPROVED'),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Future<void> _updateStatus(StaffLeave leave, String status) async {
    final db = await ref.read(databaseProvider.future);
    final user = ref.read(currentUserProvider);
    await db.enterpriseDao.updateLeave(StaffLeave(
      id: leave.id,
      staffId: leave.staffId,
      leaveType: leave.leaveType,
      startDate: leave.startDate,
      endDate: leave.endDate,
      reason: leave.reason,
      status: status,
      approvedBy: user?.name ?? 'HR',
    ));
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Leave request $status.')));
  }

  void _showRequestDialog() {
    final reasonController = TextEditingController();
    var selectedType = _leaveTypes.first;
    var emergency = false;
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final days = startDate == null || endDate == null
              ? 0
              : _workingDays(startDate!, endDate!);
          final accrued = _accruedAllowanceFor(selectedType);
          final remaining = _availableDaysFor(
            ref.read(currentUserProvider)?.id,
            selectedType,
          );
          final hasConflict = _hasOverlappingLeave(startDate, endDate);
          final valid = startDate != null &&
              endDate != null &&
              !endDate!.isBefore(startDate!) &&
              days > 0 &&
              days <= remaining &&
              !hasConflict &&
              reasonController.text.trim().isNotEmpty;

          Future<void> pickDate(bool isStart) async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime(DateTime.now().year + 2),
              initialDate: isStart
                  ? (startDate ?? DateTime.now())
                  : (endDate ?? startDate ?? DateTime.now()),
            );
            if (picked == null) return;
            setDialogState(() {
              if (isStart) {
                startDate = picked;
                if (endDate != null && endDate!.isBefore(picked))
                  endDate = picked;
              } else {
                endDate = picked;
              }
            });
          }

          return AlertDialog(
            title: const Text('Request Leave'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<_LeaveTypePolicy>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Leave Type'),
                    items: _leaveTypes
                        .map((type) => DropdownMenuItem(
                            value: type, child: Text(type.label)))
                        .toList(),
                    onChanged: (value) => setDialogState(
                        () => selectedType = value ?? selectedType),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Emergency request'),
                    value: emergency,
                    onChanged: (value) =>
                        setDialogState(() => emergency = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickDate(true),
                          icon: const Icon(Icons.date_range),
                          label: Text(startDate == null
                              ? 'Start date'
                              : _dateFormat.format(startDate!)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickDate(false),
                          icon: const Icon(Icons.event),
                          label: Text(endDate == null
                              ? 'End date'
                              : _dateFormat.format(endDate!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Reason / duty handover notes'),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        _previewRow('Working days', '$days'),
                        _previewRow('Remaining balance', '$remaining days'),
                        _previewRow(
                            'Accrued entitlement', '$accrued days this year'),
                        _previewRow('Payroll',
                            selectedType.paid ? 'Paid' : 'Unpaid deduction'),
                        _previewRow(
                            'Accrual method', selectedType.accrualMethod),
                        _previewRow(
                            'Attachment',
                            selectedType.requiresAttachment
                                ? 'Required'
                                : 'Optional'),
                        _previewRow('Conflict check',
                            hasConflict ? 'Existing leave overlaps' : 'Clear'),
                        _previewRow(
                            'Approval flow',
                            emergency
                                ? 'HOD → Deputy → Headteacher → HR'
                                : 'HOD → Deputy → HR'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: valid
                    ? () async {
                        final db = await ref.read(databaseProvider.future);
                        final user = ref.read(currentUserProvider);
                        if (user == null) return;
                        await db.enterpriseDao.requestLeave(StaffLeave(
                          id: const Uuid().v4(),
                          staffId: user.id,
                          leaveType: selectedType.code,
                          startDate:
                              _dayOnly(startDate!).millisecondsSinceEpoch,
                          endDate: _dayOnly(endDate!).millisecondsSinceEpoch,
                          reason: reasonController.text.trim(),
                        ));
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _loadData();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Leave request submitted for approval.')));
                      }
                    : null,
                child: const Text('Submit Request'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  bool _canApprove(UserModel? user) {
    if (user == null) return false;
    return user.roleLevel <= AppConstants.roleHeadteacher ||
        user.roleLevel == AppConstants.roleAccountant ||
        user.hasFlag(AppConstants.flagHOD);
  }

  int _approvedDaysFor(String? staffId, String leaveType) {
    if (staffId == null) return 0;
    final currentYear = DateTime.now().year;
    return _leaves
        .where((leave) =>
            leave.staffId == staffId &&
            leave.leaveType == leaveType &&
            leave.status == 'APPROVED' &&
            DateTime.fromMillisecondsSinceEpoch(leave.startDate).year ==
                currentYear)
        .fold(0, (total, leave) {
      return total +
          _workingDays(
            DateTime.fromMillisecondsSinceEpoch(leave.startDate),
            DateTime.fromMillisecondsSinceEpoch(leave.endDate),
          );
    });
  }

  int _availableDaysFor(String? staffId, _LeaveTypePolicy policy) {
    final accrued = _accruedAllowanceFor(policy);
    final used = _approvedDaysFor(staffId, policy.code);
    return (accrued - used).clamp(0, policy.maxDays);
  }

  int _accruedAllowanceFor(_LeaveTypePolicy policy, {DateTime? asOf}) {
    if (!policy.accrues) return policy.maxDays;
    final date = asOf ?? DateTime.now();
    final rawAccrued = policy.maxDays * (date.month / 12);
    return rawAccrued.ceil().clamp(0, policy.maxDays);
  }

  bool _hasOverlappingLeave(DateTime? start, DateTime? end) {
    final user = ref.read(currentUserProvider);
    if (user == null || start == null || end == null) return false;
    final requestedStart = _dayOnly(start);
    final requestedEnd = _dayOnly(end);
    return _leaves.any((leave) {
      if (leave.staffId != user.id || leave.status == 'REJECTED') return false;
      final existingStart =
          DateTime.fromMillisecondsSinceEpoch(leave.startDate);
      final existingEnd = DateTime.fromMillisecondsSinceEpoch(leave.endDate);
      return !requestedEnd.isBefore(existingStart) &&
          !requestedStart.isAfter(existingEnd);
    });
  }

  int _workingDays(DateTime start, DateTime end) {
    if (end.isBefore(start)) return 0;
    var count = 0;
    var day = _dayOnly(start);
    final last = _dayOnly(end);
    while (!day.isAfter(last)) {
      if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday)
        count++;
      day = day.add(const Duration(days: 1));
    }
    return count;
  }

  DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  _LeaveTypePolicy _policyFor(String code) {
    return _leaveTypes.firstWhere(
      (type) => type.code == code,
      orElse: () => _leaveTypes.first,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

class _LeaveTypePolicy {
  final String code;
  final String label;
  final int maxDays;
  final bool paid;
  final bool requiresAttachment;
  final Color color;
  final bool accrues;
  final String accrualMethod;

  const _LeaveTypePolicy(
    this.code,
    this.label,
    this.maxDays,
    this.paid,
    this.requiresAttachment,
    this.color, {
    this.accrues = true,
    this.accrualMethod = 'Monthly accrual',
  });
}

class _EmptyLeaveState extends StatelessWidget {
  final bool canApprove;

  const _EmptyLeaveState({required this.canApprove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(canApprove
              ? 'No leave requests match this filter.'
              : 'You have not submitted leave requests yet.'),
        ],
      ),
    );
  }
}
