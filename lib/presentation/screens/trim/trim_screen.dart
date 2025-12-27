import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../core/utils/file_utils.dart';
import '../../../domain/entities/conversion_job.dart';
import '../../providers/ffmpeg_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/drop_zone.dart';
import '../../widgets/media/media_info_card.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Trim screen state
class TrimScreenState {
  final String? inputPath;
  final Duration startTime;
  final Duration endTime;
  final Duration duration;
  final List<TrimSegment> segments;
  final bool lossless;
  final bool isProcessing;
  final double progress;
  final String? error;

  const TrimScreenState({
    this.inputPath,
    this.startTime = Duration.zero,
    this.endTime = Duration.zero,
    this.duration = Duration.zero,
    this.segments = const [],
    this.lossless = true,
    this.isProcessing = false,
    this.progress = 0,
    this.error,
  });

  TrimScreenState copyWith({
    String? inputPath,
    Duration? startTime,
    Duration? endTime,
    Duration? duration,
    List<TrimSegment>? segments,
    bool? lossless,
    bool? isProcessing,
    double? progress,
    String? error,
  }) {
    return TrimScreenState(
      inputPath: inputPath ?? this.inputPath,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      segments: segments ?? this.segments,
      lossless: lossless ?? this.lossless,
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

/// Trim screen provider
final trimScreenProvider =
    StateNotifierProvider<TrimScreenNotifier, TrimScreenState>((ref) {
  return TrimScreenNotifier(ref);
});

class TrimScreenNotifier extends StateNotifier<TrimScreenState> {
  final Ref ref;

  TrimScreenNotifier(this.ref) : super(const TrimScreenState());

  void setInputPath(String path) {
    state = state.copyWith(inputPath: path, error: null);
    ref.read(mediaInfoProvider.notifier).loadMediaInfo(path);
  }

  void setDuration(Duration duration) {
    state = state.copyWith(
      duration: duration,
      endTime: duration,
    );
  }

  void setStartTime(Duration time) {
    if (time < state.endTime) {
      state = state.copyWith(startTime: time);
    }
  }

  void setEndTime(Duration time) {
    if (time > state.startTime) {
      state = state.copyWith(endTime: time);
    }
  }

  void setLossless(bool value) {
    state = state.copyWith(lossless: value);
  }

  void addSegment() {
    final segment = TrimSegment(
      start: state.startTime,
      end: state.endTime,
    );
    state = state.copyWith(
      segments: [...state.segments, segment],
    );
  }

  void removeSegment(int index) {
    final newSegments = [...state.segments];
    newSegments.removeAt(index);
    state = state.copyWith(segments: newSegments);
  }

  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }

  void setProgress(double value) {
    state = state.copyWith(progress: value);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, isProcessing: false);
  }

  void clear() {
    state = const TrimScreenState();
    ref.read(mediaInfoProvider.notifier).clear();
  }
}

/// Trim screen
class TrimScreen extends ConsumerWidget {
  const TrimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenState = ref.watch(trimScreenProvider);
    final mediaInfoState = ref.watch(mediaInfoProvider);

    // Update duration when media info is loaded
    ref.listen(mediaInfoProvider, (prev, next) {
      if (next.mediaInfo != null && prev?.mediaInfo == null) {
        ref
            .read(trimScreenProvider.notifier)
            .setDuration(next.mediaInfo!.duration);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trim'),
      ),
      body: FileDropZone(
        allowedExtensions: AppConstants.supportedVideoFormats,
        onFilesDropped: (paths) {
          if (paths.isNotEmpty) {
            ref.read(trimScreenProvider.notifier).setInputPath(paths.first);
          }
        },
        child: ResponsivePadding(
          child: ConstrainedContent(
            maxWidth: 900,
            child: screenState.inputPath == null
                ? _buildEmptyState(context, ref)
                : _buildTrimInterface(
                    context, ref, screenState, mediaInfoState),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: DropZonePlaceholder(
        title: 'Drop video file here',
        subtitle: 'or click to browse',
        icon: Icons.content_cut,
        onBrowse: () => _pickFile(ref),
      ),
    );
  }

  Widget _buildTrimInterface(
    BuildContext context,
    WidgetRef ref,
    TrimScreenState screenState,
    MediaInfoState mediaInfoState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input section
          if (mediaInfoState.isLoading)
            const AppCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (mediaInfoState.mediaInfo != null)
            MediaInfoCard(
              mediaInfo: mediaInfoState.mediaInfo!,
              onRemove: () {
                ref.read(trimScreenProvider.notifier).clear();
              },
              trailing: AppButton(
                label: 'Change',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.small,
                onPressed: () => _pickFile(ref),
              ),
            ),

          const SizedBox(height: 24),

          // Video preview placeholder
          if (mediaInfoState.mediaInfo != null) ...[
            AppCard(
              padding: EdgeInsets.zero,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBgTertiary
                        : AppColors.lightBgTertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Video Preview',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Timeline slider
            _buildTimelineSlider(context, ref, screenState),

            const SizedBox(height: 24),

            // Trim settings
            Text(
              'Trim Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildTrimSettings(context, ref, screenState),

            const SizedBox(height: 24),

            // Segments
            _buildSegmentsList(context, ref, screenState),

            const SizedBox(height: 24),

            // Export button
            _buildExportButton(context, ref, screenState),

            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineSlider(
    BuildContext context,
    WidgetRef ref,
    TrimScreenState state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AppCard(
      child: Column(
        children: [
          // Time display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${DurationUtils.formatHMSms(state.startTime)}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: secondaryColor,
                ),
              ),
              Text(
                'Duration: ${DurationUtils.formatHMS(state.endTime - state.startTime)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'End: ${DurationUtils.formatHMSms(state.endTime)}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: secondaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Range slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 8,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: RangeSlider(
              values: RangeValues(
                state.startTime.inMilliseconds.toDouble(),
                state.endTime.inMilliseconds.toDouble(),
              ),
              min: 0,
              max: state.duration.inMilliseconds.toDouble(),
              onChanged: (values) {
                ref
                    .read(trimScreenProvider.notifier)
                    .setStartTime(Duration(milliseconds: values.start.toInt()));
                ref
                    .read(trimScreenProvider.notifier)
                    .setEndTime(Duration(milliseconds: values.end.toInt()));
              },
            ),
          ),

          const SizedBox(height: 8),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: () {
                  ref
                      .read(trimScreenProvider.notifier)
                      .setStartTime(Duration.zero);
                },
                tooltip: 'Go to start',
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () {
                  final newTime = state.startTime - const Duration(seconds: 5);
                  ref.read(trimScreenProvider.notifier).setStartTime(
                        newTime < Duration.zero ? Duration.zero : newTime,
                      );
                },
                tooltip: 'Back 5 seconds',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () {
                  final newTime = state.endTime + const Duration(seconds: 5);
                  ref.read(trimScreenProvider.notifier).setEndTime(
                        newTime > state.duration ? state.duration : newTime,
                      );
                },
                tooltip: 'Forward 5 seconds',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: () {
                  ref
                      .read(trimScreenProvider.notifier)
                      .setEndTime(state.duration);
                },
                tooltip: 'Go to end',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrimSettings(
    BuildContext context,
    WidgetRef ref,
    TrimScreenState state,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Mode: '),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Lossless'),
                selected: state.lossless,
                onSelected: (_) {
                  ref.read(trimScreenProvider.notifier).setLossless(true);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Re-encode'),
                selected: !state.lossless,
                onSelected: (_) {
                  ref.read(trimScreenProvider.notifier).setLossless(false);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.lossless
                ? 'Fast, no quality loss. Cut points may be slightly adjusted to keyframes.'
                : 'Slower, allows precise cuts. Uses same codec settings.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentsList(
    BuildContext context,
    WidgetRef ref,
    TrimScreenState state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Segments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            AppButton(
              label: 'Add Segment',
              icon: Icons.add,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              onPressed: () {
                ref.read(trimScreenProvider.notifier).addSegment();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (state.segments.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No segments added. Adjust the timeline and click "Add Segment".',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          ...state.segments.asMap().entries.map((entry) {
            final index = entry.key;
            final segment = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${DurationUtils.formatHMS(segment.start)} → ${DurationUtils.formatHMS(segment.end)}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    Text(
                      DurationUtils.formatHMS(segment.duration),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () {
                        ref
                            .read(trimScreenProvider.notifier)
                            .removeSegment(index);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildExportButton(
    BuildContext context,
    WidgetRef ref,
    TrimScreenState state,
  ) {
    final hasContent = state.segments.isNotEmpty ||
        state.startTime != Duration.zero ||
        state.endTime != state.duration;

    return SizedBox(
      width: double.infinity,
      child: AppButton(
        label: state.isProcessing
            ? 'Processing...'
            : state.segments.isNotEmpty
                ? 'Export ${state.segments.length} Segment${state.segments.length > 1 ? 's' : ''}'
                : 'Export Trimmed Video',
        icon: state.isProcessing ? null : Icons.save_alt,
        size: AppButtonSize.large,
        loading: state.isProcessing,
        onPressed: hasContent && !state.isProcessing
            ? () => _exportTrim(context, ref, state)
            : null,
      ),
    );
  }

  Future<void> _pickFile(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        ref.read(trimScreenProvider.notifier).setInputPath(path);
      }
    }
  }

  Future<void> _exportTrim(
    BuildContext context,
    WidgetRef ref,
    TrimScreenState state,
  ) async {
    final notifier = ref.read(trimScreenProvider.notifier);
    final ffmpegService = ref.read(ffmpegServiceProvider);

    if (state.inputPath == null) return;

    notifier.setProcessing(true);

    try {
      // Use segments if available, otherwise use current selection
      final segments = state.segments.isNotEmpty
          ? state.segments
          : [TrimSegment(start: state.startTime, end: state.endTime)];

      for (var i = 0; i < segments.length; i++) {
        final segment = segments[i];
        final suffix = segments.length > 1 ? 'trim_${i + 1}' : 'trimmed';
        final outputPath = FileUtils.generateOutputPath(
          state.inputPath!,
          suffix,
        );

        final args = <String>[
          '-y',
          '-ss',
          DurationUtils.formatForFFmpeg(segment.start),
          '-i',
          state.inputPath!,
          '-to',
          DurationUtils.formatForFFmpeg(segment.end - segment.start),
        ];

        if (state.lossless) {
          args.addAll(['-c', 'copy']);
        } else {
          args.addAll(['-c:v', 'libx264', '-crf', '23', '-c:a', 'aac']);
        }

        args.add(outputPath);

        await ffmpegService.execute(
          args,
          totalDuration: segment.duration,
          onProgress: (progress) {
            final totalProgress =
                (i + progress.progress) / segments.length;
            notifier.setProgress(totalProgress);
          },
        );
      }

      notifier.setProcessing(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully exported ${segments.length} segment${segments.length > 1 ? 's' : ''}!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      notifier.setError(e.toString());
    }
  }
}
