import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/features/discover/application/discover_providers.dart';
import 'package:github_news/features/discover/data/discover_repository.dart';
import 'package:github_news/features/discover/domain/discover_entities.dart';

class _FakeRepo implements DiscoverRepository {
  _FakeRepo({this.searchPageSize = 20});

  static const int whitelistSize = 8;
  final int searchPageSize;
  final Map<String, DiscoverProfileEntity> _detail = {};

  @override
  Future<DataResult<List<DiscoverProfileEntity>>> fetchProfiles({required DiscoverProfileKind kind, bool force = false, int page = 1, int perPage = 20}) async {
    final List<DiscoverProfileEntity> data;
    if (page == 1) {
      final whitelist = [
        for (var i = 0; i < whitelistSize; i++)
          DiscoverProfileEntity(
            login: 'wl-$i',
            name: 'WL $i',
            type: 'User',
            bio: 'bio',
            publicRepos: 1,
            followers: 1,
            avatarUrl: '',
            htmlUrl: '',
            featuredRepoFullName: 'wl-$i/repo',
            kind: kind,
            enriched: true,
          ),
      ];
      final search = [
        for (var i = 0; i < searchPageSize; i++)
          DiscoverProfileEntity(
            login: 'search-${page}_$i',
            name: 'search-${page}_$i',
            type: 'User',
            bio: '',
            publicRepos: 0,
            followers: 0,
            avatarUrl: '',
            htmlUrl: '',
            featuredRepoFullName: 'search-${page}_$i/repo',
            kind: kind,
            enriched: false,
          ),
      ];
      data = [...whitelist, ...search];
    } else {
      data = [
        for (var i = 0; i < searchPageSize; i++)
          DiscoverProfileEntity(
            login: 'search-${page}_$i',
            name: 'search-${page}_$i',
            type: 'User',
            bio: '',
            publicRepos: 0,
            followers: 0,
            avatarUrl: '',
            htmlUrl: '',
            featuredRepoFullName: 'search-${page}_$i/repo',
            kind: kind,
            enriched: false,
          ),
      ];
    }
    return DataResult(data: data, freshness: DataFreshness.live);
  }

  @override
  Future<DataResult<DiscoverProfileEntity>> fetchProfileDetail({required String login, required DiscoverProfileKind kind}) async {
    final e = _detail.putIfAbsent(
      login,
      () => DiscoverProfileEntity(
        login: login,
        name: login,
        type: 'User',
        bio: 'enriched-bio',
        publicRepos: 42,
        followers: 100,
        avatarUrl: '',
        htmlUrl: '',
        featuredRepoFullName: '$login/repo',
        kind: kind,
        enriched: true,
      ),
    );
    return DataResult(data: e, freshness: DataFreshness.live);
  }

  @override
  Future<DataResult<List<RepoEntity>>> fetchTrendingRepos({bool force = false, int page = 1, int perPage = discoverPageSize}) async {
    throw UnimplementedError();
  }

  @override
  Future<DataResult<List<SkillEntity>>> fetchAgentSkills({bool force = false, int page = 1, int perPage = discoverPageSize}) async {
    throw UnimplementedError();
  }
}

void main() {
  test('build 后白名单 enriched、搜索结果占位,hasMore=true', () async {
    final repo = _FakeRepo();
    final container = ProviderContainer(overrides: [discoverRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(officialProfilesNotifierProvider, (previous, next) {});
    addTearDown(sub.close);

    final first = await container.read(officialProfilesNotifierProvider.future);
    expect(first.length, 8 + 20);
    expect(first.take(8).every((p) => p.enriched), isTrue);
    expect(first.skip(8).every((p) => !p.enriched), isTrue);
    expect(container.read(officialProfilesNotifierProvider.notifier).hasMore, isTrue);
  });

  test('loadMore 追加搜索结果', () async {
    final repo = _FakeRepo(searchPageSize: 20);
    final container = ProviderContainer(overrides: [discoverRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(officialProfilesNotifierProvider, (previous, next) {});
    addTearDown(sub.close);

    await container.read(officialProfilesNotifierProvider.future);
    await container.read(officialProfilesNotifierProvider.notifier).loadMore();

    final list = container.read(officialProfilesNotifierProvider).value!;
    expect(list.length, 8 + 20 + 20);
  });

  test('enrichOne 把占位 entity 替换为 enriched', () async {
    final repo = _FakeRepo();
    final container = ProviderContainer(overrides: [discoverRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(officialProfilesNotifierProvider, (previous, next) {});
    addTearDown(sub.close);

    await container.read(officialProfilesNotifierProvider.future);
    await container.read(officialProfilesNotifierProvider.notifier).enrichOne('search-1_0');

    final list = container.read(officialProfilesNotifierProvider).value!;
    final target = list.firstWhere((p) => p.login == 'search-1_0');
    expect(target.enriched, isTrue);
    expect(target.bio, 'enriched-bio');
  });
}
