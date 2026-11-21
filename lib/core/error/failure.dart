import 'package:equatable/equatable.dart';

/// A recoverable, user-presentable error produced at a layer boundary.
///
/// Failures are returned inside a `Result` instead of being thrown, so every
/// caller is forced to decide how to handle them.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Developer-facing description. Never shown verbatim to children.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Reading from or writing to local storage failed.
final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// Stored or bundled data could not be parsed or failed validation.
final class DataFailure extends Failure {
  const DataFailure(super.message);
}

/// User input failed validation.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// A device service (for example text to speech) is unavailable.
final class PlatformFailure extends Failure {
  const PlatformFailure(super.message);
}
