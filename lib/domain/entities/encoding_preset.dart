import 'package:equatable/equatable.dart';

/// Preset category for organization
enum PresetCategory {
  socialMedia,
  device,
  quality,
  streaming,
  archive,
  custom,
}

/// Represents an encoding preset configuration
class EncodingPreset extends Equatable {
  final String id;
  final String name;
  final String description;
  final PresetCategory category;
  final VideoSettings video;
  final AudioSettings audio;
  final String container;
  final bool isBuiltIn;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  const EncodingPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.video,
    required this.audio,
    required this.container,
    this.isBuiltIn = false,
    this.createdAt,
    this.modifiedAt,
  });

  EncodingPreset copyWith({
    String? id,
    String? name,
    String? description,
    PresetCategory? category,
    VideoSettings? video,
    AudioSettings? audio,
    String? container,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return EncodingPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      video: video ?? this.video,
      audio: audio ?? this.audio,
      container: container ?? this.container,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        video,
        audio,
        container,
        isBuiltIn,
        createdAt,
        modifiedAt,
      ];
}

/// Video encoding settings
class VideoSettings extends Equatable {
  final String codec;
  final int? width;
  final int? height;
  final String? frameRate;
  final int? crf;
  final int? bitrate;
  final String preset;
  final String? profile;
  final String? pixelFormat;
  final bool twoPass;

  const VideoSettings({
    required this.codec,
    this.width,
    this.height,
    this.frameRate,
    this.crf,
    this.bitrate,
    this.preset = 'medium',
    this.profile,
    this.pixelFormat,
    this.twoPass = false,
  });

  VideoSettings copyWith({
    String? codec,
    int? width,
    int? height,
    String? frameRate,
    int? crf,
    int? bitrate,
    String? preset,
    String? profile,
    String? pixelFormat,
    bool? twoPass,
  }) {
    return VideoSettings(
      codec: codec ?? this.codec,
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      crf: crf ?? this.crf,
      bitrate: bitrate ?? this.bitrate,
      preset: preset ?? this.preset,
      profile: profile ?? this.profile,
      pixelFormat: pixelFormat ?? this.pixelFormat,
      twoPass: twoPass ?? this.twoPass,
    );
  }

  String get resolution =>
      width != null && height != null ? '${width}x$height' : 'Original';

  @override
  List<Object?> get props => [
        codec,
        width,
        height,
        frameRate,
        crf,
        bitrate,
        preset,
        profile,
        pixelFormat,
        twoPass,
      ];
}

/// Audio encoding settings
class AudioSettings extends Equatable {
  final String codec;
  final int? bitrate;
  final int? sampleRate;
  final int? channels;
  final bool normalize;

  const AudioSettings({
    required this.codec,
    this.bitrate,
    this.sampleRate,
    this.channels,
    this.normalize = false,
  });

  AudioSettings copyWith({
    String? codec,
    int? bitrate,
    int? sampleRate,
    int? channels,
    bool? normalize,
  }) {
    return AudioSettings(
      codec: codec ?? this.codec,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      normalize: normalize ?? this.normalize,
    );
  }

  @override
  List<Object?> get props => [
        codec,
        bitrate,
        sampleRate,
        channels,
        normalize,
      ];
}
