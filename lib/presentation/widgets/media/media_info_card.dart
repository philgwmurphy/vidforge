import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../core/utils/file_utils.dart';
import '../../../domain/entities/media_info.dart';
import '../common/app_card.dart';

/// Card displaying media file information
class MediaInfoCard extends StatelessWidget {
  final MediaInfo mediaInfo;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MediaInfoCard({
    super.key,
    required this.mediaInfo,
    this.onRemove,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail placeholder
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.movie_outlined,
              color: secondaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mediaInfo.filename,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildInfoRow(context),
                const SizedBox(height: 2),
                _buildCodecRow(context),
              ],
            ),
          ),

          // Actions
          if (trailing != null) trailing!,
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemove,
              tooltip: 'Remove',
              color: secondaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final items = <String>[];

    if (mediaInfo.hasVideo && mediaInfo.videoStream != null) {
      items.add(mediaInfo.videoStream!.resolution);
      if (mediaInfo.videoStream!.frameRate > 0) {
        items.add('${mediaInfo.videoStream!.frameRate.toStringAsFixed(0)}fps');
      }
    }

    items.add(DurationUtils.formatHMS(mediaInfo.duration));
    items.add(FileUtils.formatFileSize(mediaInfo.fileSize));

    return Text(
      items.join(' • '),
      style: TextStyle(
        fontSize: 12,
        color: secondaryColor,
      ),
    );
  }

  Widget _buildCodecRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final items = <String>[];

    if (mediaInfo.hasVideo && mediaInfo.videoStream != null) {
      items.add(mediaInfo.videoStream!.codec.toUpperCase());
    }

    if (mediaInfo.hasAudio && mediaInfo.audioStreams.isNotEmpty) {
      items.add(mediaInfo.audioStreams.first.codec.toUpperCase());
    }

    items.add(mediaInfo.format.toUpperCase());

    if (mediaInfo.videoStream?.isHDR == true) {
      items.add('HDR');
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: items
          .map((item) => _buildTag(item, isDark, secondaryColor))
          .toList(),
    );
  }

  Widget _buildTag(String text, bool isDark, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// Compact media info display
class MediaInfoCompact extends StatelessWidget {
  final MediaInfo mediaInfo;

  const MediaInfoCompact({
    super.key,
    required this.mediaInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mediaInfo.filename,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          _buildSummary(),
          style: TextStyle(
            fontSize: 13,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }

  String _buildSummary() {
    final items = <String>[];

    if (mediaInfo.hasVideo && mediaInfo.videoStream != null) {
      items.add(mediaInfo.videoStream!.resolution);
    }

    items.add(DurationUtils.formatHMS(mediaInfo.duration));
    items.add(FileUtils.formatFileSize(mediaInfo.fileSize));

    return items.join(' • ');
  }
}
