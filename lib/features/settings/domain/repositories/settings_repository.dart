import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/features/settings/domain/entities/app_settings.dart';

/// Persistence contract for [AppSettings].
abstract interface class SettingsRepository {
  Stream<AppSettings> watch();

  Future<Result<AppSettings>> load();

  Future<Result<AppSettings>> update(
    AppSettings Function(AppSettings current) transform,
  );
}
