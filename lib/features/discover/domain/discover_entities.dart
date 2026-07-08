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
    required this.kind,
  });

  final String login;
  final String name;
  final String type;
  final String bio;
  final int publicRepos;
  final int followers;
  final String avatarUrl;
  final String htmlUrl;
  final DiscoverProfileKind kind;
}
