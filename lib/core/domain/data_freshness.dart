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
