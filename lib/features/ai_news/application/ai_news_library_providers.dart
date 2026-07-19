import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/ai_news_state_dao.dart';
import '../domain/ai_news_item.dart';
import '../domain/ai_news_item_state.dart';
import '../domain/ai_news_library_filter.dart';
import 'ai_news_providers.dart';

/*
*资讯库(本地沉淀内容)相关 provider:全库搜索、已读、稍后读。
*与 ai_news_providers.dart 的「远端流 + 分页缓存」职责分离。
*/

final aiNewsStateDaoProvider = Provider<AiNewsStateDao>((ref) => AiNewsStateDao(ref.watch(appDatabaseProvider).executor));

// 只看稍后读开关(列表页)。
final aiNewsReadLaterOnlyProvider = StateProvider<bool>((ref) => false);

// 资讯库来源/时间/已读过滤器；分类仍复用页面主分类导航。
final aiNewsLibraryFilterProvider = StateProvider<AiNewsLibraryFilter>((ref) => const AiNewsLibraryFilter());

final aiNewsLibrarySourcesProvider = FutureProvider.autoDispose<List<String>>((ref) => ref.watch(aiNewsCacheDaoProvider).sources());

// 全库搜索:关键词非空时查询 SQLite 沉淀的全部历史条目,
// 不再只过滤内存中已加载的分页 buffer。跟随当前分类筛选。
final aiNewsLibrarySearchProvider = FutureProvider.autoDispose.family<List<AiNewsItem>, String>((ref, query) {
  final category = ref.watch(aiNewsCategoryFilterProvider);
  final filter = ref.watch(aiNewsLibraryFilterProvider);
  return ref.watch(aiNewsCacheDaoProvider).searchAll(query, category: category, filter: filter);
});

// 稍后读列表(实体快照重建,清缓存不受影响)。
final aiNewsReadLaterItemsProvider = FutureProvider.autoDispose<List<AiNewsItem>>((ref) => ref.watch(aiNewsStateDaoProvider).readLaterItems());

// 单条已读/稍后读状态(详情页动作按钮)。
final aiNewsItemStateProvider = FutureProvider.autoDispose.family<AiNewsItemState, String>((ref, id) => ref.watch(aiNewsStateDaoProvider).stateOf(id));

final aiNewsLibraryControllerProvider = Provider<AiNewsLibraryController>(AiNewsLibraryController.new);

/*
*资讯库写操作入口:落库后精确失效相关读 provider。
*/
class AiNewsLibraryController {
  const AiNewsLibraryController(this._ref);

  final Ref _ref;

  /*
  *详情页打开时标记已读(幂等,失败静默——阅读不应被本地 IO 打断)。
  */
  Future<void> markRead(AiNewsItem item) async {
    try {
      final now = _ref.read(clockProvider)();
      await _ref.read(aiNewsStateDaoProvider).markRead(item, now: now);
      _ref.invalidate(aiNewsItemStateProvider(item.id));
    } catch (_) {
      // 已读标记是尽力而为的本地增强,不打断阅读主流程。
    }
  }

  /*
  *切换稍后读;返回切换后的状态(true = 已加入)。
  */
  Future<bool> toggleReadLater(AiNewsItem item) async {
    final now = _ref.read(clockProvider)();
    final added = await _ref.read(aiNewsStateDaoProvider).toggleReadLater(item, now: now);
    _ref.invalidate(aiNewsItemStateProvider(item.id));
    _ref.invalidate(aiNewsReadLaterItemsProvider);
    return added;
  }
}
