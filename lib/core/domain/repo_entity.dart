import 'data_provenance.dart';

/// 仓库情报实体(纯 Dart 业务实体)。
///
/// 数据来源不限于 GitHub REST:本地模拟 / GitHub API / GraphQL 都会归一化到此形状。
/// `accent` 用 32-bit ARGB int,展示层用 `Color(repo.accentArgb)` 还原,
/// 保证 domain 层零 Flutter / 零 IO 依赖(CLAUDE.md §一)。
///
/// 之所以放在 `core/domain/` 而非 `features/trending/domain/`:
/// 该实体被 monitor / repo_detail / project / profile / shared 共享,
/// 已经事实上成为跨 feature 的"通用仓库语义",留在某个 feature 内会
/// 形成反向依赖。
class RepoEntity {
  const RepoEntity({
    required this.fullName,
    required this.description,
    required this.language,
    required this.starCount,
    required this.starDelta,
    required this.forkCount,
    required this.accentArgb,
    this.valueProvenance = DataProvenance.localFallback,
    this.trendProvenance = DataProvenance.localFallback,
    this.trend,
  });

  /// `owner/name` 形式。
  final String fullName;
  final String description;
  final String language;
  final int starCount;

  /// 今日/本周新增 Star。
  final int starDelta;
  final int forkCount;

  /// 32-bit ARGB。展示层用 `Color(repo.accentArgb)` 还原。
  final int accentArgb;

  /// Star/Fork/语言等当前快照字段的数据口径。
  final DataProvenance valueProvenance;

  /// `starDelta` 与 `trend` 曲线的数据口径。
  final DataProvenance trendProvenance;

  final List<double>? trend;

  RepoEntity copyWith({
    String? fullName,
    String? description,
    String? language,
    int? starCount,
    int? starDelta,
    int? forkCount,
    int? accentArgb,
    DataProvenance? valueProvenance,
    DataProvenance? trendProvenance,
    List<double>? trend,
  }) {
    return RepoEntity(
      fullName: fullName ?? this.fullName,
      description: description ?? this.description,
      language: language ?? this.language,
      starCount: starCount ?? this.starCount,
      starDelta: starDelta ?? this.starDelta,
      forkCount: forkCount ?? this.forkCount,
      accentArgb: accentArgb ?? this.accentArgb,
      valueProvenance: valueProvenance ?? this.valueProvenance,
      trendProvenance: trendProvenance ?? this.trendProvenance,
      trend: trend ?? this.trend,
    );
  }
}

/// 编程语言占比实体。
class LanguageEntity {
  const LanguageEntity({
    required this.name,
    required this.percent,
    required this.delta,
    required this.accentArgb,
    this.provenance = DataProvenance.localFallback,
  });

  final String name;
  final double percent;
  final double delta;
  final int accentArgb;
  final DataProvenance provenance;
}
