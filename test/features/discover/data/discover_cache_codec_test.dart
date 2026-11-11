import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/discover/data/discover_cache_codec.dart';
import 'package:github_news/features/discover/domain/discover_entities.dart';

void main() {
  group('profile 缓存编解码', () {
    test('往返保留未补全状态,分页计数与补全队列依赖该标记', () {
      const placeholder = DiscoverProfileEntity(
        login: 'some-org',
        name: 'some-org',
        type: 'Organization',
        bio: '',
        publicRepos: 0,
        followers: 0,
        avatarUrl: '',
        htmlUrl: 'https://github.com/some-org',
        featuredRepoFullName: 'some-org/some-org',
        kind: DiscoverProfileKind.official,
        enriched: false,
        enrichFailed: true,
      );

      final decoded = DiscoverCacheCodec.decodeProfiles(DiscoverCacheCodec.profilesToJson([placeholder]), DiscoverProfileKind.official);

      expect(decoded.single.enriched, isFalse);
      expect(decoded.single.enrichFailed, isTrue);
      expect(decoded.single.followers, 0);
    });

    test('远端 /users 响应无 enriched 字段时默认已补全', () {
      final decoded = DiscoverCacheCodec.profileFromJson({
        'login': 'karpathy',
        'name': 'Andrej Karpathy',
        'type': 'User',
        'bio': 'researcher',
        'public_repos': 60,
        'followers': 200000,
        'avatar_url': '',
        'html_url': '',
      }, DiscoverProfileKind.people);

      expect(decoded.enriched, isTrue);
      expect(decoded.enrichFailed, isFalse);
    });

    test('损坏的非 bool 标记按远端默认处理,不抛异常', () {
      final decoded = DiscoverCacheCodec.profileFromJson({'login': 'x', 'public_repos': 0, 'followers': 0, 'enriched': 'yes', 'enrichFailed': 1}, DiscoverProfileKind.people);

      expect(decoded.enriched, isTrue);
      expect(decoded.enrichFailed, isFalse);
    });
  });
}
