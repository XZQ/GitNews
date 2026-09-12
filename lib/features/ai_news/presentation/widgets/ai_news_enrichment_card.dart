import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/preferences/ai_digest_config_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/ai_news_enrichment_providers.dart';
import '../../domain/ai_news_enrichment.dart';
import '../../domain/ai_news_item.dart';

/*
*资讯详情的 AI 摘要与翻译，按实际生成字段展示并说明来源。
*/
class AiNewsEnrichmentCard extends ConsumerStatefulWidget {
  const AiNewsEnrichmentCard({required this.item, super.key});

  // 当前资讯。
  final AiNewsItem item;

  @override
  /* 创建局部生成状态。 */
  ConsumerState<AiNewsEnrichmentCard> createState() => _AiNewsEnrichmentCardState();
}

/*
*管理增强内容生成中的短暂交互状态。
*/
class _AiNewsEnrichmentCardState extends ConsumerState<AiNewsEnrichmentCard> {
  // 防止重复生成。
  bool _working = false;
  String? _autoRequestedItemId;

  @override
  /* 构建增强数据的加载、错误、空和内容状态。 */
  Widget build(BuildContext context) {
    final enrichment = ref.watch(aiNewsEnrichmentProvider(widget.item.id));
    final configured = ref.watch(aiDigestConfigControllerProvider).configured;
    final missingEnrichment = enrichment.when(data: (value) => value == null, loading: () => false, error: (_, __) => false);
    _scheduleAutomaticGeneration(configured: configured, missingEnrichment: missingEnrichment);
    return enrichment.when(
      data: (value) => value == null
          ? const SizedBox.shrink()
          : _EnrichmentSurface(
              child: _EnrichmentContent(enrichment: value, working: _working, onRegenerate: configured ? () => _generate(force: true) : null),
            ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /* AI 已配置且没有本地增强缓存时,在当前帧完成后自动发起一次生成。 */
  void _scheduleAutomaticGeneration({required bool configured, required bool missingEnrichment}) {
    final itemId = widget.item.id;
    if (!configured || !missingEnrichment || _working || _autoRequestedItemId == itemId) {
      return;
    }
    _autoRequestedItemId = itemId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.item.id != itemId || _autoRequestedItemId != itemId) {
        return;
      }
      unawaited(_generate());
    });
  }

  /* 生成或强制刷新当前资讯的本地增强内容。 */
  Future<void> _generate({bool force = false}) async {
    if (_working) {
      return;
    }
    setState(() {
      _working = true;
    });
    try {
      await ref.read(aiNewsEnrichmentGeneratorProvider)(widget.item, force: force);
    } catch (_) {
      // Agnes 不可用或返回无效内容时保持隐藏,不把服务商故障转嫁给用户。
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }
}

/*
*生成内容的中性卡片外层。
*/
class _EnrichmentSurface extends StatelessWidget {
  const _EnrichmentSurface({required this.child});

  // 容器内容。
  final Widget child;

  @override
  /* 构建设计稿中的白色卡片与细边框。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: child,
    );
  }
}

/*
*完整显示摘要、中文翻译、实体与重要性估计。
*/
class _EnrichmentContent extends StatelessWidget {
  const _EnrichmentContent({required this.enrichment, required this.working, required this.onRegenerate});

  // 本地增强结果。
  final AiNewsEnrichment enrichment;

  // 是否正在重新生成。
  final bool working;

  // 重新生成操作。
  final VoidCallback? onRegenerate;

  @override
  /* 不把摘要与翻译表述成深度分析，不截断生成正文。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final signals = enrichment.entities.all;
    final signalText = signals.isEmpty ? l10n.tr('ai_news.enrichment.no_entities') : signals.join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EnrichmentHeader(working: working, onRegenerate: onRegenerate),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.tr('ai_news.enrichment.note').replaceAll('{model}', enrichment.model), style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.58)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              _InsightRow(icon: Icons.summarize_outlined, title: l10n.tr('ai_news.enrichment.summary'), body: enrichment.generatedSummary),
              const Divider(height: 1),
              _InsightRow(icon: Icons.translate_rounded, title: l10n.tr('ai_news.enrichment.translation'), body: enrichment.translatedSummary),
              const Divider(height: 1),
              _InsightRow(icon: Icons.label_outline_rounded, title: l10n.tr('ai_news.enrichment.entities'), body: signalText),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.tr('ai_news.enrichment.importance').replaceAll('{score}', '${enrichment.importanceScore.round()}'),
          style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/*
*AI 内容标题与重新生成操作。
*/
class _EnrichmentHeader extends StatelessWidget {
  const _EnrichmentHeader({required this.working, required this.onRegenerate});

  // 是否正在处理。
  final bool working;

  // 可选重新生成操作。
  final VoidCallback? onRegenerate;

  @override
  /* 构建带星光图标的解读标题。 */
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(l10n.tr('ai_news.enrichment.title'), style: AppTypography.titleMedium)),
        if (onRegenerate != null)
          IconButton(
            tooltip: l10n.tr('ai_news.enrichment.regenerate'),
            onPressed: working ? null : onRegenerate,
            icon: working ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded),
          ),
      ],
    );
  }
}

/*
*生成结果中的一个命名字段。
*/
class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.icon, required this.title, required this.body});

  // 观点图标。
  final IconData icon;

  // 观点标题。
  final String title;

  // 观点内容。
  final String body;

  @override
  /* 构建图标、标题与正文行。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: AppColors.brandLight.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Icon(icon, color: AppColors.brand, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium.copyWith(color: colors.onSurface)),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant, height: 1.62)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
