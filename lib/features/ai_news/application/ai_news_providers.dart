import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_ai_news_repository.dart';
import '../domain/ai_news_item.dart';
import '../domain/ai_news_repository.dart';

final aiNewsRepositoryProvider = Provider<AiNewsRepository>((ref) {
  return const LocalAiNewsRepository();
});

final aiNewsDigestProvider = Provider<AiNewsDigest>((ref) {
  return ref.watch(aiNewsRepositoryProvider).getDigest();
});

/// 分类筛选:`null` 表示全部分类。
final aiNewsCategoryFilterProvider =
    StateProvider<AiNewsCategory?>((ref) => null);

/// 时间窗筛选,默认 24h。
final aiNewsWindowFilterProvider = StateProvider<String>((ref) => '24h');

/// 在 digest 之上派生出过滤后的列表。
final aiNewsFilteredItemsProvider = Provider<List<AiNewsItem>>((ref) {
  final digest = ref.watch(aiNewsDigestProvider);
  final category = ref.watch(aiNewsCategoryFilterProvider);
  if (category == null) return digest.items;
  return digest.items.where((e) => e.category == category).toList();
});
