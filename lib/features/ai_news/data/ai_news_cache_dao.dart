import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/cache_meta_dao.dart';
import '../domain/ai_news_item.dart';
import '../domain/ai_news_library_filter.dart';

/* 
*AI 资讯本地缓存 DAO。
*表结构由 [LocalDatabase._kBootstrap] 创建,DAO 只负责读写。
*`cache_meta` 表共享给所有 feature,通过 [CacheMetaDao] 注入。
*/
class AiNewsCacheDao {
  AiNewsCacheDao(this._db, this._meta);

  final DatabaseExecutor _db;
  final CacheMetaDao _meta;

  static const String _table = 'ai_news_item';
  static const int _readLimit = 200;

  /* 
  *cache_key 构造规则:模块名:查询维度:游标。
  *`cursor=null` 表示首屏(`head`),后续分页游标直接拼接。
  *这一 key 同时作为 [CacheMetaDao] 的 TTL 索引。
  */
  static String cacheKey({AiNewsCategory? category, String? cursor}) {
    final cat = category?.code ?? 'all';
    final cur = (cursor == null || cursor.isEmpty) ? 'head' : cursor;
    return 'ai_news:items:category=$cat:cursor=$cur';
  }

  /* 
  *读出指定分类(或全部)的所有缓存条目,按发布时间倒序。
  *注意:本方法是「整库扫描」,不区分 cursor——因为本地缓存的核心
  *价值就是「打开瞬间能渲染」,而不是严格重现远端分页。UI 侧的
  *触底加载会用 buffer 切片复刻分页体验。
  */
  Future<List<AiNewsItem>> readAll({AiNewsCategory? category}) async {
    try {
      final rows = await _db.query(
        _table,
        where: category == null ? null : 'category = ?',
        whereArgs: category == null ? null : [category.code],
        orderBy: 'published_at DESC',
        limit: _readLimit,
      );
      return rows.map(_rowToItem).toList(growable: false);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'readAll'},
      );
    }
  }

  // 单次搜索返回上限。
  static const int _searchLimit = 100;

  /*
  *资讯库全库搜索:FTS5 匹配标题/英文标题/摘要/来源,并支持来源、时间、
  *分类、已读状态过滤。非空查询按 BM25 相关性优先,同分按时间倒序。
  *与 [readAll] 不同,这里不受 [_readLimit] 的「首屏渲染」定位约束,
  *面向的是沉淀在本地的全部历史条目。`%`/`_`/转义符做 ESCAPE 处理。
  */
  Future<List<AiNewsItem>> searchAll(
    String query, {
    AiNewsCategory? category,
    AiNewsLibraryFilter filter = const AiNewsLibraryFilter(),
  }) async {
    final keyword = query.trim();
    try {
      final where = <String>[];
      final args = <Object?>[];
      final selectedCategory = filter.category ?? category;
      if (keyword.isNotEmpty) {
        where.add('ai_news_fts MATCH ?');
        args.add(_ftsQuery(keyword));
      }
      if (selectedCategory != null) {
        where.add('i.category = ?');
        args.add(selectedCategory.code);
      }
      final source = filter.source?.trim();
      if (source != null && source.isNotEmpty) {
        where.add('i.source = ?');
        args.add(source);
      }
      if (filter.publishedAfter != null) {
        where.add('i.published_at >= ?');
        args.add(filter.publishedAfter!.millisecondsSinceEpoch);
      }
      if (filter.publishedBefore != null) {
        where.add('i.published_at < ?');
        args.add(filter.publishedBefore!.millisecondsSinceEpoch);
      }
      switch (filter.read) {
        case AiNewsReadFilter.all:
          break;
        case AiNewsReadFilter.unread:
          where.add('s.read_at IS NULL');
          break;
        case AiNewsReadFilter.read:
          where.add('s.read_at IS NOT NULL');
          break;
      }
      final rows = await _db.rawQuery(
        'SELECT i.* FROM ${keyword.isEmpty ? 'ai_news_item i' : 'ai_news_fts JOIN ai_news_item i ON i.id = ai_news_fts.item_id'} '
        'LEFT JOIN ai_news_state s ON s.item_id = i.id '
        '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} '
        'ORDER BY ${keyword.isEmpty ? '' : 'bm25(ai_news_fts), '}i.published_at DESC '
        'LIMIT $_searchLimit',
        args,
      );
      return rows.map(_rowToItem).toList(growable: false);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'searchAll'},
      );
    }
  }

  /* 返回资讯库中可用于过滤的来源列表。 */
  Future<List<String>> sources() async {
    try {
      final rows = await _db.rawQuery(
        'SELECT DISTINCT source FROM $_table WHERE source != ? ORDER BY source',
        [''],
      );
      return rows.map((row) => row['source'] as String).toList(growable: false);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'sources'},
      );
    }
  }

  /*
  *按条目 id 读取缓存详情。
  */
  Future<AiNewsItem?> readById(String id) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return _rowToItem(rows.first);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'readById'},
      );
    }
  }

  /* 
  *写入一批远端返回的条目,并把对应 [cacheKey] 的 last_fetched_at 更新。
  *- 若 [digest.items] 为空,仍会更新 meta(避免「空响应也算新鲜」)
  *- 使用 INSERT OR REPLACE,使旧条目被新值覆盖
  *- 同条目再次入库时 `cached_at` 会被刷新,延长其容量清理豁免期
  */
  Future<void> upsertPage({
    required AiNewsCategory? category,
    required String? cursor,
    required AiNewsDigest digest,
    required DateTime now,
  }) async {
    final cachedAt = now.millisecondsSinceEpoch;
    try {
      final batch = _db.batch();
      for (final item in digest.items) {
        batch.insert(
          _table,
          {
            'id': item.id,
            'category': item.category.code,
            'title': item.title,
            'title_en': item.titleEn,
            'summary': item.summary,
            'source': item.source,
            'url': item.url,
            'permalink': item.permalink,
            'published_at': item.publishedAt.millisecondsSinceEpoch,
            'score': item.score,
            'selected': item.selected ? 1 : 0,
            'cached_at': cachedAt
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      await _meta.upsert(cacheKey(category: category, cursor: cursor), now);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'upsertPage'},
      );
    }
  }

  /* 
  *缓存是否还新鲜:`true` = 距上次拉取不足 [ttl]。
  */
  Future<bool> isFresh({
    required AiNewsCategory? category,
    required String? cursor,
    required Duration ttl,
    required DateTime now,
  }) async {
    final last = await _meta.lastFetched(cacheKey(category: category, cursor: cursor));
    if (last == null) {
      return false;
    }
    return now.difference(last) < ttl;
  }

  /* 
  *清空所有 AI 资讯条目(不动 meta)。
  *全局清空走 [LocalDatabase.clearAll]——它同时会清掉 meta 与其它 feature 表。
  */
  Future<void> clear() async {
    try {
      await _db.delete(_table);
    } catch (e, st) {
      throw AppException(
        kind: AppExceptionKind.cache,
        cause: e,
        stack: st,
        meta: {'op': 'clear'},
      );
    }
  }

  static AiNewsItem _rowToItem(Map<String, Object?> row) {
    return AiNewsItem(
      id: row['id'] as String,
      category: AiNewsCategory.fromCode(row['category'] as String?) ?? AiNewsCategory.industry,
      title: row['title'] as String,
      titleEn: row['title_en'] as String,
      summary: row['summary'] as String,
      source: row['source'] as String,
      url: row['url'] as String,
      permalink: row['permalink'] as String,
      publishedAt: DateTime.fromMillisecondsSinceEpoch(row['published_at'] as int, isUtc: true),
      score: row['score'] as int,
      selected: (row['selected'] as int) == 1,
    );
  }

  static String _ftsQuery(String query) {
    final tokens = query.trim().split(RegExp(r'\s+')).where((token) => token.isNotEmpty).map((token) => '"${token.replaceAll('"', '""')}"*');
    return tokens.join(' AND ');
  }
}
