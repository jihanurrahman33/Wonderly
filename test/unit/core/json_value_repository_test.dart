import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/features/settings/data/settings_repository_impl.dart';
import 'package:wonderly/features/settings/domain/entities/app_settings.dart';

import '../../helpers/fakes.dart';

void main() {
  const key = 'wonderly.settings.v1';

  test('returns defaults when nothing is stored', () async {
    final repo = SettingsRepositoryImpl(InMemoryStore());
    expect((await repo.load()).valueOrNull, const AppSettings());
  });

  test('falls back to defaults when stored JSON is corrupt', () async {
    final repo = SettingsRepositoryImpl(InMemoryStore({key: '{not json'}));
    expect((await repo.load()).valueOrNull, const AppSettings());
  });

  test('falls back to defaults when stored JSON is not an object', () async {
    final repo = SettingsRepositoryImpl(InMemoryStore({key: '[1,2,3]'}));
    expect((await repo.load()).valueOrNull, const AppSettings());
  });

  test('persists updates and reloads them in a new repository', () async {
    final store = InMemoryStore();
    final repo = SettingsRepositoryImpl(store);
    await repo.update((s) => s.copyWith(dailyLimitMinutes: 45));

    final reloaded = SettingsRepositoryImpl(store);
    expect((await reloaded.load()).valueOrNull?.dailyLimitMinutes, 45);
  });

  test('serialises concurrent updates without losing any', () async {
    final repo = SettingsRepositoryImpl(InMemoryStore());
    await Future.wait([
      repo.update((s) => s.copyWith(music: true)),
      repo.update((s) => s.copyWith(bedtimeMode: true)),
      repo.update((s) => s.copyWith(dailyLimitMinutes: 20)),
    ]);
    final value = (await repo.load()).valueOrNull!;
    expect(value.music, isTrue);
    expect(value.bedtimeMode, isTrue);
    expect(value.dailyLimitMinutes, 20);
  });

  test('emits on watch after a successful update', () async {
    final repo = SettingsRepositoryImpl(InMemoryStore());
    final emitted = expectLater(
      repo.watch(),
      emits(predicate<AppSettings>((s) => s.readAloud == false)),
    );
    await repo.update((s) => s.copyWith(readAloud: false));
    await emitted;
  });

  test(
    'reports a StorageFailure and keeps the old value on write error',
    () async {
      final store = InMemoryStore()..failWrites = true;
      final repo = SettingsRepositoryImpl(store);
      final result = await repo.update((s) => s.copyWith(music: true));

      expect(result.failureOrNull, isA<StorageFailure>());
      expect((await repo.load()).valueOrNull?.music, isFalse);
    },
  );

  test('clamps an out-of-range stored daily limit', () async {
    final repo = SettingsRepositoryImpl(
      InMemoryStore({key: '{"dailyLimitMinutes": 999}'}),
    );
    expect((await repo.load()).valueOrNull?.dailyLimitMinutes, 60);
  });
}
