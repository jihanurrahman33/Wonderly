import 'package:equatable/equatable.dart';

/// Where the on-device model is in its life cycle.
sealed class ModelStatus extends Equatable {
  const ModelStatus();

  @override
  List<Object?> get props => const [];
}

/// This device cannot run the model (for example an old Android version).
final class ModelUnsupported extends ModelStatus {
  const ModelUnsupported(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class ModelNotInstalled extends ModelStatus {
  const ModelNotInstalled();
}

final class ModelDownloading extends ModelStatus {
  const ModelDownloading(this.percent);

  final int percent;

  @override
  List<Object?> get props => [percent];
}

/// The model file is on the device and ready to be loaded.
final class ModelInstalled extends ModelStatus {
  const ModelInstalled();
}

final class ModelFailed extends ModelStatus {
  const ModelFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
