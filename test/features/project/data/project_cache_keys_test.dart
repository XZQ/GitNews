import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/project/data/project_cache_keys.dart';

void main() {
  test('contributors cache key is independent of repository order', () {
    expect(projectContributorsCacheKey(repos: ['b/two', 'a/one'], cacheScope: 'anonymous'), projectContributorsCacheKey(repos: ['a/one', 'b/two'], cacheScope: 'anonymous'));
  });

  test('contributors cache key changes with repositories and token scope', () {
    final anonymous = projectContributorsCacheKey(repos: ['a/one'], cacheScope: 'anonymous');

    expect(anonymous, isNot(projectContributorsCacheKey(repos: ['b/two'], cacheScope: 'anonymous')));
    expect(anonymous, isNot(projectContributorsCacheKey(repos: ['a/one'], cacheScope: 'token_abcd')));
    expect(anonymous, startsWith('project:github:contributors:v2:'));
  });

  test('activities cache key is ordered, scoped, and independent', () {
    final first = projectActivitiesCacheKey(repos: ['b/two', 'a/one'], cacheScope: 'anonymous');

    expect(first, projectActivitiesCacheKey(repos: ['a/one', 'b/two'], cacheScope: 'anonymous'));
    expect(first, isNot(projectActivitiesCacheKey(repos: ['a/one', 'b/two'], cacheScope: 'token_abcd')));
    expect(first, startsWith('project:github:activities:v1:'));
  });
}
