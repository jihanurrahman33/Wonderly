import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/router/app_router.dart';
import 'package:wonderly/core/theme/app_theme.dart';
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
  late final GoRouter _router = buildRouter(
    profileCubit: _profile,
    parentAccess: sl<ParentAccess>(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profile.load();
    _progress.load();
    _settings.load();
    _catalog.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _progress.refresh();
  }

  @override
  void dispose() {
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
