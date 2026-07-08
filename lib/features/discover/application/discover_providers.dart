import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/github/rate_limit_gate.dart';
import '../../../core/preferences/github_token_controller.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/discover_repository.dart';
import '../domain/discover_entities.dart';

/// 发现页数据仓库 Provider(复用 dio / 缓存 / token / 限流门控)。
final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  final token = ref.watch(githubTokenControllerProvider).token;
  final gate = ref.watch(rateLimitGateProvider);
  final gateController = ref.watch(rateLimitGateProvider.notifier);
  return DiscoverRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(jsonSnapshotCacheDaoProvider),
    token: token,
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

/// 流行仓库(实时 Top20),force 取决于刷新计数器。
final trendingReposProvider = FutureProvider<List<RepoEntity>>((ref) async {
  final force = ref.watch(discoverRefreshTickProvider) > 0;
  return ref.watch(discoverRepositoryProvider).fetchTrendingRepos(force: force);
});

/// Agent Skills 榜(实时),force 取决于刷新计数器。
final agentSkillsProvider = FutureProvider<List<SkillEntity>>((ref) async {
  final force = ref.watch(discoverRefreshTickProvider) > 0;
  return ref.watch(discoverRepositoryProvider).fetchAgentSkills(force: force);
});

/// 应用本地搜索后的流行仓库。
final filteredTrendingReposProvider =
    FutureProvider<List<RepoEntity>>((ref) async {
  final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
  final repos = await ref.watch(trendingReposProvider.future);
  if (query.isEmpty) return repos;
  return repos.where((r) => _repoText(r).contains(query)).toList();
});

/// 应用本地搜索后的 Agent Skills。
final filteredAgentSkillsProvider =
    FutureProvider<List<SkillEntity>>((ref) async {
  final query = ref.watch(discoverSearchQueryProvider).trim().toLowerCase();
  final skills = await ref.watch(agentSkillsProvider.future);
  if (query.isEmpty) return skills;
  return skills.where((s) => _skillText(s).contains(query)).toList();
});

String _repoText(RepoEntity r) =>
    '${r.fullName} ${r.description} ${r.language}'.toLowerCase();

String _skillText(SkillEntity s) =>
    '${s.repo.fullName} ${s.repo.description} ${s.category} ${s.source}'
        .toLowerCase();
