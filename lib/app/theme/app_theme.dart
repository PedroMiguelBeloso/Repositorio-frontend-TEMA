import 'package:flutter/material.dart';

abstract final class AppColors {
  // Valores existentes en el repositorio.
  static const primary = Color(0xFF176B67);
  static const surface = Color(0xFFFAFCFB);
  static const canvas = Color(0xFFF3F7F6);
  static const outline = Color(0xFF778784);

  // Convención semántica centralizada.
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEAF1F0);
  static const textPrimary = Color(0xFF1A2523);
  static const textSecondary = Color(0xFF5C6967);
  static const border = Color(0xFFD6E0DD);
  static const success = Color(0xFF2E6F52);
  static const warning = Color(0xFF8A641A);
  static const danger = Color(0xFFA83A3A);
  static const info = Color(0xFF356F8A);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}

abstract final class AppRadii {
  static const control = 8.0;
  static const card = 8.0; // conservar el valor actual
  static const dialog = 16.0;
  static const pill = 999.0;
}

final ColorScheme appColorScheme =
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.surfaceWhite,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainer: AppColors.surfaceWhite,
      error: AppColors.danger,
      onError: AppColors.surfaceWhite,
      outline: AppColors.outline,
    );

final TextTheme _baseTextTheme = Typography.material2021().black.apply(
  bodyColor: AppColors.textPrimary,
  displayColor: AppColors.textPrimary,
);

final TextTheme appTextTheme = _baseTextTheme.copyWith(
  headlineMedium: _baseTextTheme.headlineMedium?.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  ),
  headlineSmall: _baseTextTheme.headlineSmall?.copyWith(
    fontSize: 23,
    fontWeight: FontWeight.w700,
    height: 1.25,
  ),
  titleLarge: _baseTextTheme.titleLarge?.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  ),
  titleMedium: _baseTextTheme.titleMedium?.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
  ),
  titleSmall: _baseTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  bodyLarge: _baseTextTheme.bodyLarge?.copyWith(height: 1.5),
  bodyMedium: _baseTextTheme.bodyMedium?.copyWith(height: 1.5),
  labelLarge: _baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
);

ButtonStyle _standardButtonStyle({required Color background}) {
  return ElevatedButton.styleFrom(
    minimumSize: const Size(64, 48),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
  ).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.surfaceVariant;
      }
      return background;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.textSecondary;
      }
      return AppColors.surfaceWhite;
    }),
    elevation: WidgetStateProperty.resolveWith<double?>((states) {
      if (states.contains(WidgetState.disabled)) return 0;
      if (states.contains(WidgetState.pressed)) return 1;
      if (states.contains(WidgetState.hovered)) return 2;
      return 0;
    }),
    overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return appColorScheme.onPrimary.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return appColorScheme.onPrimary.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return appColorScheme.onPrimary.withValues(alpha: 0.08);
      }
      return null;
    }),
  );
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: appColorScheme,
  scaffoldBackgroundColor: AppColors.surface,
  textTheme: appTextTheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: _standardButtonStyle(background: appColorScheme.primary),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: _standardButtonStyle(background: appColorScheme.primary),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style:
        OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          foregroundColor: appColorScheme.primary,
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(
            appColorScheme.primary.withValues(alpha: 0.06),
          ),
        ),
  ),
  textButtonTheme: TextButtonThemeData(
    style:
        TextButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          foregroundColor: appColorScheme.primary,
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(
            appColorScheme.primary.withValues(alpha: 0.06),
          ),
        ),
  ),
  inputDecorationTheme: InputDecorationThemeData(
    filled: true,
    fillColor: AppColors.surfaceWhite,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: 14,
    ),
    labelStyle: appTextTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    ),
    floatingLabelStyle: appTextTheme.bodyMedium?.copyWith(
      color: appColorScheme.primary,
    ),
    hintStyle: appTextTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    ),
    errorStyle: appTextTheme.bodySmall?.copyWith(color: appColorScheme.error),
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: BorderSide(color: appColorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: BorderSide(color: appColorScheme.error, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surfaceWhite,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: const BorderSide(color: AppColors.border),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surfaceWhite,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.dialog),
    ),
    titleTextStyle: appTextTheme.titleLarge,
    contentTextStyle: appTextTheme.bodyMedium,
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: appColorScheme.primary,
    circularTrackColor: AppColors.surfaceVariant,
    linearTrackColor: AppColors.surfaceVariant,
  ),
  navigationRailTheme: NavigationRailThemeData(
    backgroundColor: AppColors.surface,
    selectedIconTheme: IconThemeData(color: appColorScheme.primary),
    unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
    selectedLabelTextStyle: appTextTheme.labelLarge?.copyWith(
      color: appColorScheme.primary,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelTextStyle: appTextTheme.labelLarge?.copyWith(
      color: AppColors.textSecondary,
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.surfaceVariant,
    iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: appColorScheme.primary, size: 22);
      }
      return const IconThemeData(color: AppColors.textSecondary, size: 22);
    }),
    labelTextStyle: WidgetStatePropertyAll(appTextTheme.labelMedium),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.textPrimary,
    contentTextStyle: TextStyle(color: AppColors.surfaceWhite),
    actionTextColor: AppColors.surfaceWhite,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
  ),
);
