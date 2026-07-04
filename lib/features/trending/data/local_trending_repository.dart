import '../domain/trending_repository.dart';
import 'local_trending_data_source.dart';
import 'trending_repository_impl.dart';

/// 基于本地模拟数据的趋势仓库。
class LocalTrendingRepository extends TrendingRepositoryImpl
    implements TrendingRepository {
  const LocalTrendingRepository()
      : super(dataSource: const LocalTrendingDataSource());
}
