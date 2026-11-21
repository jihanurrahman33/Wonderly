import 'package:shared_preferences/shared_preferences.dart';

/// Thrown when a value cannot be persisted.
class StorageException implements Exception {
  const StorageException(this.message);

  final String message;

  @override
  String toString() => 'StorageException: $message';
}

/// Tiny string storage abstraction so repositories are testable without
/// platform channels.
abstract interface class KeyValueStore {
  String? read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

/// [KeyValueStore] backed by `shared_preferences`.
class SharedPrefsStore implements KeyValueStore {
  const SharedPrefsStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) async {
    final ok = await _prefs.setString(key, value);
    if (!ok) throw StorageException('Could not persist "$key".');
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
