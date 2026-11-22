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
  final t = base.textTheme;
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
