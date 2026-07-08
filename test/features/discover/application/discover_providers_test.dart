import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/features/discover/application/discover_providers.dart';
import 'package:github_news/features/discover/data/discover_repository.dart';
import 'package:github_news/features/discover/domain/discover_entities.dart';

class _FakeDiscoverRepository implements DiscoverRepository {
  final List<int> repoPages = [];
  final List<int> skillPages = [];
  final List<DiscoverProfileKind> profileKinds = [];

  @override
  Future<List<RepoEntity>> fetchTrendingRepos({
    bool force = false,
    int page = 1,
    int perPage = discoverPageSize,
  }) async {
    repoPages.add(page);
    return List.generate(
      perPage,
      (i) => _repo('popular-${page}_$i'),
    );
  }

  @override
  Future<List<SkillEntity>> fetchAgentSkills({
    bool force = false,
    int page = 1,
    int perPage = discoverPageSize,
  }) async {
    skillPages.add(page);
    final offset = (page - 1) * perPage;
    return [
      for (var i = 0; i < perPage; i++)
        SkillEntity(
          repo: _repo('skill-${page}_$i'),
          category: 'agent',
          source: 'test',
          rank: offset + i + 1,
        ),
    ];
  }

  @override
  Future<List<DiscoverProfileEntity>> fetchProfiles({
    required DiscoverProfileKind kind,
    bool force = false,
  }) async {
    profileKinds.add(kind);
    return [
      DiscoverProfileEntity(
        login: kind == DiscoverProfileKind.official ? 'openai' : 'karpathy',
        name: kind == DiscoverProfileKind.official ? 'OpenAI' : 'Andrej',
        type: kind == DiscoverProfileKind.official ? 'Organization' : 'User',
        bio: kind == DiscoverProfileKind.official
            ? 'Official AI research organization'
            : 'AI researcher and educator',
        publicRepos: 42,
        followers: 1000,
        avatarUrl: 'https://example.com/avatar.png',
        htmlUrl: 'https://github.com/example',
        kind: kind,
      ),
    ];
  }
}

RepoEntity _repo(String suffix) => RepoEntity(
      fullName: 'example/$suffix',
      description: 'AI agent repo $suffix',
      language: 'Dart',
      starCount: 1000,
      starDelta: 10,
      forkCount: 20,
      accentArgb: 0xFF00A389,
    );

void main() {
  test('流行仓库触底加载下一页并追加列表', () async {
    final repo = _FakeDiscoverRepository();
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final firstPage =
        await container.read(trendingReposNotifierProvider.future);
    expect(firstPage.length, discoverPageSize);
    expect(repo.repoPages, [1]);

    await container.read(trendingReposNotifierProvider.notifier).loadMore();

    final combined = container.read(trendingReposNotifierProvider).valueOrNull;
    expect(combined, hasLength(discoverPageSize * 2));
    expect(repo.repoPages, [1, 2]);
  });

  test('Agent Skills 触底加载时保留连续排名', () async {
    final repo = _FakeDiscoverRepository();
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(agentSkillsNotifierProvider.future);
    await container.read(agentSkillsNotifierProvider.notifier).loadMore();

    final skills = container.read(agentSkillsNotifierProvider).valueOrNull!;
    expect(skills.map((s) => s.rank).take(3), [1, 2, 3]);
    expect(skills.last.rank, discoverPageSize * 2);
    expect(repo.skillPages, [1, 2]);
  });

  test('官方组织和知名人士进入发现页搜索池', () async {
    final repo = _FakeDiscoverRepository();
    final container = ProviderContainer(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    container.read(discoverSearchQueryProvider.notifier).state = 'openai';
    final official =
        await container.read(filteredOfficialProfilesProvider.future);
    expect(official.single.login, 'openai');

    container.read(discoverSearchQueryProvider.notifier).state = 'researcher';
    final people = await container.read(filteredPeopleProfilesProvider.future);
    expect(people.single.login, 'karpathy');
  });
}
