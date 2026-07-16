import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/preferences/ai_digest_config_controller.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../application/ai_news_enrichment_providers.dart';
import '../../domain/ai_news_enrichment.dart';
import '../../domain/ai_news_item.dart';

class AiNewsEnrichmentCard extends ConsumerStatefulWidget {
  const AiNewsEnrichmentCard({required this.item, super.key});

  final AiNewsItem item;

  @override
  ConsumerState<AiNewsEnrichmentCard> createState() => _AiNewsEnrichmentCardState();
}

class _AiNewsEnrichmentCardState extends ConsumerState<AiNewsEnrichmentCard> {
  bool _working = false;
  bool _generationFailed = false;
  String? _autoRequestedItemId;

  @override
  Widget build(BuildContext context) {
    final enrichment = ref.watch(aiNewsEnrichmentProvider(widget.item.id));
    final configured = ref.watch(aiDigestConfigControllerProvider).configured;
    final missingEnrichment = enrichment.when(
      data: (value) => value == null,
      loading: () => false,
      error: (_, __) => false,
    );
    _scheduleAutomaticGeneration(
      configured: configured,
      missingEnrichment: missingEnrichment,
    );
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: enrichment.when(
        data: (value) => value == null
            ? _generationFailed
                ? _EnrichmentFailure(onRetry: _generate)
                : _EmptyEnrichment(configured: configured)
            : _EnrichmentContent(
                enrichment: value,
                working: _working,
                onRegenerate: () => _generate(force: true),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _EnrichmentFailure(onRetry: _generate),
      ),
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

  Future<void> _generate({bool force = false}) async {
    if (_working) {
      return;
    }
    setState(() {
      _working = true;
      _generationFailed = false;
    });
    try {
      final result = await ref.read(aiNewsEnrichmentGeneratorProvider)(widget.item, force: force);
      if (result == null && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tr('ai_news.enrichment.configure'))),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _generationFailed = true);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tr('ai_news.enrichment.failed'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }
}

class _EmptyEnrichment extends StatelessWidget {
  const _EmptyEnrichment({required this.configured});

  final bool configured;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tr('ai_news.enrichment.title'), style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.tr(
            configured ? 'ai_news.enrichment.description' : 'ai_news.enrichment.configure',
          ),
        ),
        if (configured) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.tr('ai_news.enrichment.generating')),
            ],
          ),
        ],
      ],
    );
  }
}

/*
*自动增强失败状态,保留显式重试入口。
*/
class _EnrichmentFailure extends StatelessWidget {
  const _EnrichmentFailure({required this.onRetry});

  // 用户主动重试回调。
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tr('ai_news.enrichment.failed')),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.tr('common.retry')),
        ),
      ],
    );
  }
}

class _EnrichmentContent extends StatelessWidget {
  const _EnrichmentContent({
    required this.enrichment,
    required this.working,
    required this.onRegenerate,
  });

  final AiNewsEnrichment enrichment;
  final bool working;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.tr('ai_news.enrichment.title'),
                style: AppTypography.titleMedium,
              ),
            ),
            Chip(
              avatar: const Icon(Icons.bolt_rounded, size: 16),
              label: Text('${enrichment.importanceScore.round()}/100'),
            ),
            IconButton(
              tooltip: l10n.tr('ai_news.enrichment.regenerate'),
              onPressed: working ? null : onRegenerate,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          enrichment.generatedSummary,
          style: AppTypography.bodyLarge.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(enrichment.translatedTitle, style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          enrichment.translatedSummary,
          style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
        if (enrichment.entities.all.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entity in enrichment.entities.all) Chip(label: Text(entity)),
            ],
          ),
        ],
      ],
    );
  }
}
