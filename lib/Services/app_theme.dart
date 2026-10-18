import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _lightBackground = Color(0xFFFFF8F3);
  static const _darkBackground = Color(0xFF0B1113);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _darkSurface = Color(0xFF172124);
  static const _lightText = Color(0xFF261D19);
  static const _darkText = Color(0xFFE7ECEE);

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkBackground
      : _lightBackground;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkSurface
      : _lightSurface;

  static Color surfaceRaised(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF202B2E)
      : const Color(0xFFFFF4EC);

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkText : _lightText;

  static Color mutedText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFADB8BB)
      : const Color(0xFF766D68);

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0x4DFFFFFF)
      : const Color(0xFFE8E0D8);

  static LinearGradient pageGradient(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF253034), _darkBackground],
          stops: [0.0, 0.6],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEA8648), _lightBackground],
          stops: [0.0, 0.6],
        );
}
