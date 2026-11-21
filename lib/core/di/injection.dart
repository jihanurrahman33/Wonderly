import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonderly/core/services/feedback_service.dart';
import 'package:wonderly/core/services/speech_service.dart';
import 'package:wonderly/core/storage/key_value_store.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/learning/data/asset_catalog_repository.dart';
import 'package:wonderly/features/learning/domain/repositories/catalog_repository.dart';
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
Future<void> configureDependencies({
  SharedPreferences? preferences,
  Future<String> Function()? loadCatalogJson,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();

  sl
    // Core
    ..registerSingleton<Clock>(const SystemClock())
    ..registerSingleton<KeyValueStore>(SharedPrefsStore(prefs))
    ..registerLazySingleton<SpeechService>(FlutterTtsSpeechService.new)
    ..registerSingleton<FeedbackService>(const HapticFeedbackService())
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
    ..registerLazySingleton<CatalogRepository>(
      () => AssetCatalogRepository(loadJson: loadCatalogJson),
    )
    // Use cases
    ..registerLazySingleton(() => RecordAnswer(sl(), sl()))
    ..registerLazySingleton(() => RecordPlayTime(sl(), sl()))
    ..registerLazySingleton(() => ParentAccess(sl()))
    // App-wide state
    ..registerLazySingleton(() => ProfileCubit(sl()))
    ..registerLazySingleton(() => ProgressCubit(sl(), sl()))
    ..registerLazySingleton(() => SettingsCubit(sl()))
    ..registerLazySingleton(() => CatalogCubit(sl()))
    // Per-screen state
    ..registerFactory(
      () => QuizBloc(
        catalog: sl(),
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
