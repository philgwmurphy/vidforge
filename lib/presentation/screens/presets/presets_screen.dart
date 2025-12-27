import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/ffmpeg_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/encoding_preset.dart';
import '../../providers/preset_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Presets management screen
class PresetsScreen extends ConsumerWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetState = ref.watch(presetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presets'),
        actions: [
          AppButton(
            label: 'New Preset',
            icon: Icons.add,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.small,
            onPressed: () {
              // TODO: Show preset editor dialog
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ResponsivePadding(
        child: _buildPresetsList(context, ref, presetState),
      ),
    );
  }

  Widget _buildPresetsList(
    BuildContext context,
    WidgetRef ref,
    PresetState presetState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final categories = PresetCategory.values;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final category in categories) ...[
            final presets = presetState.presetsByCategory(category);
            if (presets.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Text(
                  _getCategoryName(category),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  childAspectRatio: ResponsiveLayout.isMobile(context) ? 1.6 : 1.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: presets.length,
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  final isSelected =
                      presetState.selectedPresetId == preset.id;
                  return _PresetCard(
                    preset: preset,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(presetProvider.notifier).selectPreset(preset.id);
                    },
                    onEdit: preset.isBuiltIn
                        ? null
                        : () {
                            // TODO: Show preset editor
                          },
                    onDelete: preset.isBuiltIn
                        ? null
                        : () {
                            ref
                                .read(presetProvider.notifier)
                                .deletePreset(preset.id);
                          },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ],
        ],
      ),
    );
  }

  String _getCategoryName(PresetCategory category) {
    switch (category) {
      case PresetCategory.socialMedia:
        return 'Social Media';
      case PresetCategory.device:
        return 'Devices';
      case PresetCategory.quality:
        return 'Quality';
      case PresetCategory.streaming:
        return 'Streaming';
      case PresetCategory.archive:
        return 'Archive';
      case PresetCategory.custom:
        return 'Custom';
    }
  }
}

class _PresetCard extends StatelessWidget {
  final EncodingPreset preset;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AppCard(
      selected: isSelected,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : (isDark
                          ? AppColors.darkBgTertiary
                          : AppColors.lightBgTertiary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(preset.category),
                  size: 20,
                  color: isSelected ? AppColors.primary : secondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (preset.isBuiltIn)
                      Text(
                        'Built-in',
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),

          const Spacer(),

          Text(
            preset.description,
            style: TextStyle(
              fontSize: 12,
              color: secondaryColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Settings tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _buildSettingsTags(isDark, secondaryColor),
          ),

          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    color: AppColors.error,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSettingsTags(bool isDark, Color textColor) {
    final tags = <String>[];

    // Video codec
    final videoCodec =
        FFmpegConstants.videoCodecs[preset.video.codec] ?? preset.video.codec;
    tags.add(videoCodec.split(' ').first);

    // Resolution if set
    if (preset.video.width != null && preset.video.height != null) {
      if (preset.video.height == 1080) {
        tags.add('1080p');
      } else if (preset.video.height == 720) {
        tags.add('720p');
      } else if (preset.video.height == 2160) {
        tags.add('4K');
      } else {
        tags.add('${preset.video.height}p');
      }
    }

    // CRF if set
    if (preset.video.crf != null) {
      tags.add('CRF ${preset.video.crf}');
    }

    // Container
    tags.add(preset.container.toUpperCase());

    return tags.map((tag) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.darkBgTertiary : AppColors.lightBgTertiary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      );
    }).toList();
  }

  IconData _getCategoryIcon(PresetCategory category) {
    switch (category) {
      case PresetCategory.socialMedia:
        return Icons.share_outlined;
      case PresetCategory.device:
        return Icons.devices_outlined;
      case PresetCategory.quality:
        return Icons.high_quality_outlined;
      case PresetCategory.streaming:
        return Icons.stream_outlined;
      case PresetCategory.archive:
        return Icons.archive_outlined;
      case PresetCategory.custom:
        return Icons.tune_outlined;
    }
  }
}
