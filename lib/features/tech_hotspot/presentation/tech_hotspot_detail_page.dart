import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../application/tech_hotspot_detail_providers.dart';
import '../application/tech_hotspot_providers.dart';
import '../domain/tech_hotspot_models.dart';
import 'detail/tech_hotspot_detail_body.dart';
import 'detail/tech_hotspot_detail_related.dart';
import 'detail/tech_hotspot_detail_skeleton.dart';
import 'detail/tech_hotspot_detail_topic_header.dart';

/// 技术主题详情页。
class TechHotspotDetailPage extends ConsumerWidget {
  const TechHotspotDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(techHotspotDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: state.maybeWhen(
          data: (topic) => Text(topic.name),
          orElse: () => Text(l10n.tr('tech_hotspot.detail_title')),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/tech_hotspot'),
        ),
      ),
      body: state.when(
        data: (topic) => _Loaded(id: id, topic: topic),
        loading: () => const TechHotspotDetailSkeleton(),
        error: (error, stack) => ErrorView(
          error: error.asAppException(stack),
          onRetry: () => ref.invalidate(techHotspotDetailProvider(id)),
        ),
      ),
    );
  }
}

/// 详情页加载完成后,内部再独立 watch 关联列表与语言面板。
///
/// - 关联列表 / 语言面板允许短暂 loading,期间用各自的 skeleton 占位。
/// - 任一子区块失败都通过 [_SectionError] 暴露给用户并提供重试,不再静默降级。
class _Loaded extends ConsumerWidget {
  const _Loaded({required this.id, required this.topic});

  final String id;
  final TechTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedState = ref.watch(techHotspotRelatedProvider(id));
    final languagesState = ref.watch(techHotspotDigestProvider);
    final related = relatedState.valueOrNull ?? const <TechTopic>[];
    final languages =
        languagesState.valueOrNull?.languages ?? const <LanguageStat>[];
    final formFactor = Breakpoints.of(context);
    final relatedError = relatedState.hasError
        ? relatedState.error!
            .asAppException(relatedState.stackTrace ?? StackTrace.current)
        : null;
    final languagesError = languagesState.hasError
        ? languagesState.error!
            .asAppException(languagesState.stackTrace ?? StackTrace.current)
        : null;
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        TechHotspotDetailTopicHeader(topic: topic),
        const SizedBox(height: AppSpacing.lg),
        TechHotspotDetailSummary(topic: topic),
        const SizedBox(height: AppSpacing.lg),
        if (languagesError != null)
          _SectionError(
            title: l10n.tr('tech_hotspot.error.languages'),
            error: languagesError!,
            onRetry: onRetryLanguages,
          )
        else
          TechHotspotDetailLanguages(languages: languages),
        if (relatedError != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionError(
            title: l10n.tr('tech_hotspot.error.related'),
            error: relatedError!,
            onRetry: onRetryRelated,
          ),
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
                    _SectionError(
                      title: l10n.tr('tech_hotspot.error.languages'),
                      error: languagesError!,
                      onRetry: onRetryLanguages,
                    )
                  else
                    TechHotspotDetailLanguages(languages: languages),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 4,
              child: relatedError != null
                  ? _SectionError(
                      title: l10n.tr('tech_hotspot.error.related'),
                      error: relatedError!,
                      onRetry: onRetryRelated,
                    )
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

/// 紧凑的子区块错误占位:在详情主体已加载的情况下,提供内联重试而不是全屏 ErrorView。
class _SectionError extends StatelessWidget {
  const _SectionError({
    required this.title,
    required this.error,
    required this.onRetry,
  });

  final String title;
  final AppException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  _messageFor(l10n, error),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            child: Text(l10n.tr('common.retry')),
          ),
        ],
      ),
    );
  }
}

/// 与 [ErrorView] 保持同源语义,但只输出文案以便嵌入紧凑布局。
String _messageFor(AppLocalizations l10n, AppException error) {
  switch (error.kind) {
    case AppExceptionKind.network:
      return l10n.tr('tech_hotspot.error.network');
    case AppExceptionKind.rateLimit:
      final secs = error.retryAfterSeconds ?? 60;
      return l10n
          .tr('tech_hotspot.error.rate_limit')
          .replaceAll('{secs}', secs.toString());
    case AppExceptionKind.unauthorized:
      return l10n.tr('tech_hotspot.error.unauthorized');
    case AppExceptionKind.notFound:
      return l10n.tr('tech_hotspot.error.not_found');
    case AppExceptionKind.parse:
    case AppExceptionKind.server:
    case AppExceptionKind.cache:
    case AppExceptionKind.unknown:
      return l10n.tr('tech_hotspot.error.unknown');
  }
}
