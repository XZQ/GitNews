import '../../../core/domain/repo_entity.dart';

/// AI Agent Skills 仓库的展示实体。
/// 复用 [RepoEntity] 承载仓库基础信息,附加 skills 生态元数据。
class SkillEntity {
  const SkillEntity({
    required this.repo,
    required this.category,
    required this.source,
    required this.rank,
    this.summary,
  });

  final RepoEntity repo;

  /// 分类,如 claude / cursor / copilot / other。
  final String category;

  /// 数据来源,如 agent-skills.cc / github leaderboard / search。
  final String source;

  /// 排行榜名次(1 起)。
  final int rank;

  final String? summary;
}

enum DiscoverProfileKind { official, people }

/// 发现页 GitHub 账号实体:用于官方组织与知名开发者推荐。
class DiscoverProfileEntity {
  const DiscoverProfileEntity({
    required this.login,
    required this.name,
    required this.type,
    required this.bio,
    required this.publicRepos,
    required this.followers,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.featuredRepoFullName,
    required this.kind,
    this.enriched = true,
    this.enrichFailed = false,
  });

  final String login;
  final String name;
  final String type;
  final String bio;
  final int publicRepos;
  final int followers;
  final String avatarUrl;
  final String htmlUrl;
  final String featuredRepoFullName;
  final DiscoverProfileKind kind;

  /// 是否已通过 /users/{login} 补全完整字段。
  /// `/search/users` 返回的占位 entity 此字段为 false。
  final bool enriched;

  /// 补全失败标记,避免无限重试。
  final bool enrichFailed;

  DiscoverProfileEntity copyWith({
    String? bio,
    int? publicRepos,
    int? followers,
    String? name,
    String? type,
    String? avatarUrl,
    String? htmlUrl,
    String? featuredRepoFullName,
    bool? enriched,
    bool? enrichFailed,
  }) =>
      DiscoverProfileEntity(
        login: login,
        name: name ?? this.name,
        type: type ?? this.type,
        bio: bio ?? this.bio,
        publicRepos: publicRepos ?? this.publicRepos,
        followers: followers ?? this.followers,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        htmlUrl: htmlUrl ?? this.htmlUrl,
        featuredRepoFullName: featuredRepoFullName ?? this.featuredRepoFullName,
        kind: kind,
        enriched: enriched ?? this.enriched,
        enrichFailed: enrichFailed ?? this.enrichFailed,
      );
}
