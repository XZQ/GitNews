import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repo_entity.dart';
import '../domain/discover_entities.dart';
import 'discover_providers.dart';

class TrendingReposNotifier extends AutoDisposeAsyncNotifier<List<RepoEntity>> {
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  Future<List<RepoEntity>> build() async {
    final force = ref.watch(discoverRefreshTickProvider) > 0;
    _page = 1;
    final result = await ref.read(discoverRepositoryProvider).fetchTrendingRepos(force: force, page: _page, perPage: discoverPageSize);
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
      final result = await ref.read(discoverRepositoryProvider).fetchTrendingRepos(page: nextPage, perPage: discoverPageSize);
      final repos = result.data;
      ref.read(discoverReposFreshnessProvider.notifier).state = result.freshness;
      _page = nextPage;
      _hasMore = repos.length == discoverPageSize;
      state = AsyncData([...?state.valueOrNull, ...repos]);
    } catch (error, stack) {
      state = AsyncError(error, stack);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final result = await ref.read(discoverRepositoryProvider).fetchTrendingRepos(force: true, page: 1, perPage: discoverPageSize);
      _page = 1;
      _hasMore = result.data.length == discoverPageSize;
      ref.read(discoverReposFreshnessProvider.notifier).state = result.freshness;
      state = AsyncData(result.data);
    } catch (error, stack) {
      state = previous == null ? AsyncError(error, stack) : AsyncData(previous);
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
    final result = await ref.read(discoverRepositoryProvider).fetchAgentSkills(force: force, page: _page, perPage: discoverPageSize);
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
      final result = await ref.read(discoverRepositoryProvider).fetchAgentSkills(page: nextPage, perPage: discoverPageSize);
      final skills = result.data;
      ref.read(discoverSkillsFreshnessProvider.notifier).state = result.freshness;
      _page = nextPage;
      _hasMore = skills.length == discoverPageSize;
      state = AsyncData([...?state.valueOrNull, ...skills]);
    } catch (error, stack) {
      state = AsyncError(error, stack);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final result = await ref.read(discoverRepositoryProvider).fetchAgentSkills(force: true, page: 1, perPage: discoverPageSize);
      _page = 1;
      _hasMore = result.data.length == discoverPageSize;
      ref.read(discoverSkillsFreshnessProvider.notifier).state = result.freshness;
      state = AsyncData(result.data);
    } catch (error, stack) {
      state = previous == null ? AsyncError(error, stack) : AsyncData(previous);
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
      final result = await ref.read(discoverRepositoryProvider).fetchProfiles(kind: kind, page: nextPage, perPage: discoverProfilesPageSize);
      final next = result.data;
      _updateFreshness(result.freshness);
      _page = nextPage;
      final merged = [...?state.valueOrNull, ...next];
      state = AsyncData(merged);
      _updateHasMore(next, page: nextPage);
      unawaited(_enrichNextBatch(next));
    } catch (error, stack) {
      state = AsyncError(error, stack);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final result = await ref.read(discoverRepositoryProvider).fetchProfiles(
            kind: kind,
            force: true,
            page: 1,
            perPage: discoverProfilesPageSize,
          );
      _page = 1;
      _enrichingLogins.clear();
      _enrichFailedLogins.clear();
      _updateFreshness(result.freshness);
      _updateHasMore(result.data, page: 1);
      state = AsyncData(result.data);
      unawaited(_enrichNextBatch(result.data));
    } catch (error, stack) {
      state = previous == null ? AsyncError(error, stack) : AsyncData(previous);
    }
  }

  Future<void> enrichOne(String login) async {
    if (_enrichingLogins.contains(login) || _enrichFailedLogins.contains(login)) {
      return;
    }
    _enrichingLogins.add(login);
    try {
      final result = await ref.read(discoverRepositoryProvider).fetchProfileDetail(login: login, kind: kind);
      final enriched = result.data;
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData(
        [
          for (final p in current)
            if (p.login == login) enriched else p
        ],
      );
    } catch (_) {
      _enrichFailedLogins.add(login);
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData(
        [
          for (final p in current)
            if (p.login == login) p.copyWith(enrichFailed: true) else p
        ],
      );
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

  void _updateHasMore(List<DiscoverProfileEntity> pageData, {required int page}) {
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
