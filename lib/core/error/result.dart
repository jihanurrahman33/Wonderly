import 'package:wonderly/core/error/failure.dart';

/// Minimal sealed result type: either a value or a [Failure].
sealed class Result<T> {
  const Result();

  /// Wraps [value] in a successful result.
  const factory Result.success(T value) = Success<T>;

  /// Wraps [failure] in a failed result.
  const factory Result.failure(Failure failure) = Err<T>;

  /// Collapses the result into a single value.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Err<T>(:final failure) => onFailure(failure),
    };
  }

  /// The value, or `null` when this is a failure.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure, or `null` when this is a success.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Err<T>(:final failure) => failure,
  };
}

/// Successful [Result].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// Failed [Result].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
