import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/features/settings/domain/entities/app_settings.dart';
import 'package:wonderly/features/settings/domain/repositories/settings_repository.dart';

/// Holds and edits [AppSettings] for the whole app.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository) : super(const AppSettings());

  final SettingsRepository _repository;
  StreamSubscription<AppSettings>? _subscription;

  Future<void> load() async {
    final result = await _repository.load();
    emit(result.valueOrNull ?? const AppSettings());
    await _subscription?.cancel();
    _subscription = _repository.watch().listen(emit);
  }

  Future<void> setSoundEffects({required bool value}) =>
      _update((s) => s.copyWith(soundEffects: value));

  Future<void> setMusic({required bool value}) =>
      _update((s) => s.copyWith(music: value));

  Future<void> setReadAloud({required bool value}) =>
      _update((s) => s.copyWith(readAloud: value));

  Future<void> setBedtimeMode({required bool value}) =>
      _update((s) => s.copyWith(bedtimeMode: value));

  Future<void> setWeeklyReport({required bool value}) =>
      _update((s) => s.copyWith(weeklyReport: value));

  Future<void> setAiEnabled({required bool value}) =>
      _update((s) => s.copyWith(aiEnabled: value));

  Future<void> setModelProfile(String name) =>
      _update((s) => s.copyWith(modelProfile: name));

  Future<void> setTextSize(TextSize size) =>
      _update((s) => s.copyWith(textSize: size));

  Future<void> setDailyLimit(int minutes) => _update(
    (s) => s.copyWith(
      dailyLimitMinutes: minutes.clamp(
        AppConstants.minDailyLimitMinutes,
        AppConstants.maxDailyLimitMinutes,
      ),
    ),
  );

  Future<void> _update(AppSettings Function(AppSettings) transform) async {
    // Failures keep the previous value visible; the repository logs details.
    await _repository.update(transform);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
