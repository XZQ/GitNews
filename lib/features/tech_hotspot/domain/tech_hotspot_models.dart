/// 技术热点领域模型(纯 Dart)。
library;

/// 技术栈分类:用于 [TechHotspotPage] 的左侧分类。
enum TechStack {
  all,
  ai,
  frontend,
  backend,
  cloud,
  data,
  mobile,
  rust,
  security,
}

/// 编程语言排行条目。
class LanguageStat {
  const LanguageStat({
    required this.name,
    required this.percent,
    required this.delta,
    required this.color,
    required this.repoCount,
  });

  final String name;
  final double percent;
  final double delta;
  final int color;
  final int repoCount;
}

/// 技术主题(雷达型卡片)。
class TechTopic {
  const TechTopic({
    required this.id,
    required this.name,
    required this.category,
    required this.heat,
    required this.growth,
    required this.mentions,
    required this.relatedRepos,
    required this.summary,
  });

  final String id;
  final String name;
  final String category;

  /// 热度分(0-100)。
  final int heat;

  /// 周环比(%)。
  final double growth;

  /// 相关讨论条数。
  final int mentions;

  /// 相关仓库数。
  final int relatedRepos;
  final String summary;
}

/// 技术热点时间序列(用于趋势小图)。
class TechHeatPoint {
  const TechHeatPoint({required this.label, required this.value});

  final String label;
  final double value;
}
