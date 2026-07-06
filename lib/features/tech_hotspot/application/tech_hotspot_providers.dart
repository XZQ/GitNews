import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/github/rate_limit_gate.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/github_tech_hotspot_repository.dart';
import '../data/local_tech_hotspot_repository.dart';
import '../data/tech_hotspot_history_dao.dart';
import '../domain/tech_hotspot_models.dart';
import '../domain/tech_hotspot_repository.dart';

final techHotspotHistoryDaoProvider = Provider<TechHotspotHistoryDao>((ref) {
  return TechHotspotHistoryDao(ref.watch(jsonSnapshotCacheDaoProvider));
});

final techHotspotRepositoryProvider = Provider<TechHotspotRepository>((ref) {
  final token = ref.watch(githubTokenControllerProvider).token;
  final gate = ref.watch(rateLimitGateProvider);
  final gateController = ref.watch(rateLimitGateProvider.notifier);
  return GithubTechHotspotRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonSnapshotCacheDaoProvider),
    token: token,
    history: ref.watch(techHotspotHistoryDaoProvider),
    isRateLimited: () => gate.isBlocked,
    onRateLimited: gateController.trigger,
  );
});

final localTechHotspotRepositoryProvider = Provider<TechHotspotRepository>(
  (ref) => const LocalTechHotspotRepository(),
);

final techHotspotDigestProvider = FutureProvider<TechHotspotDigest>((ref) {
  return ref.watch(techHotspotRepositoryProvider).getDigest();
});

/// AI 雷达顶部搜索关键词。空字符串表示不过滤当前本地雷达数据。
final techHotspotSearchQueryProvider = StateProvider<String>((ref) => '');

/// AI 雷达分类筛选。`all` 表示不过滤分类。
final techHotspotCategoryFilterProvider = StateProvider<String>((ref) => 'all');

/// 应用本地搜索后的 AI 雷达摘要。
final filteredTechHotspotDigestProvider =
    FutureProvider<TechHotspotDigest>((ref) async {
  final query = ref.watch(techHotspotSearchQueryProvider);
  final category = ref.watch(techHotspotCategoryFilterProvider);
  final digest = await ref.watch(techHotspotDigestProvider.future);
  return filterTechHotspotDigest(digest, query, category: category);
});

TechHotspotDigest filterTechHotspotDigest(
  TechHotspotDigest digest,
  String query, {
  String category = 'all',
}) {
  final keyword = query.trim().toLowerCase();
  final categoryKey = category.trim().toLowerCase();
  final categoryTopics = categoryKey == 'all'
      ? digest.topics
      : [
          for (final topic in digest.topics)
            if (topic.category.toLowerCase() == categoryKey) topic,
        ];
  if (keyword.isEmpty) {
    return TechHotspotDigest(
      languages: digest.languages,
      topics: categoryTopics,
      heatTrend: digest.heatTrend,
      hotTags: digest.hotTags,
    );
  }

  return TechHotspotDigest(
    languages: digest.languages,
    topics: filterTechTopics(categoryTopics, keyword),
    heatTrend: digest.heatTrend,
    hotTags: [
      for (final tag in digest.hotTags)
        if (tag.toLowerCase().contains(keyword)) tag,
    ],
  );
}

List<TechTopic> filterTechTopics(List<TechTopic> topics, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return topics;

  return [
    for (final topic in topics)
      if (_topicSearchText(topic).contains(keyword)) topic,
  ];
}

String _topicSearchText(TechTopic topic) {
  return [
    topic.id,
    topic.name,
    topic.category,
    topic.summary,
  ].join(' ').toLowerCase();
}
