# VidForge - Implementation Plan

> A modern, elegant FFmpeg GUI for video transcoding, editing, and batch processing built with Flutter for Desktop (Windows, macOS, Linux) and Mobile (iOS, Android).

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Technology Stack](#technology-stack)
3. [Architecture Design](#architecture-design)
4. [Core Features](#core-features)
5. [UI/UX Design](#uiux-design)
6. [Platform Considerations](#platform-considerations)
7. [FFmpeg Integration Strategy](#ffmpeg-integration-strategy)
8. [Project Structure](#project-structure)
9. [Implementation Phases](#implementation-phases)
10. [Key Dependencies](#key-dependencies)
11. [Testing Strategy](#testing-strategy)
12. [Distribution & Packaging](#distribution--packaging)

---

## Executive Summary

VidForge aims to be the ultimate cross-platform FFmpeg GUI, combining the power of FFmpeg's comprehensive multimedia capabilities with an intuitive, modern interface. The application will support both quick operations (lossless trimming, format conversion) and advanced workflows (batch processing, custom encoding presets).

### Target Users
- **Casual users**: Quick video trimming, format conversion, compression
- **Content creators**: Batch processing, preset management, quality optimization
- **Power users**: Custom FFmpeg command builder, advanced encoding options

### Key Differentiators
- Cross-platform consistency (Desktop + Mobile from single codebase)
- Both lossless and transcoding operations
- Intelligent preset system with visual quality preview
- Real-time progress tracking with detailed statistics
- Batch processing with queue management

---

## Technology Stack

### Core Framework
- **Flutter 3.x** - Cross-platform UI framework
- **Dart 3.x** - Programming language with null safety

### FFmpeg Integration

#### Mobile (iOS, Android, macOS)
- **ffmpeg_kit_flutter_new** - Community-maintained fork of FFmpegKit
  - Full GPL package with 25+ external libraries
  - Supports: dav1d, fontconfig, freetype, fribidi, gmp, gnutls, kvazaar, lame, libass, libiconv, libilbc, libtheora, libvorbis, libvpx, libwebp, libxml2, opencore-amr, opus, shine, snappy, soxr, speex, twolame, vo-amrwbenc, zimg
  - GPL libraries: vid.stab, x264, x265, xvidcore

#### Desktop (Windows, Linux)
- **Bundled FFmpeg binaries** - Ship platform-specific FFmpeg executables
- **Process execution** via Dart's `Process.run()` / `Process.start()`
- Parse stdout/stderr for progress tracking

### State Management
- **Riverpod** - Recommended for modern Flutter apps
  - Compile-time safety
  - Excellent testability
  - Reduced boilerplate
  - Great for mid-to-large projects

### Architecture Pattern
- **MVVM (Model-View-ViewModel)** with clean architecture principles
  - Clear separation of concerns
  - Testable business logic
  - Reactive UI updates

---

## Architecture Design

### Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Screens   │  │   Widgets   │  │   View Models       │  │
│  │  (Pages)    │  │ (Components)│  │   (Controllers)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                     DOMAIN LAYER                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Entities  │  │  Use Cases  │  │   Repository        │  │
│  │   (Models)  │  │  (Business) │  │   Interfaces        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                      DATA LAYER                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Repositories│  │Data Sources │  │   FFmpeg Service    │  │
│  │   (Impl)    │  │  (Local/DB) │  │   (Platform)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                   PLATFORM LAYER                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  FFmpegKit (Mobile)  │  Process API (Desktop)           ││
│  │  File System         │  Platform Channels               ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Core Services

```dart
// Abstract FFmpeg service interface
abstract class FFmpegService {
  Future<MediaInfo> getMediaInfo(String path);
  Future<void> execute(FFmpegCommand command, {ProgressCallback? onProgress});
  Future<void> cancel(String sessionId);
  Stream<FFmpegProgress> get progressStream;
}

// Platform-specific implementations
class MobileFFmpegService implements FFmpegService { /* FFmpegKit */ }
class DesktopFFmpegService implements FFmpegService { /* Process API */ }
```

---

## Core Features

### 1. Video Operations

#### Quick Operations (Lossless)
- **Trim/Cut** - Extract segments without re-encoding (`-c copy`)
- **Split** - Divide video into multiple parts
- **Merge/Concatenate** - Join multiple videos
- **Extract Audio** - Pull audio track without video
- **Extract Frames** - Export specific frames as images

#### Transcoding Operations
- **Format Conversion** - Convert between containers (MP4, MKV, WebM, MOV, AVI)
- **Codec Change** - Re-encode with different codecs (H.264, H.265/HEVC, VP9, AV1)
- **Compression** - Reduce file size with quality control (CRF-based)
- **Resolution Change** - Scale video dimensions
- **Frame Rate Adjustment** - Change FPS

#### Advanced Operations
- **Video Stabilization** - Using vid.stab library
- **Subtitle Burning** - Hardcode subtitles into video
- **Audio Normalization** - Consistent audio levels
- **Watermarking** - Add image/text overlays
- **Filters** - Crop, rotate, flip, color adjustments

### 2. Batch Processing

```
┌────────────────────────────────────────────┐
│            BATCH PROCESSOR                  │
├────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │  Queue   │→ │ Worker   │→ │ Output   │ │
│  │ Manager  │  │  Pool    │  │ Handler  │ │
│  └──────────┘  └──────────┘  └──────────┘ │
│                                            │
│  Features:                                 │
│  • Drag & drop multiple files              │
│  • Apply same preset to all                │
│  • Individual progress tracking            │
│  • Pause/Resume queue                      │
│  • Priority reordering                     │
│  • Concurrent processing (configurable)   │
└────────────────────────────────────────────┘
```

### 3. Preset System

```dart
class EncodingPreset {
  final String id;
  final String name;
  final String description;
  final PresetCategory category;
  final VideoSettings video;
  final AudioSettings audio;
  final ContainerFormat container;
  final List<String> tags;
  final bool isBuiltIn;
}

// Built-in presets
enum PresetCategory {
  socialMedia,    // YouTube, Instagram, TikTok, Twitter
  device,         // iPhone, Android, TV, Web
  quality,        // High, Medium, Low, Lossless
  streaming,      // HLS, DASH
  archive,        // ProRes, DNxHD
  custom,
}
```

#### Built-in Presets
| Category | Presets |
|----------|---------|
| Social Media | YouTube 4K/1080p/720p, Instagram Reels, TikTok, Twitter |
| Devices | iPhone/iPad, Android, Apple TV, Roku, Web Browser |
| Quality | High Quality (CRF 18), Balanced (CRF 23), Small Size (CRF 28) |
| Streaming | HLS Playlist, DASH Segments |
| Archive | ProRes 422, DNxHD, Lossless H.264 |

### 4. Media Analysis

```dart
class MediaInfo {
  final String path;
  final Duration duration;
  final int fileSize;
  final VideoStream? video;
  final List<AudioStream> audioStreams;
  final List<SubtitleStream> subtitleStreams;
  final Map<String, String> metadata;
  final List<Chapter> chapters;
}

class VideoStream {
  final String codec;
  final int width;
  final int height;
  final double frameRate;
  final int bitrate;
  final String pixelFormat;
  final String colorSpace;
  final bool isHDR;
}
```

---

## UI/UX Design

### Design Principles
1. **Progressive Disclosure** - Simple by default, powerful when needed
2. **Visual Feedback** - Real-time progress, thumbnails, waveforms
3. **Consistency** - Same mental model across platforms
4. **Efficiency** - Keyboard shortcuts, drag & drop, batch operations

### Main Navigation Structure

```
┌─────────────────────────────────────────────────────────────────┐
│  VidForge                                    [─] [□] [×]        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────┬─────────┬─────────┬─────────┬─────────┐           │
│  │ Convert │  Trim   │  Batch  │ Presets │Settings │           │
│  └─────────┴─────────┴─────────┴─────────┴─────────┘           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                                                           │ │
│  │                    CONTENT AREA                           │ │
│  │                                                           │ │
│  │    Varies based on selected tab:                         │ │
│  │    • Convert: Single file conversion interface            │ │
│  │    • Trim: Timeline-based trimming interface              │ │
│  │    • Batch: Queue management interface                    │ │
│  │    • Presets: Preset library and editor                   │ │
│  │    • Settings: App configuration                          │ │
│  │                                                           │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  Status: Ready │ Queue: 0 │ Processing: None                   │
└─────────────────────────────────────────────────────────────────┘
```

### Convert Screen

```
┌─────────────────────────────────────────────────────────────────┐
│  INPUT                                                          │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  ┌─────────┐                                              │ │
│  │  │ 🎬      │  video_project.mov                           │ │
│  │  │Thumbnail│  1920×1080 • 30fps • H.264 • 2:34:15        │ │
│  │  │         │  5.2 GB • ProRes 422                         │ │
│  │  └─────────┘                                              │ │
│  │                                              [Change File]│ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  OUTPUT SETTINGS                                                │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  Preset: [YouTube 1080p              ▼]  [Customize]     │ │
│  │                                                           │ │
│  │  Format:    [MP4 ▼]     Codec:    [H.264 ▼]              │ │
│  │  Quality:   ████████░░  (CRF 23 - Balanced)              │ │
│  │  Resolution:[1920×1080 ▼]  FPS: [Original ▼]             │ │
│  │                                                           │ │
│  │  Audio:     [AAC ▼]  Bitrate: [192 kbps ▼]               │ │
│  │  Channels:  [Stereo ▼]                                    │ │
│  │                                                           │ │
│  │  ┌─ Advanced ──────────────────────────────────────────┐ │ │
│  │  │ Hardware Accel: [Auto ▼]  Threads: [Auto ▼]         │ │ │
│  │  │ Two-pass: [ ]  Fast Start: [✓]                      │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  OUTPUT                                                         │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  📁 /Users/video/output/video_project_youtube.mp4         │ │
│  │  Estimated size: ~850 MB (84% smaller)           [Browse]│ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│                          [Start Conversion]                    │
└─────────────────────────────────────────────────────────────────┘
```

### Trim Screen

```
┌─────────────────────────────────────────────────────────────────┐
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                                                           │ │
│  │                   VIDEO PREVIEW                           │ │
│  │                     (Player)                              │ │
│  │                                                           │ │
│  │               advancement     00:15:32 / 02:34:15         │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ |████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░| │ │
│  │  ▲ IN                                              OUT ▲  │ │
│  │  00:05:00                                      00:25:00   │ │
│  └───────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ [|◀] [◀◀] [ ▶ ] [▶▶] [▶|]   [Set In] [Set Out] [Preview]│ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  SEGMENTS                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  1. 00:05:00 → 00:25:00  (20:00)              [✓] [🗑️]   │ │
│  │  2. 00:45:00 → 01:15:00  (30:00)              [✓] [🗑️]   │ │
│  │  ─────────────────────────────────────                    │ │
│  │  [+ Add Segment]                                          │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Mode: (●) Lossless Cut  ( ) Re-encode                         │
│                                                                 │
│               [Export Selected Segments]                        │
└─────────────────────────────────────────────────────────────────┘
```

### Batch Screen

```
┌─────────────────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │     Drag & Drop Files Here                              │   │
│  │     or [Browse Files] [Browse Folder]                   │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  QUEUE (5 files)                      [Clear All] [Start All]  │
│  ┌─────────────────────────────────────────────────────────────┤
│  │ ☐ │ video1.mov │ 1.2 GB │ YouTube 1080p │ Pending    │ ⋮ │ │
│  │ ☐ │ video2.mp4 │ 800 MB │ YouTube 1080p │ Pending    │ ⋮ │ │
│  │ ☑ │ video3.mkv │ 2.1 GB │ YouTube 1080p │ ████░ 45%  │ ⋮ │ │
│  │ ☐ │ video4.avi │ 650 MB │ YouTube 1080p │ Queued     │ ⋮ │ │
│  │ ☐ │ video5.wmv │ 450 MB │ YouTube 1080p │ Queued     │ ⋮ │ │
│  └─────────────────────────────────────────────────────────────┘
│                                                                 │
│  BATCH SETTINGS                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Apply Preset: [YouTube 1080p ▼]    to: [All Files ▼]   │   │
│  │  Output Folder: /Users/video/output/          [Browse]  │   │
│  │  Naming: [Original]_[preset]_[date]           [Edit]    │   │
│  │  Concurrent Jobs: [2 ▼]                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Mobile Adaptations

```
┌─────────────────────┐
│  VidForge      ≡    │
├─────────────────────┤
│ ┌─────────────────┐ │
│ │   Thumbnail     │ │
│ │    Preview      │ │
│ └─────────────────┘ │
│                     │
│ video_clip.mp4      │
│ 1080p • 2:34        │
│                     │
│ ┌─────────────────┐ │
│ │ Quick Actions   │ │
│ ├─────────────────┤ │
│ │ 🔄 Convert      │ │
│ │ ✂️ Trim         │ │
│ │ 🗜️ Compress     │ │
│ │ 🔊 Extract Audio│ │
│ └─────────────────┘ │
│                     │
│ Output Settings ▼   │
│ ┌─────────────────┐ │
│ │ Format: MP4     │ │
│ │ Quality: High   │ │
│ └─────────────────┘ │
│                     │
│ [  Start Process  ] │
├─────────────────────┤
│ 🏠  📁  ⚙️          │
└─────────────────────┘
```

### Color Palette & Theme

```dart
// Theme configuration
class VidForgeTheme {
  // Primary colors
  static const primary = Color(0xFF6366F1);      // Indigo
  static const primaryDark = Color(0xFF4F46E5);

  // Accent colors
  static const success = Color(0xFF10B981);      // Green
  static const warning = Color(0xFFF59E0B);      // Amber
  static const error = Color(0xFFEF4444);        // Red
  static const info = Color(0xFF3B82F6);         // Blue

  // Background (Dark theme)
  static const bgPrimary = Color(0xFF0F0F0F);
  static const bgSecondary = Color(0xFF1A1A1A);
  static const bgTertiary = Color(0xFF262626);

  // Background (Light theme)
  static const bgPrimaryLight = Color(0xFFFFFFFF);
  static const bgSecondaryLight = Color(0xFFF5F5F5);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA3A3A3);
}
```

---

## Platform Considerations

### Desktop (Windows, macOS, Linux)

| Feature | Implementation |
|---------|----------------|
| Window Management | `window_manager` package |
| Native Menus | `flutter_desktop_menus` |
| File Dialogs | `file_picker` package |
| Drag & Drop | `desktop_drop` package |
| System Tray | `tray_manager` package |
| Notifications | `local_notifier` package |
| FFmpeg | Bundled binaries + Process API |

#### Windows Specific
- MSIX packaging for Microsoft Store
- WinRT APIs for modern features
- Hardware acceleration via NVENC/QSV

#### macOS Specific
- Notarization for distribution
- Universal Binary (Intel + Apple Silicon)
- VideoToolbox hardware acceleration
- Sandbox considerations for file access

#### Linux Specific
- Flatpak/Snap/AppImage packaging
- VAAPI hardware acceleration
- XDG compliance for paths

### Mobile (iOS, Android)

| Feature | Implementation |
|---------|----------------|
| File Access | `file_picker` + SAF (Android) |
| Background Processing | Platform-specific services |
| Notifications | `flutter_local_notifications` |
| FFmpeg | `ffmpeg_kit_flutter_new` |
| Storage | Scoped storage (Android 10+) |

#### iOS Specific
- App Store guidelines compliance
- Background task limitations
- Photo Library integration
- Share extension support

#### Android Specific
- Storage Access Framework (SAF)
- MediaStore integration
- Foreground service for long operations
- Adaptive icons

---

## FFmpeg Integration Strategy

### Abstraction Layer

```dart
// Core abstraction
abstract class FFmpegService {
  /// Execute FFmpeg command
  Future<FFmpegSession> execute(
    List<String> arguments, {
    void Function(FFmpegProgress)? onProgress,
    void Function(String)? onLog,
  });

  /// Get media information
  Future<MediaInfo> probe(String path);

  /// Cancel running session
  Future<void> cancel(String sessionId);

  /// Get all active sessions
  List<FFmpegSession> get activeSessions;
}

// Platform factory
class FFmpegServiceFactory {
  static FFmpegService create() {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return FFmpegKitService();
    } else {
      return ProcessFFmpegService();
    }
  }
}
```

### Mobile Implementation (FFmpegKit)

```dart
class FFmpegKitService implements FFmpegService {
  @override
  Future<FFmpegSession> execute(
    List<String> arguments, {
    void Function(FFmpegProgress)? onProgress,
    void Function(String)? onLog,
  }) async {
    final session = await FFmpegKit.executeAsync(
      arguments.join(' '),
      (session) async {
        // Completion callback
      },
      (log) {
        onLog?.call(log.getMessage());
      },
      (statistics) {
        onProgress?.call(FFmpegProgress(
          time: statistics.getTime(),
          bitrate: statistics.getBitrate(),
          speed: statistics.getSpeed(),
          frame: statistics.getVideoFrameNumber(),
        ));
      },
    );

    return FFmpegSession(id: session.getSessionId().toString());
  }

  @override
  Future<MediaInfo> probe(String path) async {
    final session = await FFprobeKit.getMediaInformation(path);
    final info = session.getMediaInformation();
    return MediaInfo.fromFFprobe(info);
  }
}
```

### Desktop Implementation (Process API)

```dart
class ProcessFFmpegService implements FFmpegService {
  final String _ffmpegPath;
  final String _ffprobePath;
  final Map<String, Process> _activeProcesses = {};

  @override
  Future<FFmpegSession> execute(
    List<String> arguments, {
    void Function(FFmpegProgress)? onProgress,
    void Function(String)? onLog,
  }) async {
    final sessionId = const Uuid().v4();

    final process = await Process.start(
      _ffmpegPath,
      ['-progress', 'pipe:1', '-y', ...arguments],
    );

    _activeProcesses[sessionId] = process;

    // Parse progress from stderr (FFmpeg outputs progress to stderr)
    process.stderr.transform(utf8.decoder).listen((data) {
      onLog?.call(data);
      final progress = _parseProgress(data);
      if (progress != null) {
        onProgress?.call(progress);
      }
    });

    return FFmpegSession(id: sessionId, process: process);
  }

  FFmpegProgress? _parseProgress(String data) {
    // Parse FFmpeg progress output
    // frame=  123 fps= 30 q=28.0 size=    1234kB time=00:00:05.00 bitrate=2000kbits/s
    final frameMatch = RegExp(r'frame=\s*(\d+)').firstMatch(data);
    final timeMatch = RegExp(r'time=(\d+:\d+:\d+\.\d+)').firstMatch(data);
    final speedMatch = RegExp(r'speed=\s*(\d+\.?\d*)x').firstMatch(data);

    if (timeMatch != null) {
      return FFmpegProgress(
        frame: int.tryParse(frameMatch?.group(1) ?? '0') ?? 0,
        time: _parseTime(timeMatch.group(1)!),
        speed: double.tryParse(speedMatch?.group(1) ?? '1') ?? 1.0,
      );
    }
    return null;
  }
}
```

### Command Builder

```dart
class FFmpegCommandBuilder {
  final List<String> _inputs = [];
  final List<String> _outputs = [];
  final List<String> _globalOptions = [];
  final List<String> _filters = [];

  FFmpegCommandBuilder input(String path, {Map<String, String>? options}) {
    if (options != null) {
      options.forEach((key, value) {
        _inputs.addAll(['-$key', value]);
      });
    }
    _inputs.addAll(['-i', path]);
    return this;
  }

  FFmpegCommandBuilder videoCodec(String codec) {
    _outputs.addAll(['-c:v', codec]);
    return this;
  }

  FFmpegCommandBuilder audioCodec(String codec) {
    _outputs.addAll(['-c:a', codec]);
    return this;
  }

  FFmpegCommandBuilder crf(int value) {
    _outputs.addAll(['-crf', value.toString()]);
    return this;
  }

  FFmpegCommandBuilder preset(String preset) {
    _outputs.addAll(['-preset', preset]);
    return this;
  }

  FFmpegCommandBuilder resolution(int width, int height) {
    _outputs.addAll(['-vf', 'scale=$width:$height']);
    return this;
  }

  FFmpegCommandBuilder trim(Duration start, Duration end) {
    _globalOptions.addAll(['-ss', _formatDuration(start)]);
    _globalOptions.addAll(['-to', _formatDuration(end)]);
    return this;
  }

  FFmpegCommandBuilder copyCodecs() {
    _outputs.addAll(['-c', 'copy']);
    return this;
  }

  FFmpegCommandBuilder output(String path) {
    _outputs.add(path);
    return this;
  }

  List<String> build() {
    return [..._globalOptions, ..._inputs, ..._outputs];
  }
}

// Usage example
final command = FFmpegCommandBuilder()
    .input('/path/to/input.mp4')
    .videoCodec('libx264')
    .crf(23)
    .preset('medium')
    .audioCodec('aac')
    .output('/path/to/output.mp4')
    .build();
```

---

## Project Structure

```
vidforge/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── ffmpeg_constants.dart
│   │   │   └── preset_constants.dart
│   │   ├── errors/
│   │   │   ├── failures.dart
│   │   │   └── exceptions.dart
│   │   ├── extensions/
│   │   │   ├── duration_extensions.dart
│   │   │   ├── file_extensions.dart
│   │   │   └── string_extensions.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── colors.dart
│   │   │   └── typography.dart
│   │   └── utils/
│   │       ├── file_utils.dart
│   │       ├── format_utils.dart
│   │       └── platform_utils.dart
│   │
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   │   ├── preset_local_datasource.dart
│   │   │   │   ├── settings_local_datasource.dart
│   │   │   │   └── history_local_datasource.dart
│   │   │   └── ffmpeg/
│   │   │       ├── ffmpeg_service.dart
│   │   │       ├── ffmpeg_kit_service.dart
│   │   │       └── process_ffmpeg_service.dart
│   │   ├── models/
│   │   │   ├── media_info_model.dart
│   │   │   ├── preset_model.dart
│   │   │   ├── job_model.dart
│   │   │   └── settings_model.dart
│   │   └── repositories/
│   │       ├── ffmpeg_repository_impl.dart
│   │       ├── preset_repository_impl.dart
│   │       └── settings_repository_impl.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── media_info.dart
│   │   │   ├── video_stream.dart
│   │   │   ├── audio_stream.dart
│   │   │   ├── preset.dart
│   │   │   ├── job.dart
│   │   │   └── segment.dart
│   │   ├── repositories/
│   │   │   ├── ffmpeg_repository.dart
│   │   │   ├── preset_repository.dart
│   │   │   └── settings_repository.dart
│   │   └── usecases/
│   │       ├── convert_video.dart
│   │       ├── trim_video.dart
│   │       ├── merge_videos.dart
│   │       ├── extract_audio.dart
│   │       ├── compress_video.dart
│   │       ├── get_media_info.dart
│   │       └── batch_process.dart
│   │
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── ffmpeg_provider.dart
│   │   │   ├── job_queue_provider.dart
│   │   │   ├── preset_provider.dart
│   │   │   ├── settings_provider.dart
│   │   │   └── theme_provider.dart
│   │   ├── screens/
│   │   │   ├── home/
│   │   │   │   ├── home_screen.dart
│   │   │   │   └── home_viewmodel.dart
│   │   │   ├── convert/
│   │   │   │   ├── convert_screen.dart
│   │   │   │   ├── convert_viewmodel.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── input_section.dart
│   │   │   │       ├── output_settings.dart
│   │   │   │       └── progress_indicator.dart
│   │   │   ├── trim/
│   │   │   │   ├── trim_screen.dart
│   │   │   │   ├── trim_viewmodel.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── video_player.dart
│   │   │   │       ├── timeline_slider.dart
│   │   │   │       └── segment_list.dart
│   │   │   ├── batch/
│   │   │   │   ├── batch_screen.dart
│   │   │   │   ├── batch_viewmodel.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── drop_zone.dart
│   │   │   │       ├── queue_list.dart
│   │   │   │       └── batch_settings.dart
│   │   │   ├── presets/
│   │   │   │   ├── presets_screen.dart
│   │   │   │   ├── preset_editor_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── preset_card.dart
│   │   │   │       └── preset_form.dart
│   │   │   └── settings/
│   │   │       ├── settings_screen.dart
│   │   │       └── widgets/
│   │   │           ├── appearance_settings.dart
│   │   │           ├── ffmpeg_settings.dart
│   │   │           └── output_settings.dart
│   │   └── widgets/
│   │       ├── common/
│   │       │   ├── app_button.dart
│   │       │   ├── app_card.dart
│   │       │   ├── app_dropdown.dart
│   │       │   ├── app_slider.dart
│   │       │   └── app_text_field.dart
│   │       ├── media/
│   │       │   ├── media_info_card.dart
│   │       │   ├── thumbnail_widget.dart
│   │       │   └── video_preview.dart
│   │       ├── progress/
│   │       │   ├── circular_progress.dart
│   │       │   ├── linear_progress.dart
│   │       │   └── job_progress_card.dart
│   │       └── layout/
│   │           ├── responsive_layout.dart
│   │           ├── desktop_layout.dart
│   │           └── mobile_layout.dart
│   │
│   └── platform/
│       ├── desktop/
│       │   ├── window_manager.dart
│       │   ├── system_tray.dart
│       │   └── native_menus.dart
│       └── mobile/
│           ├── background_service.dart
│           └── share_handler.dart
│
├── assets/
│   ├── icons/
│   ├── images/
│   └── fonts/
│
├── ffmpeg/                          # Bundled FFmpeg binaries
│   ├── windows/
│   │   └── ffmpeg.exe
│   ├── linux/
│   │   └── ffmpeg
│   └── README.md                    # License information
│
├── test/
│   ├── unit/
│   │   ├── domain/
│   │   └── data/
│   ├── widget/
│   │   └── presentation/
│   └── integration/
│
├── integration_test/
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## Implementation Phases

### Phase 1: Foundation (Core Infrastructure)
**Goal**: Establish project structure and core functionality

#### Tasks:
1. **Project Setup**
   - Initialize Flutter project with multi-platform support
   - Configure analysis options and linting rules
   - Set up directory structure following clean architecture
   - Configure Git hooks and CI/CD basics

2. **Core Module**
   - Implement theme system (light/dark)
   - Create base widgets library
   - Set up Riverpod providers structure
   - Implement error handling framework

3. **FFmpeg Abstraction**
   - Create FFmpegService interface
   - Implement FFmpegKit service for mobile
   - Implement Process-based service for desktop
   - Build command builder utility
   - Create progress parsing utilities

4. **Basic Media Operations**
   - Implement media probing (get video info)
   - Create MediaInfo entity and model
   - Build thumbnail generation service

### Phase 2: Core Features (MVP)
**Goal**: Deliver essential video processing capabilities

#### Tasks:
1. **Convert Screen**
   - File selection with drag & drop (desktop)
   - File picker integration (mobile)
   - Output format selection
   - Basic encoding settings (codec, quality, resolution)
   - Progress tracking with cancel support
   - Output file handling

2. **Trim Screen**
   - Video player integration
   - Timeline scrubber with thumbnails
   - In/Out point selection
   - Lossless trim implementation (`-c copy`)
   - Re-encode trim option
   - Multiple segment support

3. **Preset System**
   - Preset entity and data model
   - Built-in presets (Social Media, Device, Quality)
   - Preset selection in Convert screen
   - Local storage for custom presets

4. **Settings Screen**
   - Theme selection
   - Default output directory
   - FFmpeg path configuration (desktop)
   - Hardware acceleration options

### Phase 3: Advanced Features
**Goal**: Add power-user features and batch processing

#### Tasks:
1. **Batch Processing**
   - Queue management system
   - Drag & drop multiple files
   - Apply presets to batch
   - Concurrent processing configuration
   - Individual job progress tracking
   - Pause/Resume/Cancel operations

2. **Preset Editor**
   - Full preset customization UI
   - Video settings (codec, CRF, preset, resolution, FPS)
   - Audio settings (codec, bitrate, channels)
   - Advanced options (filters, flags)
   - Import/Export presets

3. **Additional Operations**
   - Merge/Concatenate videos
   - Extract audio track
   - Extract frames/thumbnails
   - Video compression wizard
   - Subtitle burning

4. **Enhanced UI**
   - Keyboard shortcuts
   - Command palette (desktop)
   - Recent files history
   - Favorites/Bookmarks

### Phase 4: Platform Polish
**Goal**: Native platform integration and distribution

#### Tasks:
1. **Desktop Enhancements**
   - Native window management
   - Menu bar integration
   - System tray support
   - Native notifications
   - File associations

2. **Mobile Enhancements**
   - Share extension (iOS)
   - Share intent handler (Android)
   - Background processing
   - Photo Library integration
   - Widget support

3. **Distribution**
   - Windows: MSIX installer, Microsoft Store
   - macOS: DMG, App Store (sandboxed version)
   - Linux: Flatpak, Snap, AppImage
   - iOS: App Store
   - Android: Play Store, F-Droid

### Phase 5: Advanced & Polish
**Goal**: Professional features and optimization

#### Tasks:
1. **Advanced Features**
   - Custom FFmpeg command mode
   - Video stabilization
   - Audio normalization
   - Watermarking
   - Hardware acceleration optimization

2. **Performance**
   - Memory optimization for large files
   - Thumbnail caching
   - Lazy loading improvements
   - Startup time optimization

3. **Quality of Life**
   - Localization (i18n)
   - Accessibility improvements
   - Comprehensive help/documentation
   - Onboarding flow
   - Analytics (optional, privacy-respecting)

---

## Key Dependencies

### pubspec.yaml

```yaml
name: vidforge
description: A modern FFmpeg GUI for video transcoding, editing, and batch processing.
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.0

  # FFmpeg
  ffmpeg_kit_flutter_new: ^6.0.3  # Mobile + macOS

  # File Operations
  file_picker: ^6.1.1
  desktop_drop: ^0.4.4
  super_drag_and_drop: ^0.8.0
  share_plus: ^7.2.1

  # Media
  video_player: ^2.8.1
  video_thumbnail: ^0.5.3

  # UI Components
  flutter_animate: ^4.3.0
  shimmer: ^3.0.0
  percent_indicator: ^4.2.3

  # Desktop
  window_manager: ^0.3.7        # Desktop window management
  tray_manager: ^0.2.0          # System tray
  local_notifier: ^0.1.5        # Desktop notifications

  # Utilities
  uuid: ^4.2.1
  intl: ^0.18.1
  logger: ^2.0.2
  equatable: ^2.0.5
  dartz: ^0.10.1                # Functional programming (Either type)
  collection: ^1.18.0

  # Platform
  package_info_plus: ^5.0.1
  device_info_plus: ^9.1.1
  url_launcher: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
  hive_generator: ^2.0.1
  json_serializable: ^6.7.1

  # Testing
  mocktail: ^1.0.1

  # Linting
  flutter_lints: ^3.0.1

  # Icons
  flutter_launcher_icons: ^0.13.1

flutter:
  uses-material-design: true

  assets:
    - assets/icons/
    - assets/images/

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

---

## Testing Strategy

### Unit Tests
- Domain entities and use cases
- FFmpeg command builder
- Progress parsing logic
- Preset validation
- File path utilities

### Widget Tests
- Individual UI components
- Screen layouts
- Form validation
- State management integration

### Integration Tests
- Full conversion workflow
- Batch processing flow
- Preset management
- Settings persistence

### Manual Testing Matrix
| Feature | Windows | macOS | Linux | iOS | Android |
|---------|---------|-------|-------|-----|---------|
| File Selection | ✓ | ✓ | ✓ | ✓ | ✓ |
| Drag & Drop | ✓ | ✓ | ✓ | - | - |
| Convert (H.264) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Convert (H.265) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Trim (Lossless) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Batch Process | ✓ | ✓ | ✓ | ✓ | ✓ |
| HW Acceleration | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## Distribution & Packaging

### Windows
```yaml
# windows/runner/Runner.rc - version info
# Use msix package for store distribution
# Include ffmpeg.exe in bundle
```

### macOS
```yaml
# Notarization required for distribution
# Universal Binary for Intel + Apple Silicon
# Consider sandboxed version for App Store
```

### Linux
```yaml
# Flatpak (recommended)
# Snap
# AppImage
# Include ffmpeg binary or depend on system ffmpeg
```

### iOS
```yaml
# App Store distribution
# No FFmpeg binary bundling needed (uses FFmpegKit)
# Background processing limitations apply
```

### Android
```yaml
# Play Store distribution
# F-Droid (GPL version)
# No FFmpeg binary bundling needed (uses FFmpegKit)
```

---

## Risk Assessment & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| FFmpegKit deprecation | High | Use community fork, maintain abstraction layer for easy switching |
| Large file handling | Medium | Streaming approach, progress feedback, memory management |
| Platform-specific bugs | Medium | Comprehensive testing matrix, CI/CD for all platforms |
| App Store rejections | Medium | Follow guidelines strictly, consider separate sandboxed builds |
| GPL licensing compliance | High | Clearly document licenses, provide source code as required |

---

## Success Metrics

1. **Performance**
   - Conversion speed within 10% of native FFmpeg CLI
   - App startup < 2 seconds
   - Smooth 60fps UI during encoding

2. **User Experience**
   - Complete basic conversion in < 5 clicks
   - Clear progress feedback at all times
   - Intuitive preset selection

3. **Reliability**
   - No data loss on crashes (queue persistence)
   - Graceful handling of unsupported formats
   - Clear error messages with suggestions

---

## References

### FFmpeg Resources
- [FFmpeg Documentation](https://ffmpeg.org/ffmpeg.html)
- [FFmpeg Wiki](https://trac.ffmpeg.org/wiki)
- [ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new)

### Flutter Resources
- [Flutter Desktop Support](https://docs.flutter.dev/platform-integration/desktop)
- [Flutter App Architecture](https://docs.flutter.dev/app-architecture/guide)
- [Riverpod Documentation](https://riverpod.dev/)

### Design Inspiration
- [LosslessCut](https://github.com/mifi/lossless-cut) - Swiss army knife of lossless video editing
- [HandBrake](https://handbrake.fr/) - Popular open-source video transcoder
- [Shutter Encoder](https://www.shutterencoder.com/) - FFmpeg-based converter

---

*Document Version: 1.0*
*Last Updated: December 2024*
