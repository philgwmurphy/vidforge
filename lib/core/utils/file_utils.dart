import 'dart:io';
import 'package:path/path.dart' as p;

/// Utility functions for file operations
class FileUtils {
  FileUtils._();

  /// Format file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get file extension without dot
  static String getExtension(String path) {
    return p.extension(path).replaceFirst('.', '').toLowerCase();
  }

  /// Get filename without extension
  static String getBasename(String path) {
    return p.basenameWithoutExtension(path);
  }

  /// Get filename with extension
  static String getFilename(String path) {
    return p.basename(path);
  }

  /// Get directory path
  static String getDirectory(String path) {
    return p.dirname(path);
  }

  /// Generate output path with suffix
  static String generateOutputPath(
    String inputPath,
    String suffix, {
    String? newExtension,
    String? outputDir,
  }) {
    final dir = outputDir ?? getDirectory(inputPath);
    final basename = getBasename(inputPath);
    final ext = newExtension ?? getExtension(inputPath);

    return p.join(dir, '${basename}_$suffix.$ext');
  }

  /// Generate unique filename if file exists
  static String generateUniquePath(String path) {
    if (!File(path).existsSync()) return path;

    final dir = getDirectory(path);
    final basename = getBasename(path);
    final ext = getExtension(path);

    var counter = 1;
    String newPath;
    do {
      newPath = p.join(dir, '$basename ($counter).$ext');
      counter++;
    } while (File(newPath).existsSync());

    return newPath;
  }

  /// Check if file is a video file
  static bool isVideoFile(String path) {
    const videoExtensions = [
      'mp4', 'mkv', 'mov', 'avi', 'wmv', 'flv', 'webm',
      'm4v', 'mpeg', 'mpg', '3gp', 'ts', 'mts', 'm2ts',
    ];
    return videoExtensions.contains(getExtension(path));
  }

  /// Check if file is an audio file
  static bool isAudioFile(String path) {
    const audioExtensions = [
      'mp3', 'aac', 'wav', 'flac', 'ogg', 'm4a', 'wma', 'opus',
    ];
    return audioExtensions.contains(getExtension(path));
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return file.length();
    }
    return 0;
  }

  /// Check if file exists
  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// Delete file if exists
  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Ensure directory exists
  static Future<void> ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}
