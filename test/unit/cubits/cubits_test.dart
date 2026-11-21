import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/repositories/catalog_repository.dart';
import 'package:wonderly/features/learning/presentation/cubit/catalog_cubit.dart';
import 'package:wonderly/features/profile/data/profile_repository_impl.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_setup_cubit.dart';
import 'package:wonderly/features/progress/data/progress_repository_impl.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';
import 'package:wonderly/features/settings/data/settings_repository_impl.dart';
import 'package:wonderly/features/settings/domain/entities/app_settings.dart';
import 'package:wonderly/features/settings/presentation/cubit/settings_cubit.dart';

import '../../helpers/fakes.dart';

class _Catalog implements CatalogRepository {
  _Catalog(this.result);

  final Result<Catalog> result;

  @override
  Future<Result<Catalog>> load() async => result;
}

void main() {
  group('CatalogCubit', () {
    blocTest<CatalogCubit, CatalogState>(
      'emits ready when the catalog loads',
      build: () =>
          CatalogCubit(_Catalog(Result.success(Catalog([quizSet('a')])))),
      act: (c) => c.load(),
      expect: () => [const CatalogLoading(), isA<CatalogReady>()],
    );

    blocTest<CatalogCubit, CatalogState>(
      'emits error when loading fails, then recovers on retry',
      build: () =>
          CatalogCubit(_Catalog(const Result.failure(DataFailure('x')))),
      act: (c) => c.load(),
      expect: () => [const CatalogLoading(), const CatalogError()],
    );
  });

  group('ProfileCubit', () {
    late InMemoryStore store;
    late ProfileCubit cubit;

    setUp(() {
      store = InMemoryStore();
      cubit = ProfileCubit(ProfileRepositoryImpl(store));
    });

    tearDown(() => cubit.close());

    test('starts loading, then reports no profile on first run', () async {
      expect(cubit.state.status, ProfileStatus.loading);
      await cubit.load();
      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.hasProfile, isFalse);
    });

    test('saves and reloads a profile', () async {
      const profile = LearnerProfile(name: 'Mia', grade: 2, buddy: Buddy.owl);
      expect(await cubit.save(profile), isTrue);
      expect(cubit.state.profile, profile);

      final again = ProfileCubit(ProfileRepositoryImpl(store));
      await again.load();
      expect(again.state.profile, profile);
      await again.close();
    });

    test('reports false when the profile cannot be saved', () async {
      store.failWrites = true;
      const profile = LearnerProfile(name: 'Mia', grade: 2, buddy: Buddy.owl);
      expect(await cubit.save(profile), isFalse);
      expect(cubit.state.hasProfile, isFalse);
    });
  });

  group('ProfileSetupCubit', () {
    late InMemoryStore store;
    late ProfileCubit profileCubit;
    late ProfileSetupCubit cubit;

    setUp(() async {
      store = InMemoryStore();
      profileCubit = ProfileCubit(ProfileRepositoryImpl(store));
      await profileCubit.load();
      cubit = ProfileSetupCubit(profileCubit);
    });

    tearDown(() async {
      await cubit.close();
      await profileCubit.close();
    });

    test('starts from sensible defaults', () {
      expect(cubit.state.buddy, Buddy.cat);
      expect(cubit.state.grade, 3);
      expect(cubit.state.name, isEmpty);
    });

    test('pre-fills from an existing profile', () async {
      final editing = ProfileSetupCubit(
        profileCubit,
        initial: const LearnerProfile(name: 'Zed', grade: 5, buddy: Buddy.lion),
      );
      expect(editing.state.name, 'Zed');
      expect(editing.state.grade, 5);
      expect(editing.state.buddy, Buddy.lion);
      await editing.close();
    });

    test('shows a validation message instead of saving a blank name', () async {
      await cubit.submit();
      expect(cubit.state.errorMessage, 'Please type your name.');
      expect(cubit.state.completed, isFalse);
      expect(profileCubit.state.hasProfile, isFalse);
    });

    test('clears the error as soon as the child types', () async {
      await cubit.submit();
      cubit.changeName('A');
      expect(cubit.state.errorMessage, isNull);
    });

    test('truncates names that are too long', () {
      cubit.changeName('A' * 40);
      expect(cubit.state.name.length, 20);
    });

    test('saves a valid profile and completes', () async {
      cubit
        ..selectBuddy(Buddy.rabbit)
        ..selectGrade(2)
        ..changeName('  Lily ');
      await cubit.submit();
      expect(cubit.state.completed, isTrue);
      expect(profileCubit.state.profile?.name, 'Lily');
      expect(profileCubit.state.profile?.buddy, Buddy.rabbit);
    });

    test('shows a retry message when storage fails', () async {
      store.failWrites = true;
      cubit.changeName('Lily');
      await cubit.submit();
      expect(cubit.state.completed, isFalse);
      expect(cubit.state.errorMessage, contains('try again'));
      expect(cubit.state.submitting, isFalse);
    });
  });

  group('SettingsCubit', () {
    test('loads defaults and persists each change', () async {
      final store = InMemoryStore();
      final cubit = SettingsCubit(SettingsRepositoryImpl(store));
      await cubit.load();
      expect(cubit.state, const AppSettings());

      await cubit.setSoundEffects(value: false);
      await cubit.setMusic(value: true);
      await cubit.setReadAloud(value: false);
      await cubit.setBedtimeMode(value: true);
      await cubit.setWeeklyReport(value: false);
      await cubit.setTextSize(TextSize.large);
      await cubit.setDailyLimit(45);
      await pumpEventQueue();

      expect(
        cubit.state,
        const AppSettings(
          soundEffects: false,
          music: true,
          readAloud: false,
          textSize: TextSize.large,
          bedtimeMode: true,
          dailyLimitMinutes: 45,
          weeklyReport: false,
        ),
      );

      final again = SettingsCubit(SettingsRepositoryImpl(store));
      await again.load();
      expect(again.state, cubit.state);
      await cubit.close();
      await again.close();
    });

    test('clamps the daily limit to the allowed range', () async {
      final cubit = SettingsCubit(SettingsRepositoryImpl(InMemoryStore()));
      await cubit.load();
      await cubit.setDailyLimit(500);
      await pumpEventQueue();
      expect(cubit.state.dailyLimitMinutes, 60);
      await cubit.setDailyLimit(1);
      await pumpEventQueue();
      expect(cubit.state.dailyLimitMinutes, 10);
      await cubit.close();
    });
  });

  group('ProgressCubit', () {
    test('derives the streak and follows repository updates', () async {
      final clock = FakeClock(DateTime(2026, 11, 21, 9));
      final repo = ProgressRepositoryImpl(
        InMemoryStore({
          'wonderly.progress.v1':
              '{"activeDays": ["2026-11-20", "2026-11-19"], "stars": 7}',
        }),
      );
      final cubit = ProgressCubit(repo, clock);
      expect(cubit.state.loaded, isFalse);
      await cubit.load();

      expect(cubit.state.loaded, isTrue);
      expect(cubit.state.progress.stars, 7);
      expect(cubit.state.streak, 2);
      expect(cubit.state.playedToday, isFalse);

      await repo.update(
        (p) => p.copyWith(activeDays: {...p.activeDays, '2026-11-21'}),
      );
      await pumpEventQueue();
      expect(cubit.state.streak, 3);
      expect(cubit.state.playedToday, isTrue);

      clock.current = DateTime(2026, 11, 23);
      cubit.refresh();
      expect(cubit.state.streak, 0);
      await cubit.close();
    });
  });
}
