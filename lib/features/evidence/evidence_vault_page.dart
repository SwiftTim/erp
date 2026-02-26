// lib/features/evidence/evidence_vault_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../data/models/assessment_model.dart';
import '../../data/sync/sync_provider.dart';
import '../auth/auth_provider.dart';
import '../dashboard/widgets/app_shell.dart';
import 'package:animations/animations.dart';

class EvidenceVaultPage extends ConsumerStatefulWidget {
  final String studentId;
  const EvidenceVaultPage({super.key, required this.studentId});

  @override
  ConsumerState<EvidenceVaultPage> createState() => _EvidenceVaultPageState();
}

class _EvidenceVaultPageState extends ConsumerState<EvidenceVaultPage> {
  final _uuid = const Uuid();
  List<EvidenceItemModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final db = await ref.read(databaseProvider.future);
    final items = await db.assessmentDao.findEvidenceForStudent(widget.studentId);
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _addEvidence(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 80);
    if (xFile == null || !mounted) return;

    // ── FILE SIZE HARDENING (5MB Cap) ──
    final bytes = await xFile.length();
    if (bytes > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large. Max limit is 5MB.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final item = EvidenceItemModel(

      id: _uuid.v4(),
      studentId: widget.studentId,
      localPath: xFile.path,
      mediaType: 'photo',
      takenAt: DateTime.now().millisecondsSinceEpoch,
    );
    final db = await ref.read(databaseProvider.future);
    await db.assessmentDao.insertEvidence(item);
    
    // Refresh UI
    await _loadItems();
    
    // Trigger Sync automatically
    ref.read(syncProvider.notifier).runSync();
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () { Navigator.pop(context); _addEvidence(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () { Navigator.pop(context); _addEvidence(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Evidence Vault',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmptyState()
              : _buildGallery(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPickerOptions,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No evidence captured yet.', style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _showPickerOptions,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Capture Evidence'),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final item = _items[i];
        return OpenContainer(
          closedElevation: 0,
          closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          closedBuilder: (context, action) => _EvidenceThumbnail(item: item),
          openBuilder: (context, action) => _EvidencePreview(item: item),
        );
      },
    );
  }
}

class _EvidenceThumbnail extends StatelessWidget {
  final EvidenceItemModel item;
  const _EvidenceThumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        item.cloudUrl != null
            ? Image.network(item.cloudUrl!, fit: BoxFit.cover)
            : Image.file(File(item.localPath), fit: BoxFit.cover),
        if (item.uploaded == 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_upload_outlined, size: 10, color: Colors.white),
            ),
          )
        else
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_done_outlined, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _EvidencePreview extends StatelessWidget {
  final EvidenceItemModel item;
  const _EvidencePreview({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: item.id,
          child: item.cloudUrl != null
              ? Image.network(item.cloudUrl!)
              : Image.file(File(item.localPath)),
        ),
      ),
    );
  }
}
