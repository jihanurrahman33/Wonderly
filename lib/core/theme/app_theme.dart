import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.sun,
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.white,
      secondary: AppColors.sun,
      onSecondary: AppColors.ink,
      surface: AppColors.background,
      onSurface: AppColors.ink,
      error: AppColors.sunBrown,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Nunito',
      textTheme: TextTheme(
        headlineLarge: AppText.heading(30),
        headlineMedium: AppText.heading(24),
        titleLarge: AppText.heading(21),
        bodyLarge: AppText.body(17),
        bodyMedium: AppText.body(15),
        labelLarge: AppText.heading(19),
      ),
      splashFactory: InkRipple.splashFactory,
      focusColor: AppColors.ink,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body(15, color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
