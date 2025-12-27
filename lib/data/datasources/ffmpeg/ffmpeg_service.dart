import 'dart:async';
import '../../../domain/entities/media_info.dart';

/// Progress information from FFmpeg
class FFmpegProgress {
  final int frame;
  final double fps;
  final int bitrate;
  final int size;
  final Duration time;
  final double speed;
  final double progress;

  const FFmpegProgress({
    this.frame = 0,
    this.fps = 0,
    this.bitrate = 0,
    this.size = 0,
    this.time = Duration.zero,
    this.speed = 0,
    this.progress = 0,
  });

  @override
  String toString() {
    return 'FFmpegProgress(frame: $frame, fps: $fps, progress: ${(progress * 100).toStringAsFixed(1)}%, speed: ${speed}x)';
  }
}

/// Result of an FFmpeg execution
class FFmpegResult {
  final bool success;
  final int returnCode;
  final String? output;
  final String? error;
  final Duration executionTime;

  const FFmpegResult({
    required this.success,
    required this.returnCode,
    this.output,
    this.error,
    required this.executionTime,
  });
}

/// Session info for tracking FFmpeg executions
class FFmpegSession {
  final String id;
  final DateTime startTime;
  final List<String> arguments;
  bool isCancelled;

  FFmpegSession({
    required this.id,
    required this.startTime,
    required this.arguments,
    this.isCancelled = false,
  });
}

/// Abstract interface for FFmpeg operations
abstract class FFmpegService {
  /// Execute FFmpeg command with arguments
  Future<FFmpegResult> execute(
    List<String> arguments, {
    Duration? totalDuration,
    void Function(FFmpegProgress)? onProgress,
    void Function(String)? onLog,
  });

  /// Execute FFprobe to get media information
  Future<MediaInfo> getMediaInfo(String path);

  /// Generate thumbnail from video at specific time
  Future<String?> generateThumbnail(
    String videoPath,
    String outputPath, {
    Duration? atTime,
    int? width,
    int? height,
  });

  /// Cancel a running session
  Future<void> cancel(String sessionId);

  /// Cancel all running sessions
  Future<void> cancelAll();

  /// Get list of active sessions
  List<FFmpegSession> get activeSessions;

  /// Check if FFmpeg is available
  Future<bool> isAvailable();

  /// Get FFmpeg version
  Future<String?> getVersion();
}
