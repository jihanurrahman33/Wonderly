import 'package:flutter/painting.dart';

/// Colour tokens taken from the Wonderly design reference.
abstract final class AppColors {
  static const background = Color(0xFFFDFCFA);
  static const ink = Color(0xFF171910);
  static const inkSoft = Color(0xFF3F4230);
  static const muted = Color(0xFF556675);
  static const white = Color(0xFFFFFFFF);

  static const sun = Color(0xFFF7BE4B);
  static const sunDeep = Color(0xFFDC8725);
  static const sunBrown = Color(0xFFA8530C);
  static const cream = Color(0xFFF4E9D0);
  static const sand = Color(0xFFECDCBA);
  static const butter = Color(0xFFFBE3A6);
  static const sage = Color(0xFFDCE4C6);
  static const sageSoft = Color(0xFFE8EED8);
  static const olive = Color(0xFF5E6E42);
  static const oliveLight = Color(0xFF7B8B5C);
  static const sky = Color(0xFFDCE7EE);
  static const amberBadge = Color(0xFFF2B35A);
  static const mintBadge = Color(0xFFCFE0B1);
  static const lockedBadge = Color(0xFFE6E2D6);
  static const toggleOff = Color(0xFF9AA3A8);
  static const splash = Color(0xFFF7BE4B);
  static const splashDot = Color(0xFFF2A93B);

  /// Positive and gentle-negative feedback colours for answers.
  static const correct = olive;
  static const incorrect = sunBrown;

  static const trackOnLight = Color(0x2E171910);
  static const trackOnDark = oliveLight;
}
