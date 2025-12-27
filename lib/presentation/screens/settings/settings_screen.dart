import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/ffmpeg_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/layout/responsive_layout.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ResponsivePadding(
        child: ConstrainedContent(
          maxWidth: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppearanceSection(context, ref),
                const SizedBox(height: 24),
                _buildOutputSection(context, ref),
                const SizedBox(height: 24),
                if (Platform.isWindows || Platform.isLinux)
                  _buildFFmpegSection(context, ref),
                const SizedBox(height: 24),
                _buildAboutSection(context, ref),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.palette_outlined,
                title: 'Theme',
                trailing: SegmentedButton<AppThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selected) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(selected.first);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutputSection(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Output',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.folder_outlined,
                title: 'Default Output Directory',
                subtitle: settings.defaultOutputDirectory ?? 'Same as input file',
                onTap: () => _pickOutputDirectory(ref),
              ),
              const Divider(),
              _SettingsRow(
                icon: Icons.warning_amber_outlined,
                title: 'Overwrite Existing Files',
                subtitle: 'Replace files without confirmation',
                trailing: Switch(
                  value: settings.overwriteExisting,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setOverwriteExisting(value);
                  },
                ),
              ),
              const Divider(),
              _SettingsRow(
                icon: Icons.delete_outline,
                title: 'Delete Source After Conversion',
                subtitle: 'Move source files to trash',
                trailing: Switch(
                  value: settings.deleteSourceAfterConversion,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setDeleteSourceAfterConversion(value);
                  },
                ),
              ),
              const Divider(),
              _SettingsRow(
                icon: Icons.format_list_numbered,
                title: 'Concurrent Jobs',
                subtitle: 'Number of simultaneous conversions',
                trailing: DropdownButton<int>(
                  value: settings.concurrentJobs,
                  underline: const SizedBox(),
                  items: List.generate(8, (i) => i + 1).map((n) {
                    return DropdownMenuItem(
                      value: n,
                      child: Text('$n'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .setConcurrentJobs(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFFmpegSection(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ffmpegVersion = ref.watch(ffmpegVersionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FFmpeg',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.info_outline,
                title: 'FFmpeg Version',
                trailing: ffmpegVersion.when(
                  data: (version) => Text(
                    version ?? 'Not found',
                    style: TextStyle(
                      color: version != null
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text(
                    'Error',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
              const Divider(),
              _SettingsRow(
                icon: Icons.terminal,
                title: 'FFmpeg Path',
                subtitle: settings.ffmpegPath ?? 'Using system PATH',
                onTap: () => _pickFFmpegPath(ref, 'ffmpeg'),
              ),
              const Divider(),
              _SettingsRow(
                icon: Icons.terminal,
                title: 'FFprobe Path',
                subtitle: settings.ffprobePath ?? 'Using system PATH',
                onTap: () => _pickFFmpegPath(ref, 'ffprobe'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.movie_filter,
                title: 'VidForge',
                subtitle: 'Version 1.0.0',
              ),
              const Divider(),
              _SettingsRow(
                icon: Icons.code,
                title: 'GitHub',
                subtitle: 'View source code',
                onTap: () {
                  // TODO: Open GitHub URL
                },
              ),
              const Divider(),
              _SettingsRow(
                icon: Icons.description_outlined,
                title: 'Licenses',
                subtitle: 'Third-party licenses',
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'VidForge',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickOutputDirectory(WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      ref.read(settingsProvider.notifier).setDefaultOutputDirectory(result);
    }
  }

  Future<void> _pickFFmpegPath(WidgetRef ref, String binary) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      dialogTitle: 'Select $binary executable',
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        if (binary == 'ffmpeg') {
          ref.read(settingsProvider.notifier).setFFmpegPath(path);
        } else {
          ref.read(settingsProvider.notifier).setFFprobePath(path);
        }
      }
    }
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: secondaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryColor,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (onTap != null && trailing == null)
            Icon(
              Icons.chevron_right,
              color: secondaryColor,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
