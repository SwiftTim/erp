// lib/features/departments/widgets/dept_module_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/department_activity_model.dart';
import '../../../features/auth/auth_provider.dart';
import 'dept_upload_button.dart';

/// Config for one module (e.g. "Reading Fluency Tracker")
class ModuleConfig {
  final String moduleType;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<ModuleField> fields;

  const ModuleConfig({
    required this.moduleType,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.fields = const [],
  });
}

/// A single field in a module entry form
class ModuleField {
  final String key;
  final String label;
  final ModuleFieldType type;
  final List<String>? options;

  const ModuleField({
    required this.key,
    required this.label,
    this.type = ModuleFieldType.text,
    this.options,
  });
}

enum ModuleFieldType { text, multiline, dropdown, number, upload, date }

/// Renders the list of activities for a module + FAB to add new entry
class DeptModulePanel extends ConsumerStatefulWidget {
  final String deptId;
  final ModuleConfig config;
  final List<DeptActivity> activities;
  final bool isHod;
  final Future<void> Function(DeptActivity) onAdd;
  final Future<void> Function(DeptActivity) onUpdateStatus;

  const DeptModulePanel({
    super.key,
    required this.deptId,
    required this.config,
    required this.activities,
    required this.isHod,
    required this.onAdd,
    required this.onUpdateStatus,
  });

  @override
  ConsumerState<DeptModulePanel> createState() => _DeptModulePanelState();
}

class _DeptModulePanelState extends ConsumerState<DeptModulePanel> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.config.color.withOpacity(0.06),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.config.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.config.icon, color: widget.config.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.config.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(widget.config.description,
                        style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _adding ? null : _showAddDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.config.color,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // -- Activity list
        if (widget.activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 32),
                const SizedBox(height: 8),
                Text('No ${widget.config.title} records yet.',
                    style: const TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.activities.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final a = widget.activities[index];
                final date = DateFormat('MMM d, y').format(
                    DateTime.fromMillisecondsSinceEpoch(a.recordedAt));
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(a.status).withOpacity(0.1),
                    radius: 18,
                    child: Icon(_statusIcon(a.status),
                        color: _statusColor(a.status), size: 16),
                  ),
                  title: Text(a.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('${a.grade ?? ''} • $date',
                      style: const TextStyle(fontSize: 11)),
                  trailing: widget.isHod
                      ? _StatusDropdown(
                          current: a.status,
                          onChanged: (s) => widget.onUpdateStatus(
                            DeptActivity(
                              id: a.id,
                              departmentId: a.departmentId,
                              moduleType: a.moduleType,
                              title: a.title,
                              data: a.data,
                              recordedBy: a.recordedBy,
                              recordedAt: a.recordedAt,
                              status: s,
                              grade: a.grade,
                              subject: a.subject,
                            ),
                          ),
                        )
                      : _StatusBadge(status: a.status),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{};
    final dropdownValues = <String, String>{};
    String? pickedFile;
    String? pickedFileName;
    final gradeCtrl = TextEditingController();

    for (final f in widget.config.fields) {
      if (f.type != ModuleFieldType.upload && f.type != ModuleFieldType.dropdown) {
        controllers[f.key] = TextEditingController();
      }
      if (f.type == ModuleFieldType.dropdown && (f.options?.isNotEmpty ?? false)) {
        dropdownValues[f.key] = f.options!.first;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Icon(widget.config.icon, color: widget.config.color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Add ${widget.config.title}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ]),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grade filter
                    TextFormField(
                      controller: gradeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Grade / Class (optional)',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dynamic fields
                    ...widget.config.fields.map((field) {
                      switch (field.type) {
                        case ModuleFieldType.text:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: controllers[field.key],
                              decoration: InputDecoration(labelText: field.label),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          );

                        case ModuleFieldType.multiline:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: controllers[field.key],
                              decoration: InputDecoration(labelText: field.label),
                              maxLines: 3,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          );

                        case ModuleFieldType.number:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: controllers[field.key],
                              decoration: InputDecoration(labelText: field.label),
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          );

                        case ModuleFieldType.dropdown:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<String>(
                              value: dropdownValues[field.key],
                              decoration: InputDecoration(labelText: field.label),
                              items: field.options!
                                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                                  .toList(),
                              onChanged: (v) => setDialogState(
                                  () => dropdownValues[field.key] = v!),
                            ),
                          );

                        case ModuleFieldType.upload:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(field.label,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 6),
                                DeptUploadButton(
                                  label: 'Upload File',
                                  onFilePicked: (name, path) {
                                    setDialogState(() {
                                      pickedFileName = name;
                                      pickedFile = path;
                                    });
                                  },
                                ),
                              ],
                            ),
                          );

                        case ModuleFieldType.date:
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: controllers[field.key],
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: field.label,
                                suffixIcon: const Icon(Icons.calendar_today_outlined),
                              ),
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: ctx,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) {
                                  controllers[field.key]!.text =
                                      DateFormat('dd MMM yyyy').format(d);
                                }
                              },
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          );
                      }
                    }),

                    // Upload section at bottom
                    if (pickedFileName != null)
                      Chip(
                        avatar: const Icon(Icons.attach_file, size: 14),
                        label: Text(pickedFileName!,
                            style: const TextStyle(fontSize: 11)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () =>
                            setDialogState(() {
                              pickedFile = null;
                              pickedFileName = null;
                            }),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: widget.config.color),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => _adding = true);
                Navigator.pop(ctx);

                // Build data JSON from fields
                final dataMap = <String, String>{};
                controllers.forEach(
                    (k, c) => dataMap[k] = c.text.trim());
                dropdownValues.forEach(
                    (k, v) => dataMap[k] = v);
                if (pickedFile != null)
                  dataMap['file_path'] = pickedFile!;
                if (pickedFileName != null)
                  dataMap['file_name'] = pickedFileName!;

                final user = ref.read(currentUserProvider);
                final activity = DeptActivity(
                  departmentId: widget.deptId,
                  moduleType: widget.config.moduleType,
                  title: controllers.values.firstOrNull?.text.trim() ??
                      widget.config.title,
                  data: dataMap.entries
                      .map((e) => '"${e.key}":"${e.value}"')
                      .join(',')
                      .let((s) => '{$s}'),
                  recordedBy: user?.id ?? 'unknown',
                  recordedAt: DateTime.now().millisecondsSinceEpoch,
                  grade: gradeCtrl.text.isEmpty ? null : gradeCtrl.text.trim(),
                );

                await widget.onAdd(activity);
                setState(() => _adding = false);
              },
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return Colors.green;
      case 'flagged': return Colors.red;
      case 'in_progress': return Colors.orange;
      default: return Colors.blue;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed': return Icons.check_circle_outline;
      case 'flagged': return Icons.flag_outlined;
      case 'in_progress': return Icons.timelapse_outlined;
      default: return Icons.radio_button_unchecked;
    }
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

class _StatusDropdown extends StatelessWidget {
  final String current;
  final void Function(String) onChanged;
  const _StatusDropdown({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: current,
      underline: const SizedBox(),
      isDense: true,
      items: ['open', 'in_progress', 'completed', 'flagged']
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: const TextStyle(fontSize: 11)),
              ))
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final col = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.withOpacity(0.3)),
      ),
      child: Text(status.replaceAll('_', ' '),
          style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.w600)),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'completed': return Colors.green;
      case 'flagged': return Colors.red;
      case 'in_progress': return Colors.orange;
      default: return Colors.blue;
    }
  }
}
