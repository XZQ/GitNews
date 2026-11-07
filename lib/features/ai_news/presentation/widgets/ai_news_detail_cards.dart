import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_detail_section_title.dart';
import 'ai_news_detail_tokens.dart';

/*
*原文或译文卡片。
*/
class AiNewsDetailLanguageCard extends StatelessWidget {
  const AiNewsDetailLanguageCard({required this.icon, required this.title, required this.body, this.tinted = false, this.onOpenOriginal, super.key});

  // 语种图标。
  final IconData icon;

  // 区块标题。
  final String title;

  // 正文内容。
  final String body;

  // 是否使用品牌色浅底。
  final bool tinted;

  // 原文跳转操作,只在提供时展示。
  final VoidCallback? onOpenOriginal;

  @override
  /* 构建双语阅读卡片。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = tinted ? colors.primary.withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.08 : 0.05) : colors.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiNewsDetailSectionTitle(icon: icon, title: title),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: tinted ? colors.primary.withValues(alpha: 0.28) : colors.outlineVariant.withValues(alpha: 0.62)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(body, style: AppTypography.bodyLarge.copyWith(color: colors.onSurface, height: 1.72)),
              if (onOpenOriginal != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onOpenOriginal,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: Text(AppLocalizations.of(context).tr('ai_news.detail.view_original')),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/*
*详情页的原始来源入口。
*/
class AiNewsDetailSourceCard extends StatelessWidget {
  const AiNewsDetailSourceCard({required this.item, this.onOpenOriginal, super.key});

  // 当前资讯。
  final AiNewsItem item;

  // 打开原文操作。
  final VoidCallback? onOpenOriginal;

  @override
  /* 构建来源域名与跳转说明。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final host = Uri.tryParse(item.url.isNotEmpty ? item.url : item.permalink)?.host;
    final source = host == null || host.isEmpty ? item.source : host;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onOpenOriginal,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md2),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.62)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.public_rounded, color: colors.onSurfaceVariant, size: 20),
              ),
              const SizedBox(width: AppSpacing.md2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.tr('ai_news.detail.original_source'), style: AppTypography.reading(AppTypography.labelMicro).copyWith(color: aiNewsDetailMutedColor(context))),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(AppTypography.bodyLarge).copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${item.source} · ${l10n.tr('ai_news.detail.view_original')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(color: aiNewsDetailSecondaryColor(context)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: aiNewsDetailMutedColor(context), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
