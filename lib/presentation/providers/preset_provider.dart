import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/encoding_preset.dart';

/// Built-in encoding presets
class BuiltInPresets {
  BuiltInPresets._();

  static final List<EncodingPreset> all = [
    // Quality presets
    highQuality,
    balanced,
    smallSize,

    // Social media presets
    youtube1080p,
    youtube720p,
    instagram,
    tiktok,

    // Device presets
    appleDevice,
    androidDevice,
  ];

  static const highQuality = EncodingPreset(
    id: 'high_quality',
    name: 'High Quality',
    description: 'Best quality, larger file size (CRF 18)',
    category: PresetCategory.quality,
    isBuiltIn: true,
    container: 'mp4',
    video: VideoSettings(
      codec: 'libx264',
      crf: 18,
      preset: 'slow',
      profile: 'high',
    ),
    audio: AudioSettings(
      codec: 'aac',
      bitrate: 256,
    ),
  );

  static const balanced = EncodingPreset(
    id: 'balanced',
    name: 'Balanced',
    description: 'Good quality and reasonable file size (CRF 23)',
    category: PresetCategory.quality,
    isBuiltIn: true,
    container: 'mp4',
    video: VideoSettings(
      codec: 'libx264',
      crf: 23,
      preset: 'medium',
      profile: 'high',
    ),
    audio: AudioSettings(
      codec: 'aac',
      bitrate: 192,
    ),
  );

  static const smallSize = EncodingPreset(
    id: 'small_size',
    name: 'Small Size',
    description: 'Smaller file, reduced quality (CRF 28)',
    category: PresetCategory.quality,
    isBuiltIn: true,
    container: 'mp4',
    video: VideoSettings(
      codec: 'libx264',
      crf: 28,
      preset: 'fast',
      profile: 'main',
    ),
    audio: AudioSettings(
      codec: 'aac',
      bitrate: 128,
    ),
  );

  static const youtube1080p = EncodingPreset(
    id: 'youtube_1080p',
    name: 'YouTube 1080p',
    description: 'Optimized for YouTube Full HD upload',
    category: PresetCategory.socialMedia,
    isBuiltIn: true,
    container: 'mp4',
    video: VideoSettings(
      codec: 'libx264',
      width: 1920,
      height: 1080,
      crf: 20,
      preset: 'slow',
      profile: 'high',
    ),
    audio: AudioSettings(
      codec: 'aac',
      bitrate: 192,
      sampleRate: 48000,
    ),
  );

  static const youtube720p = EncodingPreset(
    id: 'youtube_720p',
    name: 'YouTube 720p',
    description: 'Optimized for YouTube HD upload',
    category: PresetCategory.socialMedia,
    isBuiltIn: true,
    container: 'mp4',
    video: VideoSettings(
      codec: 'libx264',
      width: 1280,
      height: 720,
      crf: 20,
      preset: 'medium',
      profile: 'high',
    ),
    audio: AudioSettings(
      codec: 'aac',
      bitrate: 192,
      sampleRate: 48000,
    ),
  );

  static const instagram = EncodingPreset(
    id: 'instagram',
    name: 'Instagram',
    description: 'Optimized for Instagram feed and reels',
    category: PresetCategory.socialMedia,
    isBuiltIn: true,
    container: 'mp4',
    video: VideoSettings(
      codec: 'libx264',
      width: 1080,
      height: 1920,
      frameRate: '30',
      crf: 22,
      preset: 'medium',
      profile: 'high',
      pixelFormat: 'yuv420p',
    ),
    audio: AudioSettings(
      codec: 'aac',
      bitrate: 128,
      sampleRate: 44100,
    ),
  );

  static const tiktok = EncodingPreset(
    id: 'tiktok',
    name: 'TikTok',
    description: 'Optimized for TikTok upload',
    category: PresetCategory.socialMedia,
    isBuiltIn: true,
    container: 'mp4',
    video: VideoSettings(
      codec: 'libx264',
      width: 1080,
      height: 1920,
      frameRate: '30',
      crf: 22,
      preset: 'medium',
      profile: 'high',
      pixelFormat: 'yuv420p',
    ),
    audio: AudioSettings(
      codec: 'aac',
      bitrate: 128,
      sampleRate: 44100,
    ),
  );

  static const appleDevice = EncodingPreset(
    id: 'apple_device',
    name: 'Apple Devices',
    description: 'Compatible with iPhone, iPad, Apple TV',
    category: PresetCategory.device,
    isBuiltIn: true,
    container: 'mp4',
    video: VideoSettings(
      codec: 'libx264',
      crf: 22,
      preset: 'medium',
      profile: 'high',
      pixelFormat: 'yuv420p',
    ),
    audio: AudioSettings(
      codec: 'aac',
      bitrate: 192,
      sampleRate: 48000,
      channels: 2,
    ),
  );

  static const androidDevice = EncodingPreset(
    id: 'android_device',
    name: 'Android Devices',
    description: 'Wide compatibility with Android devices',
    category: PresetCategory.device,
    isBuiltIn: true,
    container: 'mp4',
    video: VideoSettings(
      codec: 'libx264',
      crf: 23,
      preset: 'medium',
      profile: 'main',
      pixelFormat: 'yuv420p',
    ),
    audio: AudioSettings(
      codec: 'aac',
      bitrate: 128,
      sampleRate: 44100,
      channels: 2,
    ),
  );
}

/// State for preset management
class PresetState {
  final List<EncodingPreset> presets;
  final String? selectedPresetId;

  const PresetState({
    this.presets = const [],
    this.selectedPresetId,
  });

  PresetState copyWith({
    List<EncodingPreset>? presets,
    String? selectedPresetId,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
    );
  }

  EncodingPreset? get selectedPreset {
    if (selectedPresetId == null) return null;
    return presets.firstWhere(
      (p) => p.id == selectedPresetId,
      orElse: () => BuiltInPresets.balanced,
    );
  }

  List<EncodingPreset> get builtInPresets =>
      presets.where((p) => p.isBuiltIn).toList();

  List<EncodingPreset> get customPresets =>
      presets.where((p) => !p.isBuiltIn).toList();

  List<EncodingPreset> presetsByCategory(PresetCategory category) =>
      presets.where((p) => p.category == category).toList();
}

/// Notifier for preset management
class PresetNotifier extends StateNotifier<PresetState> {
  PresetNotifier()
      : super(PresetState(
          presets: BuiltInPresets.all,
          selectedPresetId: 'balanced',
        ));

  void selectPreset(String id) {
    state = state.copyWith(selectedPresetId: id);
  }

  void addCustomPreset(EncodingPreset preset) {
    final newPresets = [...state.presets, preset];
    state = state.copyWith(presets: newPresets);
  }

  void updatePreset(EncodingPreset preset) {
    final newPresets = state.presets.map((p) {
      return p.id == preset.id ? preset : p;
    }).toList();
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    // Don't delete built-in presets
    final preset = state.presets.firstWhere(
      (p) => p.id == id,
      orElse: () => BuiltInPresets.balanced,
    );
    if (preset.isBuiltIn) return;

    final newPresets = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(presets: newPresets);

    // If deleted preset was selected, select default
    if (state.selectedPresetId == id) {
      state = state.copyWith(selectedPresetId: 'balanced');
    }
  }
}

/// Provider for presets
final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  return PresetNotifier();
});

/// Provider for selected preset
final selectedPresetProvider = Provider<EncodingPreset?>((ref) {
  return ref.watch(presetProvider).selectedPreset;
});
