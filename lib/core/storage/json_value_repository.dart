import 'dart:async';
import 'dart:convert';

import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/storage/key_value_store.dart';
import 'package:wonderly/core/utils/app_logger.dart';

/// Base class for repositories that keep one JSON document in a
/// [KeyValueStore] with an in-memory cache and a change stream.
///
/// Updates are applied synchronously to the cache and serialised through a
/// queue, so concurrent callers can never overwrite each other.
abstract class JsonValueRepository<T> {
  JsonValueRepository(this._store, {required this.storageKey});

  final KeyValueStore _store;
  final String storageKey;

  final _controller = StreamController<T>.broadcast();
  Future<void> _queue = Future<void>.value();
  T? _cache;
  bool _loaded = false;

  /// Value used when nothing (or something unreadable) is stored.
  T get defaultValue;

  T decode(Map<String, Object?> json);

  Map<String, Object?> encode(T value);

  Stream<T> watch() => _controller.stream;

  Future<Result<T>> load() async {
    if (_loaded) return Result.success(_cache as T);
    final raw = _store.read(storageKey);
    var value = defaultValue;
    if (raw != null) {
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, Object?>) {
          value = decode(json);
        } else {
          AppLogger.warning('Ignoring non-object data for "$storageKey".');
        }
      } on FormatException catch (e) {
        AppLogger.warning('Corrupt data for "$storageKey"; using defaults.', e);
      } on TypeError catch (e) {
        AppLogger.warning('Bad shape for "$storageKey"; using defaults.', e);
      }
    }
    _cache = value;
    _loaded = true;
    return Result.success(value);
  }

  Future<Result<T>> update(T Function(T current) transform) {
    final completer = Completer<Result<T>>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await _apply(transform));
      } on Object catch (e, s) {
        // A bug in a transform must never wedge every later update.
        AppLogger.error(
          'Update of "$storageKey" failed.',
          error: e,
          stackTrace: s,
        );
        completer.complete(
          const Result.failure(StorageFailure('Could not save your changes.')),
        );
      }
    });
    return completer.future;
  }

  Future<Result<T>> _apply(T Function(T current) transform) async {
    final loaded = await load();
    final current = loaded.valueOrNull;
    if (current is! T) {
      return Result.failure(
        loaded.failureOrNull ?? const StorageFailure('Nothing loaded.'),
      );
    }
    final next = transform(current);
    try {
      await _store.write(storageKey, jsonEncode(encode(next)));
    } on StorageException catch (e, s) {
      AppLogger.error('Failed to save "$storageKey".', error: e, stackTrace: s);
      return const Result.failure(
        StorageFailure('Could not save your changes.'),
      );
    }
    _cache = next;
    _controller.add(next);
    return Result.success(next);
  }

  Future<void> dispose() => _controller.close();
}
