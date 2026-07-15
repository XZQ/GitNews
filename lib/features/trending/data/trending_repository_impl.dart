import '../../../core/domain/data_freshness.dart';
import '../domain/trending_repository.dart';
import 'trending_data_source.dart';

/* 
*趋势仓库默认实现。
*这里是数据源和 UI digest 的边界,后续接 GitHub Search / GraphQL 时只需要
*替换 [TrendingDataSource],页面与其它 feature 不需要感知。
*/
class TrendingRepositoryImpl implements TrendingRepository {
  const TrendingRepositoryImpl({required this.dataSource, this.fallbackFreshness = DataFreshness.seed});

  final TrendingDataSource dataSource;
  final DataFreshness fallbackFreshness;

  @override
  Future<DataResult<TrendingDigest>> getDigest({TrendingQuery query = const TrendingQuery()}) async {
    final result = dataSource is FreshnessTrendingDataSource
        ? await (dataSource as FreshnessTrendingDataSource).fetchTrendingResult(query)
        : DataResult(data: await dataSource.fetchTrending(query), freshness: fallbackFreshness);
    return result.map(
      (snapshot) => TrendingDigest(
        trendingRepos: snapshot.trendingRepos,
        recentRepos: snapshot.recentRepos,
        languages: snapshot.languages,
        primaryTrend: snapshot.primaryTrend,
        secondaryTrend: snapshot.secondaryTrend,
        tertiaryTrend: snapshot.tertiaryTrend,
      ),
    );
  }
}
