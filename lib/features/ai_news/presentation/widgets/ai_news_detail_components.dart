import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';

const double aiNewsDetailMaxWidth = 1040;

/*
* 详情页的居中纵向滚动容器。
*/
class AiNewsDetailPageFrame extends StatelessWidget {
  const AiNewsDetailPageFrame({
    required this.child,
    required this.scrollKey,
    super.key,
  });

  // 页面主体。
  final Widget child;

  // 用于测试并保存详情页滚动位置。
  final Key scrollKey;

  @override
  /* 构建按窗口宽度收敛边距的详情滚动区。 */
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 600 ? AppSpacing.lg : AppSpacing.xxl;
          return SingleChildScrollView(
            key: scrollKey,
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.lg,
              horizontal,
              AppSpacing.xxl,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: aiNewsDetailMaxWidth),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/*
*资讯分类胶囊。
*/
class AiNewsDetailCategoryPill extends StatelessWidget {
  const AiNewsDetailCategoryPill({required this.category, super.key});

  // 当前资讯分类。
  final AiNewsCategory category;

  @override
  /* 构建青绿色描边分类标签。 */
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs2,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withValues(alpha: 0.35),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        category.label,
        style: AppTypography.labelLarge.copyWith(color: AppColors.brandDark),
      ),
    );
  }
}

/*
*详情区块标题,统一图标、字号和间距。
*/
class AiNewsDetailSectionTitle extends StatelessWidget {
  const AiNewsDetailSectionTitle({
    required this.icon,
    required this.title,
    this.trailing,
    super.key,
  });

  // 标题图标。
  final IconData icon;

  // 标题文案。
  final String title;

  // 可选尾部操作。
  final Widget? trailing;

  @override
  /* 构建详情区块标题行。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.brand),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleLarge.copyWith(color: colors.onSurface),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/*
*原文或译文卡片。
*/
class AiNewsDetailLanguageCard extends StatelessWidget {
  const AiNewsDetailLanguageCard({
    required this.icon,
    required this.title,
    required this.body,
    this.tinted = false,
    this.onOpenOriginal,
    super.key,
  });

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
    final background = tinted
        ? AppColors.brandLight.withValues(
            alpha: Theme.of(context).brightness == Brightness.light ? 0.24 : 0.08,
          )
        : colors.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiNewsDetailSectionTitle(icon: icon, title: title),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(
              color: tinted ? AppColors.brand.withValues(alpha: 0.22) : colors.outlineVariant.withValues(alpha: 0.62),
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                body,
                style: AppTypography.bodyLarge.copyWith(
                  color: colors.onSurface,
                  height: 1.72,
                ),
              ),
              if (onOpenOriginal != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onOpenOriginal,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: Text(
                      AppLocalizations.of(
                        context,
                      ).tr('ai_news.detail.view_original'),
                    ),
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
  const AiNewsDetailSourceCard({
    required this.item,
    this.onOpenOriginal,
    super.key,
  });

  // 当前资讯。
  final AiNewsItem item;

  // 打开原文操作。
  final VoidCallback? onOpenOriginal;

  @override
  /* 构建来源域名与跳转说明。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final host = Uri.tryParse(
      item.url.isNotEmpty ? item.url : item.permalink,
    )?.host;
    final source = host == null || host.isEmpty ? item.source : host;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onOpenOriginal,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.62),
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.public_rounded,
                  color: colors.onSurface,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tr('ai_news.detail.original_source'),
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.tr('ai_news.detail.source_description'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/*
*热度与精选状态的紧凑指标胶囊。
*/
class AiNewsDetailMetricPill extends StatelessWidget {
  const AiNewsDetailMetricPill({
    required this.icon,
    required this.label,
    super.key,
  });

  // 指标图标。
  final IconData icon;

  // 指标文案。
  final String label;

  @override
  /* 构建品牌色指标胶囊。 */
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withValues(alpha: 0.3),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.brand),
          const SizedBox(width: AppSpacing.xs2),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.brandDark,
            ),
          ),
        ],
      ),
    );
  }
}

/* 将资讯时间格式化为详情页使用的本地时间。 */
String formatAiNewsDetailDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
