import 'dart:async';
import 'dart:convert';

import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/storage/key_value_store.dart';
import 'package:wonderly/core/utils/app_logger.dart';

/// Base class for repositories that keep one JSON document in a
/// [KeyValueStore] with an in-memory cache and a change stream.
///
/// All work is serialised through a queue, so concurrent callers can never
/// overwrite each other. [rebind] points the repository at another document,
/// which is how per-learner data is switched.
abstract class JsonValueRepository<T> {
  JsonValueRepository(this.store, {required String storageKey})
    : _storageKey = storageKey;

  final KeyValueStore store;
  String _storageKey;

  final _controller = StreamController<T>.broadcast();
  Future<void> _queue = Future<void>.value();
  T? _cache;
  bool _loaded = false;

  String get storageKey => _storageKey;

  /// Value used when nothing (or something unreadable) is stored.
  T get defaultValue;

  T decode(Map<String, Object?> json);

  Map<String, Object?> encode(T value);

  Stream<T> watch() => _controller.stream;

  Future<Result<T>> load() async {
    if (_loaded) return Result.success(_cache as T);
    final raw = store.read(_storageKey);
    var value = defaultValue;
    if (raw != null) {
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, Object?>) {
          value = decode(json);
        } else {
          AppLogger.warning('Ignoring non-object data for "$_storageKey".');
        }
      } on FormatException catch (e) {
        AppLogger.warning(
          'Corrupt data for "$_storageKey"; using defaults.',
          e,
        );
      } on TypeError catch (e) {
        AppLogger.warning('Bad shape for "$_storageKey"; using defaults.', e);
      }
    }
    _cache = value;
    _loaded = true;
    return Result.success(value);
  }

  Future<Result<T>> update(T Function(T current) transform) =>
      _enqueue(() => _apply(transform));

  /// Switches to the document stored under [key] and emits its value.
  Future<Result<T>> rebind(String key) => _enqueue(() async {
    if (key == _storageKey && _loaded) return Result.success(_cache as T);
    _storageKey = key;
    _loaded = false;
    _cache = null;
    final loaded = await load();
    final value = loaded.valueOrNull;
    if (value is T) _controller.add(value);
    return loaded;
  });

  /// Deletes the document stored under [key].
  Future<void> deleteKey(String key) => _enqueue(() async {
    await store.remove(key);
    if (key == _storageKey) {
      _loaded = false;
      _cache = null;
    }
    return const Result<void>.success(null);
  }).then((_) {});

  Future<Result<R>> _enqueue<R>(Future<Result<R>> Function() job) {
    final completer = Completer<Result<R>>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await job());
      } on Object catch (e, s) {
        // A bug in a job must never wedge every later update.
        AppLogger.error(
          'Storage job for "$_storageKey" failed.',
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
      await store.write(_storageKey, jsonEncode(encode(next)));
    } on StorageException catch (e, s) {
      AppLogger.error(
        'Failed to save "$_storageKey".',
        error: e,
        stackTrace: s,
      );
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
