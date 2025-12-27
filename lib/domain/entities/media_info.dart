import 'package:equatable/equatable.dart';

/// Represents complete information about a media file
class MediaInfo extends Equatable {
  final String path;
  final String filename;
  final int fileSize;
  final Duration duration;
  final String format;
  final int bitrate;
  final VideoStream? videoStream;
  final List<AudioStream> audioStreams;
  final List<SubtitleStream> subtitleStreams;
  final Map<String, String> metadata;

  const MediaInfo({
    required this.path,
    required this.filename,
    required this.fileSize,
    required this.duration,
    required this.format,
    required this.bitrate,
    this.videoStream,
    this.audioStreams = const [],
    this.subtitleStreams = const [],
    this.metadata = const {},
  });

  bool get hasVideo => videoStream != null;
  bool get hasAudio => audioStreams.isNotEmpty;
  bool get hasSubtitles => subtitleStreams.isNotEmpty;

  String get resolution => videoStream != null
      ? '${videoStream!.width}x${videoStream!.height}'
      : 'N/A';

  @override
  List<Object?> get props => [
        path,
        filename,
        fileSize,
        duration,
        format,
        bitrate,
        videoStream,
        audioStreams,
        subtitleStreams,
        metadata,
      ];
}

/// Represents a video stream within a media file
class VideoStream extends Equatable {
  final int index;
  final String codec;
  final String codecLong;
  final int width;
  final int height;
  final double frameRate;
  final int bitrate;
  final String pixelFormat;
  final String? colorSpace;
  final String? colorTransfer;
  final String? colorPrimaries;
  final bool isHDR;
  final int rotation;

  const VideoStream({
    required this.index,
    required this.codec,
    required this.codecLong,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.bitrate,
    required this.pixelFormat,
    this.colorSpace,
    this.colorTransfer,
    this.colorPrimaries,
    this.isHDR = false,
    this.rotation = 0,
  });

  String get resolution => '${width}x$height';

  String get aspectRatio {
    final gcd = _gcd(width, height);
    return '${width ~/ gcd}:${height ~/ gcd}';
  }

  int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  @override
  List<Object?> get props => [
        index,
        codec,
        codecLong,
        width,
        height,
        frameRate,
        bitrate,
        pixelFormat,
        colorSpace,
        colorTransfer,
        colorPrimaries,
        isHDR,
        rotation,
      ];
}

/// Represents an audio stream within a media file
class AudioStream extends Equatable {
  final int index;
  final String codec;
  final String codecLong;
  final int sampleRate;
  final int channels;
  final String channelLayout;
  final int bitrate;
  final String? language;
  final String? title;
  final bool isDefault;

  const AudioStream({
    required this.index,
    required this.codec,
    required this.codecLong,
    required this.sampleRate,
    required this.channels,
    required this.channelLayout,
    required this.bitrate,
    this.language,
    this.title,
    this.isDefault = false,
  });

  String get displayName {
    final parts = <String>[];
    if (title != null && title!.isNotEmpty) {
      parts.add(title!);
    }
    if (language != null && language!.isNotEmpty) {
      parts.add('[$language]');
    }
    parts.add(channelLayout);
    return parts.join(' ');
  }

  @override
  List<Object?> get props => [
        index,
        codec,
        codecLong,
        sampleRate,
        channels,
        channelLayout,
        bitrate,
        language,
        title,
        isDefault,
      ];
}

/// Represents a subtitle stream within a media file
class SubtitleStream extends Equatable {
  final int index;
  final String codec;
  final String? language;
  final String? title;
  final bool isDefault;
  final bool isForced;

  const SubtitleStream({
    required this.index,
    required this.codec,
    this.language,
    this.title,
    this.isDefault = false,
    this.isForced = false,
  });

  String get displayName {
    final parts = <String>[];
    if (title != null && title!.isNotEmpty) {
      parts.add(title!);
    }
    if (language != null && language!.isNotEmpty) {
      parts.add('[$language]');
    }
    if (isForced) parts.add('(Forced)');
    return parts.isEmpty ? 'Subtitle ${index + 1}' : parts.join(' ');
  }

  @override
  List<Object?> get props => [
        index,
        codec,
        language,
        title,
        isDefault,
        isForced,
      ];
}
