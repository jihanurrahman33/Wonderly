import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/router/app_router.dart';
import 'package:wonderly/core/services/sound_service.dart';
import 'package:wonderly/core/theme/app_theme.dart';
import 'package:wonderly/features/ai/presentation/cubit/generation_cubit.dart';
import 'package:wonderly/features/ai/presentation/cubit/model_cubit.dart';
import 'package:wonderly/features/learning/presentation/cubit/catalog_cubit.dart';
import 'package:wonderly/features/parent/domain/parent_access.dart';
import 'package:wonderly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';
import 'package:wonderly/features/settings/domain/entities/app_settings.dart';
import 'package:wonderly/features/settings/presentation/cubit/settings_cubit.dart';

/// Root widget: provides app-wide state, theme, text size and routing.
class WonderlyApp extends StatefulWidget {
  const WonderlyApp({super.key});

  @override
  State<WonderlyApp> createState() => _WonderlyAppState();
}

class _WonderlyAppState extends State<WonderlyApp> with WidgetsBindingObserver {
  late final ProfileCubit _profile = sl<ProfileCubit>();
  late final ProgressCubit _progress = sl<ProgressCubit>();
  late final SettingsCubit _settings = sl<SettingsCubit>();
  late final CatalogCubit _catalog = sl<CatalogCubit>();
  late final ModelCubit _model = sl<ModelCubit>();
  late final GenerationCubit _generation = sl<GenerationCubit>();
  late final GoRouter _router = buildRouter(
    profileCubit: _profile,
    parentAccess: sl<ParentAccess>(),
  );

  StreamSubscription<ProfileState>? _profileSub;
  StreamSubscription<ModelState>? _modelSub;
  StreamSubscription<bool>? _settingsSub;
  final SoundService _sound = sl<SoundService>();
  String? _activeLearnerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  /// Loads state in dependency order, then wires the background pieces.
  Future<void> _start() async {
    await _profile.load();
    _activeLearnerId = _profile.state.profile?.id;
    await _progress.load(_activeLearnerId);
    await _settings.load();
    await _catalog.load();
    _profileSub = _profile.stream.listen(_onProfileChanged);
    unawaited(_sound.syncMusic(wanted: _settings.state.music));
    _settingsSub = _settings.stream
        .map((s) => s.music)
        .distinct()
        .listen((wanted) => unawaited(_sound.syncMusic(wanted: wanted)));
    _modelSub = _model.stream.listen((state) {
      if (state.isInstalled) unawaited(_generation.maybeStart(force: true));
    });
    await _model.init(chosenModelProfile());
    await _generation.refreshCounts();
    await _generation.maybeStart();
  }

  void _onProfileChanged(ProfileState state) {
    final id = state.profile?.id;
    if (id == null || id == _activeLearnerId) return;
    _activeLearnerId = id;
    unawaited(_progress.switchLearner(id));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _progress.refresh();
      unawaited(_generation.resume(PauseReason.appInBackground));
      unawaited(_sound.resumeMusic(wanted: _settings.state.music));
    } else if (state == AppLifecycleState.paused) {
      _generation.pause(PauseReason.appInBackground);
      unawaited(_sound.pauseAll());
    }
  }

  @override
  void dispose() {
    unawaited(_profileSub?.cancel());
    unawaited(_modelSub?.cancel());
    unawaited(_settingsSub?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _profile),
        BlocProvider.value(value: _progress),
        BlocProvider.value(value: _settings),
        BlocProvider.value(value: _catalog),
        BlocProvider.value(value: _model),
        BlocProvider.value(value: _generation),
      ],
      child: BlocSelector<SettingsCubit, AppSettings, TextSize>(
        selector: (settings) => settings.textSize,
        builder: (context, textSize) => MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: _router,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: textSize.scale,
            maxScaleFactor: textSize.scale + 0.35,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
