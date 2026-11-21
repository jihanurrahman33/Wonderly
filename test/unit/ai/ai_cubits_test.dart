import 'package:flutter_test/flutter_test.dart';
import 'package:wonderly/features/ai/data/generated_bank_repository_impl.dart';
import 'package:wonderly/features/ai/domain/entities/model_profile.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';
import 'package:wonderly/features/ai/domain/usecases/bank_filler.dart';
import 'package:wonderly/features/ai/presentation/cubit/generation_cubit.dart';
import 'package:wonderly/features/ai/presentation/cubit/model_cubit.dart';
import 'package:wonderly/features/profile/data/profile_repository_impl.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/progress/data/progress_repository_impl.dart';
import 'package:wonderly/features/progress/domain/entities/learner_progress.dart';
import 'package:wonderly/features/settings/domain/entities/app_settings.dart';

import '../../helpers/fake_ai.dart';
import '../../helpers/fakes.dart';

void main() {
  group('ModelCubit', () {
    late FakeModelManager manager;
    late FakeDeviceStatus device;
    late ModelCubit cubit;

    setUp(() {
      manager = FakeModelManager();
      device = FakeDeviceStatus();
      cubit = ModelCubit(manager, device);
    });

    tearDown(() => cubit.close());

    test('mirrors the manager status', () async {
      manager.set(const ModelDownloading(40));
      await pumpEventQueue();
      expect(cubit.state.status, const ModelDownloading(40));
      manager.set(const ModelInstalled());
      await pumpEventQueue();
      expect(cubit.state.isInstalled, isTrue);
    });

    test('downloads straight away on Wi-Fi', () async {
      expect(await cubit.download(), DownloadStart.started);
      expect(manager.downloads, 1);
    });

    test('asks for confirmation before using mobile data', () async {
      device.wifi = false;
      expect(await cubit.download(), DownloadStart.needsWifiConfirmation);
      expect(manager.downloads, 0);
      expect(await cubit.download(allowMetered: true), DownloadStart.started);
      expect(manager.downloads, 1);
    });

    test('cancel and delete reach the manager', () async {
      cubit.cancel();
      await cubit.delete();
      expect(manager.cancels, 1);
      expect(manager.deletes, 1);
    });

    test('cannot switch model while a download is running', () async {
      manager.set(const ModelDownloading(5));
      await pumpEventQueue();
      await cubit.selectProfile(ModelProfile.quality);
      expect(cubit.state.profile, ModelProfile.balanced);
    });

    test('init and selectProfile record the chosen profile', () async {
      await cubit.init(ModelProfile.quality);
      expect(cubit.state.profile, ModelProfile.quality);
      await cubit.selectProfile(ModelProfile.balanced);
      expect(cubit.state.profile, ModelProfile.balanced);
    });
  });

  group('GenerationCubit', () {
    late InMemoryStore store;
    late GeneratedBankRepositoryImpl bank;
    late FakeDeviceStatus device;
    late FakeLlm llm;
    var enabled = true;
    var ready = true;

    GenerationCubit build() => GenerationCubit(
      filler: BankFiller(llm: llm, bank: bank),
      bank: bank,
      device: device,
      isModelReady: () => ready,
      isEnabled: () => enabled,
      currentGrade: () => 3,
    );

    setUp(() {
      store = InMemoryStore();
      bank = GeneratedBankRepositoryImpl(store);
      device = FakeDeviceStatus();
      enabled = true;
      ready = true;
      var n = 0;
      llm = FakeLlm(
        reply: (system, user) {
          if (system.startsWith('You answer')) {
            final options = user.split('\n').skip(1).toList();
            return '${options.indexWhere((l) => l.contains('Right')) + 1}';
          }
          n++;
          return questionReply(
            question:
                'Made up question ${String.fromCharCodes([97 + n % 26, 97 + n ~/ 26 % 26, 97 + n ~/ 676])}?',
            options: ['Right', 'Wrong $n', 'Nope $n', 'No $n'],
          );
        },
      );
    });

    test('refreshCounts reports what is missing', () async {
      final cubit = build();
      await cubit.refreshCounts();
      expect(cubit.state.bankTotal, 0);
      expect(cubit.state.bankMissing, greaterThan(0));
      await cubit.close();
    });

    test(
      'does not start without a model, when disabled, or while paused',
      () async {
        final cubit = build();
        ready = false;
        await cubit.maybeStart();
        expect(llm.users, isEmpty);

        ready = true;
        enabled = false;
        await cubit.maybeStart();
        expect(llm.users, isEmpty);

        enabled = true;
        cubit.pause(PauseReason.quizOpen);
        await cubit.maybeStart();
        expect(llm.users, isEmpty);
        await cubit.close();
      },
    );

    test('waits while the battery is low', () async {
      device.lowBattery = true;
      final cubit = build();
      await cubit.maybeStart();
      expect(cubit.state.lowBattery, isTrue);
      expect(cubit.state.running, isFalse);
      expect(llm.users, isEmpty);
      await cubit.close();
    });

    test('can be stopped and resumes with force', () async {
      final cubit = build();
      cubit.stop();
      await cubit.maybeStart();
      expect(llm.users, isEmpty);
      // A pause that is lifted lets a later run start again.
      cubit.pause(PauseReason.quizOpen);
      await cubit.resume(PauseReason.quizOpen);
      expect(llm.users, isEmpty, reason: 'still stopped by the user');
      await cubit.close();
    });

    test('writes questions into the bank and updates counters', () async {
      final cubit = build();
      final states = <GenerationState>[];
      final sub = cubit.stream.listen(states.add);
      cubit.pause(PauseReason.appInBackground);
      await cubit.resume(PauseReason.appInBackground);
      expect(states.any((s) => s.running), isTrue);
      expect(cubit.state.running, isFalse);
      expect(cubit.state.bankTotal, greaterThan(0));
      expect(llm.released, greaterThan(0));
      await sub.cancel();
      await cubit.close();
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  group('learners', () {
    late InMemoryStore store;
    late ProfileRepositoryImpl repo;
    late ProgressRepositoryImpl progress;
    final removed = <String>[];

    ProfileCubit cubit() =>
        ProfileCubit(repo, onRemoved: (id) async => removed.add(id));
    const mia = LearnerProfile(
      id: 'a',
      name: 'Mia',
      grade: 2,
      buddy: Buddy.owl,
    );
    const leo = LearnerProfile(
      id: 'b',
      name: 'Leo',
      grade: 4,
      buddy: Buddy.fox,
    );

    setUp(() {
      store = InMemoryStore();
      repo = ProfileRepositoryImpl(store);
      progress = ProgressRepositoryImpl(store);
      removed.clear();
    });

    test('adds learners, switches between them and removes one', () async {
      final c = cubit();
      await c.load();
      expect(c.state.hasProfile, isFalse);

      expect(await c.save(mia), isTrue);
      expect(await c.save(leo), isTrue);
      expect(c.state.learners, hasLength(2));
      expect(c.state.profile, leo, reason: 'a saved learner becomes active');

      expect(await c.switchTo('a'), isTrue);
      expect(c.state.profile, mia);
      expect(await c.switchTo('missing'), isTrue);
      expect(c.state.profile, mia, reason: 'unknown ids are ignored');

      expect(await c.remove('a'), isTrue);
      expect(removed, ['a']);
      expect(
        c.state.profile,
        leo,
        reason: 'falls back to the remaining learner',
      );
      expect(await c.remove('b'), isTrue);
      expect(c.state.hasProfile, isFalse);
      await c.close();
    });

    test('updating a learner keeps one entry and their id', () async {
      final c = cubit();
      await c.load();
      await c.save(mia);
      await c.save(mia.copyWith(name: 'Mia R.', grade: 3));
      expect(c.state.learners, hasLength(1));
      expect(c.state.profile?.id, 'a');
      expect(c.state.profile?.grade, 3);
      await c.close();
    });

    test('roster survives a restart', () async {
      final c = cubit();
      await c.load();
      await c.save(mia);
      await c.save(leo);
      final again = ProfileCubit(ProfileRepositoryImpl(store));
      await again.load();
      expect(again.state.learners.map((l) => l.name), ['Mia', 'Leo']);
      expect(again.state.profile?.name, 'Leo');
      await c.close();
      await again.close();
    });

    test('migrates the single profile of earlier versions', () async {
      store.values['wonderly.profile.v1'] =
          '{"name":"Alex","grade":3,"buddy":"fox"}';
      final c = ProfileCubit(ProfileRepositoryImpl(store));
      await c.load();
      expect(c.state.profile?.name, 'Alex');
      expect(c.state.profile?.id, LearnerProfile.legacyId);
      expect(c.state.profile?.buddy, Buddy.fox);
      await c.close();
    });

    test('ignores corrupt legacy data', () async {
      store.values['wonderly.profile.v1'] = '{nope';
      final c = ProfileCubit(ProfileRepositoryImpl(store));
      await c.load();
      expect(c.state.hasProfile, isFalse);
      await c.close();
    });

    test(
      'each learner has separate progress; legacy keeps the old key',
      () async {
        await progress.bindTo(LearnerProfile.legacyId);
        await progress.update((p) => p.copyWith(stars: 10));
        await progress.bindTo('a');
        expect((await progress.load()).valueOrNull?.stars, 0);
        await progress.update((p) => p.copyWith(stars: 3));
        await progress.bindTo(LearnerProfile.legacyId);
        expect((await progress.load()).valueOrNull?.stars, 10);
        await progress.bindTo('a');
        expect((await progress.load()).valueOrNull?.stars, 3);
        expect(store.values.containsKey('wonderly.progress.v1'), isTrue);
        expect(store.values.containsKey('wonderly.progress.v2.a'), isTrue);

        await progress.deleteFor('a');
        expect(store.values.containsKey('wonderly.progress.v2.a'), isFalse);
        expect((await progress.load()).valueOrNull?.stars, 0);
      },
    );

    test('rebinding emits the new learner on the watch stream', () async {
      await progress.bindTo('a');
      await progress.update((p) => p.copyWith(stars: 7));
      final next = expectLater(
        progress.watch(),
        emits(predicate<LearnerProgress>((p) => p.stars == 0)),
      );
      await progress.bindTo('b');
      await next;
    });
  });

  test('AppSettings carries the AI preferences through JSON', () {
    const s = AppSettings(aiEnabled: false, modelProfile: 'quality');
    expect(AppSettings.fromJson(s.toJson()), s);
    expect(ModelProfile.fromName('quality'), ModelProfile.quality);
    expect(ModelProfile.fromName('???'), ModelProfile.balanced);
  });
}
