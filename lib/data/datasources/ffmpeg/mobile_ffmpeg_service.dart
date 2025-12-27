import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../domain/entities/media_info.dart';
import 'ffmpeg_service.dart';

/// FFmpeg service implementation for mobile platforms using FFmpegKit
class MobileFFmpegService implements FFmpegService {
  final Map<String, int> _sessionIds = {};
  final List<FFmpegSession> _sessions = [];

  @override
  List<FFmpegSession> get activeSessions =>
      _sessions.where((s) => !s.isCancelled).toList();

  @override
  Future<bool> isAvailable() async {
    // FFmpegKit is always available when the package is included
    return true;
  }

  @override
  Future<String?> getVersion() async {
    final version = await FFmpegKitConfig.getFFmpegVersion();
    return version;
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
    final command = arguments.join(' ');

    try {
      final ffmpegSession = await FFmpegKit.executeAsync(
        command,
        (completedSession) async {
          // Completion callback
        },
        (log) {
          onLog?.call(log.getMessage());
        },
        (statistics) {
          if (session.isCancelled) return;

          final time = Duration(milliseconds: statistics.getTime().toInt());
          double progress = 0;

          if (totalDuration != null && totalDuration.inMilliseconds > 0) {
            progress = time.inMilliseconds / totalDuration.inMilliseconds;
            progress = progress.clamp(0.0, 1.0);
          }

          onProgress?.call(FFmpegProgress(
            frame: statistics.getVideoFrameNumber(),
            fps: statistics.getVideoFps(),
            bitrate: (statistics.getBitrate() * 1000).toInt(),
            size: statistics.getSize(),
            time: time,
            speed: statistics.getSpeed(),
            progress: progress,
          ));
        },
      );

      _sessionIds[sessionId] = ffmpegSession.getSessionId();

      // Wait for completion
      await ffmpegSession.getReturnCode();
      final returnCode = await ffmpegSession.getReturnCode();
      final output = await ffmpegSession.getOutput();

      stopwatch.stop();
      _sessionIds.remove(sessionId);
      _sessions.remove(session);

      if (session.isCancelled) {
        return FFmpegResult(
          success: false,
          returnCode: -1,
          error: 'Cancelled',
          executionTime: stopwatch.elapsed,
        );
      }

      final success = ReturnCode.isSuccess(returnCode);

      return FFmpegResult(
        success: success,
        returnCode: returnCode?.getValue() ?? -1,
        output: output,
        error: success ? null : output,
        executionTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _sessionIds.remove(sessionId);
      _sessions.remove(session);

      return FFmpegResult(
        success: false,
        returnCode: -1,
        error: e.toString(),
        executionTime: stopwatch.elapsed,
      );
    }
  }

  @override
  Future<MediaInfo> getMediaInfo(String path) async {
    final session = await FFprobeKit.getMediaInformation(path);
    final info = session.getMediaInformation();

    if (info == null) {
      throw Exception('Failed to get media information');
    }

    final streams = info.getStreams();
    VideoStream? videoStream;
    final audioStreams = <AudioStream>[];
    final subtitleStreams = <SubtitleStream>[];

    for (final stream in streams) {
      final codecType = stream.getType();

      switch (codecType) {
        case 'video':
          if (videoStream == null) {
            videoStream = VideoStream(
              index: stream.getIndex() ?? 0,
              codec: stream.getCodec() ?? 'unknown',
              codecLong: stream.getCodecLongName() ?? 'Unknown',
              width: stream.getWidth() ?? 0,
              height: stream.getHeight() ?? 0,
              frameRate: _parseFrameRate(stream.getRealFrameRate()),
              bitrate: int.tryParse(stream.getBitrate() ?? '0') ?? 0,
              pixelFormat: stream.getProperty('pix_fmt') ?? 'unknown',
              colorSpace: stream.getProperty('color_space'),
              colorTransfer: stream.getProperty('color_transfer'),
              colorPrimaries: stream.getProperty('color_primaries'),
              isHDR: _isHDR(stream),
              rotation: int.tryParse(
                      stream.getProperty('tags')?.toString() ?? '0') ??
                  0,
            );
          }
          break;
        case 'audio':
          audioStreams.add(AudioStream(
            index: stream.getIndex() ?? 0,
            codec: stream.getCodec() ?? 'unknown',
            codecLong: stream.getCodecLongName() ?? 'Unknown',
            sampleRate:
                int.tryParse(stream.getSampleRate() ?? '0') ?? 0,
            channels: int.tryParse(stream.getProperty('channels') ?? '0') ?? 0,
            channelLayout: stream.getChannelLayout() ?? 'unknown',
            bitrate: int.tryParse(stream.getBitrate() ?? '0') ?? 0,
            language: stream.getProperty('tags:language'),
            title: stream.getProperty('tags:title'),
            isDefault: stream.getProperty('disposition:default') == '1',
          ));
          break;
        case 'subtitle':
          subtitleStreams.add(SubtitleStream(
            index: stream.getIndex() ?? 0,
            codec: stream.getCodec() ?? 'unknown',
            language: stream.getProperty('tags:language'),
            title: stream.getProperty('tags:title'),
            isDefault: stream.getProperty('disposition:default') == '1',
            isForced: stream.getProperty('disposition:forced') == '1',
          ));
          break;
      }
    }

    final durationMs = info.getDuration() != null
        ? (double.parse(info.getDuration()!) * 1000).toInt()
        : 0;

    return MediaInfo(
      path: path,
      filename: p.basename(path),
      fileSize: int.tryParse(info.getSize() ?? '0') ?? 0,
      duration: Duration(milliseconds: durationMs),
      format: info.getFormat() ?? 'unknown',
      bitrate: int.tryParse(info.getBitrate() ?? '0') ?? 0,
      videoStream: videoStream,
      audioStreams: audioStreams,
      subtitleStreams: subtitleStreams,
      metadata: _parseMetadata(info.getTags()),
    );
  }

  double _parseFrameRate(String? frameRate) {
    if (frameRate == null) return 0;
    final parts = frameRate.split('/');
    if (parts.length != 2) return double.tryParse(frameRate) ?? 0;
    final num = double.tryParse(parts[0]) ?? 0;
    final den = double.tryParse(parts[1]) ?? 1;
    return den > 0 ? num / den : 0;
  }

  bool _isHDR(dynamic stream) {
    final colorTransfer = stream.getProperty('color_transfer');
    final colorPrimaries = stream.getProperty('color_primaries');
    return colorTransfer == 'smpte2084' ||
        colorTransfer == 'arib-std-b67' ||
        colorPrimaries == 'bt2020';
  }

  Map<String, String> _parseMetadata(Map<dynamic, dynamic>? tags) {
    if (tags == null) return {};
    return tags.map((key, value) => MapEntry(key.toString(), value.toString()));
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

    if (result.success && await File(outputPath).exists()) {
      return outputPath;
    }
    return null;
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
    final kitSessionId = _sessionIds[sessionId];
    if (kitSessionId != null) {
      final session = _sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => FFmpegSession(
          id: sessionId,
          startTime: DateTime.now(),
          arguments: [],
        ),
      );
      session.isCancelled = true;
      await FFmpegKit.cancel(kitSessionId);
    }
  }

  @override
  Future<void> cancelAll() async {
    for (final session in _sessions) {
      session.isCancelled = true;
    }
    await FFmpegKit.cancel();
  }
}
