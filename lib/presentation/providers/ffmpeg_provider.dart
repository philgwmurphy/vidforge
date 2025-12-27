import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/ffmpeg/ffmpeg_service.dart';
import '../../data/datasources/ffmpeg/ffmpeg_service_factory.dart';
import '../../domain/entities/media_info.dart';

/// Provider for FFmpeg service instance
final ffmpegServiceProvider = Provider<FFmpegService>((ref) {
  return FFmpegServiceFactory.create();
});

/// Provider for checking FFmpeg availability
final ffmpegAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(ffmpegServiceProvider);
  return service.isAvailable();
});

/// Provider for FFmpeg version
final ffmpegVersionProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(ffmpegServiceProvider);
  return service.getVersion();
});

/// State for media info loading
class MediaInfoState {
  final MediaInfo? mediaInfo;
  final bool isLoading;
  final String? error;

  const MediaInfoState({
    this.mediaInfo,
    this.isLoading = false,
    this.error,
  });

  MediaInfoState copyWith({
    MediaInfo? mediaInfo,
    bool? isLoading,
    String? error,
  }) {
    return MediaInfoState(
      mediaInfo: mediaInfo ?? this.mediaInfo,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for media info operations
class MediaInfoNotifier extends StateNotifier<MediaInfoState> {
  final FFmpegService _ffmpegService;

  MediaInfoNotifier(this._ffmpegService) : super(const MediaInfoState());

  Future<void> loadMediaInfo(String path) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final info = await _ffmpegService.getMediaInfo(path);
      state = MediaInfoState(mediaInfo: info, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clear() {
    state = const MediaInfoState();
  }
}

/// Provider for current media info
final mediaInfoProvider =
    StateNotifierProvider<MediaInfoNotifier, MediaInfoState>((ref) {
  final ffmpegService = ref.watch(ffmpegServiceProvider);
  return MediaInfoNotifier(ffmpegService);
});
