import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

import '../../../core/theme/app_colors.dart';

/// A drop zone for file drag and drop
class FileDropZone extends StatefulWidget {
  final Widget child;
  final void Function(List<String> paths)? onFilesDropped;
  final List<String>? allowedExtensions;
  final bool enabled;

  const FileDropZone({
    super.key,
    required this.child,
    this.onFilesDropped,
    this.allowedExtensions,
    this.enabled = true,
  });

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return DropTarget(
      onDragEntered: (details) {
        setState(() => _isDragging = true);
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) {
        setState(() => _isDragging = false);

        final paths = details.files
            .map((file) => file.path)
            .where((path) {
              if (widget.allowedExtensions == null) return true;
              final ext = path.split('.').last.toLowerCase();
              return widget.allowedExtensions!.contains(ext);
            })
            .toList();

        if (paths.isNotEmpty) {
          widget.onFilesDropped?.call(paths);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          border: _isDragging
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            widget.child,
            if (_isDragging)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Drop files here',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty state drop zone placeholder
class DropZonePlaceholder extends StatelessWidget {
  final VoidCallback? onBrowse;
  final String title;
  final String subtitle;
  final IconData icon;

  const DropZonePlaceholder({
    super.key,
    this.onBrowse,
    this.title = 'Drop files here',
    this.subtitle = 'or click to browse',
    this.icon = Icons.file_upload_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onBrowse,
      child: MouseRegion(
        cursor:
            onBrowse != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              style: BorderStyle.solid,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: textColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
