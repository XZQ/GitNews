import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../application/ai_news_detail_providers.dart';
import '../domain/ai_news_item.dart';
import 'detail/ai_news_detail_cover.dart';
import 'detail/ai_news_detail_meta.dart';
import 'detail/ai_news_detail_related.dart';
import 'detail/ai_news_detail_skeleton.dart';
import 'detail/ai_news_detail_source_link.dart';
import 'detail/ai_news_detail_summary.dart';

/// AI 动态详情页。
class AiNewsDetailPage extends ConsumerWidget {
  const AiNewsDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiNewsDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: state.maybeWhen(
          data: (item) => Text(item.title),
          orElse: () => const Text('动态详情'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/ai_news'),
        ),
      ),
      body: state.when(
        data: (item) {
          final related = ref.watch(aiNewsRelatedProvider(id));
          return ResponsiveLayout(
            compact: (_) => _Mobile(item: item, related: related),
            medium: (_) =>
                CenteredContent(child: _Desktop(item: item, related: related)),
            expanded: (_) =>
                CenteredContent(child: _Desktop(item: item, related: related)),
          );
        },
        loading: () => const AiNewsDetailSkeleton(),
        error: (error, stack) => ErrorView(
          error: _toAppException(error, stack),
          onRetry: () => ref.invalidate(aiNewsDetailProvider(id)),
        ),
      ),
    );
  }

  AppException _toAppException(Object error, StackTrace stack) {
    if (error is AppException) return error;
    return AppException(
      kind: AppExceptionKind.unknown,
      cause: error,
      stack: stack,
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile({required this.item, required this.related});

  final AiNewsItem item;
  final List<AiNewsItem> related;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        AiNewsDetailCover(item: item),
        const SizedBox(height: AppSpacing.lg),
        AiNewsDetailMeta(item: item),
        const SizedBox(height: AppSpacing.lg),
        AiNewsDetailSummary(item: item),
        const SizedBox(height: AppSpacing.lg),
        AiNewsDetailTags(item: item),
        if (item.sourceUrl != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AiNewsDetailSourceLink(item: item),
        ],
        if (related.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AiNewsDetailRelated(items: related),
        ],
      ],
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop({required this.item, required this.related});

  final AiNewsItem item;
  final List<AiNewsItem> related;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        AiNewsDetailCover(item: item),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AiNewsDetailMeta(item: item),
                  const SizedBox(height: AppSpacing.lg),
                  AiNewsDetailSummary(item: item),
                  const SizedBox(height: AppSpacing.lg),
                  AiNewsDetailTags(item: item),
                  if (item.sourceUrl != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AiNewsDetailSourceLink(item: item),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 4,
              child: related.isEmpty
                  ? const SizedBox.shrink()
                  : AiNewsDetailRelated(items: related),
            ),
          ],
        ),
      ],
    );
  }
}
