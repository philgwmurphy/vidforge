/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// Application name
  static const appName = 'VidForge';

  /// Application version
  static const appVersion = '1.0.0';

  /// Supported input video formats
  static const supportedVideoFormats = [
    'mp4',
    'mkv',
    'mov',
    'avi',
    'wmv',
    'flv',
    'webm',
    'm4v',
    'mpeg',
    'mpg',
    '3gp',
    'ts',
    'mts',
    'm2ts',
  ];

  /// Supported input audio formats
  static const supportedAudioFormats = [
    'mp3',
    'aac',
    'wav',
    'flac',
    'ogg',
    'm4a',
    'wma',
    'opus',
  ];

  /// Default concurrent jobs for batch processing
  static const defaultConcurrentJobs = 2;

  /// Maximum concurrent jobs
  static const maxConcurrentJobs = 8;

  /// Thumbnail generation interval in seconds
  static const thumbnailIntervalSeconds = 10;

  /// Maximum recent files to remember
  static const maxRecentFiles = 20;

  /// Animation durations
  static const animationDurationFast = Duration(milliseconds: 150);
  static const animationDurationNormal = Duration(milliseconds: 300);
  static const animationDurationSlow = Duration(milliseconds: 500);

  /// UI constants
  static const borderRadius = 8.0;
  static const borderRadiusLarge = 12.0;
  static const borderRadiusXLarge = 16.0;

  static const paddingSmall = 8.0;
  static const paddingMedium = 16.0;
  static const paddingLarge = 24.0;
  static const paddingXLarge = 32.0;

  /// Desktop window constraints
  static const minWindowWidth = 900.0;
  static const minWindowHeight = 600.0;
  static const defaultWindowWidth = 1200.0;
  static const defaultWindowHeight = 800.0;
}
