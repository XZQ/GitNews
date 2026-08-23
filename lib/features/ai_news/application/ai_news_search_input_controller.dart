import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'ai_news_providers.dart';

/*
*搜索输入防抖控制器。
*
*搜索框键入直写 [aiNewsSearchQueryProvider] 时,每次按键都会触发一次
*全库 FTS 查询 + 兴趣排序 + 事件聚类,这里统一收敛到键入间歇提交;
*回车提交、清空返回列表和跨页路由写入立即生效。
*/
final aiNewsSearchInputControllerProvider = Provider<AiNewsSearchInputController>((ref) {
  final controller = AiNewsSearchInputController(ref);
  ref.onDispose(controller.cancelPending);
  return controller;
});

// 搜索框即时草稿;远端/路由写入查询时同步,键入期间不触发昂贵的数据筛选。
final aiNewsSearchDraftProvider = StateProvider<String>((ref) => ref.watch(aiNewsSearchQueryProvider));

class AiNewsSearchInputController {
  AiNewsSearchInputController(this._ref);

  final Ref _ref;
  Timer? _timer;

  // 键入间歇语义:250ms 覆盖连续输入且无可感知延迟。
  static const Duration _debounceWindow = Duration(milliseconds: 250);

  // 键入防抖;[immediate] 用于提交、清空与路由跳转等一次性完整关键词。
  void update(String value, {bool immediate = false}) {
    if (_ref.read(aiNewsSearchDraftProvider) != value) {
      _ref.read(aiNewsSearchDraftProvider.notifier).state = value;
    }
    if (immediate || value.isEmpty) {
      cancelPending();
      _commit(value);
      return;
    }
    if (value == _ref.read(aiNewsSearchQueryProvider)) {
      cancelPending();
      return;
    }
    _timer?.cancel();
    _timer = Timer(_debounceWindow, () {
      _timer = null;
      _commit(value);
    });
  }

  // 取消未提交的防抖任务;不改变已生效的搜索词。
  void cancelPending() {
    _timer?.cancel();
    _timer = null;
  }

  void _commit(String value) {
    if (_ref.read(aiNewsSearchQueryProvider) == value) {
      return;
    }
    _ref.read(aiNewsSearchQueryProvider.notifier).state = value;
  }
}
