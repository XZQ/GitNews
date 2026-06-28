import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
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
    final state = ref.watch(techHotspotDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: state.maybeWhen(
          data: (topic) => Text(topic.name),
          orElse: () => const Text('主题详情'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/tech_hotspot'),
        ),
      ),
      body: state.when(
        data: (topic) {
          final related = ref.watch(techHotspotRelatedProvider(id));
          final languages = ref.watch(techHotspotDigestProvider).languages;
          return ResponsiveLayout(
            compact: (_) => _Mobile(
              topic: topic,
              related: related,
              languages: languages,
            ),
            medium: (_) => CenteredContent(
              child: _Desktop(
                topic: topic,
                related: related,
                languages: languages,
              ),
            ),
            expanded: (_) => CenteredContent(
              child: _Desktop(
                topic: topic,
                related: related,
                languages: languages,
              ),
            ),
          );
        },
        loading: () => const TechHotspotDetailSkeleton(),
        error: (error, stack) => ErrorView(
          error: _toAppException(error, stack),
          onRetry: () => ref.invalidate(techHotspotDetailProvider(id)),
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
  const _Mobile({
    required this.topic,
    required this.related,
    required this.languages,
  });

  final TechTopic topic;
  final List<TechTopic> related;
  final List<LanguageStat> languages;

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
        TechHotspotDetailTopicHeader(topic: topic),
        const SizedBox(height: AppSpacing.lg),
        TechHotspotDetailSummary(topic: topic),
        const SizedBox(height: AppSpacing.lg),
        TechHotspotDetailLanguages(languages: languages),
        if (related.isNotEmpty) ...[
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
  });

  final TechTopic topic;
  final List<TechTopic> related;
  final List<LanguageStat> languages;

  @override
  Widget build(BuildContext context) {
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
                  TechHotspotDetailLanguages(languages: languages),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 4,
              child: related.isEmpty
                  ? const SizedBox.shrink()
                  : TechHotspotDetailRelated(items: related),
            ),
          ],
        ),
      ],
    );
  }
}
