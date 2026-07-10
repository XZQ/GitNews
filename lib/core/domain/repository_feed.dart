import 'data_freshness.dart';
import 'repo_entity.dart';

class RepositoryFeedDigest {
  const RepositoryFeedDigest({
    required this.repos,
    required this.primaryTrend,
    required this.secondaryTrend,
  });

  final List<RepoEntity> repos;
  final List<double> primaryTrend;
  final List<double> secondaryTrend;
}

abstract interface class RepositoryFeed {
  Future<DataResult<RepositoryFeedDigest>> load();
}
