import '../../../core/ai_hot/ai_hot_resource_cache.dart';
import '../../../core/config/ai_news_sources_config.dart';
import '../../../core/config/cache_ttl_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/ai_news_item.dart';
import 'ai_news_feed_parser.dart';

/*
*RSS/Atom 源客户端。
*每个源独立保存 ETag/Last-Modified 和原始快照;
*单源失败由聚合仓库隔离,不拖垮其余源。
*/
class AiNewsRssClient {
  const AiNewsRssClient(this._resources);

  // 带条件请求与 stale fallback 的资源客户端。
  final AiHotResourceCache _resources;

  /*
  *拉取并解析单个源,返回按发布时间倒序、按源限额且在新鲜窗口内的条目。
  */
  Future<DataResult<List<AiNewsItem>>> fetchSource(AiNewsSourceConfig source, {required DateTime now}) async {
    final result = await _resources.getText(
      url: source.feedUrl,
      ttl: CacheTtlConfig.aiNewsRss,
    );
    final body = result.data;
    if (body.trim().isEmpty) {
      throw AppException(
        kind: AppExceptionKind.parse,
        meta: {'source': source.id, 'reason': 'empty body'},
      );
    }
    final items = parseAiNewsFeed(body, source: source, fallbackTime: now);
    final cutoff = now.toUtc().subtract(AiNewsSourcesConfig.recencyWindow);
    final recent = [
      for (final item in items)
        if (item.publishedAt.isAfter(cutoff)) item,
    ]..sort((left, right) => right.publishedAt.compareTo(left.publishedAt));
    if (recent.length <= AiNewsSourcesConfig.maxItemsPerSource) {
      return DataResult(data: recent, freshness: result.freshness);
    }
    return DataResult(
      data: recent.sublist(0, AiNewsSourcesConfig.maxItemsPerSource),
      freshness: result.freshness,
    );
  }
}
