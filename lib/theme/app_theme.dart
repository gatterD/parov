import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF101719);
  static const surface = Color(0xFF192326);
  static const surfaceRaised = Color(0xFF202D30);
  static const muted = Color(0xFF9BAAA9);
  static const steam = Color(0xFFFFB45C);
  static const water = Color(0xFF63C9B4);
  static const danger = Color(0xFFFF7168);
}

abstract final class AppTheme {
  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.steam,
      secondary: AppColors.water,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.steam,
      inactiveTrackColor: Colors.white12,
      thumbColor: AppColors.steam,
      overlayColor: AppColors.steam.withValues(alpha: .12),
      trackHeight: 3,
    ),
    useMaterial3: true,
  );
}
