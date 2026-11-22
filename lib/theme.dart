import 'package:flutter/material.dart';

class StickColors {
  static const bg = Color(0xFF0B0B12);
  static const lime = Color(0xFFC6FF3D);
  static const muted = Color(0xFF6B6B78);
}

ThemeData stickTheme() {
  const scheme = ColorScheme.dark(
    primary: StickColors.lime,
    onPrimary: StickColors.bg,
    surface: StickColors.bg,
    onSurface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: StickColors.bg,
    fontFamily: 'Inter',
  );
  const heading = TextStyle(fontFamily: 'ArchivoBlack');
  // The Inter TTF is one variable font: weight only switches through the
  // `wght` axis, so every style carries it next to fontWeight.
  final t = _withWeightAxis(base.textTheme);
  return base.copyWith(
    textTheme: t.copyWith(
      displayLarge: t.displayLarge?.merge(heading),
      displayMedium: t.displayMedium?.merge(heading),
      displaySmall: t.displaySmall?.merge(heading),
      headlineLarge: t.headlineLarge?.merge(heading),
      headlineMedium: t.headlineMedium?.merge(heading),
      headlineSmall: t.headlineSmall?.merge(heading),
      titleLarge: t.titleLarge?.merge(heading),
    ),
  );
}

TextStyle? _axis(TextStyle? s) {
  if (s == null) return null;
  final w = s.fontWeight ?? FontWeight.w400;
  return s.copyWith(
    fontVariations: [FontVariation('wght', w.value.toDouble())],
  );
}

TextTheme _withWeightAxis(TextTheme t) => t.copyWith(
  displayLarge: _axis(t.displayLarge),
  displayMedium: _axis(t.displayMedium),
  displaySmall: _axis(t.displaySmall),
  headlineLarge: _axis(t.headlineLarge),
  headlineMedium: _axis(t.headlineMedium),
  headlineSmall: _axis(t.headlineSmall),
  titleLarge: _axis(t.titleLarge),
  titleMedium: _axis(t.titleMedium),
  titleSmall: _axis(t.titleSmall),
  bodyLarge: _axis(t.bodyLarge),
  bodyMedium: _axis(t.bodyMedium),
  bodySmall: _axis(t.bodySmall),
  labelLarge: _axis(t.labelLarge),
  labelMedium: _axis(t.labelMedium),
  labelSmall: _axis(t.labelSmall),
);
