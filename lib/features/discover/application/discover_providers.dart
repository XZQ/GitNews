import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/github/rate_limit_gate.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/discover_repository.dart';
import '../domain/discover_entities.dart';

const int discoverPageSize = 30;
const int discoverProfilesPageSize = 20;
const int discoverLoadMoreRemainingItems = 3;
const double discoverItemExtentCards = 96.0;
const double discoverItemExtentCompact = 72.0;
const int discoverProfileEnrichBatchSize = 10;

/// 发现页数据仓库 Provider(复用 dio / 缓存 / token / 限流门控)。
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

/// 当前展示分段:'repos'(流行仓库) | 'skills'(Agent Skills)。
final discoverSegmentProvider = StateProvider<String>((ref) => 'repos');

/// 列表搜索关键词。
final discoverSearchQueryProvider = StateProvider<String>((ref) => '');

/// 刷新计数器:自增即触发强制刷新(绕过缓存 TTL)。
final discoverRefreshTickProvider = StateProvider<int>((ref) => 0);

final discoverReposFreshnessProvider = StateProvider<DataFreshness>(
  (ref) => DataFreshness.seed,
);
final discoverSkillsFreshnessProvider = StateProvider<DataFreshness>(
  (ref) => DataFreshness.seed,
);
final discoverOfficialFreshnessProvider = StateProvider<DataFreshness>(
  (ref) => DataFreshness.seed,
);
final discoverPeopleFreshnessProvider = StateProvider<DataFreshness>(
  (ref) => DataFreshness.seed,
);

final discoverFreshnessProvider = Provider<DataFreshness>((ref) {
  return switch (ref.watch(discoverSegmentProvider)) {
    'skills' => ref.watch(discoverSkillsFreshnessProvider),
    'official' => ref.watch(discoverOfficialFreshnessProvider),
    'people' => ref.watch(discoverPeopleFreshnessProvider),
    _ => ref.watch(discoverReposFreshnessProvider),
  };
});

final trendingReposNotifierProvider = AsyncNotifierProvider.autoDispose<TrendingReposNotifier, List<RepoEntity>>(
  TrendingReposNotifier.new,
);

final agentSkillsNotifierProvider = AsyncNotifierProvider.autoDispose<AgentSkillsNotifier, List<SkillEntity>>(
  AgentSkillsNotifier.new,
);

final officialProfilesNotifierProvider = AsyncNotifierProvider.autoDispose<ProfilesNotifier, List<DiscoverProfileEntity>>(
  () => ProfilesNotifier(DiscoverProfileKind.official),
);

final peopleProfilesNotifierProvider = AsyncNotifierProvider.autoDispose<ProfilesNotifier, List<DiscoverProfileEntity>>(
  () => ProfilesNotifier(DiscoverProfileKind.people),
);

/// 应用本地搜索后的流行仓库。
final filteredTrendingReposProvider = Provider<AsyncValue<List<RepoEntity>>>(
  (ref) {
    final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
    final repos = ref.watch(trendingReposNotifierProvider);
    if (query.isEmpty) {
      return repos;
    }
    return repos.whenData(
      (items) => items.where((r) => _repoText(r).contains(query)).toList(),
    );
  },
);

/// 应用本地搜索后的 Agent Skills。
final filteredAgentSkillsProvider = Provider<AsyncValue<List<SkillEntity>>>(
  (ref) {
    final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
    final skills = ref.watch(agentSkillsNotifierProvider);
    if (query.isEmpty) {
      return skills;
    }
    return skills.whenData(
      (items) => items.where((s) => _skillText(s).contains(query)).toList(),
    );
  },
);

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

class TrendingReposNotifier extends AutoDisposeAsyncNotifier<List<RepoEntity>> {
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  Future<List<RepoEntity>> build() async {
    final force = ref.watch(discoverRefreshTickProvider) > 0;
    _page = 1;
    final result = await ref.read(discoverRepositoryProvider).fetchTrendingRepos(
          force: force,
          page: _page,
          perPage: discoverPageSize,
        );
    final repos = result.data;
    ref.read(discoverReposFreshnessProvider.notifier).state = result.freshness;
    _hasMore = repos.length == discoverPageSize;
    return repos;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || state.hasError) {
      return;
    }
    _loadingMore = true;
    try {
      final nextPage = _page + 1;
      final result = await ref.read(discoverRepositoryProvider).fetchTrendingRepos(
            page: nextPage,
            perPage: discoverPageSize,
          );
      final repos = result.data;
      ref.read(discoverReposFreshnessProvider.notifier).state = result.freshness;
      _page = nextPage;
      _hasMore = repos.length == discoverPageSize;
      state = AsyncData([...?state.valueOrNull, ...repos]);
    } finally {
      _loadingMore = false;
    }
  }

  bool get hasMore => _hasMore;
}

class AgentSkillsNotifier extends AutoDisposeAsyncNotifier<List<SkillEntity>> {
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  Future<List<SkillEntity>> build() async {
    final force = ref.watch(discoverRefreshTickProvider) > 0;
    _page = 1;
    final result = await ref.read(discoverRepositoryProvider).fetchAgentSkills(
          force: force,
          page: _page,
          perPage: discoverPageSize,
        );
    final skills = result.data;
    ref.read(discoverSkillsFreshnessProvider.notifier).state = result.freshness;
    _hasMore = skills.length == discoverPageSize;
    return skills;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || state.hasError) {
      return;
    }
    _loadingMore = true;
    try {
      final nextPage = _page + 1;
      final result = await ref.read(discoverRepositoryProvider).fetchAgentSkills(
            page: nextPage,
            perPage: discoverPageSize,
          );
      final skills = result.data;
      ref.read(discoverSkillsFreshnessProvider.notifier).state = result.freshness;
      _page = nextPage;
      _hasMore = skills.length == discoverPageSize;
      state = AsyncData([...?state.valueOrNull, ...skills]);
    } finally {
      _loadingMore = false;
    }
  }

  bool get hasMore => _hasMore;
}

class ProfilesNotifier extends AutoDisposeAsyncNotifier<List<DiscoverProfileEntity>> {
  ProfilesNotifier(this.kind);

  final DiscoverProfileKind kind;

  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  final Set<String> _enrichingLogins = {};
  final Set<String> _enrichFailedLogins = {};

  @override
  Future<List<DiscoverProfileEntity>> build() async {
    final force = ref.watch(discoverRefreshTickProvider) > 0;
    _page = 1;
    _hasMore = true;
    _enrichingLogins.clear();
    _enrichFailedLogins.clear();
    final result = await ref.read(discoverRepositoryProvider).fetchProfiles(
          kind: kind,
          force: force,
          page: _page,
          perPage: discoverProfilesPageSize,
        );
    final list = result.data;
    _updateFreshness(result.freshness);
    _updateHasMore(list, page: _page);
    // Unawaited:补全在后台进行,不阻塞首屏。
    unawaited(_enrichNextBatch(list));
    return list;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || state.hasError) return;
    _loadingMore = true;
    try {
      final nextPage = _page + 1;
      final result = await ref.read(discoverRepositoryProvider).fetchProfiles(
            kind: kind,
            page: nextPage,
            perPage: discoverProfilesPageSize,
          );
      final next = result.data;
      _updateFreshness(result.freshness);
      _page = nextPage;
      final merged = [...?state.valueOrNull, ...next];
      state = AsyncData(merged);
      _updateHasMore(next, page: nextPage);
      unawaited(_enrichNextBatch(next));
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> enrichOne(String login) async {
    if (_enrichingLogins.contains(login) || _enrichFailedLogins.contains(login)) {
      return;
    }
    _enrichingLogins.add(login);
    try {
      final result = await ref.read(discoverRepositoryProvider).fetchProfileDetail(
            login: login,
            kind: kind,
          );
      final enriched = result.data;
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData([
        for (final p in current)
          if (p.login == login) enriched else p,
      ]);
    } catch (_) {
      _enrichFailedLogins.add(login);
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData([
        for (final p in current)
          if (p.login == login) p.copyWith(enrichFailed: true) else p,
      ]);
    } finally {
      _enrichingLogins.remove(login);
    }
  }

  Future<void> _enrichNextBatch(List<DiscoverProfileEntity> latest) async {
    if (_enrichingLogins.length > discoverProfileEnrichBatchSize * 2) return;
    final pending = latest.where((p) => !p.enriched && !p.enrichFailed).take(discoverProfileEnrichBatchSize).toList();
    // 串行窗口(并发度 4),无第三方依赖。
    for (var i = 0; i < pending.length; i += 4) {
      final window = pending.skip(i).take(4);
      await Future.wait([for (final p in window) enrichOne(p.login)]);
    }
  }

  bool get hasMore => _hasMore;

  void _updateHasMore(
    List<DiscoverProfileEntity> pageData, {
    required int page,
  }) {
    // page==1:whitelist 为 enriched、搜索结果为 !enriched,用 !enriched 计数。
    // page>=2:全部为 !enriched,直接用长度。
    final searchPart = page == 1 ? pageData.where((p) => !p.enriched).length : pageData.length;
    _hasMore = searchPart >= discoverProfilesPageSize;
  }

  void _updateFreshness(DataFreshness freshness) {
    final target = kind == DiscoverProfileKind.official ? discoverOfficialFreshnessProvider : discoverPeopleFreshnessProvider;
    ref.read(target.notifier).state = freshness;
  }
}

String _repoText(RepoEntity r) => '${r.fullName} ${r.description} ${r.language}'.toLowerCase();

String _skillText(SkillEntity s) => '${s.repo.fullName} ${s.repo.description} ${s.category} ${s.source}'.toLowerCase();

String _profileText(DiscoverProfileEntity p) => '${p.login} ${p.name} ${p.type} ${p.bio}'.toLowerCase();
