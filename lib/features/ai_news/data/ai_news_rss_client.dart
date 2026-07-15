import 'package:dio/dio.dart';

import '../../../core/config/ai_news_sources_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/github/github_api_support.dart';
import '../domain/ai_news_item.dart';
import 'ai_news_feed_parser.dart';

/*
*补充 RSS/Atom 源客户端。
*每次调用只拉单个源;失败以 [AppException] 抛出,由聚合仓库做
*「单源失败隔离」——任何一个源挂掉不拖垮其余源。
*/
class AiNewsRssClient {
  const AiNewsRssClient(this._dio);

  final Dio _dio;

  static const Map<String, Object?> _headers = {'Accept': 'application/rss+xml, application/atom+xml, application/xml, text/xml', 'User-Agent': GitHubApiSupport.userAgent};

  /*
  *拉取并解析单个源,返回按发布时间倒序、截断到
  *[AiNewsSourcesConfig.maxItemsPerSource]、且在
  *[AiNewsSourcesConfig.recencyWindow] 内的条目。
  */
  Future<List<AiNewsItem>> fetchSource(AiNewsSourceConfig source, {required DateTime now}) async {
    final String? body;
    try {
      final resp = await _dio.get<String>(source.feedUrl, options: Options(responseType: ResponseType.plain, headers: _headers));
      body = resp.data;
    } on DioException catch (e) {
      throw e.toAppException();
    }
    if (body == null || body.trim().isEmpty) {
      throw AppException(kind: AppExceptionKind.parse, meta: {'source': source.id, 'reason': 'empty body'});
    }
    final items = parseAiNewsFeed(body, source: source, fallbackTime: now);
    final cutoff = now.toUtc().subtract(AiNewsSourcesConfig.recencyWindow);
    final recent = [
      for (final item in items)
        if (item.publishedAt.isAfter(cutoff)) item
    ]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    if (recent.length <= AiNewsSourcesConfig.maxItemsPerSource) {
      return recent;
    }
    return recent.sublist(0, AiNewsSourcesConfig.maxItemsPerSource);
  }
}
