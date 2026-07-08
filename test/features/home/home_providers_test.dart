import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/features/home/presentation/home_chart_models.dart';
import 'package:github_news/shared/widgets/star_trend_chart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppLocalizations extends Mock implements AppLocalizations {}

void main() {
  const primary = Color(0xFF0D9488);
  final l10n = AppLocalizations(const Locale('zh', 'CN'));

  group('HomeLegacyTab', () {
    test('label returns non-empty localized string for each tab', () {
      for (final tab in HomeLegacyTab.values) {
        expect(tab.label(l10n), isNotEmpty);
      }
    });

    test('label returns distinct string for each tab', () {
      final labels = HomeLegacyTab.values.map((t) => t.label(l10n)).toSet();
      expect(labels.length, HomeLegacyTab.values.length);
    });

    test('activeIcon returns correct icon for each tab', () {
      expect(HomeLegacyTab.trending.activeIcon, Icons.trending_up_rounded);
      expect(HomeLegacyTab.growth.activeIcon, Icons.star_rounded);
      expect(HomeLegacyTab.health.activeIcon, Icons.favorite_rounded);
      expect(HomeLegacyTab.starred.activeIcon, Icons.bookmark_rounded);
    });

    test('idleIcon returns correct icon for each tab', () {
      expect(HomeLegacyTab.trending.idleIcon, Icons.trending_up_outlined);
      expect(HomeLegacyTab.growth.idleIcon, Icons.star_outline_rounded);
      expect(HomeLegacyTab.health.idleIcon, Icons.favorite_outline_rounded);
      expect(HomeLegacyTab.starred.idleIcon, Icons.bookmark_outline_rounded);
    });
  });

  group('homeChartTitle', () {
    test('returns non-empty title for each tab', () {
      for (final tab in HomeLegacyTab.values) {
        expect(homeChartTitle(l10n, tab), isNotEmpty);
      }
    });

    test('returns distinct title for each tab', () {
      final titles =
          HomeLegacyTab.values.map((t) => homeChartTitle(l10n, t)).toSet();
      expect(titles.length, HomeLegacyTab.values.length);
    });

    test('calls tr with correct localization key for each tab', () {
      final mockL10n = _MockAppLocalizations();
      when(() => mockL10n.tr(any())).thenReturn('mock');

      homeChartTitle(mockL10n, HomeLegacyTab.trending);
      verify(() => mockL10n.tr('home.chart.trending')).called(1);

      homeChartTitle(mockL10n, HomeLegacyTab.growth);
      verify(() => mockL10n.tr('home.chart.growth')).called(1);

      homeChartTitle(mockL10n, HomeLegacyTab.health);
      verify(() => mockL10n.tr('home.chart.health')).called(1);

      homeChartTitle(mockL10n, HomeLegacyTab.starred);
      verify(() => mockL10n.tr('home.chart.starred')).called(1);
    });
  });

  group('homeChartSubtitle', () {
    const window = '7天';

    test('replaces {window} placeholder with provided window label', () {
      for (final tab in HomeLegacyTab.values) {
        final subtitle = homeChartSubtitle(l10n, tab, window);
        expect(subtitle, contains(window));
        expect(subtitle.contains('{window}'), isFalse);
      }
    });

    test('returns non-empty subtitle for each tab', () {
      for (final tab in HomeLegacyTab.values) {
        expect(homeChartSubtitle(l10n, tab, window), isNotEmpty);
      }
    });

    test('returns distinct subtitle for each tab', () {
      final subtitles = HomeLegacyTab.values
          .map((t) => homeChartSubtitle(l10n, t, window))
          .toSet();
      expect(subtitles.length, HomeLegacyTab.values.length);
    });

    test('calls tr with correct key and replaces placeholder', () {
      final mockL10n = _MockAppLocalizations();
      when(() => mockL10n.tr('home.chart.subtitle.trending'))
          .thenReturn('{window} · vs last week');

      final result = homeChartSubtitle(mockL10n, HomeLegacyTab.trending, '7d');

      expect(result, '7d · vs last week');
      verify(() => mockL10n.tr('home.chart.subtitle.trending')).called(1);
    });
  });

  group('homeChartLegends', () {
    test('returns exactly 2 legend items for each tab', () {
      for (final tab in HomeLegacyTab.values) {
        final legends = homeChartLegends(l10n, tab, primary);
        expect(legends.length, 2);
      }
    });

    test('trending legends use primary and info colors', () {
      final legends = homeChartLegends(l10n, HomeLegacyTab.trending, primary);
      expect(legends[0].color, primary);
      expect(legends[1].color, AppColors.info);
    });

    test('growth legends use success and warning colors', () {
      final legends = homeChartLegends(l10n, HomeLegacyTab.growth, primary);
      expect(legends[0].color, AppColors.success);
      expect(legends[1].color, AppColors.warning);
    });

    test('health legends use primary and success colors', () {
      final legends = homeChartLegends(l10n, HomeLegacyTab.health, primary);
      expect(legends[0].color, primary);
      expect(legends[1].color, AppColors.success);
    });

    test('starred legends use starGold and info colors', () {
      final legends = homeChartLegends(l10n, HomeLegacyTab.starred, primary);
      expect(legends[0].color, AppColors.starGold);
      expect(legends[1].color, AppColors.info);
    });

    test('legend labels are non-empty', () {
      for (final tab in HomeLegacyTab.values) {
        final legends = homeChartLegends(l10n, tab, primary);
        for (final legend in legends) {
          expect(legend.label, isNotEmpty);
        }
      }
    });
  });

  group('homeSeriesForWindow', () {
    test('returns exactly 2 series for each tab', () {
      for (final tab in HomeLegacyTab.values) {
        final series = homeSeriesForWindow(7, tab, primary);
        expect(series.length, 2);
      }
    });

    test('each series has values count equal to days', () {
      for (final days in [7, 14, 30]) {
        for (final tab in HomeLegacyTab.values) {
          final series = homeSeriesForWindow(days, tab, primary);
          for (final s in series) {
            expect(s.values.length, days, reason: 'tab=$tab, days=$days');
          }
        }
      }
    });

    test('returns valid ChartSeries instances', () {
      for (final tab in HomeLegacyTab.values) {
        final series = homeSeriesForWindow(7, tab, primary);
        for (final s in series) {
          expect(s, isA<ChartSeries>());
        }
      }
    });

    group('null/empty data handling', () {
      test('falls back to demo data when primaryTrend is null (trending tab)',
          () {
        final series = homeSeriesForWindow(
          7,
          HomeLegacyTab.trending,
          primary,
        );

        expect(series.length, 2);
        expect(series[0].values.length, 7);
        expect(series[1].values.length, 7);
        expect(series[0].color, primary);
        expect(series[1].color, AppColors.info);
      });

      test('falls back to demo data when primaryTrend is empty (trending tab)',
          () {
        final series = homeSeriesForWindow(
          7,
          HomeLegacyTab.trending,
          primary,
          primaryTrend: [],
          secondaryTrend: [],
        );

        expect(series.length, 2);
        expect(series[0].values.length, 7);
        expect(series[1].values.length, 7);
      });

      test('uses dynamic primary trend when provided (trending tab)', () {
        final primaryTrend = List<double>.generate(7, (i) => i * 100.0);
        final secondaryTrend = List<double>.generate(7, (i) => i * 50.0);

        final series = homeSeriesForWindow(
          7,
          HomeLegacyTab.trending,
          primary,
          primaryTrend: primaryTrend,
          secondaryTrend: secondaryTrend,
        );

        expect(series[0].values, primaryTrend);
        expect(series[1].values, secondaryTrend);
        expect(series[0].color, primary);
        expect(series[1].color, AppColors.info);
      });

      test(
          'uses primaryTrend for both series when secondaryTrend is empty '
          '(trending tab)', () {
        final primaryTrend = List<double>.generate(7, (i) => i * 100.0);

        final series = homeSeriesForWindow(
          7,
          HomeLegacyTab.trending,
          primary,
          primaryTrend: primaryTrend,
          secondaryTrend: [],
        );

        expect(series[0].values, primaryTrend);
        expect(series[1].values, primaryTrend);
      });

      test(
          'uses primaryTrend for both series when secondaryTrend is null '
          '(trending tab)', () {
        final primaryTrend = List<double>.generate(7, (i) => i * 100.0);

        final series = homeSeriesForWindow(
          7,
          HomeLegacyTab.trending,
          primary,
          primaryTrend: primaryTrend,
        );

        expect(series[0].values, primaryTrend);
        expect(series[1].values, primaryTrend);
      });

      test('windows primaryTrend when it has more values than days', () {
        final fullTrend = List<double>.generate(30, (i) => i * 100.0);

        final series = homeSeriesForWindow(
          7,
          HomeLegacyTab.trending,
          primary,
          primaryTrend: fullTrend,
          secondaryTrend: fullTrend,
        );

        expect(series[0].values.length, 7);
        expect(series[0].values, fullTrend.sublist(23));
        expect(series[1].values.length, 7);
        expect(series[1].values, fullTrend.sublist(23));
      });

      test('uses full primaryTrend when length equals days', () {
        final trend = List<double>.generate(7, (i) => i * 100.0);

        final series = homeSeriesForWindow(
          7,
          HomeLegacyTab.trending,
          primary,
          primaryTrend: trend,
        );

        expect(series[0].values, trend);
      });

      test('uses full primaryTrend when length is less than days', () {
        final trend = List<double>.generate(5, (i) => i * 100.0);

        final series = homeSeriesForWindow(
          7,
          HomeLegacyTab.trending,
          primary,
          primaryTrend: trend,
        );

        expect(series[0].values, trend);
        expect(series[0].values.length, 5);
      });

      test('ignores dynamic trends for non-trending tabs', () {
        final primaryTrend = List<double>.generate(7, (i) => i * 100.0);
        final secondaryTrend = List<double>.generate(7, (i) => i * 50.0);

        for (final tab in [
          HomeLegacyTab.growth,
          HomeLegacyTab.health,
          HomeLegacyTab.starred,
        ]) {
          final series = homeSeriesForWindow(
            7,
            tab,
            primary,
            primaryTrend: primaryTrend,
            secondaryTrend: secondaryTrend,
          );

          expect(
            series[0].values,
            isNot(primaryTrend),
            reason: 'tab=$tab should not use provided primaryTrend',
          );
          expect(
            series[1].values,
            isNot(secondaryTrend),
            reason: 'tab=$tab should not use provided secondaryTrend',
          );
          expect(series[0].values.length, 7);
        }
      });
    });

    group('series colors per tab', () {
      test('trending tab uses primary and info colors', () {
        final series = homeSeriesForWindow(7, HomeLegacyTab.trending, primary);
        expect(series[0].color, primary);
        expect(series[1].color, AppColors.info);
      });

      test('growth tab uses success and warning colors', () {
        final series = homeSeriesForWindow(7, HomeLegacyTab.growth, primary);
        expect(series[0].color, AppColors.success);
        expect(series[1].color, AppColors.warning);
      });

      test('health tab uses primary and success colors', () {
        final series = homeSeriesForWindow(7, HomeLegacyTab.health, primary);
        expect(series[0].color, primary);
        expect(series[1].color, AppColors.success);
      });

      test('starred tab uses starGold and info colors', () {
        final series = homeSeriesForWindow(7, HomeLegacyTab.starred, primary);
        expect(series[0].color, AppColors.starGold);
        expect(series[1].color, AppColors.info);
      });
    });

    test('produces monotonically increasing demo data for trending tab', () {
      final series7 = homeSeriesForWindow(7, HomeLegacyTab.trending, primary);
      final series14 = homeSeriesForWindow(14, HomeLegacyTab.trending, primary);

      // Demo data uses base + delta * progress, so a larger window
      // produces a higher first value.
      expect(series14[0].values.first, greaterThan(series7[0].values.first));
    });
  });

  group('HomeMetricSpec', () {
    test('can be constructed with all required fields', () {
      const spec = HomeMetricSpec(
        title: '今日新增 Star',
        value: '128',
        delta: '+18.5%',
        subtitle: '对比昨日',
        icon: Icons.star_rounded,
      );

      expect(spec.title, '今日新增 Star');
      expect(spec.value, '128');
      expect(spec.delta, '+18.5%');
      expect(spec.subtitle, '对比昨日');
      expect(spec.icon, Icons.star_rounded);
      expect(spec.accent, isNull);
    });

    test('can be constructed with optional accent', () {
      const spec = HomeMetricSpec(
        title: '告警',
        value: '12',
        delta: '-2',
        subtitle: '对比昨日',
        icon: Icons.notifications_active_outlined,
        accent: AppColors.warning,
      );

      expect(spec.accent, AppColors.warning);
    });
  });

  group('HomeLegendItem', () {
    test('can be constructed with required fields', () {
      const item = HomeLegendItem(
        color: AppColors.info,
        label: '上周',
      );

      expect(item.color, AppColors.info);
      expect(item.label, '上周');
    });
  });
}
