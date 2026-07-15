import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/* 
*主题工厂:浅色/深色由 [Brightness] 决定,色相由 [seed] 决定。
*/
class AppTheme {
  const AppTheme._();

  // 当前主题色 seed(默认 Slate)。由 app.dart 从
  // `themePresetControllerProvider` 注入,UI 不应直接读此值。
  static const Color defaultSeed = Color(0xFF0D9488);

  /* 
  *以指定 seed 构造浅色主题。
  */
  static ThemeData light(Color seed) => _build(
        brightness: Brightness.light,
        seed: seed,
        background: AppColors.bgLight,
        surface: AppColors.surfaceLight,
        surfaceAlt: AppColors.surfaceLightAlt,
        border: AppColors.borderLight,
        textPrimary: AppColors.textPrimaryLight,
        textSecondary: AppColors.textSecondaryLight,
        textMuted: AppColors.textMutedLight,
      );

  /* 
  *以指定 seed 构造深色主题。
  */
  static ThemeData dark(Color seed) => _build(
        brightness: Brightness.dark,
        seed: seed,
        background: AppColors.bgDark,
        surface: AppColors.surfaceDark,
        surfaceAlt: AppColors.surfaceDarkAlt,
        border: AppColors.borderDark,
        textPrimary: AppColors.textPrimaryDark,
        textSecondary: AppColors.textSecondaryDark,
        textMuted: AppColors.textMutedDark,
      );

  /* 
  *通用工厂。
  */
  static ThemeData fromSeed(Brightness brightness, Color seed) => switch (brightness) { Brightness.light => light(seed), Brightness.dark => dark(seed) };

  static ThemeData _build(
      {required Brightness brightness,
      required Color seed,
      required Color background,
      required Color surface,
      required Color surfaceAlt,
      required Color border,
      required Color textPrimary,
      required Color textSecondary,
      required Color textMuted}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceAlt,
    ).copyWith(outline: border, outlineVariant: border, primary: seed);

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
        shadowColor: Colors.black.withValues(alpha: isLight ? 0.03 : 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg), side: BorderSide(color: border.withValues(alpha: isLight ? 0.54 : 0.9), width: 1)),
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
        // 顶部沉浸:状态栏全透明,图标亮度跟随主题;
        // AppBar 会用自己的 overlayStyle 覆盖全局设置,必须在主题里钉死。
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
          statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => AppTypography.labelSmall.copyWith(color: states.contains(WidgetState.selected) ? colorScheme.primary : textSecondary)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(color: states.contains(WidgetState.selected) ? colorScheme.primary : textSecondary, size: 22)),
        height: 64,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 22),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 22),
        selectedLabelTextStyle: AppTypography.labelMedium.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(color: textSecondary),
        labelType: NavigationRailLabelType.none,
        useIndicator: true,
        indicatorShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.md))),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: border.withValues(alpha: isLight ? 0.68 : 1), thickness: isLight ? 0.6 : 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? surface : surfaceAlt,
        hintStyle: AppTypography.bodyMedium.copyWith(color: textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: colorScheme.primary, textStyle: AppTypography.labelLarge)),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? surface : surfaceAlt,
        side: BorderSide(color: border),
        labelStyle: AppTypography.labelSmall.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? colorScheme.primary : textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? colorScheme.primary.withValues(alpha: 0.42) : border),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? colorScheme.primary.withValues(alpha: 0.48) : border),
      ),
    );
  }
}
