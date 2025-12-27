/// FFmpeg-related constants
class FFmpegConstants {
  FFmpegConstants._();

  /// Video codecs
  static const videoCodecs = {
    'libx264': 'H.264 (x264)',
    'libx265': 'H.265/HEVC (x265)',
    'libvpx-vp9': 'VP9',
    'libaom-av1': 'AV1',
    'mpeg4': 'MPEG-4',
    'copy': 'Copy (No re-encoding)',
  };

  /// Audio codecs
  static const audioCodecs = {
    'aac': 'AAC',
    'libmp3lame': 'MP3',
    'libopus': 'Opus',
    'libvorbis': 'Vorbis',
    'flac': 'FLAC',
    'pcm_s16le': 'PCM (WAV)',
    'copy': 'Copy (No re-encoding)',
  };

  /// Container formats
  static const containerFormats = {
    'mp4': 'MP4',
    'mkv': 'MKV (Matroska)',
    'webm': 'WebM',
    'mov': 'MOV (QuickTime)',
    'avi': 'AVI',
    'ts': 'MPEG-TS',
  };

  /// Common resolutions
  static const resolutions = {
    '3840x2160': '4K (3840x2160)',
    '2560x1440': '1440p (2560x1440)',
    '1920x1080': '1080p (1920x1080)',
    '1280x720': '720p (1280x720)',
    '854x480': '480p (854x480)',
    '640x360': '360p (640x360)',
  };

  /// Frame rates
  static const frameRates = {
    'original': 'Original',
    '60': '60 fps',
    '30': '30 fps',
    '29.97': '29.97 fps (NTSC)',
    '25': '25 fps (PAL)',
    '24': '24 fps (Film)',
    '23.976': '23.976 fps',
  };

  /// x264/x265 presets (speed vs compression)
  static const encodingPresets = {
    'ultrafast': 'Ultra Fast (Largest file)',
    'superfast': 'Super Fast',
    'veryfast': 'Very Fast',
    'faster': 'Faster',
    'fast': 'Fast',
    'medium': 'Medium (Balanced)',
    'slow': 'Slow',
    'slower': 'Slower',
    'veryslow': 'Very Slow (Smallest file)',
  };

  /// CRF quality descriptions
  static const crfDescriptions = {
    18: 'Visually Lossless',
    20: 'High Quality',
    23: 'Balanced (Default)',
    26: 'Good Quality',
    28: 'Medium Quality',
    32: 'Low Quality (Small file)',
  };

  /// Audio bitrates (kbps)
  static const audioBitrates = [64, 96, 128, 160, 192, 256, 320];

  /// Audio sample rates
  static const audioSampleRates = {
    'original': 'Original',
    '44100': '44.1 kHz',
    '48000': '48 kHz',
    '96000': '96 kHz',
  };

  /// Audio channels
  static const audioChannels = {
    'original': 'Original',
    '1': 'Mono',
    '2': 'Stereo',
    '6': '5.1 Surround',
  };

  /// Hardware acceleration options
  static const hardwareAccel = {
    'auto': 'Auto Detect',
    'none': 'Software Only',
    'nvenc': 'NVIDIA NVENC',
    'qsv': 'Intel Quick Sync',
    'videotoolbox': 'Apple VideoToolbox',
    'vaapi': 'VA-API (Linux)',
  };
}
