// lib/core/widgets/printable_document_hub.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/pdf_generator.dart';

class FormTemplate {
  final String title;
  final String description;
  final Map<String, String> defaultFields;

  FormTemplate({
    required this.title,
    required this.description,
    required this.defaultFields,
  });
}

class PrintableDocumentHub extends StatefulWidget {
  final String moduleName;
  final List<FormTemplate> templates;

  const PrintableDocumentHub({
    super.key,
    required this.moduleName,
    required this.templates,
  });

  static void show(BuildContext context, String moduleName, List<FormTemplate> templates) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => PrintableDocumentHub(
        moduleName: moduleName,
        templates: templates,
      ),
    );
  }

  @override
  State<PrintableDocumentHub> createState() => _PrintableDocumentHubState();
}

class _PrintableDocumentHubState extends State<PrintableDocumentHub> {
  FormTemplate? _selectedTemplate;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.templates.isNotEmpty) {
      _selectTemplate(widget.templates.first);
    }
  }

  void _selectTemplate(FormTemplate t) {
    setState(() {
      _selectedTemplate = t;
      _controllers.clear();
      t.defaultFields.forEach((key, val) {
        _controllers[key] = TextEditingController(text: val);
      });
    });
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final template = _selectedTemplate;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.moduleName} Document Registry',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Select, customize, and spool institutions forms/slips',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Template List
                    Container(
                      width: 250,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: widget.templates.length,
                        itemBuilder: (ctx, i) {
                          final t = widget.templates[i];
                          final isSelected = t == _selectedTemplate;
                          return InkWell(
                            onTap: () => _selectTemplate(t),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                      color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.description,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Editor Form
                    Expanded(
                      child: template == null
                          ? const Center(child: Text('Please select a template'))
                          : ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            template.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            template.description,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FilledButton.icon(
                                      onPressed: _spoolDocument,
                                      icon: const Icon(Icons.print_outlined, size: 16),
                                      label: const Text('Print / Export'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),
                                const Text(
                                  'Form Data Customization Fields',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ...template.defaultFields.keys.map((key) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: TextField(
                                      controller: _controllers[key],
                                      decoration: InputDecoration(
                                        labelText: key.toUpperCase().replaceAll('_', ' '),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.all(14),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _spoolDocument() {
    if (_selectedTemplate == null) return;
    final Map<String, String> data = {};
    _controllers.forEach((key, controller) {
      data[key] = controller.text;
    });

    // Automatically stamp date spooled
    data['Date Issued'] = DateFormat('dd MMMM yyyy, h:mm a').format(DateTime.now());

    PdfGenerator.printDocument(_selectedTemplate!.title, data);
  }
}
