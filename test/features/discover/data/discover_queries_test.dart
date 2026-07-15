import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/discover/data/discover_queries.dart';
import 'package:github_news/features/discover/domain/discover_entities.dart';

void main() {
  test('skills query 包含放宽后的 topic 与 stars 门槛', () {
    expect(DiscoverQueries.skills, contains('topic:ai-agent'));
    expect(DiscoverQueries.skills, contains('topic:llm-agent'));
    expect(DiscoverQueries.skills, contains('topic:mcp-server'));
    expect(DiscoverQueries.skills, contains('stars:>10'));
  });

  test('officialSearchQuery 使用 type:org + ai 关键词', () {
    expect(DiscoverQueries.officialSearchQuery, contains('type:org'));
    expect(DiscoverQueries.officialSearchQuery, contains('followers:>5000'));
    expect(DiscoverQueries.officialSearchQuery, contains('ai in:name,bio'));
  });

  test('peopleSearchQuery 使用 type:user + ai 关键词', () {
    expect(DiscoverQueries.peopleSearchQuery, contains('type:user'));
    expect(DiscoverQueries.peopleSearchQuery, contains('followers:>1000'));
    expect(DiscoverQueries.peopleSearchQuery, contains('ai in:bio'));
  });

  test('profilesPageKey 按 kind 与分页维度生成', () {
    final key = DiscoverQueries.profilesPageKey(DiscoverProfileKind.official, 2, 20);
    expect(key, 'discover_profiles:official:p2:n20');
  });

  test('白名单 login 列表保持不变(置顶用)', () {
    expect(DiscoverQueries.officialLogins, contains('openai'));
    expect(DiscoverQueries.officialLogins.length, greaterThanOrEqualTo(8));
    expect(DiscoverQueries.peopleLogins, contains('karpathy'));
    expect(DiscoverQueries.peopleLogins.length, greaterThanOrEqualTo(8));
  });
}
