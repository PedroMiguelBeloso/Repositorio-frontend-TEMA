import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF176B67);
  static const surface = Color(0xFFFAFCFB);
  static const outline = Color(0xFF778784);
}

abstract final class AppRadii {
  static const control = 8.0;
  static const card = 8.0;
}

final ColorScheme appColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.light,
  surface: AppColors.surface,
);

final TextTheme appTextTheme = Typography.material2021().black.apply(
  bodyColor: const Color(0xFF1A2523),
  displayColor: const Color(0xFF1A2523),
);

final ButtonStyle _appButtonStyle = ElevatedButton.styleFrom(
  minimumSize: const Size(64, 48),
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.control),
  ),
);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: appColorScheme,
  scaffoldBackgroundColor: AppColors.surface,
  textTheme: appTextTheme,
  elevatedButtonTheme: ElevatedButtonThemeData(style: _appButtonStyle),
  filledButtonTheme: FilledButtonThemeData(style: _appButtonStyle),
  inputDecorationTheme: InputDecorationThemeData(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: const BorderSide(color: AppColors.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: const BorderSide(color: AppColors.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: BorderSide(color: appColorScheme.primary, width: 2),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: const BorderSide(color: Color(0xFFE0E7E5)),
    ),
  ),
);
