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
