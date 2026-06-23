import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 主题工厂:浅色为默认,深色为可选。
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: AppColors.bgLight,
        surface: AppColors.surfaceLight,
        surfaceAlt: AppColors.surfaceLightAlt,
        border: AppColors.borderLight,
        textPrimary: AppColors.textPrimaryLight,
        textSecondary: AppColors.textSecondaryLight,
        textMuted: AppColors.textMutedLight,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: AppColors.bgDark,
        surface: AppColors.surfaceDark,
        surfaceAlt: AppColors.surfaceDarkAlt,
        border: AppColors.borderDark,
        textPrimary: AppColors.textPrimaryDark,
        textSecondary: AppColors.textSecondaryDark,
        textMuted: AppColors.textMutedDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceAlt,
    );

    final textTheme = TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: textPrimary),
      displayMedium: AppTypography.displayMedium.copyWith(color: textPrimary),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: textPrimary),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: textPrimary),
      titleLarge: AppTypography.titleLarge.copyWith(color: textPrimary),
      titleMedium: AppTypography.titleMedium.copyWith(color: textPrimary),
      titleSmall: AppTypography.titleSmall.copyWith(color: textPrimary),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: textPrimary),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: textPrimary),
      bodySmall: AppTypography.bodySmall.copyWith(color: textSecondary),
      labelLarge: AppTypography.labelLarge.copyWith(color: textPrimary),
      labelMedium: AppTypography.labelMedium.copyWith(color: textSecondary),
      labelSmall: AppTypography.labelSmall.copyWith(color: textMuted),
    );

    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: textSecondary, size: 20),
      primaryIconTheme: IconThemeData(color: colorScheme.primary),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.labelSmall.copyWith(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : textSecondary,
            size: 22,
          ),
        ),
        height: 64,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 22),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 22),
        selectedLabelTextStyle: AppTypography.labelMedium
            .copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle:
            AppTypography.labelMedium.copyWith(color: textSecondary),
        labelType: NavigationRailLabelType.none,
        useIndicator: true,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? surface : surfaceAlt,
        hintStyle: AppTypography.bodyMedium.copyWith(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? surface : surfaceAlt,
        side: BorderSide(color: border),
        labelStyle: AppTypography.labelSmall.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? colorScheme.primary
              : textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? colorScheme.primary.withValues(alpha: 0.4)
              : border,
        ),
      ),
    );
  }
}
