import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_utils.dart';
import '../../../domain/entities/conversion_job.dart';
import '../../providers/preset_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/drop_zone.dart';
import '../../widgets/progress/job_progress_card.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Batch queue item
class BatchItem {
  final String id;
  final String inputPath;
  final String filename;
  final int fileSize;
  final JobStatus status;
  final double progress;
  final String? error;

  BatchItem({
    required this.id,
    required this.inputPath,
    required this.filename,
    required this.fileSize,
    this.status = JobStatus.pending,
    this.progress = 0,
    this.error,
  });

  BatchItem copyWith({
    JobStatus? status,
    double? progress,
    String? error,
  }) {
    return BatchItem(
      id: id,
      inputPath: inputPath,
      filename: filename,
      fileSize: fileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

/// Batch screen state
class BatchScreenState {
  final List<BatchItem> items;
  final bool isProcessing;
  final int currentIndex;

  const BatchScreenState({
    this.items = const [],
    this.isProcessing = false,
    this.currentIndex = 0,
  });

  BatchScreenState copyWith({
    List<BatchItem>? items,
    bool? isProcessing,
    int? currentIndex,
  }) {
    return BatchScreenState(
      items: items ?? this.items,
      isProcessing: isProcessing ?? this.isProcessing,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  int get completedCount => items.where((i) => i.status == JobStatus.completed).length;
  int get failedCount => items.where((i) => i.status == JobStatus.failed).length;
  double get overallProgress {
    if (items.isEmpty) return 0;
    final total = items.fold<double>(0, (sum, item) => sum + item.progress);
    return total / items.length;
  }
}

/// Batch screen provider
final batchScreenProvider =
    StateNotifierProvider<BatchScreenNotifier, BatchScreenState>((ref) {
  return BatchScreenNotifier();
});

class BatchScreenNotifier extends StateNotifier<BatchScreenState> {
  BatchScreenNotifier() : super(const BatchScreenState());

  void addFiles(List<String> paths) {
    final newItems = paths.map((path) {
      return BatchItem(
        id: const Uuid().v4(),
        inputPath: path,
        filename: FileUtils.getFilename(path),
        fileSize: 0, // Would need async file size check
      );
    }).toList();

    state = state.copyWith(items: [...state.items, ...newItems]);
  }

  void removeItem(String id) {
    final newItems = state.items.where((i) => i.id != id).toList();
    state = state.copyWith(items: newItems);
  }

  void clearAll() {
    state = const BatchScreenState();
  }

  void clearCompleted() {
    final newItems =
        state.items.where((i) => i.status != JobStatus.completed).toList();
    state = state.copyWith(items: newItems);
  }

  void updateItemStatus(String id, JobStatus status, {double? progress, String? error}) {
    final newItems = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(status: status, progress: progress, error: error);
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}

/// Batch processing screen
class BatchScreen extends ConsumerWidget {
  const BatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenState = ref.watch(batchScreenProvider);
    final presetState = ref.watch(presetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Processing'),
        actions: [
          if (screenState.items.isNotEmpty) ...[
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear'),
              onPressed: () {
                ref.read(batchScreenProvider.notifier).clearAll();
              },
            ),
          ],
        ],
      ),
      body: FileDropZone(
        allowedExtensions: AppConstants.supportedVideoFormats,
        onFilesDropped: (paths) {
          ref.read(batchScreenProvider.notifier).addFiles(paths);
        },
        child: ResponsivePadding(
          child: screenState.items.isEmpty
              ? _buildEmptyState(context, ref)
              : _buildBatchQueue(context, ref, screenState, presetState),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedContent(
        maxWidth: 500,
        child: DropZonePlaceholder(
          title: 'Drop video files here',
          subtitle: 'Add multiple files for batch processing',
          icon: Icons.folder_outlined,
          onBrowse: () => _pickFiles(ref),
        ),
      ),
    );
  }

  Widget _buildBatchQueue(
    BuildContext context,
    WidgetRef ref,
    BatchScreenState screenState,
    PresetState presetState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Queue header with controls
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${screenState.items.length} file${screenState.items.length > 1 ? 's' : ''} in queue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (screenState.isProcessing)
                    Text(
                      'Processing ${screenState.currentIndex + 1} of ${screenState.items.length}',
                      style: TextStyle(color: secondaryColor),
                    ),
                ],
              ),
            ),
            AppButton(
              label: 'Add Files',
              icon: Icons.add,
              variant: AppButtonVariant.outline,
              onPressed: () => _pickFiles(ref),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Batch settings card
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.tune, size: 20),
              const SizedBox(width: 12),
              const Text('Preset:'),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: presetState.selectedPresetId,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: presetState.presets.map((preset) {
                    return DropdownMenuItem(
                      value: preset.id,
                      child: Text(preset.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(presetProvider.notifier).selectPreset(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Progress summary
        if (screenState.isProcessing || screenState.completedCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Progress',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '${(screenState.overallProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: screenState.overallProgress,
                    backgroundColor:
                        isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatBadge(
                        'Completed',
                        screenState.completedCount,
                        AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      if (screenState.failedCount > 0)
                        _buildStatBadge(
                          'Failed',
                          screenState.failedCount,
                          AppColors.error,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Queue list
        Expanded(
          child: ListView.builder(
            itemCount: screenState.items.length,
            itemBuilder: (context, index) {
              final item = screenState.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildQueueItem(context, ref, item, index),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Start button
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: screenState.isProcessing
                ? 'Processing...'
                : 'Start Batch Conversion',
            icon: screenState.isProcessing ? null : Icons.play_arrow,
            size: AppButtonSize.large,
            loading: screenState.isProcessing,
            onPressed: screenState.isProcessing
                ? null
                : () => _startBatchProcessing(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem(
    BuildContext context,
    WidgetRef ref,
    BatchItem item,
    int index,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getStatusColor(item.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: item.status == JobStatus.running
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: item.progress,
                      ),
                    )
                  : Icon(
                      _getStatusIcon(item.status),
                      size: 18,
                      color: _getStatusColor(item.status),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.filename,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.status == JobStatus.running)
                  Text(
                    '${(item.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryColor,
                    ),
                  )
                else if (item.error != null)
                  Text(
                    item.error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Remove button
          if (item.status == JobStatus.pending)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                ref.read(batchScreenProvider.notifier).removeItem(item.id);
              },
              color: secondaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
      case JobStatus.queued:
        return AppColors.info;
      case JobStatus.running:
        return AppColors.primary;
      case JobStatus.completed:
        return AppColors.success;
      case JobStatus.failed:
        return AppColors.error;
      case JobStatus.cancelled:
      case JobStatus.paused:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
      case JobStatus.queued:
        return Icons.schedule;
      case JobStatus.running:
        return Icons.play_arrow;
      case JobStatus.completed:
        return Icons.check;
      case JobStatus.failed:
        return Icons.error_outline;
      case JobStatus.cancelled:
        return Icons.cancel_outlined;
      case JobStatus.paused:
        return Icons.pause;
    }
  }

  Future<void> _pickFiles(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final paths = result.files
          .where((f) => f.path != null)
          .map((f) => f.path!)
          .toList();
      ref.read(batchScreenProvider.notifier).addFiles(paths);
    }
  }

  Future<void> _startBatchProcessing(BuildContext context, WidgetRef ref) async {
    // Placeholder for batch processing logic
    final notifier = ref.read(batchScreenProvider.notifier);
    final state = ref.read(batchScreenProvider);

    notifier.setProcessing(true);

    for (var i = 0; i < state.items.length; i++) {
      final item = state.items[i];
      notifier.setCurrentIndex(i);
      notifier.updateItemStatus(item.id, JobStatus.running);

      // Simulate processing
      for (var p = 0; p <= 10; p++) {
        await Future.delayed(const Duration(milliseconds: 200));
        notifier.updateItemStatus(
          item.id,
          JobStatus.running,
          progress: p / 10,
        );
      }

      notifier.updateItemStatus(item.id, JobStatus.completed, progress: 1.0);
    }

    notifier.setProcessing(false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch processing completed!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
