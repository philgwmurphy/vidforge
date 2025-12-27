import 'package:equatable/equatable.dart';
import 'encoding_preset.dart';

/// Status of a conversion job
enum JobStatus {
  pending,
  queued,
  running,
  paused,
  completed,
  failed,
  cancelled,
}

/// Represents a video conversion job
class ConversionJob extends Equatable {
  final String id;
  final String inputPath;
  final String outputPath;
  final EncodingPreset preset;
  final JobStatus status;
  final double progress;
  final Duration? estimatedTimeRemaining;
  final String? currentOperation;
  final double? currentFps;
  final double? currentSpeed;
  final int? currentBitrate;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const ConversionJob({
    required this.id,
    required this.inputPath,
    required this.outputPath,
    required this.preset,
    required this.status,
    this.progress = 0.0,
    this.estimatedTimeRemaining,
    this.currentOperation,
    this.currentFps,
    this.currentSpeed,
    this.currentBitrate,
    this.errorMessage,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  ConversionJob copyWith({
    String? id,
    String? inputPath,
    String? outputPath,
    EncodingPreset? preset,
    JobStatus? status,
    double? progress,
    Duration? estimatedTimeRemaining,
    String? currentOperation,
    double? currentFps,
    double? currentSpeed,
    int? currentBitrate,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ConversionJob(
      id: id ?? this.id,
      inputPath: inputPath ?? this.inputPath,
      outputPath: outputPath ?? this.outputPath,
      preset: preset ?? this.preset,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      estimatedTimeRemaining:
          estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      currentOperation: currentOperation ?? this.currentOperation,
      currentFps: currentFps ?? this.currentFps,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      currentBitrate: currentBitrate ?? this.currentBitrate,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isActive =>
      status == JobStatus.running || status == JobStatus.queued;
  bool get isComplete => status == JobStatus.completed;
  bool get isFailed => status == JobStatus.failed;
  bool get canCancel =>
      status == JobStatus.pending ||
      status == JobStatus.queued ||
      status == JobStatus.running;

  Duration? get duration {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }

  @override
  List<Object?> get props => [
        id,
        inputPath,
        outputPath,
        preset,
        status,
        progress,
        estimatedTimeRemaining,
        currentOperation,
        currentFps,
        currentSpeed,
        currentBitrate,
        errorMessage,
        createdAt,
        startedAt,
        completedAt,
      ];
}

/// Represents a trim segment
class TrimSegment extends Equatable {
  final Duration start;
  final Duration end;
  final String? label;

  const TrimSegment({
    required this.start,
    required this.end,
    this.label,
  });

  Duration get duration => end - start;

  TrimSegment copyWith({
    Duration? start,
    Duration? end,
    String? label,
  }) {
    return TrimSegment(
      start: start ?? this.start,
      end: end ?? this.end,
      label: label ?? this.label,
    );
  }

  @override
  List<Object?> get props => [start, end, label];
}
