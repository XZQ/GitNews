import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import '../application/tech_hotspot_detail_providers.dart';
import '../application/tech_hotspot_providers.dart';
import '../domain/tech_hotspot_models.dart';
import 'detail/tech_hotspot_detail_body.dart';
import 'detail/tech_hotspot_detail_related.dart';
import 'detail/tech_hotspot_detail_section_error.dart';
import 'detail/tech_hotspot_detail_skeleton.dart';
import 'detail/tech_hotspot_detail_topic_header.dart';

/* 
*技术主题详情页。
*/
class TechHotspotDetailPage extends ConsumerWidget {
  const TechHotspotDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(techHotspotDetailProvider(id));
    return SecondaryPageScaffold(
      title: state.maybeWhen(data: (topic) => topic.name, orElse: () => l10n.tr('tech_hotspot.detail_title')),
      subtitle: l10n.tr('tech_hotspot.detail.summary.subtitle'),
      icon: Icons.device_hub_rounded,
      fallbackPath: '/tech_hotspot',
      body: state.when(
        data: (topic) => _Loaded(id: id, topic: topic),
        loading: () => const TechHotspotDetailSkeleton(),
        error: (error, stack) => ErrorView(error: error.asAppException(stack), onRetry: () => ref.invalidate(techHotspotDetailProvider(id))),
      ),
    );
  }
}

/* 
*详情页加载完成后,内部再独立 watch 关联列表与语言面板。
*- 关联列表 / 语言面板允许短暂 loading,期间用各自的 skeleton 占位。
*- 任一子区块失败都通过 [_SectionError] 暴露给用户并提供重试,不再静默降级。
*/
class _Loaded extends ConsumerWidget {
  const _Loaded({required this.id, required this.topic});

  final String id;
  final TechTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedState = ref.watch(techHotspotRelatedProvider(id));
    final languagesState = ref.watch(techHotspotDigestProvider);
    final related = relatedState.value ?? const <TechTopic>[];
    final languages = languagesState.value?.languages ?? const <LanguageStat>[];
    final formFactor = Breakpoints.of(context);
    final relatedError = relatedState.hasError ? relatedState.error!.asAppException(relatedState.stackTrace ?? StackTrace.current) : null;
    final languagesError = languagesState.hasError ? languagesState.error!.asAppException(languagesState.stackTrace ?? StackTrace.current) : null;
    if (formFactor == FormFactor.compact) {
      return _Mobile(
        topic: topic,
        related: related,
        languages: languages,
        relatedError: relatedError,
        languagesError: languagesError,
        onRetryRelated: () => ref.invalidate(techHotspotRelatedProvider(id)),
        onRetryLanguages: () => ref.invalidate(techHotspotDigestProvider),
      );
    }
    return CenteredContent(
      child: _Desktop(
        topic: topic,
        related: related,
        languages: languages,
        relatedError: relatedError,
        languagesError: languagesError,
        onRetryRelated: () => ref.invalidate(techHotspotRelatedProvider(id)),
        onRetryLanguages: () => ref.invalidate(techHotspotDigestProvider),
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile({
    required this.topic,
    required this.related,
    required this.languages,
    required this.relatedError,
    required this.languagesError,
    required this.onRetryRelated,
    required this.onRetryLanguages,
  });

  final TechTopic topic;
  final List<TechTopic> related;
  final List<LanguageStat> languages;
  final AppException? relatedError;
  final AppException? languagesError;
  final VoidCallback onRetryRelated;
  final VoidCallback onRetryLanguages;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      children: [
        TechHotspotDetailTopicHeader(topic: topic),
        const SizedBox(height: AppSpacing.lg),
        TechHotspotDetailSummary(topic: topic),
        const SizedBox(height: AppSpacing.lg),
        if (languagesError != null)
          TechHotspotDetailSectionError(title: l10n.tr('tech_hotspot.error.languages'), error: languagesError!, onRetry: onRetryLanguages)
        else
          TechHotspotDetailLanguages(languages: languages),
        if (relatedError != null) ...[
          const SizedBox(height: AppSpacing.lg),
          TechHotspotDetailSectionError(title: l10n.tr('tech_hotspot.error.related'), error: relatedError!, onRetry: onRetryRelated),
        ] else if (related.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          TechHotspotDetailRelated(items: related),
        ],
      ],
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop({
    required this.topic,
    required this.related,
    required this.languages,
    required this.relatedError,
    required this.languagesError,
    required this.onRetryRelated,
    required this.onRetryLanguages,
  });

  final TechTopic topic;
  final List<TechTopic> related;
  final List<LanguageStat> languages;
  final AppException? relatedError;
  final AppException? languagesError;
  final VoidCallback onRetryRelated;
  final VoidCallback onRetryLanguages;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        TechHotspotDetailTopicHeader(topic: topic),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TechHotspotDetailSummary(topic: topic),
                  const SizedBox(height: AppSpacing.lg),
                  if (languagesError != null)
                    TechHotspotDetailSectionError(title: l10n.tr('tech_hotspot.error.languages'), error: languagesError!, onRetry: onRetryLanguages)
                  else
                    TechHotspotDetailLanguages(languages: languages),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 4,
              child: relatedError != null
                  ? TechHotspotDetailSectionError(title: l10n.tr('tech_hotspot.error.related'), error: relatedError!, onRetry: onRetryRelated)
                  : related.isEmpty
                  ? const SizedBox.shrink()
                  : TechHotspotDetailRelated(items: related),
            ),
          ],
        ),
      ],
    );
  }
}
