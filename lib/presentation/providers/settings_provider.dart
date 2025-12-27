import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application settings state
class AppSettings {
  final String? defaultOutputDirectory;
  final String? ffmpegPath;
  final String? ffprobePath;
  final int concurrentJobs;
  final bool showNotifications;
  final bool deleteSourceAfterConversion;
  final bool overwriteExisting;
  final String defaultPresetId;

  const AppSettings({
    this.defaultOutputDirectory,
    this.ffmpegPath,
    this.ffprobePath,
    this.concurrentJobs = 2,
    this.showNotifications = true,
    this.deleteSourceAfterConversion = false,
    this.overwriteExisting = false,
    this.defaultPresetId = 'balanced',
  });

  AppSettings copyWith({
    String? defaultOutputDirectory,
    String? ffmpegPath,
    String? ffprobePath,
    int? concurrentJobs,
    bool? showNotifications,
    bool? deleteSourceAfterConversion,
    bool? overwriteExisting,
    String? defaultPresetId,
  }) {
    return AppSettings(
      defaultOutputDirectory:
          defaultOutputDirectory ?? this.defaultOutputDirectory,
      ffmpegPath: ffmpegPath ?? this.ffmpegPath,
      ffprobePath: ffprobePath ?? this.ffprobePath,
      concurrentJobs: concurrentJobs ?? this.concurrentJobs,
      showNotifications: showNotifications ?? this.showNotifications,
      deleteSourceAfterConversion:
          deleteSourceAfterConversion ?? this.deleteSourceAfterConversion,
      overwriteExisting: overwriteExisting ?? this.overwriteExisting,
      defaultPresetId: defaultPresetId ?? this.defaultPresetId,
    );
  }
}

/// Notifier for app settings
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    state = AppSettings(
      defaultOutputDirectory: prefs.getString('defaultOutputDirectory'),
      ffmpegPath: prefs.getString('ffmpegPath'),
      ffprobePath: prefs.getString('ffprobePath'),
      concurrentJobs: prefs.getInt('concurrentJobs') ?? 2,
      showNotifications: prefs.getBool('showNotifications') ?? true,
      deleteSourceAfterConversion:
          prefs.getBool('deleteSourceAfterConversion') ?? false,
      overwriteExisting: prefs.getBool('overwriteExisting') ?? false,
      defaultPresetId: prefs.getString('defaultPresetId') ?? 'balanced',
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (state.defaultOutputDirectory != null) {
      await prefs.setString(
          'defaultOutputDirectory', state.defaultOutputDirectory!);
    }
    if (state.ffmpegPath != null) {
      await prefs.setString('ffmpegPath', state.ffmpegPath!);
    }
    if (state.ffprobePath != null) {
      await prefs.setString('ffprobePath', state.ffprobePath!);
    }
    await prefs.setInt('concurrentJobs', state.concurrentJobs);
    await prefs.setBool('showNotifications', state.showNotifications);
    await prefs.setBool(
        'deleteSourceAfterConversion', state.deleteSourceAfterConversion);
    await prefs.setBool('overwriteExisting', state.overwriteExisting);
    await prefs.setString('defaultPresetId', state.defaultPresetId);
  }

  Future<void> setDefaultOutputDirectory(String? path) async {
    state = state.copyWith(defaultOutputDirectory: path);
    await _saveSettings();
  }

  Future<void> setFFmpegPath(String? path) async {
    state = state.copyWith(ffmpegPath: path);
    await _saveSettings();
  }

  Future<void> setFFprobePath(String? path) async {
    state = state.copyWith(ffprobePath: path);
    await _saveSettings();
  }

  Future<void> setConcurrentJobs(int count) async {
    state = state.copyWith(concurrentJobs: count.clamp(1, 8));
    await _saveSettings();
  }

  Future<void> setShowNotifications(bool value) async {
    state = state.copyWith(showNotifications: value);
    await _saveSettings();
  }

  Future<void> setDeleteSourceAfterConversion(bool value) async {
    state = state.copyWith(deleteSourceAfterConversion: value);
    await _saveSettings();
  }

  Future<void> setOverwriteExisting(bool value) async {
    state = state.copyWith(overwriteExisting: value);
    await _saveSettings();
  }

  Future<void> setDefaultPresetId(String id) async {
    state = state.copyWith(defaultPresetId: id);
    await _saveSettings();
  }
}

/// Provider for app settings
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
