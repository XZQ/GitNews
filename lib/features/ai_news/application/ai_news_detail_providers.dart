import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/ai_news_item.dart';
import 'ai_news_providers.dart';

/// 单条 AI 动态详情。未找到时抛 [AppExceptionKind.notFound]。
final aiNewsDetailProvider =
    FutureProvider.family<AiNewsItem, String>((ref, id) async {
  final item = ref.watch(aiNewsRepositoryProvider).getById(id);
  if (item == null) {
    throw const AppException(kind: AppExceptionKind.notFound);
  }
  return item;
});

/// 与当前条目相关的其它动态(取前 3 条,排除自身)。
final aiNewsRelatedProvider =
    Provider.family<List<AiNewsItem>, String>((ref, id) {
  final all = ref.watch(aiNewsRepositoryProvider).all();
  return all.where((e) => e.id != id).take(3).toList();
});
