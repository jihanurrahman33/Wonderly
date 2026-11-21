import 'package:wonderly/core/storage/json_value_repository.dart';
import 'package:wonderly/features/settings/domain/entities/app_settings.dart';
import 'package:wonderly/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl extends JsonValueRepository<AppSettings>
    implements SettingsRepository {
  SettingsRepositoryImpl(super.store)
    : super(storageKey: 'wonderly.settings.v1');

  @override
  AppSettings get defaultValue => const AppSettings();

  @override
  AppSettings decode(Map<String, Object?> json) => AppSettings.fromJson(json);

  @override
  Map<String, Object?> encode(AppSettings value) => value.toJson();
}
