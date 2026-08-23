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

  // 默认主题色 seed(Slate,冷静工具风基线)。由 app.dart 从
  // `themePresetControllerProvider` 注入,UI 不应直接读此值。
  static const Color defaultSeed = Color(0xFF64748B);

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
  static ThemeData fromSeed(Brightness brightness, Color seed) => switch (brightness) {
    Brightness.light => light(seed),
    Brightness.dark => dark(seed),
  };

  static ThemeData _build({
    required Brightness brightness,
    required Color seed,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border.withValues(alpha: isLight ? 0.72 : 1), width: 1),
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
      // 底栏按设计稿去掉 M3 药丸指示器,只用主色区分选中态,让五个目的地
      // 在窄屏下保持等宽、安静的排布。
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => AppTypography.labelSmall.copyWith(color: states.contains(WidgetState.selected) ? colorScheme.primary : textMuted)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(color: states.contains(WidgetState.selected) ? colorScheme.primary : textMuted, size: 22)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      // 导航窄栏走单色:选中态靠中性底 + 一级文字对比表达,不消耗主色,
      // 让主色只出现在真正需要引导视线的小面积元素上。
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: surfaceAlt,
        selectedIconTheme: IconThemeData(color: textPrimary, size: 22),
        unselectedIconTheme: IconThemeData(color: textMuted, size: 22),
        selectedLabelTextStyle: AppTypography.labelMedium.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(color: textSecondary),
        labelType: NavigationRailLabelType.none,
        useIndicator: true,
        indicatorShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm))),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: border.withValues(alpha: isLight ? 0.68 : 1),
        thickness: isLight ? 0.6 : 1,
        space: 1,
      ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
      // 实心按钮是全局唯一允许的大面积主色元素,只留给真正的主行动点;
      // 圆角与内边距收紧,避免"营销页大色块"观感。
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary, textStyle: AppTypography.labelLarge),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? surface : surfaceAlt,
        selectedColor: colorScheme.primary.withValues(alpha: isLight ? 0.08 : 0.16),
        side: BorderSide(color: border),
        labelStyle: AppTypography.labelSmall.copyWith(color: textSecondary),
        secondaryLabelStyle: AppTypography.labelSmall.copyWith(color: colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? colorScheme.primary.withValues(alpha: isLight ? 0.08 : 0.16) : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? colorScheme.primary : textSecondary),
          side: WidgetStateProperty.all(BorderSide(color: border)),
          textStyle: WidgetStateProperty.all(AppTypography.labelMedium),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm))),
          visualDensity: VisualDensity.compact,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textMuted,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border.withValues(alpha: isLight ? 0.7 : 1)),
        ),
        titleTextStyle: AppTypography.titleMedium.copyWith(color: textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? textPrimary : surfaceAlt,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: isLight ? surface : textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? textPrimary : surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: isLight ? null : Border.all(color: border),
        ),
        textStyle: AppTypography.labelSmall.copyWith(color: isLight ? surface : textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border.withValues(alpha: isLight ? 0.7 : 1)),
        ),
        labelTextStyle: WidgetStateProperty.all(AppTypography.bodyMedium.copyWith(color: textPrimary)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? colorScheme.primary : textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? colorScheme.primary.withValues(alpha: 0.42) : border),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? colorScheme.primary.withValues(alpha: 0.48) : border),
      ),
    );
  }
}
