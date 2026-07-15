import '../../../core/config/ai_news_sources_config.dart';
import '../../../core/domain/data_freshness.dart';
import '../domain/ai_news_item.dart';
import '../domain/ai_news_repository.dart';
import 'ai_news_merge.dart';
import 'ai_news_rss_client.dart';

/*
*多源聚合仓库:主源(aihot 精选流)+ 补充 RSS/Atom 源。
*策略:
*- head 页(cursor 为空):并行拉主源与全部适用 RSS 源,去重合并
*- 游标翻页:RSS 无分页概念,直接透传主源
*- 关键词搜索:只有主源支持服务端搜索,同样透传
*- 失败隔离:单个 RSS 源失败静默丢弃;主源失败但存在 RSS 结果时
*  模块仍返回 live 数据(这正是引入多源要消除的单点);全军覆没才抛错
*/
class AggregatedAiNewsRepository implements AiNewsRepository {
  const AggregatedAiNewsRepository(
    this._primary,
    this._rssClient, {
    this.sources = AiNewsSourcesConfig.sources,
    this.clock = DateTime.now,
    this.onSourceSuccess,
    this.onSourceFailure,
  });

  final AiNewsRepository _primary;
  final AiNewsRssClient _rssClient;
  final List<AiNewsSourceConfig> sources;
  final DateTime Function() clock;
  final Future<void> Function(String sourceId, DateTime at)? onSourceSuccess;
  final Future<void> Function(String sourceId, DateTime at, Object error)? onSourceFailure;

  @override
  Future<DataResult<AiNewsDigest>> fetchItems({
    AiNewsCategory? category,
    DateTime? since,
    String? query,
    String? cursor,
    bool selectedOnly = true,
  }) async {
    final isHead = cursor == null || cursor.isEmpty;
    final hasQuery = query != null && query.trim().isNotEmpty;
    if (!isHead || hasQuery) {
      return _primary.fetchItems(
        category: category,
        since: since,
        query: query,
        cursor: cursor,
        selectedOnly: selectedOnly,
      );
    }

    final now = clock();
    // 分类筛选时只请求默认分类匹配的源,省掉必然被过滤的流量。
    final applicable = [
      for (final s in sources)
        if (category == null || s.categoryCode == category.code) s
    ];

    final primaryFuture = _guard(() => _primary.fetchItems(category: category, since: since, selectedOnly: selectedOnly));
    final rssFutures = [for (final source in applicable) _fetchSource(source, now)];

    final primaryOutcome = await primaryFuture;
    final rssOutcomes = await Future.wait(rssFutures);

    final extras = [
      for (final o in rssOutcomes)
        if (o.value != null) o.value!
    ];
    final primaryDigest = primaryOutcome.value?.data;
    if (primaryDigest == null && extras.isEmpty) {
      // 全部源失败:抛主源错误,让上层走 staleCache/seed 降级链。
      throw primaryOutcome.error ?? StateError('all ai news sources failed');
    }

    final merged = mergeAiNewsItems(primary: primaryDigest?.items ?? const [], extras: extras);
    return DataResult(
        data: AiNewsDigest(
            items: merged,
            count: merged.length,
            // 分页能力完全由主源提供;主源失败时本页即为全部。
            hasNext: primaryDigest?.hasNext ?? false,
            nextCursor: primaryDigest?.nextCursor),
        freshness: DataFreshness.live);
  }

  static Future<_Outcome<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return _Outcome(value: await run());
    } catch (e) {
      return _Outcome(error: e);
    }
  }

  Future<_Outcome<List<AiNewsItem>>> _fetchSource(AiNewsSourceConfig source, DateTime now) async {
    try {
      final items = await _rssClient.fetchSource(source, now: now);
      await _reportSuccess(source.id, now);
      return _Outcome(value: items);
    } catch (error) {
      await _reportFailure(source.id, now, error);
      return _Outcome(error: error);
    }
  }

  Future<void> _reportSuccess(String sourceId, DateTime at) async {
    try {
      await onSourceSuccess?.call(sourceId, at);
    } catch (_) {
      // 健康状态落盘失败不应把已成功抓取的资讯判为源失败。
    }
  }

  Future<void> _reportFailure(
    String sourceId,
    DateTime at,
    Object error,
  ) async {
    try {
      await onSourceFailure?.call(sourceId, at, error);
    } catch (_) {
      // 健康状态仅用于诊断；记录失败不能改变聚合仓库的降级语义。
    }
  }
}

class _Outcome<T> {
  const _Outcome({this.value, this.error});

  final T? value;
  final Object? error;
}
