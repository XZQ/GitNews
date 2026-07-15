import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/features/discover/application/discover_providers.dart';
import 'package:github_news/features/discover/data/discover_repository.dart';
import 'package:github_news/features/discover/domain/discover_entities.dart';
import 'package:github_news/features/discover/presentation/discover_navigation.dart';

class _FakeDiscoverRepository implements DiscoverRepository {
  final List<int> repoPages = [];
  final List<int> skillPages = [];
  final List<DiscoverProfileKind> profileKinds = [];

  @override
  Future<DataResult<List<RepoEntity>>> fetchTrendingRepos({bool force = false, int page = 1, int perPage = discoverPageSize}) async {
    repoPages.add(page);
    return DataResult(freshness: DataFreshness.live, data: List.generate(perPage, (i) => _repo('popular-${page}_$i')));
  }

  @override
  Future<DataResult<List<SkillEntity>>> fetchAgentSkills({bool force = false, int page = 1, int perPage = discoverPageSize}) async {
    skillPages.add(page);
    final offset = (page - 1) * perPage;
    return DataResult(freshness: DataFreshness.live, data: [
      for (var i = 0; i < perPage; i++)
        SkillEntity(
          repo: _repo('skill-${page}_$i'),
          category: 'agent',
          source: 'test',
          rank: offset + i + 1,
        )
    ]);
  }

  @override
  Future<DataResult<List<DiscoverProfileEntity>>> fetchProfiles({
    required DiscoverProfileKind kind,
    bool force = false,
    int page = 1,
    int perPage = 20,
  }) async {
    profileKinds.add(kind);
    return DataResult(
      freshness: DataFreshness.live,
      data: [
        DiscoverProfileEntity(
          login: kind == DiscoverProfileKind.official ? 'openai' : 'karpathy',
          name: kind == DiscoverProfileKind.official ? 'OpenAI' : 'Andrej',
          type: kind == DiscoverProfileKind.official ? 'Organization' : 'User',
          bio: kind == DiscoverProfileKind.official ? 'Official AI research organization' : 'AI researcher and educator',
          publicRepos: 42,
          followers: 1000,
          avatarUrl: 'https://example.com/avatar.png',
          htmlUrl: 'https://github.com/example',
          featuredRepoFullName: kind == DiscoverProfileKind.official ? 'openai/openai-agents-python' : 'karpathy/nanoGPT',
          kind: kind,
        )
      ],
    );
  }

  @override
  Future<DataResult<DiscoverProfileEntity>> fetchProfileDetail({required String login, required DiscoverProfileKind kind}) async {
    return DataResult(
      freshness: DataFreshness.live,
      data: DiscoverProfileEntity(
        login: login,
        name: login,
        type: kind == DiscoverProfileKind.official ? 'Organization' : 'User',
        bio: '',
        publicRepos: 0,
        followers: 0,
        avatarUrl: '',
        htmlUrl: 'https://github.com/$login',
        featuredRepoFullName: '$login/$login',
        kind: kind,
      ),
    );
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
    final container = ProviderContainer(overrides: [discoverRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final firstPage = await container.read(trendingReposNotifierProvider.future);
    expect(firstPage.length, discoverPageSize);
    expect(container.read(discoverReposFreshnessProvider), DataFreshness.live);
    expect(repo.repoPages, [1]);

    await container.read(trendingReposNotifierProvider.notifier).loadMore();

    final combined = container.read(trendingReposNotifierProvider).valueOrNull;
    expect(combined, hasLength(discoverPageSize * 2));
    expect(repo.repoPages, [1, 2]);
  });

  test('Agent Skills 触底加载时保留连续排名', () async {
    final repo = _FakeDiscoverRepository();
    final container = ProviderContainer(overrides: [discoverRepositoryProvider.overrideWithValue(repo)]);
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
    final container = ProviderContainer(overrides: [discoverRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    container.read(discoverSearchQueryProvider.notifier).state = 'openai';
    final official = await container.read(filteredOfficialProfilesProvider.future);
    expect(official.single.login, 'openai');

    container.read(discoverSearchQueryProvider.notifier).state = 'researcher';
    final people = await container.read(filteredPeopleProfilesProvider.future);
    expect(people.single.login, 'karpathy');
  });

  test('官方账号和知名人士点击后进入仓库详情页', () {
    const official = DiscoverProfileEntity(
      login: 'openai',
      name: 'OpenAI',
      type: 'Organization',
      bio: 'Official AI research organization',
      publicRepos: 42,
      followers: 1000,
      avatarUrl: 'https://example.com/openai.png',
      htmlUrl: 'https://github.com/openai',
      featuredRepoFullName: 'openai/openai-agents-python',
      kind: DiscoverProfileKind.official,
    );
    const person = DiscoverProfileEntity(
      login: 'karpathy',
      name: 'Andrej Karpathy',
      type: 'User',
      bio: 'AI researcher and educator',
      publicRepos: 42,
      followers: 1000,
      avatarUrl: 'https://example.com/karpathy.png',
      htmlUrl: 'https://github.com/karpathy',
      featuredRepoFullName: 'karpathy/nanoGPT',
      kind: DiscoverProfileKind.people,
    );

    expect(discoverProfileDetailLocation(official), '/discover/detail/openai%2Fopenai-agents-python');
    expect(discoverProfileDetailLocation(person), '/discover/detail/karpathy%2FnanoGPT');
    expect(discoverProfileDetailLocation(official), isNot(contains('/webview')));
  });
}
