import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_detail_components.dart';

/*
*详情阅读流第一页:标题、摘要、双语内容与来源。
*/
class AiNewsDetailOverview extends StatelessWidget {
  const AiNewsDetailOverview({
    required this.item,
    this.onOpenOriginal,
    super.key,
  });

  static const double _wideHeroBreakpoint = 760;
  static const double _wideHeroWidth = 340;
  static const double _compactHeroHeight = 165;
  static const double _compactHeroWidth = 196;

  // 当前资讯。
  final AiNewsItem item;

  // 打开原文操作。
  final VoidCallback? onOpenOriginal;

  @override
  /* 构建第一页完整阅读内容。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final originalText = item.titleEn.trim().isEmpty ? item.summary : item.titleEn;
    return AiNewsDetailPageFrame(
      scrollKey: const PageStorageKey('ai-news-detail-overview-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AiNewsDetailCategoryPill(category: item.category),
              Text(
                formatAiNewsDetailDate(item.publishedAt),
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                '·  ${item.source}',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _wideHeroBreakpoint) {
                return _CompactHero(
                  item: item,
                  height: constraints.maxWidth < 410 ? _compactHeroHeight : 145,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WideHero(item: item),
                  const SizedBox(height: AppSpacing.lg),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: AiNewsDetailPageMarker(current: 1, total: 3),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            item.summary,
            style: AppTypography.bodyLarge.copyWith(
              color: colors.onSurface,
              height: 1.86,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AiNewsDetailLanguageCard(
            icon: Icons.translate_rounded,
            title: l10n.tr('ai_news.detail.original'),
            body: originalText,
            onOpenOriginal: onOpenOriginal,
          ),
          const SizedBox(height: AppSpacing.lg),
          AiNewsDetailLanguageCard(
            icon: Icons.g_translate_rounded,
            title: l10n.tr('ai_news.detail.translation'),
            body: item.summary,
            tinted: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.tr('ai_news.detail.translation_note'),
            style: AppTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              AiNewsDetailMetricPill(
                icon: Icons.local_fire_department_rounded,
                label: '${l10n.tr('ai_news.detail_score')} ${item.score}',
              ),
              if (item.selected)
                AiNewsDetailMetricPill(
                  icon: Icons.verified_rounded,
                  label: l10n.tr('ai_news.detail_selected'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AiNewsDetailSourceCard(item: item, onOpenOriginal: onOpenOriginal),
        ],
      ),
    );
  }
}

/*
*宽窗口标题与主视觉并排布局。
*/
class _WideHero extends StatelessWidget {
  const _WideHero({required this.item});

  // 当前资讯。
  final AiNewsItem item;

  @override
  /* 构建桌面并排标题区。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: AppTypography.displayLarge.copyWith(
                  color: colors.onSurface,
                  height: 1.26,
                ),
              ),
              if (item.titleEn.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  item.titleEn,
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Semantics(
          image: true,
          label: 'AI memory synchronization illustration',
          child: Image.asset(
            'assets/ai_news/detail_memory_sync_hero.png',
            width: AiNewsDetailOverview._wideHeroWidth,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

/*
*紧凑窗口标题与主视觉叠放布局。
*/
class _CompactHero extends StatelessWidget {
  const _CompactHero({required this.item, required this.height});

  // 当前资讯。
  final AiNewsItem item;

  // 当前紧凑宽度下的标题区高度。
  final double height;

  @override
  /* 构建接近参考截图的紧凑标题区。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleWidth = (constraints.maxWidth - 118).clamp(248.0, constraints.maxWidth).toDouble();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -AppSpacing.md,
                top: -AppSpacing.lg,
                child: Semantics(
                  image: true,
                  label: 'AI memory synchronization illustration',
                  child: Image.asset(
                    'assets/ai_news/detail_memory_sync_hero.png',
                    width: AiNewsDetailOverview._compactHeroWidth,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: AiNewsDetailPageMarker(current: 1, total: 3),
              ),
              SizedBox(
                width: titleWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.displayMedium.copyWith(
                          color: colors.onSurface,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.26,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: 260,
                        child: Text(
                          item.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
