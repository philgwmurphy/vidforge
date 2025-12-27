import '../../../core/utils/duration_utils.dart';
import '../../../domain/entities/encoding_preset.dart';

/// Builder for constructing FFmpeg command arguments
class FFmpegCommandBuilder {
  final List<String> _globalOptions = [];
  final List<String> _inputOptions = [];
  final List<String> _inputs = [];
  final List<String> _outputOptions = [];
  final List<String> _filters = [];
  String? _output;

  /// Add global option (before inputs)
  FFmpegCommandBuilder globalOption(String key, [String? value]) {
    _globalOptions.add('-$key');
    if (value != null) _globalOptions.add(value);
    return this;
  }

  /// Add input file with optional options
  FFmpegCommandBuilder input(String path, {Map<String, String>? options}) {
    if (options != null) {
      options.forEach((key, value) {
        _inputOptions.add('-$key');
        _inputOptions.add(value);
      });
    }
    _inputs.add('-i');
    _inputs.add(path);
    return this;
  }

  /// Set video codec
  FFmpegCommandBuilder videoCodec(String codec) {
    _outputOptions.addAll(['-c:v', codec]);
    return this;
  }

  /// Set audio codec
  FFmpegCommandBuilder audioCodec(String codec) {
    _outputOptions.addAll(['-c:a', codec]);
    return this;
  }

  /// Copy streams without re-encoding
  FFmpegCommandBuilder copyCodecs() {
    _outputOptions.addAll(['-c', 'copy']);
    return this;
  }

  /// Copy video stream only
  FFmpegCommandBuilder copyVideo() {
    _outputOptions.addAll(['-c:v', 'copy']);
    return this;
  }

  /// Copy audio stream only
  FFmpegCommandBuilder copyAudio() {
    _outputOptions.addAll(['-c:a', 'copy']);
    return this;
  }

  /// Set CRF (Constant Rate Factor) for quality
  FFmpegCommandBuilder crf(int value) {
    _outputOptions.addAll(['-crf', value.toString()]);
    return this;
  }

  /// Set video bitrate
  FFmpegCommandBuilder videoBitrate(int kbps) {
    _outputOptions.addAll(['-b:v', '${kbps}k']);
    return this;
  }

  /// Set audio bitrate
  FFmpegCommandBuilder audioBitrate(int kbps) {
    _outputOptions.addAll(['-b:a', '${kbps}k']);
    return this;
  }

  /// Set encoding preset (speed vs compression tradeoff)
  FFmpegCommandBuilder preset(String preset) {
    _outputOptions.addAll(['-preset', preset]);
    return this;
  }

  /// Set video resolution
  FFmpegCommandBuilder resolution(int width, int height) {
    _filters.add('scale=$width:$height');
    return this;
  }

  /// Scale video maintaining aspect ratio
  FFmpegCommandBuilder scaleToWidth(int width) {
    _filters.add('scale=$width:-2');
    return this;
  }

  /// Scale video maintaining aspect ratio
  FFmpegCommandBuilder scaleToHeight(int height) {
    _filters.add('scale=-2:$height');
    return this;
  }

  /// Set frame rate
  FFmpegCommandBuilder frameRate(double fps) {
    _outputOptions.addAll(['-r', fps.toString()]);
    return this;
  }

  /// Set start time for trimming
  FFmpegCommandBuilder startTime(Duration time) {
    _globalOptions.addAll(['-ss', DurationUtils.formatForFFmpeg(time)]);
    return this;
  }

  /// Set end time for trimming
  FFmpegCommandBuilder endTime(Duration time) {
    _outputOptions.addAll(['-to', DurationUtils.formatForFFmpeg(time)]);
    return this;
  }

  /// Set duration
  FFmpegCommandBuilder duration(Duration duration) {
    _outputOptions.addAll(['-t', DurationUtils.formatForFFmpeg(duration)]);
    return this;
  }

  /// Set audio sample rate
  FFmpegCommandBuilder sampleRate(int rate) {
    _outputOptions.addAll(['-ar', rate.toString()]);
    return this;
  }

  /// Set audio channels
  FFmpegCommandBuilder audioChannels(int channels) {
    _outputOptions.addAll(['-ac', channels.toString()]);
    return this;
  }

  /// Disable audio
  FFmpegCommandBuilder noAudio() {
    _outputOptions.add('-an');
    return this;
  }

  /// Disable video
  FFmpegCommandBuilder noVideo() {
    _outputOptions.add('-vn');
    return this;
  }

  /// Set pixel format
  FFmpegCommandBuilder pixelFormat(String format) {
    _outputOptions.addAll(['-pix_fmt', format]);
    return this;
  }

  /// Add custom video filter
  FFmpegCommandBuilder videoFilter(String filter) {
    _filters.add(filter);
    return this;
  }

  /// Set fast start for web playback (moov atom at beginning)
  FFmpegCommandBuilder fastStart() {
    _outputOptions.addAll(['-movflags', '+faststart']);
    return this;
  }

  /// Set H.264/H.265 profile
  FFmpegCommandBuilder profile(String profile) {
    _outputOptions.addAll(['-profile:v', profile]);
    return this;
  }

  /// Set H.264/H.265 level
  FFmpegCommandBuilder level(String level) {
    _outputOptions.addAll(['-level', level]);
    return this;
  }

  /// Set number of threads
  FFmpegCommandBuilder threads(int count) {
    _outputOptions.addAll(['-threads', count.toString()]);
    return this;
  }

  /// Overwrite output file without asking
  FFmpegCommandBuilder overwrite() {
    _globalOptions.add('-y');
    return this;
  }

  /// Set metadata
  FFmpegCommandBuilder metadata(String key, String value) {
    _outputOptions.addAll(['-metadata', '$key=$value']);
    return this;
  }

  /// Map specific stream
  FFmpegCommandBuilder mapStream(String stream) {
    _outputOptions.addAll(['-map', stream]);
    return this;
  }

  /// Set output file
  FFmpegCommandBuilder output(String path) {
    _output = path;
    return this;
  }

  /// Apply encoding preset settings
  FFmpegCommandBuilder applyPreset(EncodingPreset preset) {
    // Video settings
    if (preset.video.codec != 'copy') {
      videoCodec(preset.video.codec);

      if (preset.video.crf != null) {
        crf(preset.video.crf!);
      } else if (preset.video.bitrate != null) {
        videoBitrate(preset.video.bitrate!);
      }

      if (preset.video.width != null && preset.video.height != null) {
        resolution(preset.video.width!, preset.video.height!);
      }

      if (preset.video.frameRate != null &&
          preset.video.frameRate != 'original') {
        frameRate(double.parse(preset.video.frameRate!));
      }

      preset(preset.video.preset);

      if (preset.video.profile != null) {
        profile(preset.video.profile!);
      }

      if (preset.video.pixelFormat != null) {
        pixelFormat(preset.video.pixelFormat!);
      }
    } else {
      copyVideo();
    }

    // Audio settings
    if (preset.audio.codec != 'copy') {
      audioCodec(preset.audio.codec);

      if (preset.audio.bitrate != null) {
        audioBitrate(preset.audio.bitrate!);
      }

      if (preset.audio.sampleRate != null) {
        sampleRate(preset.audio.sampleRate!);
      }

      if (preset.audio.channels != null) {
        audioChannels(preset.audio.channels!);
      }
    } else {
      copyAudio();
    }

    // MP4-specific optimizations
    if (preset.container == 'mp4') {
      fastStart();
    }

    return this;
  }

  /// Build the complete command arguments
  List<String> build() {
    final args = <String>[];

    // Global options (before input)
    args.addAll(_globalOptions);

    // Input options and inputs
    args.addAll(_inputOptions);
    args.addAll(_inputs);

    // Video filters
    if (_filters.isNotEmpty) {
      args.addAll(['-vf', _filters.join(',')]);
    }

    // Output options
    args.addAll(_outputOptions);

    // Output file
    if (_output != null) {
      args.add(_output!);
    }

    return args;
  }

  /// Build command for thumbnail extraction
  static List<String> thumbnail({
    required String input,
    required String output,
    Duration? atTime,
    int? width,
    int? height,
  }) {
    final builder = FFmpegCommandBuilder()
      ..overwrite();

    if (atTime != null) {
      builder.startTime(atTime);
    }

    builder.input(input);
    builder.globalOption('frames:v', '1');

    if (width != null && height != null) {
      builder.resolution(width, height);
    } else if (width != null) {
      builder.scaleToWidth(width);
    }

    builder.output(output);

    return builder.build();
  }

  /// Build command for lossless trim
  static List<String> losslessTrim({
    required String input,
    required String output,
    required Duration start,
    required Duration end,
  }) {
    return FFmpegCommandBuilder()
      ..overwrite()
      ..startTime(start)
      ..input(input)
      ..endTime(end - start) // Duration from new start point
      ..copyCodecs()
      ..output(output)
      ..build();
  }

  /// Build command for audio extraction
  static List<String> extractAudio({
    required String input,
    required String output,
    String codec = 'copy',
    int? bitrate,
  }) {
    final builder = FFmpegCommandBuilder()
      ..overwrite()
      ..input(input)
      ..noVideo();

    if (codec == 'copy') {
      builder.copyAudio();
    } else {
      builder.audioCodec(codec);
      if (bitrate != null) {
        builder.audioBitrate(bitrate);
      }
    }

    builder.output(output);
    return builder.build();
  }
}
