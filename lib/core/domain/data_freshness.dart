enum DataFreshness {
  live,
  // 主体来自远端实时结果,但其中一部分条目拉取失败,不能整体宣称实时。
  partial,
  freshCache,
  staleCache,
  seed;

  static DataFreshness fromName(String? name) {
    return DataFreshness.values.firstWhere((value) => value.name == name, orElse: () => DataFreshness.seed);
  }

  /// 多来源聚合时该档位扮演的角色。
  ///
  /// 用穷举 switch 而不是散落的 `contains` 判断:新增枚举成员时编译器会强制
  /// 在这里补齐,避免新档位在聚合时被静默降级成最差档。
  FreshnessRole get role => switch (this) {
    DataFreshness.live => FreshnessRole.live,
    DataFreshness.partial => FreshnessRole.partial,
    DataFreshness.freshCache => FreshnessRole.cached,
    DataFreshness.staleCache => FreshnessRole.stale,
    DataFreshness.seed => FreshnessRole.seed,
  };
}

/*
 *多来源聚合时单个来源的角色。
 *
 *聚合规则是「保守取严」:任何一个来源不完整,整体就不能宣称更完整的新鲜度。
 *角色把这条规则拆成两个维度,每个维度都用穷举 switch 表达,新增
 *`DataFreshness` 成员时编译器会强制逐个补齐。
 */
enum FreshnessRole {
  /// 实时且完整。
  live,

  /// 完整但来自缓存,不宣称实时。
  cached,

  /// 主体实时但有条目缺失。
  partial,

  /// 整体来自陈旧数据。
  stale,

  /// 种子/占位数据。
  seed;

  /// 该角色是否构成否决:出现即让整体降级,不允许被其它来源掩盖。
  bool get vetoes => switch (this) {
    FreshnessRole.live => false,
    FreshnessRole.cached => false,
    FreshnessRole.partial => true,
    FreshnessRole.stale => true,
    FreshnessRole.seed => true,
  };

  /// 否决的严重度:数值越大越严重,取所有否决中最严重的一个。
  int get vetoSeverity => switch (this) {
    FreshnessRole.live => 0,
    FreshnessRole.cached => 0,
    FreshnessRole.partial => 1,
    FreshnessRole.stale => 2,
    FreshnessRole.seed => 2,
  };

  /// 否决时整体降级到的档位。
  DataFreshness get vetoLevel => switch (this) {
    FreshnessRole.live => DataFreshness.live,
    FreshnessRole.cached => DataFreshness.freshCache,
    FreshnessRole.partial => DataFreshness.partial,
    FreshnessRole.stale => DataFreshness.staleCache,
    // seed 与其它来源共存时降级为陈旧:此时页面里混着占位数据,不能宣称有实况。
    FreshnessRole.seed => DataFreshness.staleCache,
  };
}

/// 把多个来源的新鲜度合并成一个整体档位。
///
/// 合并是保守的:整体档位不会比其中任何一个来源更「完整」。
/// - 全部是种子数据 → `seed`;
/// - 任一来源陈旧或缺条目 → 降到对应的否决档位(陈旧优先于缺条目);
/// - 其余情况有实时来源 → `live`,全是缓存 → `freshCache`。
///
/// 空集合返回 `seed`:没有任何来源就没有任何实况。
DataFreshness combineFreshness(Iterable<DataFreshness> values) {
  final roles = values.map((value) => value.role).toList();
  if (roles.isEmpty) {
    return DataFreshness.seed;
  }
  if (roles.every((role) => role == FreshnessRole.seed)) {
    return DataFreshness.seed;
  }
  final vetoes = roles.where((role) => role.vetoes).toList();
  if (vetoes.isNotEmpty) {
    final worst = vetoes.reduce((a, b) => a.vetoSeverity >= b.vetoSeverity ? a : b);
    return worst.vetoLevel;
  }
  // 无否决时,实时来源优先于缓存来源(与既有聚合行为一致)。
  return roles.any((role) => role == FreshnessRole.live) ? DataFreshness.live : DataFreshness.freshCache;
}

enum MetricBasis {
  observed,
  estimated,
  unavailable,
  seed;

  static MetricBasis fromName(String? name) {
    return MetricBasis.values.firstWhere((value) => value.name == name, orElse: () => MetricBasis.seed);
  }

  static MetricBasis fromLegacyName(String? name) {
    return switch (name) {
      'live' || 'freshCache' || 'staleCache' || 'partial' || 'observed' => MetricBasis.observed,
      'estimated' => MetricBasis.estimated,
      _ => MetricBasis.seed,
    };
  }

  String get labelKey => switch (this) {
    MetricBasis.observed => 'basis.observed.full',
    MetricBasis.estimated => 'provenance.estimated.full',
    MetricBasis.unavailable => 'growth.pending',
    MetricBasis.seed => 'provenance.seed.full',
  };
}

class DataResult<T> {
  const DataResult({required this.data, required this.freshness, this.validatedAt, this.revalidated = false});

  final T data;
  final DataFreshness freshness;

  /// Last successful remote validation; a cache read must not advance this time.
  final DateTime? validatedAt;

  /// True only when this operation successfully checked the remote resource.
  final bool revalidated;

  DataResult<R> map<R>(R Function(T value) convert) {
    return DataResult<R>(data: convert(data), freshness: freshness, validatedAt: validatedAt, revalidated: revalidated);
  }
}
