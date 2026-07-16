import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/github/rate_limit_gate.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/discover_repository.dart';
import '../domain/discover_entities.dart';
import 'discover_notifiers.dart';

const int discoverPageSize = 30;
const int discoverProfilesPageSize = 20;
const int discoverLoadMoreRemainingItems = 3;
const double discoverItemExtentCards = 96.0;
const int discoverProfileEnrichBatchSize = 10;

/*
 *发现页数据仓库 Provider(复用 dio / 缓存 / token / 限流门控)。
 */
final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  final token = ref.watch(githubTokenControllerProvider).token;
  final gate = ref.watch(rateLimitGateProvider);
  final gateController = ref.watch(rateLimitGateProvider.notifier);
  return DiscoverRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonSnapshotCacheDaoProvider),
    token: token,
    cacheScope: ref.watch(githubTokenControllerProvider).cacheScope,
    isRateLimited: () => gate.isBlocked,
    onRateLimited: gateController.trigger,
  );
});

// 当前展示分段:'repos'(流行仓库) | 'skills'(Agent Skills)。
final discoverSegmentProvider = StateProvider<String>((ref) => 'repos');

// 列表搜索关键词。
final discoverSearchQueryProvider = StateProvider<String>((ref) => '');

// 刷新计数器:自增即触发强制刷新(绕过缓存 TTL)。
final discoverRefreshTickProvider = StateProvider<int>((ref) => 0);

final discoverReposFreshnessProvider = StateProvider<DataFreshness>((ref) => DataFreshness.seed);
final discoverSkillsFreshnessProvider = StateProvider<DataFreshness>((ref) => DataFreshness.seed);
final discoverOfficialFreshnessProvider = StateProvider<DataFreshness>((ref) => DataFreshness.seed);
final discoverPeopleFreshnessProvider = StateProvider<DataFreshness>((ref) => DataFreshness.seed);

final discoverFreshnessProvider = Provider<DataFreshness>((ref) {
  return switch (ref.watch(discoverSegmentProvider)) {
    'skills' => ref.watch(discoverSkillsFreshnessProvider),
    'official' => ref.watch(discoverOfficialFreshnessProvider),
    'people' => ref.watch(discoverPeopleFreshnessProvider),
    _ => ref.watch(discoverReposFreshnessProvider)
  };
});

final trendingReposNotifierProvider = AsyncNotifierProvider.autoDispose<TrendingReposNotifier, List<RepoEntity>>(TrendingReposNotifier.new);

final agentSkillsNotifierProvider = AsyncNotifierProvider.autoDispose<AgentSkillsNotifier, List<SkillEntity>>(AgentSkillsNotifier.new);

final officialProfilesNotifierProvider = AsyncNotifierProvider.autoDispose<ProfilesNotifier, List<DiscoverProfileEntity>>(() => ProfilesNotifier(DiscoverProfileKind.official));

final peopleProfilesNotifierProvider = AsyncNotifierProvider.autoDispose<ProfilesNotifier, List<DiscoverProfileEntity>>(() => ProfilesNotifier(DiscoverProfileKind.people));

// 应用本地搜索后的流行仓库。
final filteredTrendingReposProvider = Provider<AsyncValue<List<RepoEntity>>>((ref) {
  final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
  final repos = ref.watch(trendingReposNotifierProvider);
  if (query.isEmpty) {
    return repos;
  }
  return repos.whenData((items) => items.where((r) => _repoText(r).contains(query)).toList());
});

// 应用本地搜索后的 Agent Skills。
final filteredAgentSkillsProvider = Provider<AsyncValue<List<SkillEntity>>>((ref) {
  final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
  final skills = ref.watch(agentSkillsNotifierProvider);
  if (query.isEmpty) {
    return skills;
  }
  return skills.whenData((items) => items.where((s) => _skillText(s).contains(query)).toList());
});

final filteredOfficialProfilesProvider = FutureProvider.autoDispose<List<DiscoverProfileEntity>>((ref) async {
  final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
  final profiles = await ref.watch(officialProfilesNotifierProvider.future);
  if (query.isEmpty) {
    return profiles;
  }
  return profiles.where((p) => _profileText(p).contains(query)).toList();
});

final filteredPeopleProfilesProvider = FutureProvider.autoDispose<List<DiscoverProfileEntity>>((ref) async {
  final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
  final profiles = await ref.watch(peopleProfilesNotifierProvider.future);
  if (query.isEmpty) {
    return profiles;
  }
  return profiles.where((p) => _profileText(p).contains(query)).toList();
});

// 移动端「官方内容」把官方组织与知名人士合并成一个发现入口。
final filteredFeaturedProfilesProvider = FutureProvider.autoDispose<List<DiscoverProfileEntity>>((ref) async {
  final groups = await Future.wait<List<DiscoverProfileEntity>>([
    ref.watch(filteredOfficialProfilesProvider.future),
    ref.watch(filteredPeopleProfilesProvider.future),
  ]);
  return [...groups[0], ...groups[1]];
});

String _repoText(RepoEntity r) => '${r.fullName} ${r.description} ${r.language}'.toLowerCase();

String _skillText(SkillEntity s) => '${s.repo.fullName} ${s.repo.description} ${s.category} ${s.source}'.toLowerCase();

String _profileText(DiscoverProfileEntity p) => '${p.login} ${p.name} ${p.type} ${p.bio}'.toLowerCase();
