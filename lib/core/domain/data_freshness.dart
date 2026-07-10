enum DataFreshness {
  live,
  freshCache,
  staleCache,
  seed;

  static DataFreshness fromName(String? name) {
    return DataFreshness.values.firstWhere(
      (value) => value.name == name,
      orElse: () => DataFreshness.seed,
    );
  }
}

enum MetricBasis {
  observed,
  estimated,
  seed;

  static MetricBasis fromName(String? name) {
    return MetricBasis.values.firstWhere(
      (value) => value.name == name,
      orElse: () => MetricBasis.seed,
    );
  }
}

class DataResult<T> {
  const DataResult({required this.data, required this.freshness});

  final T data;
  final DataFreshness freshness;

  DataResult<R> map<R>(R Function(T value) convert) {
    return DataResult<R>(
      data: convert(data),
      freshness: freshness,
    );
  }
}
