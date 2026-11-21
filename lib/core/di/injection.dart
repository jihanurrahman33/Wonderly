import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonderly/core/services/feedback_service.dart';
import 'package:wonderly/core/services/sound_service.dart';
import 'package:wonderly/core/services/speech_service.dart';
import 'package:wonderly/core/storage/key_value_store.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/ai/data/edge_ai_llm_client.dart';
import 'package:wonderly/features/ai/data/edge_ai_model_manager.dart';
import 'package:wonderly/features/ai/data/generated_bank_repository_impl.dart';
import 'package:wonderly/features/ai/data/plus_device_status.dart';
import 'package:wonderly/features/ai/domain/entities/model_profile.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';
import 'package:wonderly/features/ai/domain/repositories/generated_bank_repository.dart';
import 'package:wonderly/features/ai/domain/services/device_status.dart';
import 'package:wonderly/features/ai/domain/services/llm_client.dart';
import 'package:wonderly/features/ai/domain/services/model_manager.dart';
import 'package:wonderly/features/ai/domain/usecases/bank_filler.dart';
import 'package:wonderly/features/ai/presentation/cubit/generation_cubit.dart';
import 'package:wonderly/features/ai/presentation/cubit/model_cubit.dart';
import 'package:wonderly/features/learning/data/asset_catalog_repository.dart';
import 'package:wonderly/features/learning/data/live_catalog_repository.dart';
import 'package:wonderly/features/learning/presentation/cubit/catalog_cubit.dart';
import 'package:wonderly/features/parent/domain/parent_access.dart';
import 'package:wonderly/features/parent/presentation/cubit/parent_gate_cubit.dart';
import 'package:wonderly/features/profile/data/profile_repository_impl.dart';
import 'package:wonderly/features/profile/domain/entities/learner_profile.dart';
import 'package:wonderly/features/profile/domain/repositories/profile_repository.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_setup_cubit.dart';
import 'package:wonderly/features/progress/data/progress_repository_impl.dart';
import 'package:wonderly/features/progress/domain/repositories/progress_repository.dart';
import 'package:wonderly/features/progress/domain/usecases/record_answer.dart';
import 'package:wonderly/features/progress/domain/usecases/record_play_time.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';
import 'package:wonderly/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:wonderly/features/settings/data/settings_repository_impl.dart';
import 'package:wonderly/features/settings/domain/repositories/settings_repository.dart';
import 'package:wonderly/features/settings/presentation/cubit/settings_cubit.dart';

/// Global service locator. Only the composition root and route builders use it;
/// everything else receives dependencies through constructors.
final sl = GetIt.instance;

/// Registers every dependency. Safe to call again after [sl.reset].
///
/// Tests override [loadCatalogJson] (the bundled safety-net questions),
/// [llm] (the on-device model) and [modelManager].
Future<void> configureDependencies({
  SharedPreferences? preferences,
  Future<String> Function()? loadCatalogJson,
  LlmClient? llm,
  ModelManager? modelManager,
  DeviceStatus? deviceStatus,
  SoundService? sound,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();

  sl
    // Core
    ..registerSingleton<Clock>(const SystemClock())
    ..registerSingleton<KeyValueStore>(SharedPrefsStore(prefs))
    ..registerLazySingleton<SpeechService>(FlutterTtsSpeechService.new)
    ..registerSingleton<FeedbackService>(const HapticFeedbackService())
    ..registerLazySingleton<SoundService>(
      () =>
          sound ??
          AudioplayersSoundService(
            effectsEnabled: () => sl<SettingsCubit>().state.soundEffects,
          ),
    )
    // Repositories
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ProgressRepository>(
      () => ProgressRepositoryImpl(sl()),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(sl()),
    )
    ..registerLazySingleton<GeneratedBankRepository>(
      () => GeneratedBankRepositoryImpl(sl()),
    )
    ..registerLazySingleton(
      () => AssetCatalogRepository(loadJson: loadCatalogJson),
    )
    ..registerLazySingleton(
      () => LiveCatalogRepository(
        seed: sl<AssetCatalogRepository>(),
        bank: sl(),
        profile: sl(),
        progress: sl(),
        clock: sl(),
      ),
    )
    // On-device AI
    ..registerLazySingleton<ModelManager>(
      () => modelManager ?? EdgeAiModelManager(),
    )
    ..registerLazySingleton<DeviceStatus>(
      () => deviceStatus ?? PlusDeviceStatus(),
    )
    ..registerLazySingleton<LlmClient>(() => llm ?? EdgeAiLlmClient(sl()))
    ..registerLazySingleton(() => BankFiller(llm: sl(), bank: sl()))
    // Use cases
    ..registerLazySingleton(() => RecordAnswer(sl(), sl()))
    ..registerLazySingleton(() => RecordPlayTime(sl(), sl()))
    ..registerLazySingleton(() => ParentAccess(sl()))
    // App-wide state
    ..registerLazySingleton(
      () => ProfileCubit(sl(), onRemoved: sl<ProgressRepository>().deleteFor),
      dispose: (c) => c.close(),
    )
    ..registerLazySingleton(
      () => ProgressCubit(sl(), sl()),
      dispose: (c) => c.close(),
    )
    ..registerLazySingleton(
      () => SettingsCubit(sl()),
      dispose: (c) => c.close(),
    )
    ..registerLazySingleton(
      () => CatalogCubit(
        sl<LiveCatalogRepository>(),
        changes: sl<LiveCatalogRepository>().changes,
      ),
      dispose: (c) => c.close(),
    )
    ..registerLazySingleton(
      () => ModelCubit(sl(), sl()),
      dispose: (c) => c.close(),
    )
    ..registerLazySingleton(
      () => GenerationCubit(
        filler: sl(),
        bank: sl(),
        device: sl(),
        isModelReady: () => sl<ModelManager>().current is ModelInstalled,
        isEnabled: () => sl<SettingsCubit>().state.aiEnabled,
        currentGrade: () => sl<ProfileCubit>().state.profile?.grade ?? 3,
      ),
    )
    // Per-screen state
    ..registerFactory(
      () => QuizBloc(
        catalog: sl<LiveCatalogRepository>(),
        progress: sl(),
        settings: sl(),
        recordAnswer: sl(),
        recordPlayTime: sl(),
        clock: sl(),
      ),
    )
    ..registerFactory(() => ParentGateCubit(clock: sl()))
    ..registerFactoryParam<ProfileSetupCubit, LearnerProfile?, void>(
      (initial, _) => ProfileSetupCubit(sl(), initial: initial),
    );
}

/// The model profile a grown-up chose.
ModelProfile chosenModelProfile() =>
    ModelProfile.fromName(sl<SettingsCubit>().state.modelProfile);
