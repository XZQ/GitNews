import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_category_style.dart';

class AiNewsDetailContent extends StatelessWidget {
  const AiNewsDetailContent({required this.item, super.key});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.tr('ai_news.detail_title'),
          subtitle: item.source,
          actions: [
            IconButton(
              tooltip: l10n.tr('webview.copy_link'),
              onPressed: () => _copyLink(context),
              icon: const Icon(Icons.content_copy_rounded),
            ),
            IconButton(
              tooltip: l10n.tr('webview.open_in_browser'),
              onPressed: () => _openOriginal(context),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: _ArticleSummary(item: item),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: _ArticleMeta(item: item),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    final link = item.url.isNotEmpty ? item.url : item.permalink;
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.tr('webview.copied'))),
    );
  }

  Future<void> _openOriginal(BuildContext context) async {
    final target = item.url.isNotEmpty ? item.url : item.permalink;
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('ai_news.open_failed'))),
      );
    }
  }
}

class _ArticleSummary extends StatelessWidget {
  const _ArticleSummary({required this.item});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _CategoryBadge(category: item.category),
            _MetaText(text: item.source),
            _MetaText(text: _formatDate(item.publishedAt)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          item.title,
          style: AppTypography.headlineMedium.copyWith(
            color: colors.onSurface,
            height: 1.18,
          ),
        ),
        if (item.titleEn.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            item.titleEn,
            style: AppTypography.titleMedium.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          item.summary,
          style: AppTypography.bodyLarge.copyWith(
            color: colors.onSurface,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _ArticleMeta extends StatelessWidget {
  const _ArticleMeta({required this.item});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: [
        _MetricChip(
          icon: Icons.local_fire_department_rounded,
          label: l10n.tr('ai_news.detail_score'),
          value: item.score.toString(),
        ),
        _MetricChip(
          icon: Icons.verified_rounded,
          label: l10n.tr('ai_news.detail_selected'),
          value: item.selected ? l10n.tr('common.confirm') : '-',
        ),
        _MetricChip(
          icon: Icons.link_rounded,
          label: l10n.tr('ai_news.detail_source'),
          value: Uri.tryParse(item.url)?.host ?? item.source,
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final AiNewsCategory category;

  @override
  Widget build(BuildContext context) {
    final color = aiNewsCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.34)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(aiNewsCategoryIcon(category), size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            category.label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label $value',
          style: AppTypography.labelLarge.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
