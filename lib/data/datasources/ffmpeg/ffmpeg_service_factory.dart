import 'dart:io';

import 'ffmpeg_service.dart';
import 'desktop_ffmpeg_service.dart';
import 'mobile_ffmpeg_service.dart';

/// Factory for creating platform-appropriate FFmpeg service
class FFmpegServiceFactory {
  FFmpegServiceFactory._();

  /// Create the appropriate FFmpeg service for the current platform
  static FFmpegService create({
    String? ffmpegPath,
    String? ffprobePath,
  }) {
    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platforms use FFmpegKit
      return MobileFFmpegService();
    } else if (Platform.isMacOS) {
      // macOS can use either - prefer FFmpegKit for bundled solution
      // but fall back to system FFmpeg if needed
      return MobileFFmpegService();
    } else {
      // Windows and Linux use bundled/system FFmpeg
      return DesktopFFmpegService(
        ffmpegPath: ffmpegPath,
        ffprobePath: ffprobePath,
      );
    }
  }

  /// Check if the current platform uses FFmpegKit
  static bool get usesFFmpegKit {
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  /// Check if the current platform needs bundled FFmpeg binaries
  static bool get needsBundledBinaries {
    return Platform.isWindows || Platform.isLinux;
  }
}
