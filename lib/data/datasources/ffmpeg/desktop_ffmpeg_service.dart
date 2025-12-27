import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../domain/entities/media_info.dart';
import 'ffmpeg_service.dart';

/// FFmpeg service implementation for desktop platforms using Process API
class DesktopFFmpegService implements FFmpegService {
  final String? _ffmpegPath;
  final String? _ffprobePath;
  final Map<String, Process> _activeProcesses = {};
  final List<FFmpegSession> _sessions = [];

  DesktopFFmpegService({
    String? ffmpegPath,
    String? ffprobePath,
  })  : _ffmpegPath = ffmpegPath,
        _ffprobePath = ffprobePath;

  String get ffmpegPath => _ffmpegPath ?? 'ffmpeg';
  String get ffprobePath => _ffprobePath ?? 'ffprobe';

  @override
  List<FFmpegSession> get activeSessions =>
      _sessions.where((s) => !s.isCancelled).toList();

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run(ffmpegPath, ['-version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getVersion() async {
    try {
      final result = await Process.run(ffmpegPath, ['-version']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(r'ffmpeg version (\S+)').firstMatch(output);
        return match?.group(1);
      }
    } catch (e) {
      // FFmpeg not available
    }
    return null;
  }

  @override
  Future<FFmpegResult> execute(
    List<String> arguments, {
    Duration? totalDuration,
    void Function(FFmpegProgress)? onProgress,
    void Function(String)? onLog,
  }) async {
    final sessionId = const Uuid().v4();
    final session = FFmpegSession(
      id: sessionId,
      startTime: DateTime.now(),
      arguments: arguments,
    );
    _sessions.add(session);

    final stopwatch = Stopwatch()..start();

    try {
      final process = await Process.start(
        ffmpegPath,
        ['-progress', 'pipe:1', ...arguments],
      );

      _activeProcesses[sessionId] = process;

      final progressController = StreamController<String>();
      final logBuffer = StringBuffer();
      Duration? lastTime;

      // Parse stdout for progress
      process.stdout.transform(utf8.decoder).listen((data) {
        progressController.add(data);
      });

      // Parse stderr for logs
      process.stderr.transform(utf8.decoder).listen((data) {
        logBuffer.write(data);
        onLog?.call(data);
      });

      // Process progress updates
      progressController.stream.listen((data) {
        final progress = _parseProgress(data, totalDuration, lastTime);
        if (progress != null) {
          lastTime = progress.time;
          onProgress?.call(progress);
        }
      });

      final exitCode = await process.exitCode;
      stopwatch.stop();

      _activeProcesses.remove(sessionId);
      _sessions.remove(session);

      if (session.isCancelled) {
        return FFmpegResult(
          success: false,
          returnCode: -1,
          error: 'Cancelled',
          executionTime: stopwatch.elapsed,
        );
      }

      return FFmpegResult(
        success: exitCode == 0,
        returnCode: exitCode,
        output: logBuffer.toString(),
        error: exitCode != 0 ? logBuffer.toString() : null,
        executionTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _activeProcesses.remove(sessionId);
      _sessions.remove(session);

      return FFmpegResult(
        success: false,
        returnCode: -1,
        error: e.toString(),
        executionTime: stopwatch.elapsed,
      );
    }
  }

  FFmpegProgress? _parseProgress(
    String data,
    Duration? totalDuration,
    Duration? lastTime,
  ) {
    final lines = data.split('\n');
    int? frame;
    double? fps;
    int? bitrate;
    int? size;
    Duration? time;
    double? speed;

    for (final line in lines) {
      final parts = line.split('=');
      if (parts.length != 2) continue;

      final key = parts[0].trim();
      final value = parts[1].trim();

      switch (key) {
        case 'frame':
          frame = int.tryParse(value);
          break;
        case 'fps':
          fps = double.tryParse(value);
          break;
        case 'bitrate':
          final match = RegExp(r'(\d+\.?\d*)').firstMatch(value);
          if (match != null) {
            bitrate = (double.parse(match.group(1)!) * 1000).toInt();
          }
          break;
        case 'total_size':
          size = int.tryParse(value);
          break;
        case 'out_time_ms':
          final ms = int.tryParse(value);
          if (ms != null) {
            time = Duration(microseconds: ms);
          }
          break;
        case 'speed':
          final match = RegExp(r'(\d+\.?\d*)').firstMatch(value);
          if (match != null) {
            speed = double.tryParse(match.group(1)!);
          }
          break;
      }
    }

    if (time != null) {
      double progress = 0;
      if (totalDuration != null && totalDuration.inMilliseconds > 0) {
        progress = time.inMilliseconds / totalDuration.inMilliseconds;
        progress = progress.clamp(0.0, 1.0);
      }

      return FFmpegProgress(
        frame: frame ?? 0,
        fps: fps ?? 0,
        bitrate: bitrate ?? 0,
        size: size ?? 0,
        time: time,
        speed: speed ?? 0,
        progress: progress,
      );
    }

    return null;
  }

  @override
  Future<MediaInfo> getMediaInfo(String path) async {
    final result = await Process.run(
      ffprobePath,
      [
        '-v',
        'quiet',
        '-print_format',
        'json',
        '-show_format',
        '-show_streams',
        path,
      ],
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to probe media: ${result.stderr}');
    }

    final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    return _parseMediaInfo(path, json);
  }

  MediaInfo _parseMediaInfo(String path, Map<String, dynamic> json) {
    final format = json['format'] as Map<String, dynamic>? ?? {};
    final streams = json['streams'] as List<dynamic>? ?? [];

    VideoStream? videoStream;
    final audioStreams = <AudioStream>[];
    final subtitleStreams = <SubtitleStream>[];

    for (final stream in streams) {
      final s = stream as Map<String, dynamic>;
      final codecType = s['codec_type'] as String?;

      switch (codecType) {
        case 'video':
          if (videoStream == null) {
            videoStream = _parseVideoStream(s);
          }
          break;
        case 'audio':
          audioStreams.add(_parseAudioStream(s));
          break;
        case 'subtitle':
          subtitleStreams.add(_parseSubtitleStream(s));
          break;
      }
    }

    final durationStr = format['duration'] as String?;
    final duration = durationStr != null
        ? Duration(
            milliseconds: (double.parse(durationStr) * 1000).toInt(),
          )
        : Duration.zero;

    return MediaInfo(
      path: path,
      filename: p.basename(path),
      fileSize: int.tryParse(format['size']?.toString() ?? '0') ?? 0,
      duration: duration,
      format: format['format_name'] as String? ?? 'unknown',
      bitrate: int.tryParse(format['bit_rate']?.toString() ?? '0') ?? 0,
      videoStream: videoStream,
      audioStreams: audioStreams,
      subtitleStreams: subtitleStreams,
      metadata: _parseMetadata(format['tags'] as Map<String, dynamic>?),
    );
  }

  VideoStream _parseVideoStream(Map<String, dynamic> s) {
    final frameRateStr = s['r_frame_rate'] as String? ?? '0/1';
    final frameRateParts = frameRateStr.split('/');
    double frameRate = 0;
    if (frameRateParts.length == 2) {
      final num = double.tryParse(frameRateParts[0]) ?? 0;
      final den = double.tryParse(frameRateParts[1]) ?? 1;
      frameRate = den > 0 ? num / den : 0;
    }

    final tags = s['tags'] as Map<String, dynamic>? ?? {};
    final rotation =
        int.tryParse(tags['rotate']?.toString() ?? '0') ?? 0;

    return VideoStream(
      index: s['index'] as int? ?? 0,
      codec: s['codec_name'] as String? ?? 'unknown',
      codecLong: s['codec_long_name'] as String? ?? 'Unknown',
      width: s['width'] as int? ?? 0,
      height: s['height'] as int? ?? 0,
      frameRate: frameRate,
      bitrate: int.tryParse(s['bit_rate']?.toString() ?? '0') ?? 0,
      pixelFormat: s['pix_fmt'] as String? ?? 'unknown',
      colorSpace: s['color_space'] as String?,
      colorTransfer: s['color_transfer'] as String?,
      colorPrimaries: s['color_primaries'] as String?,
      isHDR: _isHDR(s),
      rotation: rotation,
    );
  }

  bool _isHDR(Map<String, dynamic> s) {
    final colorTransfer = s['color_transfer'] as String?;
    final colorPrimaries = s['color_primaries'] as String?;
    return colorTransfer == 'smpte2084' ||
        colorTransfer == 'arib-std-b67' ||
        colorPrimaries == 'bt2020';
  }

  AudioStream _parseAudioStream(Map<String, dynamic> s) {
    final tags = s['tags'] as Map<String, dynamic>? ?? {};
    final disposition = s['disposition'] as Map<String, dynamic>? ?? {};

    return AudioStream(
      index: s['index'] as int? ?? 0,
      codec: s['codec_name'] as String? ?? 'unknown',
      codecLong: s['codec_long_name'] as String? ?? 'Unknown',
      sampleRate: int.tryParse(s['sample_rate']?.toString() ?? '0') ?? 0,
      channels: s['channels'] as int? ?? 0,
      channelLayout: s['channel_layout'] as String? ?? 'unknown',
      bitrate: int.tryParse(s['bit_rate']?.toString() ?? '0') ?? 0,
      language: tags['language'] as String?,
      title: tags['title'] as String?,
      isDefault: disposition['default'] == 1,
    );
  }

  SubtitleStream _parseSubtitleStream(Map<String, dynamic> s) {
    final tags = s['tags'] as Map<String, dynamic>? ?? {};
    final disposition = s['disposition'] as Map<String, dynamic>? ?? {};

    return SubtitleStream(
      index: s['index'] as int? ?? 0,
      codec: s['codec_name'] as String? ?? 'unknown',
      language: tags['language'] as String?,
      title: tags['title'] as String?,
      isDefault: disposition['default'] == 1,
      isForced: disposition['forced'] == 1,
    );
  }

  Map<String, String> _parseMetadata(Map<String, dynamic>? tags) {
    if (tags == null) return {};
    return tags.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Future<String?> generateThumbnail(
    String videoPath,
    String outputPath, {
    Duration? atTime,
    int? width,
    int? height,
  }) async {
    final args = <String>['-y'];

    if (atTime != null) {
      args.addAll(['-ss', _formatDuration(atTime)]);
    }

    args.addAll(['-i', videoPath, '-frames:v', '1']);

    if (width != null && height != null) {
      args.addAll(['-vf', 'scale=$width:$height']);
    } else if (width != null) {
      args.addAll(['-vf', 'scale=$width:-2']);
    }

    args.add(outputPath);

    final result = await execute(args);
    return result.success ? outputPath : null;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds.$ms';
  }

  @override
  Future<void> cancel(String sessionId) async {
    final process = _activeProcesses[sessionId];
    if (process != null) {
      final session = _sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => FFmpegSession(
          id: sessionId,
          startTime: DateTime.now(),
          arguments: [],
        ),
      );
      session.isCancelled = true;
      process.kill(ProcessSignal.sigterm);
    }
  }

  @override
  Future<void> cancelAll() async {
    for (final sessionId in _activeProcesses.keys.toList()) {
      await cancel(sessionId);
    }
  }
}
