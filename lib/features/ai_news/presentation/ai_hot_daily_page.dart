import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/data_freshness.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/data_provenance_badge.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import '../application/ai_news_providers.dart';
import '../domain/ai_hot_daily.dart';

/*
*AI HOT 指定日期官方日报页。
*作为 AI 主入口的二级页留在应用 shell 内,并支持最近 30 期切换。
*/
class AiHotDailyPage extends ConsumerWidget {
  const AiHotDailyPage({required this.date, super.key});

  // YYYY-MM-DD 日报日期。
  final String date;

  @override
  /* 构建指定日期日报的完整状态。 */
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(aiHotDailyProvider(date));
    return SecondaryPageScaffold(
      title: '${l10n.tr('ai_news.daily.page_title')} · $date',
      subtitle: l10n.tr('ai_news.daily.page_subtitle'),
      icon: Icons.auto_stories_rounded,
      fallbackPath: '/ai_news',
      actions: [
        IconButton(tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel, onPressed: () => ref.invalidate(aiHotDailyProvider(date)), icon: const Icon(Icons.refresh_rounded)),
      ],
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(error: error.asAppException(stack), onRetry: () => ref.invalidate(aiHotDailyProvider(date))),
        data: (result) => _DailyReportBody(report: result.data, freshness: result.freshness),
      ),
    );
  }
}

class _DailyReportBody extends ConsumerWidget {
  const _DailyReportBody({required this.report, required this.freshness});

  static const double _maxWidth = 980;

  // 完整官方日报。
  final AiHotDailyReport report;

  // 日报数据新鲜度。
  final DataFreshness freshness;

  @override
  /* 构建日期切换、导语、分类与快讯。 */
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (report.sections.every((section) => section.items.isEmpty) && report.flashes.isEmpty) {
      return EmptyView(icon: Icons.article_outlined, message: l10n.tr('ai_news.daily.empty'));
    }
    final index = ref.watch(aiHotDailyIndexProvider).value?.data ?? const <AiHotDailyEntry>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DateToolbar(date: report.date, dates: index, freshness: freshness),
                if (report.lead != null) ...[const SizedBox(height: AppSpacing.lg), _LeadCard(lead: report.lead!)],
                for (final section in report.sections)
                  if (section.items.isNotEmpty) ...[const SizedBox(height: AppSpacing.xl), _Section(section: section)],
                if (report.flashes.isNotEmpty) ...[const SizedBox(height: AppSpacing.xl), _Flashes(items: report.flashes)],
                const SizedBox(height: AppSpacing.xl),
                _Attribution(report: report),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateToolbar extends StatelessWidget {
  const _DateToolbar({required this.date, required this.dates, required this.freshness});

  // 当前日期。
  final String date;

  // 可切换日报索引。
  final List<AiHotDailyEntry> dates;

  // 日报数据新鲜度。
  final DataFreshness freshness;

  @override
  /* 构建日期选择与数据口径。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = dates.any((entry) => entry.date == date) ? dates : [AiHotDailyEntry(date: date, generatedAt: null), ...dates];
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: date,
            decoration: InputDecoration(labelText: l10n.tr('ai_news.daily.select_date'), prefixIcon: const Icon(Icons.calendar_month_rounded)),
            items: [for (final entry in options) DropdownMenuItem(value: entry.date, child: Text(entry.date))],
            onChanged: (value) {
              if (value != null && value != date) {
                context.go('/ai_news/daily/$value');
              }
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        DataFreshnessBadge(freshness: freshness, compact: false),
      ],
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  // 当期主编导语。
  final AiHotDailyLead lead;

  @override
  /* 构建日报导语卡。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lead.title.isNotEmpty) Text(lead.title, style: AppTypography.headlineMedium.copyWith(color: colors.onSurface, height: 1.35)),
          if (lead.paragraph.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text(lead.paragraph, style: AppTypography.bodyLarge.copyWith(color: colors.onSurfaceVariant, height: 1.7))],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.section});

  // 日报分类区块。
  final AiHotDailySection section;

  @override
  /* 构建分类标题与条目列表。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(section.label, style: AppTypography.titleLarge.copyWith(color: colors.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < section.items.length; index++) ...[_DailyItemCard(item: section.items[index]), if (index != section.items.length - 1) const SizedBox(height: AppSpacing.sm)],
      ],
    );
  }
}

class _DailyItemCard extends StatelessWidget {
  const _DailyItemCard({required this.item});

  // 日报精选条目。
  final AiHotDailyItem item;

  @override
  /* 构建摘要、署名、AI HOT canonical 与原文入口。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: AppTypography.titleMedium.copyWith(color: colors.onSurface, height: 1.42)),
          if (item.summary.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text(item.summary, style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant, height: 1.65))],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(item.sourceName, style: AppTypography.labelMedium.copyWith(color: colors.onSurfaceVariant)),
              if (item.permalink != null)
                TextButton.icon(onPressed: () => _openWeb(context, item.permalink!, item.title), icon: const Icon(Icons.auto_stories_outlined, size: 17), label: Text(l10n.tr('ai_news.daily.aihot'))),
              if (item.sourceUrl.isNotEmpty)
                TextButton.icon(onPressed: () => _openWeb(context, item.sourceUrl, item.title), icon: const Icon(Icons.open_in_new_rounded, size: 17), label: Text(l10n.tr('ai_news.daily.original'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Flashes extends StatelessWidget {
  const _Flashes({required this.items});

  // 日报快讯。
  final List<AiHotDailyFlash> items;

  @override
  /* 构建快讯列表。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.tr('ai_news.daily.flash'), style: AppTypography.titleLarge.copyWith(color: colors.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(items[index].title),
                  subtitle: Text(items[index].sourceName),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openWeb(context, items[index].permalink ?? items[index].sourceUrl, items[index].title),
                ),
                if (index != items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.report});

  // 当期日报。
  final AiHotDailyReport report;

  @override
  /* 构建聚合方署名与 canonical 入口。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final attribution = report.attribution;
    return Row(
      children: [
        const Icon(Icons.verified_outlined, size: 18, color: AppColors.brand),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(l10n.tr('ai_news.official_daily.attribution'))),
        if (attribution != null) TextButton(onPressed: () => _openWeb(context, attribution.canonical, '${l10n.tr('ai_news.daily.page_title')} ${report.date}'), child: Text(attribution.source)),
      ],
    );
  }
}

/* 在应用内 WebView 打开 AI HOT canonical 或第三方原文。 */
void _openWeb(BuildContext context, String url, String title) {
  if (url.trim().isEmpty) {
    return;
  }
  context.go(Uri(path: '/ai_news/webview', queryParameters: {'url': url, 'title': title}).toString());
}
