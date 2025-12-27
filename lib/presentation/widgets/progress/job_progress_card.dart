import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../core/utils/file_utils.dart';
import '../../../domain/entities/conversion_job.dart';
import '../common/app_card.dart';

/// Card showing conversion job progress
class JobProgressCard extends StatelessWidget {
  final ConversionJob job;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  const JobProgressCard({
    super.key,
    required this.job,
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FileUtils.getFilename(job.inputPath),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.preset.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context),
              const SizedBox(width: 8),
              _buildActions(context),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 8,
            percent: job.progress.clamp(0, 1),
            backgroundColor:
                isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary,
            progressColor: _getProgressColor(),
            barRadius: const Radius.circular(4),
            animation: true,
            animationDuration: 300,
          ),

          const SizedBox(height: 8),

          // Stats
          _buildStatsRow(context),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final (label, color) = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (String, Color) _getStatusInfo() {
    switch (job.status) {
      case JobStatus.pending:
        return ('Pending', AppColors.info);
      case JobStatus.queued:
        return ('Queued', AppColors.info);
      case JobStatus.running:
        return ('Processing', AppColors.primary);
      case JobStatus.paused:
        return ('Paused', AppColors.warning);
      case JobStatus.completed:
        return ('Completed', AppColors.success);
      case JobStatus.failed:
        return ('Failed', AppColors.error);
      case JobStatus.cancelled:
        return ('Cancelled', AppColors.darkTextSecondary);
    }
  }

  Color _getProgressColor() {
    switch (job.status) {
      case JobStatus.running:
        return AppColors.primary;
      case JobStatus.completed:
        return AppColors.success;
      case JobStatus.failed:
        return AppColors.error;
      case JobStatus.paused:
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  Widget _buildActions(BuildContext context) {
    if (job.canCancel && onCancel != null) {
      return IconButton(
        icon: const Icon(Icons.close, size: 20),
        onPressed: onCancel,
        tooltip: 'Cancel',
      );
    }

    if (job.isFailed && onRetry != null) {
      return IconButton(
        icon: const Icon(Icons.refresh, size: 20),
        onPressed: onRetry,
        tooltip: 'Retry',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatsRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final items = <Widget>[];

    // Progress percentage
    items.add(Text(
      '${(job.progress * 100).toStringAsFixed(1)}%',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
      ),
    ));

    // Speed
    if (job.currentSpeed != null && job.currentSpeed! > 0) {
      items.add(Text(
        '${job.currentSpeed!.toStringAsFixed(1)}x',
        style: TextStyle(fontSize: 12, color: secondaryColor),
      ));
    }

    // FPS
    if (job.currentFps != null && job.currentFps! > 0) {
      items.add(Text(
        '${job.currentFps!.toStringAsFixed(0)} fps',
        style: TextStyle(fontSize: 12, color: secondaryColor),
      ));
    }

    // ETA
    if (job.estimatedTimeRemaining != null) {
      items.add(Text(
        'ETA: ${DurationUtils.formatHumanReadable(job.estimatedTimeRemaining!)}',
        style: TextStyle(fontSize: 12, color: secondaryColor),
      ));
    }

    // Error message
    if (job.isFailed && job.errorMessage != null) {
      return Text(
        job.errorMessage!,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.error,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      children: items
          .expand((item) => [item, const SizedBox(width: 16)])
          .toList()
        ..removeLast(),
    );
  }
}

/// Simple inline progress indicator
class InlineProgress extends StatelessWidget {
  final double progress;
  final String? label;
  final bool showPercentage;

  const InlineProgress({
    super.key,
    required this.progress,
    this.label,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryColor,
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                    ),
                  ),
              ],
            ),
          ),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 6,
          percent: progress.clamp(0, 1),
          backgroundColor:
              isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary,
          progressColor: AppColors.primary,
          barRadius: const Radius.circular(3),
        ),
      ],
    );
  }
}
