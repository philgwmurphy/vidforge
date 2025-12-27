import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/ffmpeg_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_utils.dart';
import '../../../domain/entities/encoding_preset.dart';
import '../../providers/ffmpeg_provider.dart';
import '../../providers/preset_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/drop_zone.dart';
import '../../widgets/media/media_info_card.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Convert screen state
class ConvertScreenState {
  final String? inputPath;
  final String? outputPath;
  final bool isConverting;
  final double progress;
  final String? error;

  const ConvertScreenState({
    this.inputPath,
    this.outputPath,
    this.isConverting = false,
    this.progress = 0,
    this.error,
  });

  ConvertScreenState copyWith({
    String? inputPath,
    String? outputPath,
    bool? isConverting,
    double? progress,
    String? error,
  }) {
    return ConvertScreenState(
      inputPath: inputPath ?? this.inputPath,
      outputPath: outputPath ?? this.outputPath,
      isConverting: isConverting ?? this.isConverting,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

/// Convert screen state provider
final convertScreenProvider =
    StateNotifierProvider<ConvertScreenNotifier, ConvertScreenState>((ref) {
  return ConvertScreenNotifier(ref);
});

class ConvertScreenNotifier extends StateNotifier<ConvertScreenState> {
  final Ref ref;

  ConvertScreenNotifier(this.ref) : super(const ConvertScreenState());

  void setInputPath(String path) {
    state = state.copyWith(inputPath: path, error: null);
    // Load media info
    ref.read(mediaInfoProvider.notifier).loadMediaInfo(path);
    // Generate default output path
    final preset = ref.read(selectedPresetProvider);
    if (preset != null) {
      final outputPath = FileUtils.generateOutputPath(
        path,
        preset.id,
        newExtension: preset.container,
      );
      state = state.copyWith(outputPath: outputPath);
    }
  }

  void setOutputPath(String path) {
    state = state.copyWith(outputPath: path);
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void setConverting(bool value) {
    state = state.copyWith(isConverting: value);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, isConverting: false);
  }

  void clear() {
    state = const ConvertScreenState();
    ref.read(mediaInfoProvider.notifier).clear();
  }
}

/// Main convert screen
class ConvertScreen extends ConsumerWidget {
  const ConvertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenState = ref.watch(convertScreenProvider);
    final mediaInfoState = ref.watch(mediaInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convert'),
      ),
      body: FileDropZone(
        allowedExtensions: AppConstants.supportedVideoFormats,
        onFilesDropped: (paths) {
          if (paths.isNotEmpty) {
            ref.read(convertScreenProvider.notifier).setInputPath(paths.first);
          }
        },
        child: ResponsivePadding(
          child: ConstrainedContent(
            maxWidth: 800,
            child: screenState.inputPath == null
                ? _buildEmptyState(context, ref)
                : _buildConvertForm(context, ref, screenState, mediaInfoState),
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
        icon: Icons.movie_outlined,
        onBrowse: () => _pickFile(ref),
      ),
    );
  }

  Widget _buildConvertForm(
    BuildContext context,
    WidgetRef ref,
    ConvertScreenState screenState,
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
          Text(
            'Input',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

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
                ref.read(convertScreenProvider.notifier).clear();
              },
              trailing: AppButton(
                label: 'Change',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.small,
                onPressed: () => _pickFile(ref),
              ),
            )
          else if (mediaInfoState.error != null)
            AppCard(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load media info',
                    style: TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Try another file',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _pickFile(ref),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Output settings section
          Text(
            'Output Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildOutputSettings(context, ref),

          const SizedBox(height: 24),

          // Convert button
          if (mediaInfoState.mediaInfo != null)
            _buildConvertButton(context, ref, screenState),

          // Error message
          if (screenState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      screenState.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOutputSettings(BuildContext context, WidgetRef ref) {
    final presetState = ref.watch(presetProvider);
    final selectedPreset = presetState.selectedPreset;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preset selector
          Row(
            children: [
              const Icon(Icons.tune, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Preset',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedPreset?.id,
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
                      // Update output path with new extension
                      final inputPath =
                          ref.read(convertScreenProvider).inputPath;
                      if (inputPath != null) {
                        final preset = presetState.presets.firstWhere(
                          (p) => p.id == value,
                        );
                        final outputPath = FileUtils.generateOutputPath(
                          inputPath,
                          preset.id,
                          newExtension: preset.container,
                        );
                        ref
                            .read(convertScreenProvider.notifier)
                            .setOutputPath(outputPath);
                      }
                    }
                  },
                ),
              ),
            ],
          ),

          if (selectedPreset != null) ...[
            const SizedBox(height: 12),
            Text(
              selectedPreset.description,
              style: TextStyle(fontSize: 13, color: secondaryColor),
            ),

            const Divider(height: 24),

            // Video settings summary
            _buildSettingSummary(
              context,
              'Video',
              _formatVideoSettings(selectedPreset.video),
            ),

            const SizedBox(height: 8),

            // Audio settings summary
            _buildSettingSummary(
              context,
              'Audio',
              _formatAudioSettings(selectedPreset.audio),
            ),

            const SizedBox(height: 8),

            // Container
            _buildSettingSummary(
              context,
              'Format',
              selectedPreset.container.toUpperCase(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingSummary(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: secondaryColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatVideoSettings(VideoSettings video) {
    final parts = <String>[];
    parts.add(FFmpegConstants.videoCodecs[video.codec] ?? video.codec);
    if (video.crf != null) {
      parts.add('CRF ${video.crf}');
    }
    if (video.width != null && video.height != null) {
      parts.add('${video.width}x${video.height}');
    }
    return parts.join(' • ');
  }

  String _formatAudioSettings(AudioSettings audio) {
    final parts = <String>[];
    parts.add(FFmpegConstants.audioCodecs[audio.codec] ?? audio.codec);
    if (audio.bitrate != null) {
      parts.add('${audio.bitrate} kbps');
    }
    return parts.join(' • ');
  }

  Widget _buildConvertButton(
    BuildContext context,
    WidgetRef ref,
    ConvertScreenState screenState,
  ) {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        label: screenState.isConverting ? 'Converting...' : 'Start Conversion',
        icon: screenState.isConverting ? null : Icons.play_arrow,
        size: AppButtonSize.large,
        loading: screenState.isConverting,
        onPressed: screenState.isConverting
            ? null
            : () => _startConversion(context, ref),
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
        ref.read(convertScreenProvider.notifier).setInputPath(path);
      }
    }
  }

  Future<void> _startConversion(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(convertScreenProvider.notifier);
    final state = ref.read(convertScreenProvider);
    final preset = ref.read(selectedPresetProvider);
    final ffmpegService = ref.read(ffmpegServiceProvider);
    final mediaInfo = ref.read(mediaInfoProvider).mediaInfo;

    if (state.inputPath == null ||
        state.outputPath == null ||
        preset == null ||
        mediaInfo == null) {
      return;
    }

    notifier.setConverting(true);
    notifier.updateProgress(0);

    try {
      // Build FFmpeg command
      final args = <String>[
        '-y',
        '-i',
        state.inputPath!,
      ];

      // Video settings
      if (preset.video.codec != 'copy') {
        args.addAll(['-c:v', preset.video.codec]);
        if (preset.video.crf != null) {
          args.addAll(['-crf', preset.video.crf.toString()]);
        }
        args.addAll(['-preset', preset.video.preset]);
        if (preset.video.width != null && preset.video.height != null) {
          args.addAll([
            '-vf',
            'scale=${preset.video.width}:${preset.video.height}'
          ]);
        }
      } else {
        args.addAll(['-c:v', 'copy']);
      }

      // Audio settings
      if (preset.audio.codec != 'copy') {
        args.addAll(['-c:a', preset.audio.codec]);
        if (preset.audio.bitrate != null) {
          args.addAll(['-b:a', '${preset.audio.bitrate}k']);
        }
      } else {
        args.addAll(['-c:a', 'copy']);
      }

      // MP4 fast start
      if (preset.container == 'mp4') {
        args.addAll(['-movflags', '+faststart']);
      }

      args.add(state.outputPath!);

      final result = await ffmpegService.execute(
        args,
        totalDuration: mediaInfo.duration,
        onProgress: (progress) {
          notifier.updateProgress(progress.progress);
        },
      );

      if (result.success) {
        notifier.setConverting(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversion completed successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        notifier.setError(result.error ?? 'Conversion failed');
      }
    } catch (e) {
      notifier.setError(e.toString());
    }
  }
}
