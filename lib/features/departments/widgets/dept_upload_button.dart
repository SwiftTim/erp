// lib/features/departments/widgets/dept_upload_button.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';

/// A reusable upload widget. Tapping opens a file/image picker and returns
/// the picked file metadata through [onFilePicked].
class DeptUploadButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final void Function(String fileName, String filePath) onFilePicked;
  final bool compact;

  const DeptUploadButton({
    super.key,
    required this.label,
    required this.onFilePicked,
    this.icon = Icons.upload_file_outlined,
    this.compact = false,
  });

  @override
  State<DeptUploadButton> createState() => _DeptUploadButtonState();
}

class _DeptUploadButtonState extends State<DeptUploadButton> {
  String? _pickedFileName;
  bool _picking = false;

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      // Show choice: camera photo or gallery
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select File Source',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.photo_camera_outlined,
                      label: 'Take Photo',
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery / Files',
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );

      if (source == null) {
        setState(() => _picking = false);
        return;
      }

      final XFile? file = await picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        setState(() => _pickedFileName = file.name);
        widget.onFilePicked(file.name, file.path);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return TextButton.icon(
        onPressed: _picking ? null : _pick,
        icon: _picking
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(widget.icon, size: 16, color: AppTheme.primary),
        label: Text(
          _pickedFileName ?? widget.label,
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 1,
        ),
      );
    }

    return GestureDetector(
      onTap: _picking ? null : _pick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _pickedFileName != null
              ? AppTheme.primary.withOpacity(0.05)
              : Colors.grey.shade50,
          border: Border.all(
            color: _pickedFileName != null
                ? AppTheme.primary.withOpacity(0.4)
                : Colors.grey.shade300,
            style: BorderStyle.solid,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: _picking
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _pickedFileName != null ? Icons.check_circle_outline : widget.icon,
                      color: AppTheme.primary,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pickedFileName != null ? 'File Selected' : widget.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _pickedFileName != null ? AppTheme.primary : Colors.black87,
                    ),
                  ),
                  if (_pickedFileName != null)
                    Text(
                      _pickedFileName!,
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const Text(
                      'Tap to select a file or take a photo',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                ],
              ),
            ),
            if (_pickedFileName != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.black45),
                onPressed: () => setState(() => _pickedFileName = null),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}
