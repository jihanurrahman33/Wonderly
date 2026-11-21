import 'package:flutter/painting.dart';
import 'package:wonderly/core/theme/app_colors.dart';

/// Text style factories: Fredoka for headings and buttons, Nunito for body.
abstract final class AppText {
  static const _display = 'Fredoka';
  static const _body = 'Nunito';

  static TextStyle heading(
    double size, {
    Color color = AppColors.ink,
    double height = 1.2,
  }) => TextStyle(
    fontFamily: _display,
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
    height: height,
  );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
    double height = 1.25,
  }) => TextStyle(
    fontFamily: _body,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  /// Secondary copy under headings.
  static TextStyle subtitle(double size, {Color color = AppColors.muted}) =>
      body(size, color: color);

  static TextStyle label(double size, {Color color = AppColors.muted}) =>
      body(size, weight: FontWeight.w800, color: color);
}
