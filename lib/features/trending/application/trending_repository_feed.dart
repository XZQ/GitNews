import '../../../core/domain/data_freshness.dart';
import '../../../core/domain/repository_feed.dart';
import '../domain/trending_repository.dart';

class TrendingRepositoryFeed implements RepositoryFeed {
  const TrendingRepositoryFeed(this._repository);

  final TrendingRepository _repository;

  @override
  Future<DataResult<RepositoryFeedDigest>> load() async {
    final result = await _repository.getDigest();
    return result.map((digest) => RepositoryFeedDigest(repos: digest.allRepos, primaryTrend: digest.primaryTrend, secondaryTrend: digest.secondaryTrend));
  }
}
